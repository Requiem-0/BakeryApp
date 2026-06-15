import 'package:flutter/foundation.dart';

import '../../../../core/constants.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../orders/data/models/order.dart';
import '../../data/models/api_cart.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';

/// Cart state with two modes: authed users round-trip every mutation
/// through `/api/cart/*` (local state is optimistic); guests get a pure
/// in-memory cart that doesn't survive restarts. main.dart's auth
/// listener flips modes via [bootstrap] / [clear].
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final CartRepository _repo;

  /// True iff the customer is signed in. CartProvider uses this to skip
  /// API calls for guests (the cart endpoints all 401 without a token).
  bool Function() _isAuthenticated;

  /// Hydrates a productId to a full [Product] from the catalogue, since
  /// `GET /my-cart` only returns thin (id/name/image) product data.
  /// Null when the catalogue hasn't loaded that product yet.
  Product? Function(String productId)? _productResolver;

  /// Reads the per-order service charge from the live business config
  /// instead of hardcoding. 0 until the business loads.
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
  /// On sign-in: any items the user added as a guest are pushed to the
  /// server first so they survive the login transition. The server-
  /// authoritative cart is fetched at the end to pick up anything the
  /// server already had.
  ///
  /// No-ops for guests. Errors are swallowed (caller can't recover) but
  /// logged for diagnostics.
  Future<void> bootstrap() async {
    if (!_isAuthenticated()) return;
    _isLoading = true;
    notifyListeners();

    // Snapshot the guest cart before any server call overwrites _items.
    final guestItems = List<CartItem>.from(_items);

    try {
      if (guestItems.isEmpty) {
        // Cold-start: no local items to migrate, just hydrate from
        // whatever the server already has for this user.
        final result = await _repo.fetchMyCart();
        if (result.isSuccess && result.data != null) {
          _replaceItemsFrom(result.data!);
        }
        return;
      }

      // Guest → user migration. addItem returns the full updated cart,
      // so the loop's last successful response already includes any
      // pre-existing server lines. No separate fetch needed — that
      // would wipe local items if pushes 401 during the auth-token
      // handover race.
      bool anyPushSucceeded = false;
      for (final guest in guestItems) {
        final adminId = guest.product.adminId;
        if (adminId == null || adminId.isEmpty) continue; // synthetic product

        final addonsMap = <String, int>{
          for (final a in guest.addons) a.addonId: a.quantity,
        };

        final pushed = await _repo.addItem(
          adminId: adminId,
          productId: guest.product.id,
          variantItemId: guest.variantItemId,
          quantity: guest.quantity,
          addons: addonsMap,
        );
        if (pushed.isSuccess && pushed.data != null) {
          _replaceItemsFrom(pushed.data!);
          anyPushSucceeded = true;
        } else {
          debugPrint(
              '⚠️ Cart migration push failed: ${pushed.failure?.message}');
        }
      }

      if (!anyPushSucceeded) {
        // Every push 401'd or errored. Local items are still in _items
        // (no _replaceItemsFrom fired), so the user keeps their cart.
        // Server stays empty until they take another mutation that
        // succeeds; for then-future syncs we'll be back in normal mode.
        debugPrint(
            '⚠️ Guest cart migration: 0/${guestItems.length} lines reached '
            'the server. Cart preserved locally; will resync on next mutation.');
      }
    } catch (e) {
      debugPrint('🚨 CartProvider.bootstrap: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Adds [product] to the cart. Auto-picks the first variant when
  /// [variant] is null but the product has variants (home-grid "+"
  /// flow). [addons] maps addon id → qty. Returns false + rolls back
  /// the optimistic add on server failure; reason in [errorMessage].
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
      // Synthetic product (reorder fallback) — server doesn't know
      // this id. Leave the optimistic add in place; checkout will
      // refuse it later, which is the right outcome.
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

  /// Targets a specific line by index — needed when two cart lines share
  /// a product id but carry different variants/addons ([updateById]
  /// can't disambiguate). Server `PUT /cart/` keys by product id, so
  /// it may merge variant-distinct lines on its side; checkout re-sends
  /// per-line variants and addons so the ticket stays accurate.
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
        // Match the original variant by price — ticket doesn't round-trip
        // the variant id. Ties (same price across variants) take the first
        // hit; the customer can re-pick before checkout.
        VariantItem? variantPick;
        if (oi.price > 0) {
          for (final v in match.variantItems) {
            if (v.price == oi.price) {
              variantPick = v;
              break;
            }
          }
        }

        // Backend regenerates subdoc _ids per order, so addon ids won't
        // match the catalogue's. Match by normalised name instead.
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

        // Fire-and-forget; errors surface via errorMessage + notify.
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
