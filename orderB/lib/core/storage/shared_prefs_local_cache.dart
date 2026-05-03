import 'package:shared_preferences/shared_preferences.dart';

import 'local_cache.dart';

/// SharedPreferences-backed [LocalCache].
///
/// Keys are namespaced with `cache:` so [clear] only wipes cache entries and
/// leaves other SharedPreferences usage (e.g. theme, onboarding flags) intact.
class SharedPrefsLocalCache implements LocalCache {
  static const String _prefix = 'cache:';

  final Future<SharedPreferences> _prefs;

  SharedPrefsLocalCache({Future<SharedPreferences>? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance();

  String _k(String key) => '$_prefix$key';

  @override
  Future<String?> read(String key) async {
    final p = await _prefs;
    return p.getString(_k(key));
  }

  @override
  Future<void> write(String key, String value) async {
    final p = await _prefs;
    await p.setString(_k(key), value);
  }

  @override
  Future<void> remove(String key) async {
    final p = await _prefs;
    await p.remove(_k(key));
  }

  @override
  Future<void> clear() async {
    final p = await _prefs;
    final keys = p.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await p.remove(k);
    }
  }
}
