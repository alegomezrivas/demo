import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/app/session_bootstrap.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The router needs the session state before the locator exists.
  final session = SessionService();
  final router = AppRouter.create(
    redirect: AuthGuard(session).redirect,
    refreshListenable: session,
  );
  await setupLocator(
    router: router,
    session: session,
    mockRoutes: MockAuthBackend().routes,
  );

  session.attach(locator<SessionExpiredNotifier>().onExpired);
  await restoreSession(
    getCurrentUser: locator<GetCurrentUserUseCase>(),
    session: session,
  );

  runApp(
    App(
      routerConfig: locator<GoRouter>(),
      integrityViewModelBuilder: locator.call<IntegrityGateViewModel>,
    ),
  );
}
