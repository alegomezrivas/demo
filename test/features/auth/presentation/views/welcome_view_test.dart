import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/views/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'sign_up_harness.dart';

void main() {
  late SignUpHarness harness;

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  group('WelcomeView', () {
    testWidgets('shows the pitch, the illustration and both actions', (
      tester,
    ) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
      expect(find.textContaining('Crea una cuenta en unos pasos'), findsOne);
      expect(find.text('Empezar'), findsOneWidget);
      expect(find.text('Ya tengo cuenta'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ilustración de tareas completadas'),
        findsOneWidget,
      );
    });

    testWidgets('has no back arrow: it is the first screen', (tester) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('"Empezar" starts the sign-up at the e-mail step', (
      tester,
    ) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      await tester.tap(find.text('Empezar'));
      await tester.pump();

      verify(harness.navigation.push<void>(AppRoutes.signUpEmail)).called(1);
      expect(harness.progress.furthest, SignUpStep.email);
    });

    testWidgets('starting forgets a previous attempt', (tester) async {
      usePhone(tester);
      harness.progress.unlock(SignUpStep.terms);
      await harness.pump(tester, const WelcomeView());

      await tester.tap(find.text('Empezar'));
      await tester.pump();

      expect(harness.progress.furthest, SignUpStep.email);
    });

    testWidgets('"Ya tengo cuenta" opens the sign-in screen', (tester) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      await tester.tap(find.text('Ya tengo cuenta'));
      await tester.pump();

      verify(harness.navigation.go(AppRoutes.login)).called(1);
    });

    testWidgets('is available in English', (tester) async {
      usePhone(tester);
      await harness.pump(
        tester,
        const WelcomeView(),
        locale: const Locale('en'),
      );

      expect(find.text('Organize your tasks, noise-free'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });

    testWidgets('both actions are pills of at least 48 dp', (tester) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      for (final type in [FilledButton, OutlinedButton]) {
        expect(
          tester.getSize(find.byType(type)).height,
          greaterThanOrEqualTo(48),
        );
      }
    });

    testWidgets('keeps the actions pinned to the bottom', (tester) async {
      usePhone(tester);
      await harness.pump(tester, const WelcomeView());

      final bottom = tester.getBottomLeft(find.byType(OutlinedButton)).dy;

      expect(bottom, greaterThan(700));
    });

    testWidgets('is announced with a header and labelled buttons', (
      tester,
    ) async {
      usePhone(tester);
      final handle = tester.ensureSemantics();
      await harness.pump(tester, const WelcomeView());

      expect(
        tester.getSemantics(find.text('Organiza tus tareas, sin ruido')),
        matchesSemantics(
          isHeader: true,
          label: 'Organiza tus tareas, sin ruido',
        ),
      );
      expect(
        find.bySemanticsLabel('Empezar'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
