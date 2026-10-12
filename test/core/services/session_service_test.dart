import 'dart:async';

import 'package:demo/core/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionService', () {
    test('starts signed out by default', () {
      expect(SessionService().isAuthenticated, isFalse);
      expect(SessionService(isAuthenticated: true).isAuthenticated, isTrue);
    });

    test('notifies only when the state actually changes', () {
      var notified = 0;
      SessionService()
        ..addListener(() => notified++)
        ..markSignedIn()
        ..markSignedIn()
        ..markSignedOut()
        ..markSignedOut();

      expect(notified, 2);
    });

    test('signs out when the session-expired stream emits', () async {
      final controller = StreamController<void>.broadcast();
      final session = SessionService(isAuthenticated: true)
        ..attach(controller.stream);

      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(session.isAuthenticated, isFalse);
      await controller.close();
    });

    test('replaces a previous subscription when attached again', () async {
      final first = StreamController<void>.broadcast();
      final second = StreamController<void>.broadcast();
      final session = SessionService()
        ..attach(first.stream)
        ..attach(second.stream)
        ..markSignedIn();

      first.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(session.isAuthenticated, isTrue);

      second.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(session.isAuthenticated, isFalse);
      await first.close();
      await second.close();
    });

    test('stops listening after dispose', () async {
      final controller = StreamController<void>.broadcast();
      final session = SessionService(isAuthenticated: true)
        ..attach(controller.stream)
        ..dispose();

      expect(controller.hasListener, isFalse);
      await controller.close();
      expect(session.isAuthenticated, isTrue);
    });
  });
}
