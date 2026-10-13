import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late SessionService session;
  late GoRouter router;

  Widget page(String name) => Scaffold(body: Text(name));

  setUp(() {
    session = SessionService();
    router = GoRouter(
      redirect: AuthGuard(session).redirect,
      refreshListenable: session,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => page('home')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => page('login')),
        GoRoute(path: AppRoutes.about, builder: (_, _) => page('about')),
      ],
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  group('AuthGuard', () {
    testWidgets('sends signed-out users to login from private routes', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('login'), findsOneWidget);

      router.go(AppRoutes.about);
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('moves to home as soon as the session starts', (tester) async {
      await pumpApp(tester);

      session.markSignedIn();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('keeps signed-in users away from the auth screens', (
      tester,
    ) async {
      session.markSignedIn();
      await pumpApp(tester);

      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      router.go(AppRoutes.about);
      await tester.pumpAndSettle();
      expect(find.text('about'), findsOneWidget);
    });

    testWidgets('returns to login when the session ends', (tester) async {
      session.markSignedIn();
      await pumpApp(tester);

      session.markSignedOut();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });
  });
}
