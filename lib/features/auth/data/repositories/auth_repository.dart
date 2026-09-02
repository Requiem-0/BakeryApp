import 'package:dio/dio.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/customer.dart';

/// Wraps the /api/auth/* endpoints. Stateless — does not hold tokens or user
/// state. Callers (AuthProvider) own that.
class AuthRepository {
  final ApiClient _api;

  AuthRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();



  Future<ApiResult<void>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await _api.post('/auth/register', body: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Registration failed');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// Returns the sessionToken on success.
  Future<ApiResult<String>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', body: {
        'emailOrPhone': emailOrPhone,
        'password': password,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Login failed');
      if (failure != null) return ApiResult.failure(failure);
      final token = _extractToken(res.data);
      if (token == null) {
        // Backend returns 200 with no token when the account is
        // deactivated (rather than a proper error). Signal that via
        // the message wording — the login screen's heuristic keys off
        // the word "deactivat" and rewrites this to a nicer toast.
        return ApiResult.failure(const ApiFailure(
          message: 'This account has been deactivated.',
        ));
      }
      return ApiResult.success(token);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> verifyEmail({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _api.post('/auth/verify-email', body: {
        'email': email,
        'token': token,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Email verification failed');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> sendResetToken({String? email, String? phone}) async {
    try {
      final res = await _api.post('/auth/send-token', body: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Failed to send verification code');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _api.patch('/auth/reset-password', body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Failed to reset password');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// Reactivates a deactivated account. Returns the new sessionToken on
  /// success so the caller can log the user in immediately.
  Future<ApiResult<String>> reactivate({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/reactivate', body: {
        'emailOrPhone': emailOrPhone,
        'password': password,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Reactivation failed');
      if (failure != null) return ApiResult.failure(failure);
      final token = _extractReactivateToken(res.data);
      if (token == null) {
        return ApiResult.failure(const ApiFailure(
          message: 'We couldn\'t reactivate your account. Please try again.',
        ));
      }
      return ApiResult.success(token);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }



  Future<ApiResult<Customer>> getMe() async {
    try {
      final res = await _api.get('/auth/me');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response shape from /auth/me.',
        ));
      }
      return ApiResult.success(Customer.fromJson(data));
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? imagePath,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) map['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) map['phone'] = phone.trim();
      if (address != null && address.trim().isNotEmpty) map['address'] = address.trim();

      if (imageBytes != null && imageBytes.isNotEmpty) {
        map['image'] = MultipartFile.fromBytes(
          imageBytes,
          filename: imageFilename ?? 'profile_image.jpg',
        );
      } else if (imagePath != null && imagePath.isNotEmpty) {
        map['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: imageFilename ?? imagePath.split(RegExp(r'[/\\]')).last,
        );
      }

      final formData = FormData.fromMap(map);
      final res = await _api.patch('/auth/me', body: formData);
      final failure = _checkFailure(res.data, defaultMessage: 'Failed to update profile');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _api.patch('/auth/change-password', body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      final failure = _checkFailure(res.data, defaultMessage: 'Failed to change password');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> logout() async {
    try {
      final res = await _api.post('/auth/logout');
      final failure = _checkFailure(res.data, defaultMessage: 'Logout failed');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> deactivate() async {
    try {
      final res = await _api.post('/auth/deactivate');
      final failure = _checkFailure(res.data, defaultMessage: 'Deactivation failed');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> deleteAccount() async {
    try {
      final res = await _api.post('/auth/delete');
      final failure = _checkFailure(res.data, defaultMessage: 'Account deletion failed');
      if (failure != null) return ApiResult.failure(failure);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// Inspects response data for failure flags or error messages returned with 200 OK.
  ApiFailure? _checkFailure(dynamic data, {String defaultMessage = 'Request failed'}) {
    if (data is Map) {
      if (data['success'] == false ||
          data['status'] == 'fail' ||
          data['status'] == 'error' ||
          (data.containsKey('error') && data['error'] != null && data['error'] != false)) {
        final rawMsg = data['message'] ?? data['error'];
        final msg = rawMsg?.toString().trim();
        return ApiFailure(message: (msg != null && msg.isNotEmpty) ? msg : defaultMessage);
      }
    }
    return null;
  }

  /// Pulls a session token from a login-style response, accepting either
  /// `sessionToken` (current API) or `token`/`accessToken` (defensive).
  String? _extractToken(dynamic data) {
    if (data is! Map) return null;
    final raw = data['sessionToken'] ?? data['token'] ?? data['accessToken'];
    final str = raw?.toString().trim();
    return (str == null || str.isEmpty) ? null : str;
  }

  /// The prod `/auth/reactivate` response buries the token inside
  /// `customer.hashRt[]` (an array of session objects). Falls back to
  /// the top-level keys used by beta.
  String? _extractReactivateToken(dynamic data) {
    if (data is! Map) return null;

    // Prod shape: customer.hashRt[last].token
    final customer = data['customer'];
    if (customer is Map) {
      final hashRt = customer['hashRt'];
      if (hashRt is List && hashRt.isNotEmpty) {
        final last = hashRt.last;
        if (last is Map) {
          final raw = last['token'];
          final str = raw?.toString().trim();
          if (str != null && str.isNotEmpty) return str;
        }
      }
    }

    // Beta shape / fallback: top-level sessionToken
    final raw = data['sessionToken'] ?? data['token'] ?? data['accessToken'];
    final str = raw?.toString().trim();
    if (str != null && str.isNotEmpty) return str;

    return null;
  }
}
