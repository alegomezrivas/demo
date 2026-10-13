import 'dart:async';

import 'package:demo/app/session_cleanup.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../features/auth/helpers/auth_mocks.dart';

void main() {
  late SessionExpiredNotifier notifier;
  late MockAuthLocalDataSource local;
  late StreamSubscription<void> subscription;

  setUp(() {
    notifier = SessionExpiredNotifier();
    local = MockAuthLocalDataSource();
    subscription = wipeStoredSessionOnExpiry(notifier: notifier, local: local);
  });

  tearDown(() async {
    await subscription.cancel();
    await notifier.dispose();
  });

  group('wipeStoredSessionOnExpiry', () {
    test('clears the stored session when it expires', () async {
      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      verify(local.clear()).called(1);
    });

    test('does nothing before an expiry', () async {
      await Future<void>.delayed(Duration.zero);

      verifyZeroInteractions(local);
    });

    test('clears on every expiry', () async {
      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);
      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      verify(local.clear()).called(2);
    });

    test('survives a storage failure', () async {
      when(local.clear()).thenThrow(Exception('boom'));

      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);
      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      verify(local.clear()).called(2);
    });

    test('stops after the subscription is cancelled', () async {
      await subscription.cancel();

      notifier.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      verifyZeroInteractions(local);
    });
  });
}
