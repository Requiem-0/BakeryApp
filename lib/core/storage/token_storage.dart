import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for the auth Bearer token.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e, st) {
      debugPrint('🚨 TokenStorage.read failed: $e\n$st');
      return null;
    }
  }

  Future<void> write(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e, st) {
      debugPrint('🚨 TokenStorage.write failed: $e\n$st');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e, st) {
      debugPrint('🚨 TokenStorage.clear failed: $e\n$st');
    }
  }
}
