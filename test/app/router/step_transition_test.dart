import 'dart:async';

import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/core/theme/app_motion.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/views/sign_up_harness.dart';
import '../../helpers/pump_app.dart';

void main() {
  late SignUpHarness harness;
  late GoRouter router;

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
    router = AppRouter.create(
      initialLocation: AppRoutes.welcome,
      redirect: AuthGuard(
        harness.session,
        signUpProgress: harness.progress,
      ).redirect,
      refreshListenable: harness.session,
    );
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: pumpLocalizedDelegates,
        supportedLocales: pumpLocalizedLocales,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
  }

  void openEmailStep() {
    harness.progress.unlock(SignUpStep.email);
    unawaited(router.push<void>(AppRoutes.signUpEmail));
  }

  group('step transition', () {
    testWidgets('the welcome screen is the signed-out start', (tester) async {
      await pumpRouter(tester);

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });

    testWidgets('slides and fades between steps', (tester) async {
      await pumpRouter(tester);

      openEmailStep();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.hasRunningAnimations, isTrue);
      expect(
        find.text('Organiza tus tareas, sin ruido', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('finishes within the normal motion duration', (tester) async {
      await pumpRouter(tester);

      openEmailStep();
      await tester.pump();
      const step = Duration(milliseconds: 16);
      final frames = await tester.pumpAndSettle(step);

      expect(step * frames, lessThanOrEqualTo(const AppMotion().normal * 2));
    });

    testWidgets('does not animate when the system reduces motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpRouter(tester);

      openEmailStep();
      await tester.pump();
      final frames = await tester.pumpAndSettle(
        const Duration(milliseconds: 16),
      );

      expect(frames, lessThanOrEqualTo(3));
      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
    });

    testWidgets('going back animates too', (tester) async {
      await pumpRouter(tester);
      openEmailStep();
      await tester.pumpAndSettle();

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });
  });
}
