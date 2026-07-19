import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../orders/data/models/order.dart';
import '../../data/models/api_cart.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';

/// SharedPreferences key for the locally-persisted cart snapshot.
/// Bumped via the `_v1` suffix if the shape ever changes — older
/// payloads decode safely (try/catch wraps the decode) but the user
/// loses their old cart, which is acceptable for a one-time migration.
const String _kCartLocalKey = 'cart:local_items_v1';

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



  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal =>
      _items.fold<double>(0, (sum, i) => sum + i.lineTotal);

  /// Total amount the `applyEverytime` rules knocked off this cart.
  /// Computed by reverse-projecting each line's post-discount unitPrice
  /// through its rule rate to get the pre-discount total, then summing
  /// the deltas. Zero when no line carries an active rule.
  double get discountTotal {
    double total = 0;
    for (final i in _items) {
      final disc = i.product.autoDiscount;
      if (disc == null || disc.rate <= 0) continue;

      final addonPerUnit = i.addons
          .fold<double>(0, (s, a) => s + a.unitPrice * a.quantity);
      final paid = (i.unitPrice + addonPerUnit) * i.quantity;
      double pre = paid;
      if (disc.type == 'percentage' && disc.rate < 100) {
        pre = paid / (1 - disc.rate / 100);
      } else if (disc.type == 'flat') {
        pre = paid + disc.rate * i.quantity;
      }
      total += pre - paid;
    }
    return total;
  }

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

  /// Quantity in cart for a specific (product, variant, addons) tuple.
  /// Returns 0 when no line matches.
  ///
  /// When [addons] is null, sums across every addon combination of
  /// the same product+variant — useful for surfaces (e.g. the home
  /// card stepper) that don't track a specific configuration. When
  /// non-null, only the line with the exact same addon set counts;
  /// this is what the detail screen wants so its stepper reflects
  /// the customer's CURRENT picker selection, not unrelated lines.
  int qtyOf({
    required String productId,
    String? variantItemId,
    Map<String, int>? addons,
  }) {
    if (addons == null) {
      return _items
          .where((i) =>
              i.product.id == productId && i.variantItemId == variantItemId)
          .fold(0, (sum, i) => sum + i.quantity);
    }
    final idx = _items.indexWhere(
      (i) =>
          i.product.id == productId &&
          i.variantItemId == variantItemId &&
          _addonsMatch(i.addons, addons),
    );
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  /// Decrement the cart line matching the given product + variant +
  /// (optional) addons by one. Removes the line entirely when its
  /// quantity would drop to zero. Returns false when no matching
  /// line exists.
  Future<bool> decrementVariantLine({
    required String productId,
    String? variantItemId,
    Map<String, int>? addons,
  }) async {
    final idx = _items.indexWhere(
      (i) =>
          i.product.id == productId &&
          i.variantItemId == variantItemId &&
          (addons == null || _addonsMatch(i.addons, addons)),
    );
    if (idx < 0) return false;
    final newQty = _items[idx].quantity - 1;
    if (newQty <= 0) return removeAt(idx);
    return updateQuantity(idx, newQty);
  }

  /// Default variant selection used by [addProduct] when the caller
  /// didn't specify one (quick-add from the home card). Picks the
  /// variant whose price matches `product.price` — that's the number
  /// the customer saw on the card, and getting a different variant
  /// added to the cart is a confusing surprise. Falls back to the
  /// cheapest variant, then to the first.
  VariantItem? _defaultVariantFor(Product product) {
    final items = product.variantItems;
    if (items.isEmpty) return null;
    for (final v in items) {
      if (v.price == product.price) return v;
    }
    return items.reduce((a, b) => a.price <= b.price ? a : b);
  }

  /// True when [existing] cart-line addons match the [requested] addon
  /// map exactly — same set of addon ids with the same quantity each.
  /// Used by [addProduct] to keep distinct addon combinations as
  /// distinct cart lines instead of silently merging "Egg + Mayo"
  /// and "Egg + Cheese" into one.
  bool _addonsMatch(
    List<CartItemAddon> existing,
    Map<String, int> requested,
  ) {
    if (existing.length != requested.length) return false;
    for (final a in existing) {
      if (requested[a.addonId] != a.quantity) return false;
    }
    return true;
  }

  /// Re-resolves each line's [Product] against the catalogue. Used when
  /// the catalogue finishes loading AFTER the cart already hydrated —
  /// without this, lines that landed during the loading window keep
  /// their thin Product (no image, no `autoDiscount`, no variantItems,
  /// no addons) and the cart shows fork-and-knife placeholders next
  /// to broken discount/receipt math.
  ///
  /// The catalogue is the canonical source for product data, so we
  /// swap whenever it has a match. The cart's prior Product copy
  /// might have come from a thinner backend cart payload (productId
  /// + name + adminId but no image), in which case the catalogue
  /// version is strictly more complete.
  void rehydrateProducts() {
    if (_items.isEmpty || _productResolver == null) return;
    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      final current = _items[i];
      final resolved = _productResolver!(current.product.id);
      if (resolved == null) continue;
      // Identity skip — if the resolved product is the exact same
      // instance already held, nothing changed.
      if (identical(resolved, current.product)) continue;
      // Re-resolve the variant label from the newly-resolved product
      // when the current label is null but a variantItemId is set —
      // covers the case where the cart came in with an unexpanded
      // variant object and we now have the full variantItems list.
      String? variantLabel = current.variantItemLabel;
      if (variantLabel == null && current.variantItemId != null) {
        for (final v in resolved.variantItems) {
          if (v.id == current.variantItemId) {
            variantLabel = v.label;
            break;
          }
        }
      }
      _items[i] = CartItem(
        product: resolved,
        quantity: current.quantity,
        variantItemId: current.variantItemId,
        variantItemLabel: variantLabel,
        unitPrice: current.unitPrice,
        addons: current.addons,
        serverItemId: current.serverItemId,
        selectedVariants: current.selectedVariants,
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }



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

    // Only items WITHOUT a serverItemId need migrating — those are the
    // guest additions that never round-tripped to the cart endpoint.
    // Items already synced (pull-to-refresh, post-login bootstrap) get
    // a clean fetch instead, so we don't re-POST and double-count them.
    final guestItems = _items
        .where(
          (i) => i.serverItemId == null || i.serverItemId!.isEmpty,
        )
        .toList();

    try {
      if (guestItems.isEmpty) {
        // No unsynced items — pure fetch from the server.
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
      // Backend cart responses ship thin Products (id + name + maybe
      // adminId), so swap in the full catalogue version for image,
      // discount, variants, addons. The catalogue→cart listener only
      // covers the case where catalogue lands AFTER cart; this call
      // covers the reverse — catalogue already loaded when cart
      // finishes hydrating.
      rehydrateProducts();
      notifyListeners();
    }
  }



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
    final effectiveVariant = variant ?? _defaultVariantFor(product);
    final effectiveAddons = _buildLocalAddons(product, addons);


    // Dedupe key is (productId, variantItemId, addons). Two lines
    // with the same product+variant but different addons stay
    // separate so "Egg + Mayo" and "Egg + Cheese" don't silently
    // merge into one mystery-line that loses one of the addon sets.
    final snapshot = _snapshot();
    final existingIdx = _items.indexWhere((i) =>
        i.product.id == product.id &&
        i.variantItemId == effectiveVariant?.id &&
        _addonsMatch(i.addons, addons));

    if (existingIdx >= 0) {
      _items[existingIdx].quantity += quantity;
    } else {
      // Compute post-discount unit + addon prices so guests see the
      // same math the backend would produce. Without this, guests
      // pay the sticker price (Almond Water = Rs 100 instead of
      // Rs 90 — autoDiscount never gets applied because there's no
      // backend round-trip to write back the post-discount unitPrice).
      // Authed carts overwrite both via _replaceItemsFrom; doing it
      // locally first means the receipt math still adds up during the
      // optimistic window before the response lands.
      final stickerUnit = effectiveVariant?.price ?? product.price;
      final disc = product.autoDiscount;
      final unitPrice = disc?.apply(stickerUnit) ?? stickerUnit;
      // Percentage rate applies to addons too (mirrors
      // discountTotal's reverse-projection); flat discounts only
      // knock the rate off the unit, addons unchanged.
      final finalAddons = (disc != null &&
              disc.type == 'percentage' &&
              disc.rate > 0)
          ? effectiveAddons
              .map((a) => CartItemAddon(
                    addonId: a.addonId,
                    name: a.name,
                    quantity: a.quantity,
                    unitPrice: disc.apply(a.unitPrice),
                  ))
              .toList()
          : effectiveAddons;
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        variantItemId: effectiveVariant?.id,
        variantItemLabel: effectiveVariant?.label,
        unitPrice: unitPrice,
        addons: finalAddons,
        selectedVariants: selectedVariants,
      ));
    }
    notifyListeners();


    if (!_isAuthenticated()) return true;


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

      // POST/PUT cart responses sometimes return `variantProduct` as
      // just an id string, not the expanded `{ _id, optionValues }`
      // object — so [line.variantItemLabel] comes back null even
      // though a variant is selected. Recover the label from the
      // resolved product's variantItems list so the cart screen +
      // bill keep showing which variant each line is.
      String? variantLabel = line.variantItemLabel;
      if (variantLabel == null && line.variantItemId != null) {
        for (final v in product.variantItems) {
          if (v.id == line.variantItemId) {
            variantLabel = v.label;
            break;
          }
        }
      }

      next.add(CartItem(
        product: product,
        quantity: line.quantity,
        variantItemId: line.variantItemId,
        variantItemLabel: variantLabel,
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



  /// Restore the cart from a SharedPreferences-backed JSON snapshot.
  /// Wired from main.dart at app startup so a hot-restart / cold-start
  /// doesn't drop the cart on the floor — applies to BOTH guests
  /// (whose cart lives only client-side) and authed users (whose
  /// backend cart may not have synced back yet when the splash
  /// finishes). Once authed bootstrap runs and the backend cart
  /// arrives, [_replaceItemsFrom] overwrites whatever this restored.
  ///
  /// Restored products are thin (just the fields we serialized);
  /// [rehydrateProducts] swaps them with full catalogue Products
  /// once the catalogue finishes loading.
  Future<void> tryLoadLocalCart() async {
    if (_items.isNotEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartLocalKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      for (final m in data) {
        final map = (m as Map).cast<String, dynamic>();
        final product = Product(
          id: map['productId'] as String,
          name: (map['productName'] as String?) ?? 'Product',
          category: '',
          price: (map['productPrice'] as num?)?.toDouble() ?? 0,
          reviews: 0,
          image: (map['productImage'] as String?) ?? '🍴',
          imageUrl: map['productImageUrl'] as String?,
          description: '',
          tags: const [],
          time: '',
        );
        _items.add(CartItem(
          product: product,
          quantity: (map['quantity'] as num).toInt(),
          variantItemId: map['variantItemId'] as String?,
          variantItemLabel: map['variantItemLabel'] as String?,
          unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? product.price,
          serverItemId: map['serverItemId'] as String?,
          selectedVariants: ((map['selectedVariants'] as Map?) ?? const {})
              .map((k, v) => MapEntry(k.toString(), v.toString())),
          addons: ((map['addons'] as List?) ?? const [])
              .map((a) {
                final am = (a as Map).cast<String, dynamic>();
                return CartItemAddon(
                  addonId: am['addonId'] as String,
                  name: (am['name'] as String?) ?? '',
                  quantity: (am['quantity'] as num?)?.toInt() ?? 1,
                  unitPrice: (am['unitPrice'] as num?)?.toDouble() ?? 0,
                );
              })
              .toList(),
        ));
      }
      rehydrateProducts();
      super.notifyListeners();
    } catch (e) {
      debugPrint('🚨 CartProvider.tryLoadLocalCart: $e');
    }
  }

  /// Serializes the current cart to JSON and writes it to
  /// SharedPreferences. Fire-and-forget — failures are swallowed
  /// because losing one save doesn't break anything (next mutation
  /// re-saves).
  void _saveLocal() {
    final data = _items
        .map((i) => {
              'productId': i.product.id,
              'productName': i.product.name,
              'productImage': i.product.image,
              'productImageUrl': i.product.imageUrl,
              'productPrice': i.product.price,
              'quantity': i.quantity,
              'variantItemId': i.variantItemId,
              'variantItemLabel': i.variantItemLabel,
              'unitPrice': i.unitPrice,
              'serverItemId': i.serverItemId,
              'selectedVariants': i.selectedVariants,
              'addons': i.addons
                  .map((a) => {
                        'addonId': a.addonId,
                        'name': a.name,
                        'quantity': a.quantity,
                        'unitPrice': a.unitPrice,
                      })
                  .toList(),
            })
        .toList();
    SharedPreferences.getInstance()
        .then((p) => p.setString(_kCartLocalKey, jsonEncode(data)));
  }

  /// Persist on every notify. ChangeNotifier dispatches this on
  /// every state change (mutation, loading toggle, error update); we
  /// piggyback to keep the local snapshot fresh without sprinkling
  /// _saveLocal() calls across a dozen mutation methods. The extra
  /// writes on non-mutation notifies are cheap (SharedPreferences
  /// batches in memory) and have no semantic effect.
  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveLocal();
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
