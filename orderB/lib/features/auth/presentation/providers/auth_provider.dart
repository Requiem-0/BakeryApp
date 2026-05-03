import 'package:flutter/foundation.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

/// Single source of truth for authentication state.
///
/// UI consumes [status] / [user] / [isBusy] / [errorMessage] and calls the
/// public methods. All methods (except [logout] and [bootstrap]) return
/// `Future<bool>` so callers can navigate or surface errors directly:
///
///     final ok = await context.read<AuthProvider>().login(...);
///     if (!ok) showSnackBar(authProvider.errorMessage ?? 'Login failed');
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.initial;
  Customer? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AuthProvider({
    required AuthRepository repository,
    required TokenStorage tokenStorage,
  })  : _repo = repository,
        _tokenStorage = tokenStorage;

  // ── Public state ──────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  Customer? get user => _user;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Called on app start. Reads stored token; if present, validates by
  /// fetching /me. On any failure, ends in [AuthStatus.unauthenticated].
  Future<void> bootstrap() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      _setUnauthenticated();
      return;
    }
    final result = await _repo.getMe();
    if (result.isSuccess && result.data != null) {
      _user = result.data;
      _setStatus(AuthStatus.authenticated);
    } else {
      await _tokenStorage.clear();
      _setUnauthenticated();
    }
  }

  /// Called by ApiClient's 401 interceptor. Idempotent: only acts if currently
  /// authenticated. Clears token + flips state to unauthenticated.
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.authenticated) return;
    await _tokenStorage.clear();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Auth flows ────────────────────────────────────────────────────────────

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) =>
      _run(() async {
        final result = await _repo.login(
          emailOrPhone: emailOrPhone,
          password: password,
        );
        if (result.isFailure || result.data == null) {
          _errorMessage = result.failure?.message ?? 'Login failed.';
          return false;
        }
        await _tokenStorage.write(result.data!);
        final me = await _repo.getMe();
        if (me.isFailure || me.data == null) {
          await _tokenStorage.clear();
          _errorMessage = me.failure?.message ?? 'Failed to load profile.';
          return false;
        }
        _user = me.data;
        _setStatus(AuthStatus.authenticated);
        return true;
      });

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) =>
      _runSimple(() => _repo.register(
            name: name,
            phone: phone,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
          ));

  Future<bool> verifyEmail({required String email, required String token}) =>
      _runSimple(() => _repo.verifyEmail(email: email, token: token));

  Future<bool> qrLogin({required String qrToken}) => _run(() async {
        final result = await _repo.qrLogin(qrToken: qrToken);
        if (result.isFailure || result.data == null) {
          _errorMessage = result.failure?.message ?? 'QR login failed.';
          return false;
        }
        await _tokenStorage.write(result.data!);
        final me = await _repo.getMe();
        if (me.isFailure || me.data == null) {
          await _tokenStorage.clear();
          _errorMessage = me.failure?.message ?? 'Failed to load profile.';
          return false;
        }
        _user = me.data;
        _setStatus(AuthStatus.authenticated);
        return true;
      });

  Future<bool> sendResetToken({String? email, String? phone}) =>
      _runSimple(() => _repo.sendResetToken(email: email, phone: phone));

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _runSimple(() => _repo.resetPassword(
            resetToken: resetToken,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          ));

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _runSimple(() => _repo.changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ));

  /// On success, refreshes [user] from /me so UI sees the new fields.
  Future<bool> updateProfile({String? address, String? imageFilePath}) =>
      _run(() async {
        final result = await _repo.updateProfile(
          address: address,
          imageFilePath: imageFilePath,
        );
        if (result.isFailure) {
          _errorMessage = result.failure?.message ?? 'Profile update failed.';
          return false;
        }
        final me = await _repo.getMe();
        if (me.isSuccess && me.data != null) {
          _user = me.data;
        }
        return true;
      });

  Future<bool> deactivate() => _run(() async {
        final result = await _repo.deactivate();
        if (result.isFailure) {
          _errorMessage =
              result.failure?.message ?? 'Account deactivation failed.';
          return false;
        }
        await _tokenStorage.clear();
        _user = null;
        _setStatus(AuthStatus.unauthenticated);
        return true;
      });

  Future<bool> reactivate({
    required String email,
    required String password,
  }) =>
      _run(() async {
        final result = await _repo.reactivate(email: email, password: password);
        if (result.isFailure) {
          _errorMessage = result.failure?.message ?? 'Reactivation failed.';
          return false;
        }
        // Server may or may not return a token; if it does, log in directly.
        final token = result.data;
        if (token != null && token.isNotEmpty) {
          await _tokenStorage.write(token);
          final me = await _repo.getMe();
          if (me.isSuccess && me.data != null) {
            _user = me.data;
            _setStatus(AuthStatus.authenticated);
          }
        }
        return true;
      });

  /// Best-effort. Always clears local token + state, even if the API call
  /// fails (server might be offline; user still wants to be logged out).
  Future<void> logout() async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.logout();
    } catch (_) {
      // Intentionally swallowed — local logout proceeds regardless.
    }
    await _tokenStorage.clear();
    _user = null;
    _isBusy = false;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// For methods that return an [ApiResult<void>] and have no extra
  /// post-success state changes — just maps success/failure to bool.
  Future<bool> _runSimple(Future<dynamic> Function() call) => _run(() async {
        final result = await call();
        if (result.isSuccess) return true;
        _errorMessage = result.failure?.message ?? 'Request failed.';
        return false;
      });

  Future<bool> _run(Future<bool> Function() body) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    bool ok = false;
    try {
      ok = await body();
    } catch (e) {
      _errorMessage = e.toString();
      ok = false;
    }
    _isBusy = false;
    notifyListeners();
    return ok;
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }
}
