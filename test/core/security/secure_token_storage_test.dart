import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/secure_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_storage.dart';

void main() {
  late InMemorySecureStorage backing;
  late SecureTokenStorage storage;
  const tokens = AuthTokens(accessToken: 'a1', refreshToken: 'r1');

  setUp(() {
    backing = InMemorySecureStorage();
    storage = SecureTokenStorage(backing);
  });

  group('SecureTokenStorage', () {
    test('returns null when nothing is stored', () async {
      expect(await storage.read(), isNull);
    });

    test('round-trips a token pair', () async {
      await storage.save(tokens);

      expect(await storage.read(), tokens);
    });

    test('overwrites previous tokens', () async {
      await storage.save(tokens);
      await storage.save(
        const AuthTokens(accessToken: 'a2', refreshToken: 'r2'),
      );

      expect((await storage.read())?.accessToken, 'a2');
    });

    test('returns null when only one of the tokens exists', () async {
      backing.values['auth.access_token'] = 'a1';

      expect(await storage.read(), isNull);
    });

    test('clear removes both tokens', () async {
      await storage.save(tokens);

      await storage.clear();

      expect(await storage.read(), isNull);
      expect(backing.values, isEmpty);
    });
  });
}
