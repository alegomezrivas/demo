import 'package:demo/core/security/security_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityPolicy.parse', () {
    test('parses known values ignoring case and whitespace', () {
      expect(SecurityPolicy.parse(' BLOCK '), SecurityPolicy.block);
      expect(SecurityPolicy.parse('warn'), SecurityPolicy.warn);
    });

    test('falls back to warn for unknown or empty values', () {
      expect(SecurityPolicy.parse('nonsense'), SecurityPolicy.warn);
      expect(SecurityPolicy.parse(''), SecurityPolicy.warn);
    });
  });
}
