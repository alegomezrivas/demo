import 'package:demo/core/security/local_auth_biometric_authenticator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockLocalAuthentication auth;
  late LocalAuthBiometricAuthenticator authenticator;

  setUp(() {
    auth = MockLocalAuthentication();
    authenticator = LocalAuthBiometricAuthenticator(auth);
  });

  group('isAvailable', () {
    test('mirrors device support', () async {
      when(auth.isDeviceSupported()).thenAnswer((_) async => true);

      expect(await authenticator.isAvailable(), isTrue);
    });

    test('is false when the platform call fails', () async {
      when(auth.isDeviceSupported()).thenThrow(PlatformException(code: 'x'));

      expect(await authenticator.isAvailable(), isFalse);
    });
  });

  group('authenticate', () {
    test('returns true when the user is authenticated', () async {
      when(auth.authenticate(localizedReason: 'Confirm'))
          .thenAnswer((_) async => true);

      expect(await authenticator.authenticate(reason: 'Confirm'), isTrue);
    });

    test('returns false when the user cancels', () async {
      when(auth.authenticate(localizedReason: 'Confirm'))
          .thenAnswer((_) async => false);

      expect(await authenticator.authenticate(reason: 'Confirm'), isFalse);
    });

    test('denies access instead of throwing on a local_auth error', () async {
      when(auth.authenticate(localizedReason: 'Confirm')).thenThrow(
        const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
      );

      expect(await authenticator.authenticate(reason: 'Confirm'), isFalse);
    });
  });
}
