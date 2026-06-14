import '../../../../core/constants.dart';
import 'api_product.dart';

/// UI-facing product model. Construct via [Product.fromApi] to adapt
/// from the live [ApiProduct] shape. Will merge with [ApiProduct] once
/// the legacy mock path is retired.
class Product {
  final String id;

  /// Owner's id — required by `POST /api/cart/`. Null on synthetic
  /// products (reorder fallback); cart layer guards that case.
  final String? adminId;

  final String name;

  /// Category label ("breads") for mock data, or Mongo ObjectId for
  /// live products. Home filter uses equality so both shapes work.
  final String category;

  final double price;
  final int reviews;

  /// Emoji fallback. Always present so screens that haven't migrated to
  /// network image rendering still display something.
  final String image;

  /// Resolved network image URL (absolute). Null when there is no image
  /// or the source path was empty.
  final String? imageUrl;

  final String? badge;
  final String description;
  final List<String> tags;
  final String time;

  /// Picker model: option groups for the variant chooser UI.
  final List<VariantGroup> variants;

  /// Lookup table for resolving a customer's picks → concrete variant
  /// `_id`. Use [findVariantItem] to map picked labels → the id that
  /// `POST /cart/` requires.
  final List<VariantItem> variantItems;

  /// Optional add-ons (e.g. Egg, Cheese) the customer can attach to a
  /// product line. Empty list when the product has none.
  final List<ProductAddon> addons;

  /// The `applyEverytime` discount backend will auto-apply, or null.
  /// Drives the "10% OFF" badge. Selective discounts (coupon codes)
  /// are intentionally excluded.
  final ProductDiscount? autoDiscount;

  const Product({
    required this.id,
    this.adminId,
    required this.name,
    required this.category,
    required this.price,
    required this.reviews,
    required this.image,
    this.imageUrl,
    this.badge,
    required this.description,
    required this.tags,
    required this.time,
    this.variants = const [],
    this.variantItems = const [],
    this.addons = const [],
    this.autoDiscount,
  });

  /// True when this product needs the customer to choose a variant before
  /// it can be added to the cart (i.e. there's at least one variant group
  /// with more than one option).
  bool get hasVariants =>
      variants.any((g) => g.options.length > 1) || variantItems.length > 1;

  /// Resolves a [VariantItem] by matching the user-picked option labels
  /// (order-independent). Returns null when no match exists — caller
  /// should treat this as "the user hasn't completed the picker yet".
  VariantItem? findVariantItem(Iterable<String> pickedValues) {
    if (variantItems.isEmpty) return null;
    final picked = pickedValues.toSet();
    for (final item in variantItems) {
      if (item.optionValues.length != picked.length) continue;
      if (item.optionValues.every(picked.contains)) return item;
    }
    return null;
  }

  /// Adapts an [ApiProduct] (live API shape) into this UI-friendly form.
  /// Fields the API doesn't supply (reviews, badge, time, emoji) fall
  /// back to safe defaults so existing UI keeps rendering.
  factory Product.fromApi(ApiProduct api) {
    final autoDiscount = _resolveAutoDiscount(api);
    final isPopular = api.orderedCount >= 25;
    final apiVariants = api.variants;
    return Product(
      id: api.id,
      adminId: api.adminId,
      name: api.name,
      category: api.categoryId ?? '',
      // Variant-only products carry `price: 0` at the top; surface the
      // cheapest available variant so cards show a real number.
      price: _derivePrice(api),
      reviews: api.orderedCount,
      image: '🍴',
      imageUrl: AppConstants.resolveImageUrl(api.image),
      // Skip the legacy text badge when autoDiscount has its own pill.
      badge: autoDiscount == null && isPopular ? 'Popular' : null,
      description: api.description ?? '',
      tags: [
        if (api.isVeg) 'Vegan',
        ...api.tags,
      ],
      time: _deriveSubtitle(api),
      variants: apiVariants == null
          ? const []
          : apiVariants.options.map(VariantGroup.fromApi).toList(),
      variantItems: apiVariants == null
          ? const []
          : apiVariants.items
              .where((i) => i.id != null && i.id!.isNotEmpty)
              .map(VariantItem.fromApi)
              .toList(),
      addons: api.addons
          .where((a) => a.id.isNotEmpty)
          .map(ProductAddon.fromApi)
          .toList(),
      autoDiscount: autoDiscount,
    );
  }

  /// Returns the first enabled discount the backend will auto-apply
  /// for this product, or null. Selective discounts (coupon codes)
  /// don't qualify — those require customer input we don't surface.
  static ProductDiscount? _resolveAutoDiscount(ApiProduct api) {
    if (api.discountType != 'applyEverytime') return null;
    for (final d in api.discounts) {
      if (!d.isEnabled) continue;
      if (d.rate == null || d.rate! <= 0) continue;
      return ProductDiscount(
        id: d.id,
        name: d.name ?? '',
        type: d.type ?? 'percentage',
        rate: d.rate!.toDouble(),
      );
    }
    return null;
  }

  /// Surface price for cards. Prefers the API's base, falls back to
  /// the cheapest available variant. Returns 0 only when the product
  /// has no price anywhere — UI should hide the price tag in that case.
  static double _derivePrice(ApiProduct api) {
    if (api.price > 0) return api.price.toDouble();
    final apiVariants = api.variants;
    if (apiVariants == null || apiVariants.items.isEmpty) return 0;
    num? cheapest;
    for (final item in apiVariants.items) {
      if (!item.isAvailable) continue;
      if (item.price <= 0) continue;
      if (cheapest == null || item.price < cheapest) cheapest = item.price;
    }
    return cheapest?.toDouble() ?? 0;
  }

  static String _deriveSubtitle(ApiProduct api) {
    final desc = api.description?.trim() ?? '';
    if (desc.isNotEmpty) {
      final firstClause = desc.split(RegExp(r'[.\n]')).first.trim();
      return firstClause.length > 40
          ? '${firstClause.substring(0, 40)}…'
          : firstClause;
    }
    final biz = api.businessName?.trim() ?? '';
    if (biz.isNotEmpty) return biz;
    return '';
  }
}

/// A group of selectable options (e.g. "Type": [Steam, Fried, Chilly]).
class VariantGroup {
  final String title;
  final List<String> options;

  const VariantGroup({required this.title, required this.options});

  factory VariantGroup.fromApi(ApiVariantOption api) =>
      VariantGroup(title: api.title, options: api.values);
}

/// A concrete variant — the `variantItem` id the cart/ticket endpoints
/// accept. Maps 1:1 to `variants.variantItems[]` in the products API.
class VariantItem {
  final String id;

  /// User-visible labels (e.g. ["Steam"] or ["Large", "Hot"]). Order
  /// matches the parent product's [VariantGroup] order.
  final List<String> optionValues;

  /// Server-authoritative price. Client values are ignored by the
  /// cart/ticket endpoints.
  final double price;

  final bool isAvailable;

  const VariantItem({
    required this.id,
    required this.optionValues,
    required this.price,
    this.isAvailable = true,
  });

  factory VariantItem.fromApi(ApiVariantItem api) => VariantItem(
        id: api.id!,
        optionValues: api.optionValues,
        price: api.price.toDouble(),
        isAvailable: api.isAvailable,
      );

  /// Human-friendly label like "Steam" or "Large · Hot". Used in cart
  /// rows so the customer can tell their picks apart.
  String get label => optionValues.join(' · ');
}

/// A product add-on (e.g. Egg, Cheese). Maps to entries in the products
/// API's `addons[]` array.
class ProductAddon {
  final String id;
  final String name;
  final double price;

  const ProductAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductAddon.fromApi(ApiProductAddon api) => ProductAddon(
        id: api.id,
        name: api.name ?? 'Addon',
        price: (api.price ?? 0).toDouble(),
      );
}

/// A discount the backend will auto-apply to a product. UI-side
/// projection of the relevant fields from [ApiProductDiscount] — just
/// the bits the badge needs.
class ProductDiscount {
  final String id;
  final String name;

  /// "percentage" or "flat".
  final String type;
  final double rate;

  const ProductDiscount({
    required this.id,
    required this.name,
    required this.type,
    required this.rate,
  });

  /// Short label for the corner badge: "10% OFF" / "Rs 50 OFF".
  String get badgeLabel {
    if (type == 'percentage') {
      final r = rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toString();
      return '$r% OFF';
    }
    return 'Rs ${rate.toStringAsFixed(0)} OFF';
  }
}
