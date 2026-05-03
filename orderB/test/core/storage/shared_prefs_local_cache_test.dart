import 'package:bakery/core/storage/shared_prefs_local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsLocalCache', () {
    test('write/read round-trip', () async {
      final cache = SharedPrefsLocalCache();
      await cache.write('catalogue', '{"x":1}');
      expect(await cache.read('catalogue'), '{"x":1}');
    });

    test('read returns null for missing keys', () async {
      final cache = SharedPrefsLocalCache();
      expect(await cache.read('nope'), isNull);
    });

    test('remove deletes a single entry without touching others', () async {
      final cache = SharedPrefsLocalCache();
      await cache.write('a', '1');
      await cache.write('b', '2');
      await cache.remove('a');
      expect(await cache.read('a'), isNull);
      expect(await cache.read('b'), '2');
    });

    test('clear wipes only namespaced cache entries', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', 'dark');
      final cache = SharedPrefsLocalCache();
      await cache.write('a', '1');
      await cache.write('b', '2');
      await cache.clear();
      expect(await cache.read('a'), isNull);
      expect(await cache.read('b'), isNull);
      expect(prefs.getString('theme'), 'dark');
    });
  });
}
