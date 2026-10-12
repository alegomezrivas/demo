import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';

/// [DeviceIntegrityChecker] backed by the `jailbreak_root_detection` plugin.
class JailbreakRootIntegrityChecker implements DeviceIntegrityChecker {
  /// Creates the checker around a plugin detector.
  const JailbreakRootIntegrityChecker(this._detector);

  final JailbreakRootDetection _detector;

  @override
  Future<Set<IntegrityIssue>> check() async {
    try {
      return {
        if (await _detector.isJailBroken) IntegrityIssue.rootedOrJailbroken,
        if (await _detector.isDebugged) IntegrityIssue.debuggerAttached,
      };
    } on Exception {
      // Report the failure instead of hiding it: the policy decides whether an
      // unknown device state is acceptable (see DeviceIntegrityService).
      return {IntegrityIssue.checkFailed};
    }
  }
}
