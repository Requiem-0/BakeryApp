import 'package:flutter/foundation.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/app_toast.dart';
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
    try {
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
    } catch (e, st) {
      debugPrint('🚨 AuthProvider.bootstrap failed: $e\n$st');
      _setUnauthenticated();
    }
  }

  /// Called by ApiClient's 401 interceptor. Idempotent: only acts if currently
  /// authenticated. Clears token, flips state to unauthenticated, and
  /// surfaces a toast so the user understands why they got kicked. The
  /// router's protected-path redirect handles the actual nav to /login.
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.authenticated) return;
    await _tokenStorage.clear();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      AppToast.info(ctx, 'Session expired. Please sign in again.');
    }
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
    required String emailOrPhone,
    required String password,
  }) =>
      _run(() async {
        final result = await _repo.reactivate(
          emailOrPhone: emailOrPhone,
          password: password,
        );
        if (result.isFailure || result.data == null) {
          _errorMessage = result.failure?.message ?? 'Reactivation failed.';
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

  /// Best-effort. Always clears local token + state, even if the API call
  /// fails (server might be offline; user still wants to be logged out).
  Future<void> logout() async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.logout();
    } catch (e) {
      debugPrint('🚨 AuthProvider.logout (API call failed, local logout continues): $e');
    }
    await _tokenStorage.clear();
    _user = null;
    _isBusy = false;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  //
  // Every public method in this class needs the same boilerplate:
  //   1. set isBusy = true, clear errorMessage, notify
  //   2. run the actual logic, catching errors
  //   3. set isBusy = false, notify
  //
  // [_run] does that wrapping for any method whose body decides true/false.
  // [_runSimple] is a thin convenience for methods that just want
  // "ApiResult.isSuccess → true, otherwise false + capture the message".

  /// Use for methods that just call a repository method and return its
  /// success/failure as a bool.
  Future<bool> _runSimple(Future<dynamic> Function() call) => _run(() async {
        final result = await call();
        if (result.isSuccess) return true;
        _errorMessage = result.failure?.message ?? 'Request failed.';
        return false;
      });

  /// Use for methods that need custom logic between the busy-state flips
  /// (e.g. login, which saves a token AND fetches /me on success).
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
