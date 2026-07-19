import '../../../../core/utils/json_helpers.dart';

/// Server-side cart shape returned by the `/api/cart/*` family.
///
/// Three response shapes feed this:
///   1. `GET /my-cart` → `{ cart: { ... } }`
///   2. `POST /api/cart/` → `{ response: { ... } }`
///   3. `PUT /api/cart/`, `DELETE /api/cart/`, `DELETE /api/cart/{id}` →
///      bare cart object at the top level.
///
/// [ApiCart.fromAny] unwraps all three.
class ApiCart {
  final String? id;
  final List<ApiCartLine> items;
  final double total;

  const ApiCart({
    this.id,
    required this.items,
    required this.total,
  });

  /// Empty-cart fallback. Useful when the server returns no cart yet
  /// (e.g. brand-new user, server cleared the cart, etc.).
  static const ApiCart empty =
      ApiCart(id: null, items: <ApiCartLine>[], total: 0);

  /// Unwraps any of the three known response envelopes and returns the
  /// parsed cart. Returns [ApiCart.empty] when the shape isn't
  /// recognizable, so callers can treat any response as a cart.
  static ApiCart fromAny(dynamic raw) {
    if (raw is! Map<String, dynamic>) return empty;
    final inner = raw['cart'] ?? raw['response'] ?? raw;
    if (inner is! Map<String, dynamic>) return empty;
    return ApiCart.fromJson(inner);
  }

  factory ApiCart.fromJson(Map<String, dynamic> json) {
    return ApiCart(
      id: json['_id'] as String?,
      items: parseObjectList(json['items'], ApiCartLine.fromJson),
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One line in the server cart.
///
/// `product` and `variantItem` come back in two shapes depending on
/// the endpoint: a raw `_id` string on the POST response, or a
/// populated object on `GET /my-cart`. This class flattens both into
/// a few simple fields so the CartProvider doesn't have to branch.
class ApiCartLine {
  final String lineId;
  final String productId;
  final String? variantItemId;

  /// Human-readable label like "Steam" or "Large · Hot". Only populated
  /// from `GET /my-cart` (which expands `variantItem` into a full
  /// object); the POST/PUT/DELETE responses just return the `_id` and
  /// the label has to be resolved from the local catalogue.
  final String? variantItemLabel;

  /// Inlined product fields from `GET /my-cart`. Null on the
  /// POST/PUT/DELETE responses where `product` is just an `_id`. Callers
  /// that need full product data should look up [productId] against the
  /// local catalogue.
  final String? productName;
  final String? productImage;

  final int quantity;
  final double unitPrice;

  final List<ApiCartLineAddon> addons;

  const ApiCartLine({
    required this.lineId,
    required this.productId,
    this.variantItemId,
    this.variantItemLabel,
    this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    this.addons = const [],
  });

  factory ApiCartLine.fromJson(Map<String, dynamic> json) {
    final productRaw = json['product'];
    final productId = productRaw is Map<String, dynamic>
        ? (productRaw['_id'] as String? ?? '')
        : (productRaw as String? ?? '');
    final productName = productRaw is Map<String, dynamic>
        ? productRaw['name'] as String?
        : null;
    final productImage = productRaw is Map<String, dynamic>
        ? productRaw['image'] as String?
        : null;

    // `variantProduct` is the canonical field name on the POST/PUT/DELETE
    // responses; `variantItem` is the expanded object on GET /my-cart.
    final variantRaw = json['variantItem'] ?? json['variantProduct'];
    final variantItemId = variantRaw is Map<String, dynamic>
        ? variantRaw['_id'] as String?
        : variantRaw as String?;
    final variantItemLabel = variantRaw is Map<String, dynamic>
        ? (variantRaw['optionValues'] is List
            ? (variantRaw['optionValues'] as List)
                .map((v) => v.toString())
                .join(' · ')
            : null)
        : null;

    return ApiCartLine(
      lineId: json['_id'] as String? ?? '',
      productId: productId,
      variantItemId: variantItemId,
      variantItemLabel:
          (variantItemLabel != null && variantItemLabel.isNotEmpty)
              ? variantItemLabel
              : null,
      productName: productName,
      productImage: productImage,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      addons: parseObjectList(json['addons'], ApiCartLineAddon.fromJson),
    );
  }
}

/// An addon attached to a server cart line.
class ApiCartLineAddon {
  final String lineId;
  final String addonId;
  final String name;
  final int quantity;
  final double unitPrice;

  const ApiCartLineAddon({
    required this.lineId,
    required this.addonId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory ApiCartLineAddon.fromJson(Map<String, dynamic> json) =>
      ApiCartLineAddon(
        lineId: json['_id'] as String? ?? '',
        addonId: json['addon'] as String? ?? '',
        name: json['name'] as String? ?? 'Addon',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}
