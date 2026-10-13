import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late SessionService session;
  late SignUpProgress progress;
  late GoRouter router;

  Widget page(String name) => Scaffold(body: Text(name));

  GoRouter buildRouter({String signedOut = AppRoutes.welcome}) {
    return GoRouter(
      redirect: AuthGuard(
        session,
        signUpProgress: progress,
        signedOutLocation: signedOut,
      ).redirect,
      refreshListenable: session,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => page('home')),
        GoRoute(path: AppRoutes.welcome, builder: (_, _) => page('welcome')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => page('login')),
        GoRoute(path: AppRoutes.terms, builder: (_, _) => page('terms-text')),
        GoRoute(path: AppRoutes.about, builder: (_, _) => page('about')),
        for (final step in SignUpStep.values)
          GoRoute(path: step.route, builder: (_, _) => page(step.name)),
      ],
    );
  }

  setUp(() {
    session = SessionService();
    progress = SignUpProgress();
    router = buildRouter();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  Future<void> goTo(WidgetTester tester, String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  group('signed-out destination', () {
    testWidgets('sends private routes to the configured location', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('welcome'), findsOneWidget);
      await goTo(tester, AppRoutes.about);
      expect(find.text('welcome'), findsOneWidget);
    });

    testWidgets('can still send them to login', (tester) async {
      router = buildRouter(signedOut: AppRoutes.login);
      await pumpApp(tester);

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('welcome and login are public', (tester) async {
      await pumpApp(tester);

      await goTo(tester, AppRoutes.login);
      expect(find.text('login'), findsOneWidget);
      await goTo(tester, AppRoutes.welcome);
      expect(find.text('welcome'), findsOneWidget);
    });
  });

  group('sign-up steps', () {
    testWidgets('cannot be opened before the flow starts', (tester) async {
      await pumpApp(tester);

      for (final step in SignUpStep.values) {
        await goTo(tester, step.route);
        expect(find.text('welcome'), findsOneWidget, reason: '$step');
      }
    });

    testWidgets('open up to the furthest unlocked step', (tester) async {
      progress
        ..unlock(SignUpStep.email)
        ..unlock(SignUpStep.code);
      await pumpApp(tester);

      await goTo(tester, SignUpStep.email.route);
      expect(find.text('email'), findsOneWidget);
      await goTo(tester, SignUpStep.code.route);
      expect(find.text('code'), findsOneWidget);
    });

    testWidgets('a locked step resumes at the furthest unlocked one', (
      tester,
    ) async {
      progress
        ..unlock(SignUpStep.email)
        ..unlock(SignUpStep.code);
      await pumpApp(tester);

      await goTo(tester, SignUpStep.terms.route);

      expect(find.text('code'), findsOneWidget);
    });

    testWidgets('skipping straight to the end is refused', (tester) async {
      progress.unlock(SignUpStep.email);
      await pumpApp(tester);

      await goTo(tester, SignUpStep.done.route);

      expect(find.text('email'), findsOneWidget);
    });

    testWidgets('once the account exists the earlier steps are closed', (
      tester,
    ) async {
      progress
        ..unlock(SignUpStep.avatar)
        ..lockBeforeAvatar();
      await pumpApp(tester);

      await goTo(tester, SignUpStep.terms.route);
      expect(find.text('avatar'), findsOneWidget);
      await goTo(tester, SignUpStep.email.route);
      expect(find.text('avatar'), findsOneWidget);
    });

    testWidgets('the picture and final steps work while still signed out', (
      tester,
    ) async {
      progress
        ..unlock(SignUpStep.done)
        ..lockBeforeAvatar();
      await pumpApp(tester);

      await goTo(tester, SignUpStep.done.route);

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('signed-in people are sent home from every step', (
      tester,
    ) async {
      progress.unlock(SignUpStep.done);
      session.markSignedIn();
      await pumpApp(tester);

      for (final step in SignUpStep.values) {
        await goTo(tester, step.route);
        expect(find.text('home'), findsOneWidget, reason: '$step');
      }
    });
  });

  group('terms text', () {
    testWidgets('is readable signed out', (tester) async {
      await pumpApp(tester);

      await goTo(tester, AppRoutes.terms);

      expect(find.text('terms-text'), findsOneWidget);
    });

    testWidgets('is readable signed in', (tester) async {
      session.markSignedIn();
      await pumpApp(tester);

      await goTo(tester, AppRoutes.terms);

      expect(find.text('terms-text'), findsOneWidget);
    });
  });

  group('without a progress tracker', () {
    testWidgets('step routes are ordinary public routes', (tester) async {
      router = GoRouter(
        redirect: AuthGuard(session).redirect,
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, _) => page('login')),
          GoRoute(path: AppRoutes.home, builder: (_, _) => page('home')),
          GoRoute(
            path: AppRoutes.signUpCode,
            builder: (_, _) => page('code'),
          ),
        ],
      );
      await pumpApp(tester);

      await goTo(tester, AppRoutes.signUpCode);

      expect(find.text('code'), findsOneWidget);
    });
  });
}
