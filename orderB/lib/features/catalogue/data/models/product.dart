import '../../../../core/constants.dart';
import 'api_product.dart';

/// UI-facing product model. Holds the fields the existing widgets render.
///
/// Most consumers should construct via [Product.fromApi] which adapts the
/// canonical [ApiProduct] (live API shape) into this UI-friendly form.
/// Once the legacy mock data path is fully retired, this class merges
/// with [ApiProduct] and goes away.
class Product {
  final String id;

  /// The business owner's ID. Required when POSTing this product to the
  /// cart endpoint (`POST /api/cart/` expects `adminId` per item). Null
  /// for synthetic/legacy products created without an API origin (e.g.
  /// the reorder fallback path); the cart layer guards against that case.
  final String? adminId;

  final String name;

  /// Either a category label ("breads") for legacy mock data, or a Mongo
  /// ObjectId string for live API products. The home screen filter uses
  /// equality against the active category-pill ID, which matches both
  /// shapes naturally.
  final String category;

  final double price;
  final double rating;
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

  /// Picker model — groups of selectable options (e.g. "Type": Steam,
  /// Fried, Chilly). Use this to render the variant chooser UI.
  final List<VariantGroup> variants;

  /// Lookup table — every concrete variant combination carries its own
  /// `_id` and resolved price. After the user picks labels via [variants],
  /// resolve the chosen [VariantItem] via [findVariantItem] to get the
  /// `_id` the cart endpoint requires.
  final List<VariantItem> variantItems;

  /// Optional add-ons (e.g. Egg, Cheese) the customer can attach to a
  /// product line. Empty list when the product has none.
  final List<ProductAddon> addons;

  const Product({
    required this.id,
    this.adminId,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
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
  /// Fields the API doesn't supply (rating, reviews, badge, time, emoji)
  /// fall back to safe defaults so existing UI keeps rendering.
  factory Product.fromApi(ApiProduct api) {
    final hasDiscount = api.discounts.isNotEmpty;
    final isPopular = api.orderedCount >= 25;
    final apiVariants = api.variants;
    return Product(
      id: api.id,
      adminId: api.adminId,
      name: api.name,
      category: api.categoryId ?? '',
      // Many variant-driven products (Momo, Americano, Simmi, etc.) come
      // back with `price: 0` at the top level — the real prices live
      // inside `variants.variantItems[].price`. Use the cheapest available
      // variant as the displayed anchor so card listings show a real
      // "from ₹X" instead of "₹0". Falls through to api.price for plain
      // products and for the edge case where every variant is also 0.
      price: _derivePrice(api),
      rating: 0,
      reviews: api.orderedCount,
      // Single-codepoint fallback (fork+knife). Avoid emoji that need a
      // variation selector — some platforms ship without those glyphs and
      // log "Could not find a set of Noto fonts" warnings.
      image: '🍴',
      imageUrl: AppConstants.resolveImageUrl(api.image),
      badge: hasDiscount
          ? 'Sale'
          : (isPopular ? 'Popular' : null),
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
    );
  }

  /// Picks a one-line subtitle for cards. Order of preference:
  ///   1. First sentence/clause of description
  ///   2. Business name
  ///   3. Empty string (UI shows the slot blank — layout preserved)
  /// Picks the price to surface on product cards. Prefers the API's base
  /// price when set; otherwise falls back to the cheapest *available*
  /// variant. Returns 0 only when there's genuinely no price anywhere
  /// (e.g. a not-yet-priced product) so cards don't crash on missing
  /// data — UI should hide the price tag in that case.
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

/// A concrete, addressable variant of a product — the thing the cart
/// endpoint accepts as `variantItem`. Maps 1:1 to the
/// `variants.variantItems[]` array in the products API response.
class VariantItem {
  final String id;

  /// The user-visible labels for this variant (e.g. ["Steam"] for a
  /// single-group product, or ["Large", "Hot"] for multi-group). Order
  /// matches the [VariantGroup] order in the product's `variants` list.
  final List<String> optionValues;

  /// Server-resolved price for this variant. Server uses this as the
  /// authoritative price; client-side price overrides are ignored on
  /// the POST /cart/ path.
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
