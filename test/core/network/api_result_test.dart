import 'package:bakery/core/errors/api_failure.dart';
import 'package:bakery/core/network/api_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiFailure', () {
    test('toString includes status code and message', () {
      const f = ApiFailure(message: 'nope', statusCode: 404);
      expect(f.toString(), contains('404'));
      expect(f.toString(), contains('nope'));
    });

    test('toString shows "-" when status code is null', () {
      const f = ApiFailure(message: 'oops');
      expect(f.toString(), contains('-'));
      expect(f.toString(), contains('oops'));
    });

    test('is an Exception', () {
      const f = ApiFailure(message: 'x');
      expect(f, isA<Exception>());
    });
  });

  group('ApiResult', () {
    test('success carries data and reports isSuccess', () {
      final r = ApiResult<int>.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.data, 42);
      expect(r.failure, isNull);
    });

    test('failure carries failure and reports isFailure', () {
      const failure = ApiFailure(message: 'x', statusCode: 500);
      final r = ApiResult<int>.failure(failure);
      expect(r.isSuccess, isFalse);
      expect(r.isFailure, isTrue);
      expect(r.data, isNull);
      expect(r.failure, same(failure));
    });
  });
}
