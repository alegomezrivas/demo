import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/scoped_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_token_storage.dart';

void main() {
  const first = AuthTokens(accessToken: 'a1', refreshToken: 'r1');
  const second = AuthTokens(accessToken: 'a2', refreshToken: 'r2');

  late InMemoryTokenStorage persistent;
  late ScopedTokenStorage storage;

  setUp(() {
    persistent = InMemoryTokenStorage();
    storage = ScopedTokenStorage(persistent);
  });

  group('persistent mode (the default)', () {
    test('saves and reads through the persistent store', () async {
      await storage.save(first);

      expect(persistent.tokens, first);
      expect(await storage.read(), first);
    });

    test('reads what an earlier run persisted', () async {
      persistent.tokens = first;

      expect(await storage.read(), first);
    });

    test('keeps refreshed tokens in the persistent store', () async {
      await storage.save(first);
      await storage.save(second);

      expect(persistent.tokens, second);
    });
  });

  group('memory mode', () {
    setUp(() async => storage.usePersistence(persist: false));

    test('never writes to the persistent store', () async {
      await storage.save(first);

      expect(persistent.tokens, isNull);
      expect(await storage.read(), first);
    });

    test('keeps refreshed tokens in memory too', () async {
      await storage.save(first);
      await storage.save(second);

      expect(persistent.tokens, isNull);
      expect(await storage.read(), second);
    });

    test('ignores tokens persisted by an earlier session', () async {
      persistent.tokens = first;

      expect(await storage.read(), isNull);
    });

    test('removes tokens persisted by an earlier session', () async {
      persistent.tokens = first;

      await storage.usePersistence(persist: false);

      expect(persistent.tokens, isNull);
    });

    test('forgets everything on clear', () async {
      await storage.save(first);

      await storage.clear();

      expect(await storage.read(), isNull);
    });

    test('a new process starts empty', () async {
      await storage.save(first);

      final restarted = ScopedTokenStorage(persistent);

      expect(await restarted.read(), isNull);
    });
  });

  group('switching modes', () {
    test('back to persistent drops what only lived in memory', () async {
      await storage.usePersistence(persist: false);
      await storage.save(first);

      await storage.usePersistence(persist: true);

      expect(await storage.read(), isNull);
      await storage.save(second);
      expect(persistent.tokens, second);
    });

    test('clear wipes both places', () async {
      await storage.save(first);

      await storage.clear();

      expect(persistent.tokens, isNull);
      expect(await storage.read(), isNull);
    });
  });
}
