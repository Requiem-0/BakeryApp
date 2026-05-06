/// Category as returned by /api/products/categories.
///
/// Named `ApiCategory` to avoid colliding with the legacy wishful-shape
/// `Category` in category.dart, which is still consumed by the mock-data
/// UI. When UI is rewritten, this becomes the canonical `Category`.
class ApiCategory {
  final String id;
  final String name;

  /// Hex string without the leading `#` (e.g. "03a9f4").
  final String color;

  final String? adminId;

  const ApiCategory({
    required this.id,
    required this.name,
    required this.color,
    this.adminId,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) => ApiCategory(
        id: (json['_id'] ?? json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        color: (json['color'] ?? '') as String,
        adminId: json['adminId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'color': color,
        if (adminId != null) 'adminId': adminId,
      };
}
