import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for the auth Bearer token.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
