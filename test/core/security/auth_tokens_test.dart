import 'package:demo/core/security/auth_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTokens', () {
    test('has value equality', () {
      const a = AuthTokens(accessToken: 'a', refreshToken: 'r');
      const b = AuthTokens(accessToken: 'a', refreshToken: 'r');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const AuthTokens(accessToken: 'x', refreshToken: 'r')));
    });

    test('never prints token values', () {
      const tokens = AuthTokens(
        accessToken: 'secret-a',
        refreshToken: 'secret-r',
      );

      expect(tokens.toString(), isNot(contains('secret')));
    });
  });
}
