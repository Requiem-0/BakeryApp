import 'package:dio/dio.dart';

import '../constants.dart';
import '../errors/api_failure.dart';
import '../storage/token_storage.dart';

/// Dio-backed HTTP client with a Bearer-token interceptor and a unified
/// error parser that handles both RebuzzPOS response shapes:
///   { "status": "fail",   "message": "..." }
///   { "success": false,   "error":   "..." }
class ApiClient {
  /// JSON API host. Driven by [AppConstants.useProd] so the dev/prod
  /// swap is a single toggle in one file rather than three.
  static const String baseUrl = AppConstants.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 15);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Fired once when any request returns 401. Wired by AuthProvider so an
  /// expired/revoked token boots the user back to the login screen.
  void Function()? onUnauthorized;

  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
              contentType: 'application/json',
              responseType: ResponseType.json,
              headers: {'app': 'customer'},
            )),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _dio.get(path, queryParameters: query);

  Future<Response<dynamic>> post(String path, {Object? body}) =>
      _dio.post(path, data: body);

  Future<Response<dynamic>> put(String path, {Object? body}) =>
      _dio.put(path, data: body);

  Future<Response<dynamic>> patch(String path, {Object? body}) =>
      _dio.patch(path, data: body);

  Future<Response<dynamic>> delete(String path, {Object? body}) =>
      _dio.delete(path, data: body);

  /// Convert any thrown error from a Dio call into an [ApiFailure].
  /// Reads `message` first, then `error`, to cover both backend shapes.
  static ApiFailure parseError(Object error) {
    if (error is DioException) {
      final response = error.response;
      final status = response?.statusCode;
      final data = response?.data;

      if (data is Map) {
        final raw = data['message'] ?? data['error'];
        final msg = raw?.toString().trim();
        if (msg != null && msg.isNotEmpty) {
          return ApiFailure(message: msg, statusCode: status);
        }
      }

      String fallback;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          fallback = 'Request timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          fallback = 'No internet connection.';
          break;
        case DioExceptionType.badCertificate:
          fallback = 'Secure connection failed.';
          break;
        case DioExceptionType.cancel:
          fallback = 'Request cancelled.';
          break;
        default:
          fallback = error.message ?? 'Something went wrong.';
      }
      return ApiFailure(message: fallback, statusCode: status);
    }
    return ApiFailure(message: error.toString());
  }
}
