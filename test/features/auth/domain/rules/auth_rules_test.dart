import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRules.isValidEmail', () {
    test('accepts ordinary addresses', () {
      for (final email in ['a@b.co', 'first.last+tag@mail.example.com']) {
        expect(AuthRules.isValidEmail(email), isTrue, reason: email);
      }
    });

    test('rejects malformed or oversized addresses', () {
      for (final email in [
        '',
        'nope',
        'a@b',
        '@b.co',
        'a b@c.co',
        '${'x' * 250}@b.co',
      ]) {
        expect(AuthRules.isValidEmail(email), isFalse, reason: email);
      }
    });
  });

  group('AuthRules.isValidUsername', () {
    test('accepts letters, digits, dots and underscores', () {
      for (final name in [
        'abc',
        'ana.perez',
        'a_b',
        'USER_01',
        '_ab',
        'a' * 30,
      ]) {
        expect(AuthRules.isValidUsername(name), isTrue, reason: name);
      }
    });

    test('rejects the wrong length, characters and dotted ends', () {
      for (final name in [
        '',
        'ab',
        'a' * 31,
        'two words',
        'bad@name',
        'name.',
        '.name',
        'ñandú',
      ]) {
        expect(AuthRules.isValidUsername(name), isFalse, reason: name);
      }
    });
  });

  group('AuthRules.isValidCode', () {
    test('needs exactly six digits', () {
      expect(AuthRules.isValidCode('123456'), isTrue);
      for (final code in [
        '',
        '12345',
        '1234567',
        'abcdef',
        '12 456',
        '12345a',
      ]) {
        expect(AuthRules.isValidCode(code), isFalse, reason: code);
      }
    });

    test('rejects a trailing newline', () {
      expect(AuthRules.isValidCode('123456\n'), isFalse);
    });
  });

  group('AuthRules.passwordProblems', () {
    test('is empty for a strong password', () {
      expect(AuthRules.passwordProblems('Str0ng!Pass'), isEmpty);
    });

    test('names every broken rule', () {
      expect(
        AuthRules.passwordProblems('abc'),
        unorderedEquals(['length', 'uppercase', 'digit', 'symbol']),
      );
      expect(
        AuthRules.passwordProblems('ALLUPPER1!'),
        equals(['lowercase']),
      );
    });

    test('rejects passwords over the maximum length', () {
      expect(
        AuthRules.passwordProblems('Aa1!${'x' * 125}'),
        contains('max_length'),
      );
    });
  });

  test('exposes the limits of the contract', () {
    expect(AuthRules.codeLength, 6);
    expect(AuthRules.maxAvatarBytes, 204800);
  });
}
