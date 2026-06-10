import 'package:flutter/foundation.dart';

import '../../../../core/constants.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../orders/data/models/order.dart';
import '../../data/models/api_cart.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';

/// Manages the shopping-cart state.
///
/// Authed users get a server-synced cart: local state is the optimistic
/// reflection of `/api/cart/*` and every mutation round-trips through the
/// backend. Guests get a pure in-memory cart — same data shape, no API
/// calls, no persistence across app restarts. The auth listener in
/// `main.dart` flips between the two modes by calling [bootstrap] on
/// login and [clear] on logout.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final CartRepository _repo;

  /// True iff the customer is signed in. CartProvider uses this to skip
  /// API calls for guests (the cart endpoints all 401 without a token).
  bool Function() _isAuthenticated;

  /// Resolves a productId to a fully-populated [Product]. Used when
  /// hydrating from `GET /my-cart` — the cart response only carries a
  /// thin product (id, name, image), so we ask the catalogue for the
  /// full version (with adminId, variantItems, addons) when available.
  /// Returns null when the catalogue hasn't loaded that product yet, in
  /// which case we fall back to a thin local Product.
  Product? Function(String productId)? _productResolver;

  /// Pulls the per-order service charge (baking/packaging/etc.) from the
  /// active business config. Lets the cart's total reflect what the
  /// backend will actually charge instead of a hardcoded number. Returns
  /// 0 when no business has loaded yet (fee just won't show until then).
  double Function()? _serviceChargeResolver;

  bool _isLoading = false;
  String? _errorMessage;

  CartProvider({
    required CartRepository repository,
    required bool Function() isAuthenticated,
    Product? Function(String productId)? productResolver,
    double Function()? serviceChargeResolver,
  })  : _repo = repository,
        _isAuthenticated = isAuthenticated,
        _productResolver = productResolver,
        _serviceChargeResolver = serviceChargeResolver;

  /// Late-bound resolver — main.dart needs to wire the cart before the
  /// catalogue provider is constructed, so we expose a setter so the
  /// catalogue lookup can be attached once both providers exist.
  set productResolver(Product? Function(String productId)? resolver) {
    _productResolver = resolver;
  }

  set isAuthenticatedFn(bool Function() fn) {
    _isAuthenticated = fn;
  }

  /// Late-bound — set this from main.dart once BusinessProvider exists so
  /// the cart's [serviceCharge] reflects the live business config.
  set serviceChargeResolver(double Function()? resolver) {
    _serviceChargeResolver = resolver;
    notifyListeners();
  }

  // ── Public state ──────────────────────────────────────────────────────────

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal =>
      _items.fold<double>(0, (sum, i) => sum + i.lineTotal);

  /// Per-order service charge applied at checkout. Reads from the live
  /// business config (`orderChargePerOrder`) when one is wired, falling
  /// back to 0 when no business has loaded — never falls back to a
  /// hardcoded number so we don't quietly charge the wrong amount.
  double get serviceCharge {
    if (_items.isEmpty) return 0;
    return _serviceChargeResolver?.call() ?? 0;
  }

  double get total => subtotal + serviceCharge;

  bool contains(Product product) =>
      _items.any((i) => i.product.id == product.id);

  // ── Hydration ─────────────────────────────────────────────────────────────

  /// Pulls the server-side cart and replaces the local list.
  ///
  /// No-ops for guests. Errors are swallowed (caller cannot recover; the
  /// local cart just stays empty) but logged for diagnostics.
  Future<void> bootstrap() async {
    if (!_isAuthenticated()) return;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repo.fetchMyCart();
      if (result.isSuccess && result.data != null) {
        _replaceItemsFrom(result.data!);
      }
    } catch (e) {
      debugPrint('🚨 CartProvider.bootstrap: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Adds [product] to the cart.
  ///
  /// When the product has variants and the caller doesn't specify
  /// [variant], the first available variant is auto-picked (mirrors the
  /// pre-API behaviour of the quick-add button on product cards). When
  /// [variant] is non-null the caller's pick wins.
  ///
  /// [addons] maps addon `_id` → quantity. Pass an empty map (default)
  /// when the product has no addons or the user picked none.
  ///
  /// Returns true on success. On failure, the optimistic local update is
  /// rolled back and [errorMessage] is set so the caller can surface a
  /// toast.
  Future<bool> addProduct(
    Product product, {
    VariantItem? variant,
    Map<String, int> addons = const {},
    int quantity = 1,
    Map<String, String> selectedVariants = const {},
  }) async {
    final effectiveVariant = variant ??
        (product.variantItems.isNotEmpty ? product.variantItems.first : null);
    final effectiveAddons = _buildLocalAddons(product, addons);

    // ── Optimistic local update ──────────────────────────────────
    final snapshot = _snapshot();
    final existingIdx = _items.indexWhere((i) =>
        i.product.id == product.id &&
        i.variantItemId == effectiveVariant?.id);

    if (existingIdx >= 0) {
      _items[existingIdx].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        variantItemId: effectiveVariant?.id,
        variantItemLabel: effectiveVariant?.label,
        unitPrice: effectiveVariant?.price ?? product.price,
        addons: effectiveAddons,
        selectedVariants: selectedVariants,
      ));
    }
    notifyListeners();

    // ── Guest mode: stop here (in-memory only) ───────────────────
    if (!_isAuthenticated()) return true;

    // ── Server sync ──────────────────────────────────────────────
    final adminId = product.adminId;
    if (adminId == null || adminId.isEmpty) {
      // Synthetic product (e.g. reorder fallback) — can't address the
      // server's catalogue, so leave the optimistic add in place but
      // don't try to sync.
      debugPrint(
          '⚠️ CartProvider.addProduct: skipping API for product without adminId (${product.id})');
      return true;
    }

    final result = await _repo.addItem(
      adminId: adminId,
      productId: product.id,
      variantItemId: effectiveVariant?.id,
      quantity: quantity,
      addons: addons,
    );
    if (result.isFailure) {
      _restore(snapshot);
      _errorMessage = result.failure?.message ?? 'Could not add to cart';
      notifyListeners();
      return false;
    }
    _replaceItemsFrom(result.data!);
    notifyListeners();
    return true;
  }

  /// Sets the absolute quantity of the line for [productId]. Quantity 0
  /// removes the line.
  Future<bool> updateById(String productId, int quantity) async {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return false;

    if (quantity <= 0) {
      return removeAt(index);
    }

    final snapshot = _snapshot();
    _items[index].quantity = quantity;
    notifyListeners();

    if (!_isAuthenticated()) return true;

    final result =
        await _repo.updateItem(productId: productId, quantity: quantity);
    if (result.isFailure) {
      _restore(snapshot);
      _errorMessage = result.failure?.message ?? 'Could not update cart';
      notifyListeners();
      return false;
    }
    _replaceItemsFrom(result.data!);
    notifyListeners();
    return true;
  }

  /// Updates the quantity of the line at [index] directly. Required
  /// when the cart contains two lines that share a product id but
  /// carry different variants/addons — going through [updateById]
  /// would always hit the first match by product id, hijacking the
  /// wrong line.
  ///
  /// Server sync still goes through `PUT /cart/` which keys by
  /// product id, so the server may merge variant-distinct lines into
  /// a single quantity. The local state stays correct; checkout
  /// re-sends the right per-line variants and addons so the ticket
  /// is accurate.
  Future<bool> updateQuantity(int index, int qty) async {
    if (index < 0 || index >= _items.length) return false;

    if (qty <= 0) {
      return removeAt(index);
    }

    final snapshot = _snapshot();
    _items[index].quantity = qty;
    notifyListeners();

    if (!_isAuthenticated()) return true;

    final productId = _items[index].product.id;
    final result =
        await _repo.updateItem(productId: productId, quantity: qty);
    if (result.isFailure) {
      _restore(snapshot);
      _errorMessage = result.failure?.message ?? 'Could not update cart';
      notifyListeners();
      return false;
    }
    _replaceItemsFrom(result.data!);
    notifyListeners();
    return true;
  }

  /// Removes the line at [index]. Uses `DELETE /api/cart/{lineId}` when
  /// the line has a [CartItem.serverItemId]; otherwise just drops it
  /// locally (it was never persisted server-side).
  Future<bool> removeAt(int index) async {
    if (index < 0 || index >= _items.length) return false;
    final snapshot = _snapshot();
    final removed = _items.removeAt(index);
    notifyListeners();

    if (!_isAuthenticated() ||
        removed.serverItemId == null ||
        removed.serverItemId!.isEmpty) {
      return true;
    }

    final result = await _repo.deleteItem(removed.serverItemId!);
    if (result.isFailure) {
      _restore(snapshot);
      _errorMessage = result.failure?.message ?? 'Could not remove item';
      notifyListeners();
      return false;
    }
    _replaceItemsFrom(result.data!);
    notifyListeners();
    return true;
  }

  /// Empties the cart. For authed users with synced lines, sends a bulk
  /// delete; for guests (or items without serverItemId), just drops
  /// everything locally.
  Future<void> clear() async {
    if (_items.isEmpty) return;

    final syncedIds = _items
        .map((i) => i.serverItemId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    _items.clear();
    notifyListeners();

    if (!_isAuthenticated() || syncedIds.isEmpty) return;

    final result = await _repo.deleteItems(syncedIds);
    if (result.isFailure) {
      debugPrint('🚨 CartProvider.clear: ${result.failure?.message}');
    }
  }

  /// Adds items from a past order directly to the cart. Best-effort —
  /// items whose source product can't be located in the live catalogue
  /// fall through to a thin synthetic Product so the line still renders
  /// (but won't sync to the server, since synthetic products have no
  /// adminId).
  void reorder(Order pastOrder, {List<Product> availableProducts = const []}) {
    _items.clear();

    for (final oi in pastOrder.items) {
      if ((oi.productId == null || oi.productId!.isEmpty) &&
          oi.name == 'Item' &&
          oi.price == 0) {
        continue;
      }

      Product? match;
      if (oi.productId != null && oi.productId!.isNotEmpty) {
        try {
          match = availableProducts.firstWhere((p) => p.id == oi.productId);
        } catch (_) {}
      }

      if (match != null) {
        // Re-pick the variant the customer originally chose. The
        // ticket endpoint stores `unitPrice` (the variant's price) on
        // the line, so matching by price is the most reliable signal
        // — the order itself doesn't round-trip the variant id or
        // label in any field we can read. When multiple variants
        // share the same price (e.g. Brownie's 4 flavors all at Rs
        // 375), we accept the first hit; the customer can re-pick
        // before checkout if it matters.
        VariantItem? variantPick;
        if (oi.price > 0) {
          for (final v in match.variantItems) {
            if (v.price == oi.price) {
              variantPick = v;
              break;
            }
          }
        }

        // Re-pick addons. The backend stores fresh _ids for embedded
        // subdocuments, so the order's addon id doesn't match the
        // catalogue's — same gotcha we hit in OrderProvider
        // enrichment. Fall back to a normalized name match to bridge
        // the gap.
        final addonsMap = <String, int>{};
        for (final orderAddon in oi.addons) {
          if (orderAddon.name.isEmpty) continue;
          final target = orderAddon.name.trim().toLowerCase();
          for (final pa in match.addons) {
            if (pa.name.trim().toLowerCase() == target) {
              addonsMap[pa.id] = orderAddon.quantity;
              break;
            }
          }
        }

        // Fire-and-forget — addProduct returns a Future but reorder is
        // sync from the caller's perspective. Errors are surfaced via
        // errorMessage and notifyListeners.
        addProduct(
          match,
          quantity: oi.qty,
          variant: variantPick,
          addons: addonsMap,
        );
      } else {
        final label = (oi.name == 'Item' || oi.name.trim().isEmpty)
            ? (oi.productId != null && oi.productId!.isNotEmpty
                ? 'Item from order #${pastOrder.id}'
                : 'Previously ordered item')
            : oi.name;

        addProduct(
          Product(
            id: oi.productId ?? 'reorder_${label.hashCode}',
            name: label,
            category: 'breads',
            price: oi.price,
            reviews: 100,
            image: '🍴',
            imageUrl: (oi.image.startsWith('http') || oi.image.contains('/'))
                ? oi.image
                : null,
            description: 'From your previous purchase history.',
            tags: const ['Reordered'],
            time: 'Freshly baked',
          ),
          quantity: oi.qty,
        );
      }
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Rebuilds [_items] from the server's authoritative cart.
  ///
  /// Each line's product is resolved against the catalogue (via
  /// [_productResolver]); on miss, we build a thin Product from the
  /// inline fields the cart endpoint returns. Either way the user sees
  /// a name + image — they won't see "Product 6a21..." in the cart.
  void _replaceItemsFrom(ApiCart cart) {
    final next = <CartItem>[];
    for (final line in cart.items) {
      final resolved = _productResolver?.call(line.productId);
      final product = resolved ??
          Product(
            id: line.productId,
            name: line.productName ?? 'Product',
            category: '',
            price: line.unitPrice,
            reviews: 0,
            image: '🍴',
            imageUrl: AppConstants.resolveImageUrl(line.productImage),
            description: '',
            tags: const [],
            time: '',
          );

      next.add(CartItem(
        product: product,
        quantity: line.quantity,
        variantItemId: line.variantItemId,
        variantItemLabel: line.variantItemLabel,
        unitPrice: line.unitPrice,
        addons: line.addons
            .map((a) => CartItemAddon(
                  addonId: a.addonId,
                  name: a.name,
                  quantity: a.quantity,
                  unitPrice: a.unitPrice,
                ))
            .toList(),
        serverItemId: line.lineId,
      ));
    }
    _items
      ..clear()
      ..addAll(next);
  }

  /// Maps `addonId → qty` (the format used by the API) into the local
  /// `CartItemAddon` model (carries name + price for display). Resolves
  /// the name/price from [product.addons]; falls back to a placeholder
  /// when the addon isn't found (shouldn't happen in practice).
  List<CartItemAddon> _buildLocalAddons(
    Product product,
    Map<String, int> selected,
  ) {
    if (selected.isEmpty) return const [];
    return selected.entries.map((e) {
      final src = product.addons.firstWhere(
        (a) => a.id == e.key,
        orElse: () => ProductAddon(id: e.key, name: 'Addon', price: 0),
      );
      return CartItemAddon(
        addonId: e.key,
        name: src.name,
        quantity: e.value,
        unitPrice: src.price,
      );
    }).toList();
  }

  /// Snapshot the current items list so a failed API call can be rolled
  /// back. Deep enough to preserve item state (qty changes inside the
  /// optimistic phase) without cloning Product (which is immutable).
  List<CartItem> _snapshot() {
    return _items
        .map((i) => i.copyWith(quantity: i.quantity, addons: List.of(i.addons)))
        .toList();
  }

  void _restore(List<CartItem> snapshot) {
    _items
      ..clear()
      ..addAll(snapshot);
  }
}
