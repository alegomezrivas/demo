import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route guard: private screens need a session, auth screens need none, and
/// the sign-up steps can only be reached in order.
class AuthGuard {
  /// Creates the guard around the [_session] state.
  ///
  /// [signUpProgress] enables the step check; [signedOutLocation] is where
  /// people without a session land when they ask for a private screen.
  const AuthGuard(
    this._session, {
    SignUpProgress? signUpProgress,
    this.signedOutLocation = AppRoutes.login,
  }) : _progress = signUpProgress;

  static const Set<String> _publicRoutes = {
    AppRoutes.welcome,
    AppRoutes.login,
    AppRoutes.signUpEmail,
    AppRoutes.signUpCode,
    AppRoutes.signUpPassword,
    AppRoutes.signUpName,
    AppRoutes.signUpUsername,
    AppRoutes.signUpTerms,
    AppRoutes.signUpAvatar,
    AppRoutes.signUpDone,
  };

  final SessionService _session;
  final SignUpProgress? _progress;

  /// Where signed-out people are sent from private screens.
  final String signedOutLocation;

  /// Redirect callback for `GoRouter`.
  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    // Readable by everybody, signed in or not.
    if (location == AppRoutes.terms) return null;
    final isPublic = _publicRoutes.contains(location);
    if (!_session.isAuthenticated && !isPublic) return signedOutLocation;
    if (_session.isAuthenticated && isPublic) return AppRoutes.home;
    return _stepRedirect(location);
  }

  /// Sends people back to the furthest step they unlocked (or to the start)
  /// when they ask for one they have not reached.
  String? _stepRedirect(String location) {
    final progress = _progress;
    final step = SignUpStep.fromLocation(location);
    if (progress == null || step == null || progress.canEnter(step)) {
      return null;
    }
    return progress.resumeRoute ?? signedOutLocation;
  }
}
