import '../../../catalogue/data/models/product.dart';

/// A cart line item.
///
/// Carries everything the server needs to round-trip a single product
/// line: the chosen variant `_id`, the addon `_id`s with quantities, and
/// the server-assigned line `_id` (used by `DELETE /api/cart/{item_id}`).
class CartItem {
  final Product product;
  int quantity;

  /// The chosen variant's `_id`. Null when the product has no variants.
  /// Required by `POST /api/cart/` for products that do have variants —
  /// the cart layer fills this in from the user's picker selection.
  final String? variantItemId;

  /// Human-readable label for the chosen variant ("Steam", "Large · Hot").
  /// Pure UI; the server doesn't see this.
  final String? variantItemLabel;

  /// Server-resolved per-unit price. The server is authoritative on price
  /// (POST /cart ignores client unitPrice), so this is whatever it
  /// returned in the cart response.
  final double unitPrice;

  /// Add-ons attached to this line. Empty list when none.
  final List<CartItemAddon> addons;

  /// The line's `_id` as assigned by the server (e.g.
  /// `"6a21a51ab8240fef3bad1a77"`). Null for items that haven't synced
  /// yet (e.g. an optimistic local-only add). Required for the single-
  /// item DELETE path; the multi-delete + PUT paths use the product id.
  final String? serverItemId;

  /// Legacy field — title → option-label map (e.g. `{"Type": "Steam"}`).
  /// Kept so existing UI that already reads it keeps rendering. New
  /// code should rely on [variantItemLabel] instead.
  final Map<String, String> selectedVariants;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.variantItemId,
    this.variantItemLabel,
    double? unitPrice,
    this.addons = const [],
    this.serverItemId,
    this.selectedVariants = const {},
  }) : unitPrice = unitPrice ?? product.price;

  /// Per-unit total including addons (one of each, multiplied by addon
  /// quantity).
  double get lineTotal {
    final addonTotal =
        addons.fold<double>(0, (s, a) => s + (a.unitPrice * a.quantity));
    return (unitPrice + addonTotal) * quantity;
  }

  /// Copy with selectively-replaced fields. The cart layer uses this to
  /// merge server responses back into the local list without mutating
  /// the existing object.
  CartItem copyWith({
    int? quantity,
    String? variantItemId,
    String? variantItemLabel,
    double? unitPrice,
    List<CartItemAddon>? addons,
    String? serverItemId,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      variantItemId: variantItemId ?? this.variantItemId,
      variantItemLabel: variantItemLabel ?? this.variantItemLabel,
      unitPrice: unitPrice ?? this.unitPrice,
      addons: addons ?? this.addons,
      serverItemId: serverItemId ?? this.serverItemId,
      selectedVariants: selectedVariants,
    );
  }
}

/// An addon attached to a [CartItem].
class CartItemAddon {
  final String addonId;
  final String name;
  int quantity;
  final double unitPrice;

  CartItemAddon({
    required this.addonId,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
  });
}
