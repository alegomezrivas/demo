import 'package:demo/core/utils/input_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputSanitizer.text', () {
    test('trims and strips HTML tags and control characters', () {
      expect(
        InputSanitizer.text('  <b>Hola</b>\u0000 mundo\u0007  '),
        'Hola mundo',
      );
    });

    test('caps the length', () {
      expect(InputSanitizer.text('abcdef', maxLength: 3), 'abc');
    });

    test('returns an empty string for blank input', () {
      expect(InputSanitizer.text('   '), isEmpty);
    });
  });

  group('InputSanitizer.email', () {
    test('lower-cases and trims', () {
      expect(InputSanitizer.email('  Ana@Example.COM '), 'ana@example.com');
    });
  });

  group('InputSanitizer.phone', () {
    test('keeps digits and a leading plus only', () {
      expect(InputSanitizer.phone('+57 (300) 123-4567'), '+573001234567');
    });

    test('drops plus signs that are not leading', () {
      expect(InputSanitizer.phone('300+123'), '300123');
    });
  });
}
