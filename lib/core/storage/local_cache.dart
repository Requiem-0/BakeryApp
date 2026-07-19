/// Storage abstraction for offline-cacheable payloads (catalogue, categories,
/// search results, etc.).
///
/// Values are raw strings — callers handle JSON encode/decode. This keeps the
/// contract small enough that the SharedPreferences-backed default impl can be
/// swapped for a Hive-backed one later without touching call sites.
abstract class LocalCache {
  /// Reads the value at [key], or null if absent.
  Future<String?> read(String key);

  /// Writes [value] at [key], overwriting any existing entry.
  Future<void> write(String key, String value);

  /// Removes the entry at [key]. No-op if absent.
  Future<void> remove(String key);

  /// Clears every entry owned by this cache.
  Future<void> clear();
}
