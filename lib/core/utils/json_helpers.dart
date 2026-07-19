// Tiny helpers for parsing JSON arrays into typed Dart lists.
// All three return `const []` when `data` isn't a List, so callers can
// feed them whatever the API returned without null-checking first.

/// A JSON array where each entry is an object — feed each through `fromJson`.
///
///     parseObjectList(json['variantItems'], ApiVariantItem.fromJson)
List<T> parseObjectList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is! List) return const [];
  final result = <T>[];
  for (final entry in data) {
    if (entry is Map<String, dynamic>) {
      result.add(fromJson(entry));
    }
  }
  return result;
}

/// A JSON array of strings — non-string entries are dropped.
///
///     parseStringList(json['tags'])
List<String> parseStringList(dynamic data) {
  if (data is! List) return const [];
  final result = <String>[];
  for (final entry in data) {
    if (entry is String) result.add(entry);
  }
  return result;
}

/// A JSON array where each entry could be any shape — `fromAny` decides.
/// Used for fields like `addons` that the API returns as either a list of
/// IDs (strings) or a list of full objects.
///
///     parseAnyList(json['addons'], ApiProductAddon.fromAny)
List<T> parseAnyList<T>(dynamic data, T Function(dynamic) fromAny) {
  if (data is! List) return const [];
  return data.map(fromAny).toList();
}
