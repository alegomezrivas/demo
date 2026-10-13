import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/scoped_token_storage.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';
import '../../../../helpers/in_memory_token_storage.dart';

void main() {
  late InMemoryTokenStorage persistent;
  late ScopedTokenStorage tokens;
  late InMemorySecureStorage storage;
  late AuthLocalDataSourceImpl source;
  const pair = AuthTokens(accessToken: 'a', refreshToken: 'r');
  const user = UserDto(id: '1', name: 'Ana', email: 'a@b.co', username: 'ana');

  setUp(() {
    persistent = InMemoryTokenStorage();
    tokens = ScopedTokenStorage(persistent);
    storage = InMemorySecureStorage();
    source = AuthLocalDataSourceImpl(tokens, storage);
  });

  group('AuthLocalDataSourceImpl', () {
    test('saves tokens and the user, then reads the user back', () async {
      await source.saveSession(tokens: pair, user: user);

      expect(persistent.tokens, pair);
      expect(await source.readUser(), user);
    });

    test('returns null without tokens even if a user is cached', () async {
      await source.saveSession(tokens: pair, user: user);
      persistent.tokens = null;

      expect(await source.readUser(), isNull);
    });

    test('returns null when tokens exist but no user was cached', () async {
      persistent.tokens = pair;

      expect(await source.readUser(), isNull);
    });

    test('raises CacheException for corrupted JSON', () async {
      persistent.tokens = pair;
      storage.values['auth.user'] = '{not json';

      await expectLater(source.readUser(), throwsA(isA<CacheException>()));
    });

    test('raises CacheException for JSON with the wrong shape', () async {
      persistent.tokens = pair;
      storage.values['auth.user'] = '{"id": 1}';

      await expectLater(source.readUser(), throwsA(isA<CacheException>()));
    });

    test('clear wipes tokens and the cached user', () async {
      await source.saveSession(tokens: pair, user: user);

      await source.clear();

      expect(persistent.tokens, isNull);
      expect(storage.values, isEmpty);
    });
  });

  group('readRefreshToken', () {
    test('returns the stored refresh token', () async {
      await source.saveSession(tokens: pair, user: user);

      expect(await source.readRefreshToken(), 'r');
    });

    test('returns null when there is no session', () async {
      expect(await source.readRefreshToken(), isNull);
    });

    test('returns null after the session was cleared', () async {
      await source.saveSession(tokens: pair, user: user);
      await source.clear();

      expect(await source.readRefreshToken(), isNull);
    });
  });

  group('sessions that are not remembered', () {
    test('keep the tokens and the user out of secure storage', () async {
      await source.saveSession(tokens: pair, user: user, persist: false);

      expect(persistent.tokens, isNull);
      expect(storage.values, isEmpty);
      expect(await source.readUser(), user);
      expect(await source.readRefreshToken(), 'r');
    });

    test(
      'are gone after a restart (new instances over the same storage)',
      () async {
        await source.saveSession(tokens: pair, user: user, persist: false);

        final restarted = AuthLocalDataSourceImpl(
          ScopedTokenStorage(persistent),
          storage,
        );

        expect(await restarted.readUser(), isNull);
        expect(await restarted.readRefreshToken(), isNull);
      },
    );

    test('remove a session persisted earlier', () async {
      await source.saveSession(tokens: pair, user: user);
      expect(persistent.tokens, pair);

      await source.saveSession(
        tokens: const AuthTokens(accessToken: 'a2', refreshToken: 'r2'),
        user: user,
        persist: false,
      );

      expect(persistent.tokens, isNull);
      expect(storage.values, isEmpty);
    });

    test('clear wipes memory as well', () async {
      await source.saveSession(tokens: pair, user: user, persist: false);

      await source.clear();

      expect(await source.readUser(), isNull);
      expect(await source.readRefreshToken(), isNull);
    });

    test('updating the user stays in memory', () async {
      await source.saveSession(tokens: pair, user: user, persist: false);
      final updated = user.copyWith(hasAvatar: true);

      await source.updateUser(updated);

      expect(await source.readUser(), updated);
      expect(storage.values, isEmpty);
    });

    test('a later remembered login persists again', () async {
      await source.saveSession(tokens: pair, user: user, persist: false);
      await source.saveSession(tokens: pair, user: user);

      expect(persistent.tokens, pair);
      expect(storage.values['auth.user'], isNotNull);
    });
  });

  group('updateUser', () {
    test('replaces the persisted user and keeps the tokens', () async {
      await source.saveSession(tokens: pair, user: user);
      final updated = user.copyWith(hasAvatar: true);

      await source.updateUser(updated);

      expect(await source.readUser(), updated);
      expect(persistent.tokens, pair);
    });
  });
}
