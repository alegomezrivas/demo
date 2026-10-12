/// Problems that make a device untrustworthy.
enum IntegrityIssue {
  /// Rooted (Android) or jailbroken (iOS) device.
  rootedOrJailbroken,

  /// A debugger is attached to the process.
  debuggerAttached,
}

/// Detects whether the device was tampered with.
abstract interface class DeviceIntegrityChecker {
  /// Returns the detected issues; empty when the device looks healthy.
  Future<Set<IntegrityIssue>> check();
}
