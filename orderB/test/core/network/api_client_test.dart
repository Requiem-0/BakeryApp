import 'dart:typed_data';

import 'package:bakery/core/network/api_client.dart';
import 'package:bakery/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeTokenStorage extends TokenStorage {
  String? _token;
  _FakeTokenStorage({String? token}) : _token = token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  group('ApiClient.parseError', () {
    test('parses RebuzzPOS shape A: { status, message }', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: const {'status': 'fail', 'message': 'bad input'},
        ),
        type: DioExceptionType.badResponse,
      );
      final f = ApiClient.parseError(err);
      expect(f.message, 'bad input');
      expect(f.statusCode, 400);
    });

    test('parses RebuzzPOS shape B: { success, error }', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 422,
          data: const {'success': false, 'error': 'validation failed'},
        ),
        type: DioExceptionType.badResponse,
      );
      final f = ApiClient.parseError(err);
      expect(f.message, 'validation failed');
      expect(f.statusCode, 422);
    });

    test('prefers `message` when both keys are present', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: const {'message': 'first', 'error': 'second'},
        ),
        type: DioExceptionType.badResponse,
      );
      final f = ApiClient.parseError(err);
      expect(f.message, 'first');
    });

    test('falls back to friendly text on connection timeout', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      final f = ApiClient.parseError(err);
      expect(f.message.toLowerCase(), contains('timed out'));
    });

    test('falls back to friendly text on connection error', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      final f = ApiClient.parseError(err);
      expect(f.message.toLowerCase(), contains('no internet'));
    });

    test('handles non-Dio errors', () {
      final f = ApiClient.parseError(Exception('boom'));
      expect(f.message, contains('boom'));
      expect(f.statusCode, isNull);
    });
  });

  group('ApiClient Bearer interceptor', () {
    test('attaches Bearer header when token is present', () async {
      final adapter = _FakeAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        dio: dio,
        tokenStorage: _FakeTokenStorage(token: 'abc123'),
      );

      await client.get('/x');

      expect(adapter.captured!.headers['Authorization'], 'Bearer abc123');
    });

    test('omits Bearer header when no token is stored', () async {
      final adapter = _FakeAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      final client = ApiClient(
        dio: dio,
        tokenStorage: _FakeTokenStorage(),
      );

      await client.get('/x');

      expect(adapter.captured!.headers.containsKey('Authorization'), isFalse);
    });

    test('reads the token fresh on each request', () async {
      final adapter = _FakeAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      final tokenStorage = _FakeTokenStorage();
      final client = ApiClient(dio: dio, tokenStorage: tokenStorage);

      await client.get('/x');
      expect(adapter.captured!.headers.containsKey('Authorization'), isFalse);

      await tokenStorage.write('new-token');
      await client.get('/x');
      expect(adapter.captured!.headers['Authorization'], 'Bearer new-token');
    });
  });
}
