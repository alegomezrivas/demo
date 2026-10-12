import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';
import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  late InMemoryTokenStorage tokens;
  late InMemorySecureStorage storage;
  late AuthLocalDataSourceImpl source;
  const pair = AuthTokens(accessToken: 'a', refreshToken: 'r');
  const user = UserDto(id: '1', name: 'Ana', email: 'a@b.co');

  setUp(() {
    tokens = InMemoryTokenStorage();
    storage = InMemorySecureStorage();
    source = AuthLocalDataSourceImpl(tokens, storage);
  });

  group('AuthLocalDataSourceImpl', () {
    test('saves tokens and the user, then reads the user back', () async {
      await source.saveSession(tokens: pair, user: user);

      expect(tokens.tokens, pair);
      expect(await source.readUser(), user);
    });

    test('returns null without tokens even if a user is cached', () async {
      await source.saveSession(tokens: pair, user: user);
      tokens.tokens = null;

      expect(await source.readUser(), isNull);
    });

    test('returns null when tokens exist but no user was cached', () async {
      tokens.tokens = pair;

      expect(await source.readUser(), isNull);
    });

    test('raises CacheException for corrupted JSON', () async {
      tokens.tokens = pair;
      storage.values['auth.user'] = '{not json';

      await expectLater(source.readUser(), throwsA(isA<CacheException>()));
    });

    test('raises CacheException for JSON with the wrong shape', () async {
      tokens.tokens = pair;
      storage.values['auth.user'] = '{"id": 1}';

      await expectLater(source.readUser(), throwsA(isA<CacheException>()));
    });

    test('clear wipes tokens and the cached user', () async {
      await source.saveSession(tokens: pair, user: user);

      await source.clear();

      expect(tokens.tokens, isNull);
      expect(storage.values, isEmpty);
    });
  });
}
