import 'package:demo/core/security/biometric_authenticator.dart';

/// Asks for biometric / device-credential confirmation before sensitive
/// actions, when the user turned that protection on.
class SensitiveActionGuard {
  /// Creates the guard; [_isEnabled] is read every time so changes apply at once.
  const SensitiveActionGuard({
    required BiometricAuthenticator authenticator,
    required bool Function() isEnabled,
  }) : _authenticator = authenticator,
       _isEnabled = isEnabled;

  final BiometricAuthenticator _authenticator;
  final bool Function() _isEnabled;

  /// Returns true when the action may proceed.
  ///
  /// * Protection off: always true.
  /// * Device cannot authenticate (no lock screen): true, since there is
  ///   nothing to ask and the user must not be locked out of their data.
  /// * Otherwise: true only if the user authenticates.
  Future<bool> confirm({required String reason}) async {
    if (!_isEnabled()) return true;
    if (!await _authenticator.isAvailable()) return true;
    return await _authenticator.authenticate(reason: reason);
  }
}
