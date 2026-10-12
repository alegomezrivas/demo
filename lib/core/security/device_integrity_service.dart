import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:demo/core/security/security_policy.dart';

/// What the app must do after checking the device.
enum IntegrityDecision {
  /// Device is healthy.
  allow,

  /// Show a warning and let the user continue.
  warn,

  /// Refuse to run.
  block,
}

/// Applies the configured [SecurityPolicy] to the detected issues.
class DeviceIntegrityService {
  /// Creates the service.
  const DeviceIntegrityService(this._checker, this._policy);

  final DeviceIntegrityChecker _checker;
  final SecurityPolicy _policy;

  /// Checks the device and returns the resulting decision.
  Future<IntegrityDecision> evaluate() async {
    final issues = await _checker.check();
    if (issues.isEmpty) return IntegrityDecision.allow;
    return switch (_policy) {
      // A failed check is not evidence of tampering, so it never warns.
      SecurityPolicy.warn when _onlyCheckFailed(issues) =>
        IntegrityDecision.allow,
      SecurityPolicy.warn => IntegrityDecision.warn,
      // Strict mode treats an unknown device state as untrusted.
      SecurityPolicy.block => IntegrityDecision.block,
    };
  }

  bool _onlyCheckFailed(Set<IntegrityIssue> issues) =>
      issues.length == 1 && issues.contains(IntegrityIssue.checkFailed);
}
