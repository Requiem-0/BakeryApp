import '../../../../core/utils/json_helpers.dart';

/// Product as returned by /api/products/*. Distinct from `Product`
/// (the UI-facing model) until the mock-data path is retired.
class ApiProduct {
  final String id;
  final String name;
  final num price;
  final num? costPrice;
  final bool isVeg;
  final bool isAvailable;
  final bool usesOfferPrice;
  final List<ApiProductAddon> addons;

  /// API field is literally `categories` (singular reference, plural-named
  /// for legacy reasons). Renamed for clarity.
  final String? categoryId;

  final String? adminId;
  final String? addedBy;
  final String? sku;
  final String soldBy;
  final int orderedCount;
  final bool isTaxable;
  final bool showInOrdering;
  final bool? usesStocks;
  final List<String> tags;
  final String? image;
  final String? description;

  // Inventory — present on stock-tracked products, absent on others.
  // `inStock` can be -1 to mean "unlimited" / not tracked.
  final num? inStock;
  final num? lowStock;

  // Composite items / bundles — null for plain products, a list when used.
  final dynamic compositeItems;
  final bool? usesCompositeItems;

  // Discount rules attached to this product. Backend has been seen
  // returning these as bare id strings on some endpoints and as
  // full populated objects on others; [_parseDiscounts] accepts both
  // and normalizes to [ApiProductDiscount] — id only on the bare-
  // string shape, full metadata on the populated shape.
  final List<ApiProductDiscount> discounts;
  final String? discountType;

  // Business / admin metadata.
  final String? businessId;
  final String? businessName;
  final String? businessType;
  final String? businessAddress;
  final String? businessOwner;
  final num? businessPanNumber;

  final ApiProductVariants? variants;

  const ApiProduct({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice,
    required this.isVeg,
    required this.isAvailable,
    required this.usesOfferPrice,
    required this.addons,
    this.categoryId,
    this.adminId,
    this.addedBy,
    this.sku,
    required this.soldBy,
    required this.orderedCount,
    required this.isTaxable,
    required this.showInOrdering,
    this.usesStocks,
    required this.tags,
    this.image,
    this.description,
    this.inStock,
    this.lowStock,
    this.compositeItems,
    this.usesCompositeItems,
    required this.discounts,
    this.discountType,
    this.businessId,
    this.businessName,
    this.businessType,
    this.businessAddress,
    this.businessOwner,
    this.businessPanNumber,
    this.variants,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) => ApiProduct(
        id: (json['_id'] ?? json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        price: (json['price'] as num?) ?? 0,
        costPrice: json['costPrice'] as num?,
        isVeg: (json['isVeg'] as bool?) ?? false,
        isAvailable: (json['isAvailable'] as bool?) ?? false,
        usesOfferPrice: (json['usesOfferPrice'] as bool?) ?? false,
        addons: parseAnyList(json['addons'], ApiProductAddon.fromAny),
        categoryId: json['categories'] as String?,
        adminId: json['adminId'] as String?,
        addedBy: json['added_by'] as String?,
        sku: json['sku'] as String?,
        soldBy: (json['soldBy'] as String?) ?? 'each',
        orderedCount: ((json['orderedCount'] as num?) ?? 0).toInt(),
        isTaxable: (json['isTaxable'] as bool?) ?? false,
        showInOrdering: (json['showInOrdering'] as bool?) ?? true,
        usesStocks: json['usesStocks'] as bool?,
        tags: parseStringList(json['tags']),
        image: json['image'] as String?,
        description: json['description'] as String?,
        inStock: json['inStock'] as num?,
        lowStock: json['lowStock'] as num?,
        compositeItems: json['compositeItems'],
        usesCompositeItems: json['usesCompositeItems'] as bool?,
        discounts: _parseDiscounts(json['discounts']),
        discountType: json['discountType'] as String?,
        businessId: json['businessId'] as String?,
        businessName: json['businessName'] as String?,
        businessType: json['businessType'] as String?,
        businessAddress: json['businessAddress'] as String?,
        businessOwner: json['businessOwner'] as String?,
        businessPanNumber: json['businessPanNumber'] as num?,
        variants: json['variants'] is Map<String, dynamic>
            ? ApiProductVariants.fromJson(
                json['variants'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'price': price,
        if (costPrice != null) 'costPrice': costPrice,
        'isVeg': isVeg,
        'isAvailable': isAvailable,
        'usesOfferPrice': usesOfferPrice,
        'addons': addons.map((a) => a.toJson()).toList(),
        if (categoryId != null) 'categories': categoryId,
        if (adminId != null) 'adminId': adminId,
        if (addedBy != null) 'added_by': addedBy,
        if (sku != null) 'sku': sku,
        'soldBy': soldBy,
        'orderedCount': orderedCount,
        'isTaxable': isTaxable,
        'showInOrdering': showInOrdering,
        if (usesStocks != null) 'usesStocks': usesStocks,
        'tags': tags,
        if (image != null) 'image': image,
        if (description != null) 'description': description,
        if (inStock != null) 'inStock': inStock,
        if (lowStock != null) 'lowStock': lowStock,
        if (compositeItems != null) 'compositeItems': compositeItems,
        if (usesCompositeItems != null)
          'usesCompositeItems': usesCompositeItems,
        'discounts': discounts.map((d) => d.toJson()).toList(),
        if (discountType != null) 'discountType': discountType,
        if (businessId != null) 'businessId': businessId,
        if (businessName != null) 'businessName': businessName,
        if (businessType != null) 'businessType': businessType,
        if (businessAddress != null) 'businessAddress': businessAddress,
        if (businessOwner != null) 'businessOwner': businessOwner,
        if (businessPanNumber != null) 'businessPanNumber': businessPanNumber,
        if (variants != null) 'variants': variants!.toJson(),
      };

  /// Normalizes the `discounts` array — accepts bare id strings AND
  /// populated objects, returns full [ApiProductDiscount]s either way
  /// (with only the id populated for the bare-string shape).
  static List<ApiProductDiscount> _parseDiscounts(dynamic raw) {
    if (raw is! List) return const [];
    final result = <ApiProductDiscount>[];
    for (final entry in raw) {
      if (entry is String && entry.isNotEmpty) {
        result.add(ApiProductDiscount(id: entry));
      } else if (entry is Map<String, dynamic>) {
        result.add(ApiProductDiscount.fromJson(entry));
      }
    }
    return result;
  }
}

/// A discount rule attached to a product on `/api/products/*`.
///
/// Carries the metadata the UI needs to render a "10% OFF" / "Rs 50 off"
/// badge — the cart endpoint itself ignores client-sent discounts and
/// auto-applies them server-side from the same rule, so this object is
/// display-only.
class ApiProductDiscount {
  final String id;
  final String? name;

  /// "percentage" or "flat". Empty when the backend returned a bare id.
  final String? type;

  /// For percentage: 10 means 10%. For flat: the absolute amount.
  final num? rate;

  /// False when the admin paused the rule. We still parse it but the
  /// badge / cart auto-apply should ignore disabled entries.
  final bool isEnabled;

  const ApiProductDiscount({
    required this.id,
    this.name,
    this.type,
    this.rate,
    this.isEnabled = true,
  });

  factory ApiProductDiscount.fromJson(Map<String, dynamic> json) =>
      ApiProductDiscount(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: json['name'] as String?,
        type: json['type'] as String?,
        rate: json['rate'] as num?,
        isEnabled: (json['isEnabled'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        if (rate != null) 'rate': rate,
        'isEnabled': isEnabled,
      };
}

/// Addons come back in two shapes depending on the endpoint:
///   1. A raw string ID:                 "68132460872da4dcaab36c2d"
///   2. A full populated object:         { _id, name, price, description, ... }
///
/// `fromAny` accepts either; consumers always get the same Dart shape.
class ApiProductAddon {
  final String id;
  final String? name;
  final String? description;
  final num? price;
  final num? maxAvailable;
  final String? adminId;

  const ApiProductAddon({
    required this.id,
    this.name,
    this.description,
    this.price,
    this.maxAvailable,
    this.adminId,
  });

  factory ApiProductAddon.fromAny(dynamic value) {
    if (value is String) {
      return ApiProductAddon(id: value);
    }
    if (value is Map<String, dynamic>) {
      return ApiProductAddon(
        id: (value['_id'] ?? value['id'] ?? '') as String,
        name: value['name'] as String?,
        description: value['description'] as String?,
        price: value['price'] as num?,
        maxAvailable: value['maxAvailable'] as num?,
        adminId: value['adminId'] as String?,
      );
    }
    return const ApiProductAddon(id: '');
  }

  /// True when only the ID is known (came back as a raw string from the
  /// list endpoints). Useful for UI that needs to decide whether to fetch
  /// the full addon record.
  bool get isHydrated => name != null;

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (maxAvailable != null) 'maxAvailable': maxAvailable,
        if (adminId != null) 'adminId': adminId,
      };
}

class ApiProductVariants {
  final String? id;
  final String? productId;
  final String? adminId;
  final List<ApiVariantOption> options;
  final List<ApiVariantItem> items;
  final String? createdAt;
  final String? updatedAt;

  const ApiProductVariants({
    this.id,
    this.productId,
    this.adminId,
    required this.options,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiProductVariants.fromJson(Map<String, dynamic> json) =>
      ApiProductVariants(
        id: json['_id'] as String?,
        productId: json['productId'] as String?,
        adminId: json['adminId'] as String?,
        options: parseObjectList(json['options'], ApiVariantOption.fromJson),
        items: parseObjectList(json['variantItems'], ApiVariantItem.fromJson),
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (productId != null) 'productId': productId,
        if (adminId != null) 'adminId': adminId,
        'options': options.map((o) => o.toJson()).toList(),
        'variantItems': items.map((i) => i.toJson()).toList(),
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}

class ApiVariantOption {
  final String? id;
  final String title;
  final List<String> values;

  const ApiVariantOption({
    this.id,
    required this.title,
    required this.values,
  });

  factory ApiVariantOption.fromJson(Map<String, dynamic> json) =>
      ApiVariantOption(
        id: json['_id'] as String?,
        title: (json['title'] ?? '') as String,
        values: parseStringList(json['values']),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        'values': values,
      };
}

class ApiVariantItem {
  final String? id;
  final List<String> optionValues;
  final num price;
  final num? costPrice;
  final bool isAvailable;
  final num? inStock;
  final num? lowStock;
  final String? createdAt;
  final String? updatedAt;

  const ApiVariantItem({
    this.id,
    required this.optionValues,
    required this.price,
    this.costPrice,
    required this.isAvailable,
    this.inStock,
    this.lowStock,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiVariantItem.fromJson(Map<String, dynamic> json) => ApiVariantItem(
        id: json['_id'] as String?,
        optionValues: parseStringList(json['optionValues']),
        price: (json['price'] as num?) ?? 0,
        costPrice: json['costPrice'] as num?,
        isAvailable: (json['isAvailable'] as bool?) ?? false,
        inStock: json['inStock'] as num?,
        lowStock: json['lowStock'] as num?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'optionValues': optionValues,
        'price': price,
        if (costPrice != null) 'costPrice': costPrice,
        'isAvailable': isAvailable,
        if (inStock != null) 'inStock': inStock,
        if (lowStock != null) 'lowStock': lowStock,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}

/// Wraps a paginated /products/ response: the items plus a forward cursor.
/// `nextCursor` is null when there are no more pages.
class ApiProductPage {
  final List<ApiProduct> products;
  final String? nextCursor;

  const ApiProductPage({required this.products, this.nextCursor});

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
