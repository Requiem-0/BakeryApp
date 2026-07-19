import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bakery logo on disk so the splash (and anywhere else
/// that wants to render it) can swap in a real image instantly on cold
/// boot, instead of waiting for the `/businesses/{id}` call to land
/// + the image bytes to download from a different host.
///
/// Flow:
///   1. App boot calls [loadCached] — reads the path saved in
///      SharedPreferences and warms [file] if the on-disk PNG still
///      exists.
///   2. When [BusinessProvider] resolves a logo URL, [ensureCached] is
///      called. If the URL matches what we already cached, no-op. If
///      not, download the bytes, write them to the app docs dir,
///      remember the new path + source URL.
///   3. Listeners are notified on every successful refresh so widgets
///      can react and rebuild with the new file.
///
/// Web is unsupported (no app docs dir); [ensureCached] silently
/// swallows the platform error and consumers fall through to the
/// network image path.
class LogoCacheService extends ChangeNotifier {
  static const _kSourceUrlKey = 'logo_cache_source_url';
  static const _kFilePathKey = 'logo_cache_file_path';
  static const _kFileName = 'bakery_logo.png';

  File? _file;
  String? _sourceUrl;
  bool _refreshing = false;

  /// The cached logo file, or null when nothing's cached yet.
  /// Synchronous — safe to read inside `build()`.
  File? get file => _file;

  /// The URL the cached file was downloaded from. Useful for detecting
  /// when the backend has changed the logo and we should re-fetch.
  String? get sourceUrl => _sourceUrl;

  /// Loads the on-disk cache pointer into memory. Call once at app boot
  /// before the first frame.
  Future<void> loadCached() async {
    // No-op on web — dart:io File throws UnsupportedError in the
    // browser, and there's no app docs dir to point at anyway.
    // Splash falls through to CachedNetworkImage's HTTP cache on web.
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_kFilePathKey);
      final url = prefs.getString(_kSourceUrlKey);
      if (path == null || path.isEmpty) return;
      final f = File(path);
      if (!f.existsSync()) return;
      _file = f;
      _sourceUrl = url;
      notifyListeners();
    } catch (e) {
      assert(() {
        debugPrint('LogoCacheService.loadCached: $e');
        return true;
      }());
    }
  }

  /// Ensures the on-disk cache matches [url]. No-op when the URL
  /// matches what we already have. Concurrent calls collapse — the
  /// first one wins and the rest return immediately.
  Future<void> ensureCached(String url) async {
    if (kIsWeb) return;
    if (url.isEmpty) return;
    if (_refreshing) return;
    if (_sourceUrl == url && _file != null && _file!.existsSync()) return;
    _refreshing = true;
    try {
      final res = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return;
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$_kFileName');
      await f.writeAsBytes(bytes, flush: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSourceUrlKey, url);
      await prefs.setString(_kFilePathKey, f.path);
      _file = f;
      _sourceUrl = url;
      notifyListeners();
    } catch (e) {
      // Cache miss is non-fatal — splash falls back to the bundled
      // asset. No reason to scream about it.
      assert(() {
        debugPrint('LogoCacheService.ensureCached: $e');
        return true;
      }());
    } finally {
      _refreshing = false;
    }
  }
}
