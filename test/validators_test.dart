import 'package:flutter_test/flutter_test.dart';
import 'package:bakery/core/utils/validators.dart';

void main() {
  group('Validators.validateNepalPhone', () {
    test('rejects random non-Nepal numbers', () {
      expect(Validators.validateNepalPhone('1234567669'), isNotNull);
      expect(Validators.validateNepalPhone('0123456789'), isNotNull);
      expect(Validators.validateNepalPhone('5551234567'), isNotNull);
      expect(Validators.validateNepalPhone('98123'), isNotNull);
      expect(Validators.validateNepalPhone('981234567890'), isNotNull);
      expect(Validators.validateNepalPhone('abcdefghij'), isNotNull);
    });

    test('accepts valid Nepal phone numbers', () {
      expect(Validators.validateNepalPhone('9841234567'), isNull);
      expect(Validators.validateNepalPhone('9801234567'), isNull);
      expect(Validators.validateNepalPhone('9741234567'), isNull);
      expect(Validators.validateNepalPhone('9761234567'), isNull);
      expect(Validators.validateNepalPhone('+9779841234567'), isNull);
      expect(Validators.validateNepalPhone('+977 9801234567'), isNull);
      expect(Validators.validateNepalPhone('+977-9741234567'), isNull);
    });

    test('normalizes numbers correctly to 10 digits', () {
      expect(Validators.normalizePhone('+9779841234567'), '9841234567');
      expect(Validators.normalizePhone('+977 9801234567'), '9801234567');
      expect(Validators.normalizePhone('+977-9741234567'), '9741234567');
      expect(Validators.normalizePhone('9841234567'), '9841234567');
    });
  });
}
