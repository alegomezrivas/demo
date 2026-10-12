/// Biometric / device-credential confirmation for sensitive actions.
abstract interface class BiometricAuthenticator {
  /// Whether the device can authenticate the user.
  Future<bool> isAvailable();

  /// Prompts the user; returns true only on success. Never throws.
  Future<bool> authenticate({required String reason});
}
