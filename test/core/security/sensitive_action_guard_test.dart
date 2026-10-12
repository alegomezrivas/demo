import 'package:demo/core/security/sensitive_action_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../features/settings/helpers/settings_mocks.dart';

void main() {
  late MockBiometricAuthenticator authenticator;
  var enabled = true;

  SensitiveActionGuard build() => SensitiveActionGuard(
    authenticator: authenticator,
    isEnabled: () => enabled,
  );

  setUp(() {
    authenticator = MockBiometricAuthenticator();
    enabled = true;
    when(authenticator.isAvailable()).thenAnswer((_) async => true);
  });

  group('SensitiveActionGuard.confirm', () {
    test(
      'allows everything without prompting when protection is off',
      () async {
        enabled = false;

        expect(await build().confirm(reason: 'r'), isTrue);
        verifyZeroInteractions(authenticator);
      },
    );

    test('allows the action when the user authenticates', () async {
      when(
        authenticator.authenticate(reason: 'r'),
      ).thenAnswer((_) async => true);

      expect(await build().confirm(reason: 'r'), isTrue);
    });

    test('blocks the action when authentication fails', () async {
      when(
        authenticator.authenticate(reason: 'r'),
      ).thenAnswer((_) async => false);

      expect(await build().confirm(reason: 'r'), isFalse);
    });

    test(
      'does not lock the user out when the device cannot authenticate',
      () async {
        when(authenticator.isAvailable()).thenAnswer((_) async => false);

        expect(await build().confirm(reason: 'r'), isTrue);
        verifyNever(authenticator.authenticate(reason: anyNamed('reason')));
      },
    );

    test('reads the enabled flag on every call', () async {
      when(
        authenticator.authenticate(reason: 'r'),
      ).thenAnswer((_) async => false);
      final guard = build();

      expect(await guard.confirm(reason: 'r'), isFalse);
      enabled = false;
      expect(await guard.confirm(reason: 'r'), isTrue);
    });
  });
}
