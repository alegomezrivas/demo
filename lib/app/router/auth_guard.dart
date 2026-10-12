import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route guard: private screens need a session, auth screens need none.
class AuthGuard {
  /// Creates the guard around the [_session] state.
  const AuthGuard(this._session);

  static const Set<String> _publicRoutes = {
    AppRoutes.login,
    AppRoutes.register,
  };

  final SessionService _session;

  /// Redirect callback for `GoRouter`.
  String? redirect(BuildContext context, GoRouterState state) {
    final isPublic = _publicRoutes.contains(state.matchedLocation);
    if (!_session.isAuthenticated && !isPublic) return AppRoutes.login;
    if (_session.isAuthenticated && isPublic) return AppRoutes.home;
    return null;
  }
}
