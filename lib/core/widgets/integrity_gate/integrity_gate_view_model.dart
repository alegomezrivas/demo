import 'package:demo/core/security/device_integrity_service.dart';
import 'package:stacked/stacked.dart';

/// Holds the result of the device integrity check for the whole app.
class IntegrityGateViewModel extends BaseViewModel {
  /// Creates the ViewModel around the integrity [_service].
  IntegrityGateViewModel(this._service);

  final DeviceIntegrityService _service;

  IntegrityDecision _decision = IntegrityDecision.allow;
  bool _checked = false;
  bool _warningDismissed = false;

  /// Whether the check already finished.
  bool get isChecked => _checked;

  /// Whether the app must not run.
  bool get isBlocked => _decision == IntegrityDecision.block;

  /// Whether the (dismissible) warning must be visible.
  bool get showWarning =>
      _decision == IntegrityDecision.warn && !_warningDismissed;

  /// Runs the check once.
  Future<void> initialise() async {
    _decision = await _service.evaluate();
    _checked = true;
    notifyListeners();
  }

  /// Hides the warning for the rest of the session.
  void dismissWarning() {
    _warningDismissed = true;
    notifyListeners();
  }
}
