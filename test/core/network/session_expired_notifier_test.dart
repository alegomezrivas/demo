import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionExpiredNotifier', () {
    test('emits an event for every notification', () async {
      final notifier = SessionExpiredNotifier();
      var count = 0;
      final sub = notifier.onExpired.listen((_) => count++);

      notifier
        ..notifyExpired()
        ..notifyExpired();
      await Future<void>.delayed(Duration.zero);

      expect(count, 2);
      await sub.cancel();
      await notifier.dispose();
    });

    test('supports several listeners', () async {
      final notifier = SessionExpiredNotifier();
      final first = expectLater(notifier.onExpired, emits(isNull));
      final second = expectLater(notifier.onExpired, emits(isNull));

      notifier.notifyExpired();

      await first;
      await second;
      await notifier.dispose();
    });

    test('ignores notifications after dispose', () async {
      final notifier = SessionExpiredNotifier();
      await notifier.dispose();

      expect(notifier.notifyExpired, returnsNormally);
    });
  });
}
