/// Product data model.
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int reviews;
  final String image; // emoji fallback
  final String? imageUrl; // network image URL
  final String? badge;
  final String description;
  final List<String> tags;
  final String time;
  final List<VariantGroup> variants;

  const Product({
    required this.id,
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
  });
}

/// A group of selectable options (e.g. "Fillings": [Buff, Chicken, Veg]).
class VariantGroup {
  final String title;
  final List<String> options;

  const VariantGroup({required this.title, required this.options});
}
