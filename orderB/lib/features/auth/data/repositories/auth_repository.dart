import 'dart:io';

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

  // ── Public (no token) ─────────────────────────────────────────────────────

  Future<ApiResult<void>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _api.post('/auth/register', body: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      });
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
      final token = _extractToken(res.data);
      if (token == null) {
        return ApiResult.failure(const ApiFailure(
          message: 'Login response did not contain a session token.',
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
      await _api.post('/auth/verify-email', body: {
        'email': email,
        'token': token,
      });
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<String>> qrLogin({required String qrToken}) async {
    try {
      final res = await _api.post('/auth/qr-login', body: {'qrToken': qrToken});
      final token = _extractToken(res.data);
      if (token == null) {
        return ApiResult.failure(const ApiFailure(
          message: 'QR login response did not contain a session token.',
        ));
      }
      return ApiResult.success(token);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> sendResetToken({String? email, String? phone}) async {
    try {
      await _api.post('/auth/send-token', body: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
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
      await _api.dio.patch('/auth/reset-password', data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<String>> reactivate({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/reactivate', body: {
        'email': email,
        'password': password,
      });
      // Reactivate may or may not return a sessionToken — handle both.
      final token = _extractToken(res.data);
      return ApiResult.success(token ?? '');
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  // ── Authenticated (Bearer attached by ApiClient interceptor) ──────────────

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

  /// Multipart PATCH /auth/me — both fields optional.
  Future<ApiResult<void>> updateProfile({
    String? address,
    String? imageFilePath,
  }) async {
    try {
      final form = FormData.fromMap({
        if (address != null) 'address': address,
        if (imageFilePath != null && File(imageFilePath).existsSync())
          'image': await MultipartFile.fromFile(imageFilePath),
      });
      await _api.dio.patch('/auth/me', data: form);
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
      await _api.dio.patch('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> logout() async {
    try {
      await _api.post('/auth/logout');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  Future<ApiResult<void>> deactivate() async {
    try {
      await _api.post('/auth/deactivate');
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// Pulls a session token from a login-style response, accepting either
  /// `sessionToken` (current API) or `token`/`accessToken` (defensive).
  String? _extractToken(dynamic data) {
    if (data is! Map) return null;
    final raw = data['sessionToken'] ?? data['token'] ?? data['accessToken'];
    final str = raw?.toString().trim();
    return (str == null || str.isEmpty) ? null : str;
  }
}
