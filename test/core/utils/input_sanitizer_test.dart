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
}
