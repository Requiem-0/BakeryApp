import 'api_category.dart';

/// UI-facing category model used by the home-screen filter pills.
///
/// Bridges between live [ApiCategory] data and the existing pill widget
/// via [Category.fromApi].
class Category {
  final String id;
  final String label;
  final String icon;
  final int? count;

  const Category({
    required this.id,
    required this.label,
    required this.icon,
    this.count,
  });

  /// Adapts an [ApiCategory] into the UI-friendly form. The pill widget
  /// only renders [icon] for the "All" entry, so an empty icon for live
  /// categories is fine.
  factory Category.fromApi(ApiCategory api) => Category(
        id: api.id,
        label: api.name,
        icon: '',
        count: null,
      );
}
