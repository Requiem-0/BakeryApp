/// One notification as returned by `/api/notification/`.
///
/// The wire shape nests per-user flags under a `userNotification` array;
/// the server pre-filters this to a single entry for the logged-in user,
/// so we flatten `userNotification[0]` into `isRead` / `isImportant` /
/// `isArchived` on the parent for ergonomic UI access.
class ApiNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String image;
  final String url;
  final String adminId;
  final bool isRead;
  final bool isImportant;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.image,
    required this.url,
    required this.adminId,
    required this.isRead,
    required this.isImportant,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) {
    final un = json['userNotification'];
    Map<String, dynamic>? userEntry;
    if (un is List && un.isNotEmpty && un.first is Map<String, dynamic>) {
      userEntry = un.first as Map<String, dynamic>;
    }
    return ApiNotification(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      adminId: json['adminId']?.toString() ?? '',
      isRead: userEntry?['isRead'] == true,
      isImportant: userEntry?['isImportant'] == true,
      isArchived: userEntry?['isArchived'] == true,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Used by the provider for optimistic updates (flip a flag locally,
  /// fire the PATCH, roll back on failure).
  ApiNotification copyWith({
    bool? isRead,
    bool? isImportant,
    bool? isArchived,
  }) =>
      ApiNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        image: image,
        url: url,
        adminId: adminId,
        isRead: isRead ?? this.isRead,
        isImportant: isImportant ?? this.isImportant,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

DateTime? _parseDate(dynamic v) {
  if (v is String && v.isNotEmpty) {
    try {
      return DateTime.parse(v).toLocal();
    } catch (_) {
      return null;
    }
  }
  return null;
}
