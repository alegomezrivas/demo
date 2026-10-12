import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:local_auth/local_auth.dart';

/// [BiometricAuthenticator] backed by `local_auth`.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  /// Creates the authenticator around [_auth].
  const LocalAuthBiometricAuthenticator(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on Exception {
      // Any failure (cancelled, locked out, unsupported) denies access.
      return false;
    }
  }
}
