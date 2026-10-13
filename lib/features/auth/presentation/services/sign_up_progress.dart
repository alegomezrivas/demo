import 'package:demo/features/auth/presentation/models/sign_up_step.dart';

/// Remembers how far the person got in the sign-up, so the route guard can
/// refuse deep links and back-stack tricks that would skip a step.
class SignUpProgress {
  SignUpStep? _furthest;
  SignUpStep _earliest = SignUpStep.email;

  /// The furthest step unlocked so far, or null before the flow starts.
  SignUpStep? get furthest => _furthest;

  /// Whether the flow was started.
  bool get hasStarted => _furthest != null;

  /// Path to resume at, or null before the flow starts.
  String? get resumeRoute => _furthest?.route;

  /// Whether [step] can be shown now.
  ///
  /// Steps after the furthest one are locked; once the account exists the
  /// steps before the picture are locked too (they would create it twice).
  bool canEnter(SignUpStep step) {
    final furthest = _furthest;
    if (furthest == null) return false;
    return step.index <= furthest.index && step.index >= _earliest.index;
  }

  /// Unlocks [step]; never moves backwards.
  void unlock(SignUpStep step) {
    final furthest = _furthest;
    if (furthest == null || step.index > furthest.index) _furthest = step;
  }

  /// Locks everything after [step], for example when the e-mail changes and
  /// the old confirmation no longer applies.
  // It is an action with a rule, not a plain property write.
  // ignore: use_setters_to_change_properties
  void rewindTo(SignUpStep step) {
    _furthest = step;
  }

  /// Locks the steps that create the account once it exists.
  void lockBeforeAvatar() {
    _earliest = SignUpStep.avatar;
  }

  /// Forgets everything (flow finished, abandoned or restarted).
  void clear() {
    _furthest = null;
    _earliest = SignUpStep.email;
  }
}
