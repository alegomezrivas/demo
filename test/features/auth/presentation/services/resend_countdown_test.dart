import 'package:demo/features/auth/presentation/services/resend_countdown.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResendCountdown', () {
    test('is idle until started', () {
      final countdown = ResendCountdown(onChanged: () {});

      expect(countdown.isActive, isFalse);
      expect(countdown.secondsLeft, 0);
    });

    test('counts down once per tick and notifies each time', () {
      fakeAsync((async) {
        var notified = 0;
        final countdown = ResendCountdown(
          onChanged: () => notified++,
          seconds: 3,
        )..start();
        expect(countdown.secondsLeft, 3);
        expect(countdown.isActive, isTrue);

        async.elapse(const Duration(seconds: 1));
        expect(countdown.secondsLeft, 2);

        async.elapse(const Duration(seconds: 2));
        expect(countdown.secondsLeft, 0);
        expect(countdown.isActive, isFalse);
        // start + three ticks
        expect(notified, 4);
      });
    });

    test('stops ticking at zero', () {
      fakeAsync((async) {
        var notified = 0;
        ResendCountdown(onChanged: () => notified++, seconds: 1).start();

        async.elapse(const Duration(seconds: 10));

        expect(notified, 2);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('restarting begins again from the full wait', () {
      fakeAsync((async) {
        final countdown = ResendCountdown(onChanged: () {}, seconds: 5)
          ..start();
        async.elapse(const Duration(seconds: 3));

        countdown.start();

        expect(countdown.secondsLeft, 5);
        async.elapse(const Duration(seconds: 1));
        expect(countdown.secondsLeft, 4);
        expect(async.pendingTimers, hasLength(1));
      });
    });

    test('cancel stops it silently', () {
      fakeAsync((async) {
        var notified = 0;
        final countdown = ResendCountdown(onChanged: () => notified++)..start();
        final before = notified;

        countdown.cancel();
        async.elapse(const Duration(seconds: 60));

        expect(countdown.isActive, isFalse);
        expect(notified, before);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('honors a custom tick', () {
      fakeAsync((async) {
        final countdown = ResendCountdown(
          onChanged: () {},
          seconds: 2,
          tick: const Duration(milliseconds: 10),
        )..start();

        async.elapse(const Duration(milliseconds: 20));

        expect(countdown.isActive, isFalse);
      });
    });
  });
}
