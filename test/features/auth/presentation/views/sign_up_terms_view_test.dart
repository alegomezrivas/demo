import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_terms_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

  /// Gets the flow to the terms step with everything collected.
  Future<void> reachTerms() async {
    final flow = harness.flow..start();
    flow.forms.email.control(SignUpForms.emailField).value = 'lucia@test.com';
    await flow.submitEmail();
    flow.forms.code.control(SignUpForms.codeField).value = '123456';
    await flow.submitCode();
    flow.forms.password.control(SignUpForms.passwordField).value =
        'Str0ng!Pass';
    flow.submitPassword();
    flow.forms.name.control(SignUpForms.nameField).value = 'Lucía Gómez';
    flow.submitName();
    flow.forms.username.control(SignUpForms.usernameField).value = 'lucia';
    await flow.submitUsername();
    clearInteractions(harness.navigation);
  }

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await reachTerms();
    await harness.pump(
      tester,
      const SignUpTermsView(),
      locale: locale,
      dark: dark,
    );
  }

  group('SignUpTermsView', () {
    testWidgets('explains what accepting means', (tester) async {
      await pumpView(tester);

      expect(find.text('Acepta los términos y políticas'), findsOneWidget);
      expect(find.textContaining('Al crear tu cuenta aceptas'), findsOneWidget);
      expect(find.text('Acepto'), findsOneWidget);
      expect(find.text('Leer los términos y políticas'), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('accepting creates the account and opens the picture step', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.text('Acepto'));
      await tester.pumpAndSettle();

      verify(harness.completeSignUp(any)).called(1);
      verify(harness.navigation.go(AppRoutes.signUpAvatar)).called(1);
      harness.flow.reset();
    });

    testWidgets('shows a spinner while the account is created', (tester) async {
      await pumpView(tester);
      final pending = Completer<Either<Failure, User>>();
      when(harness.completeSignUp(any)).thenAnswer((_) => pending.future);

      await tester.tap(find.text('Acepto'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(right(SignUpHarness.user));
      await tester.pumpAndSettle();
      harness.flow.reset();
    });

    testWidgets('a connection failure is shown and can be retried', (
      tester,
    ) async {
      when(
        harness.completeSignUp(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await tester.tap(find.text('Acepto'));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );
      verifyNever(harness.navigation.go(AppRoutes.signUpAvatar));
      harness.flow.reset();
    });

    testWidgets('"Leer" opens the full text', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Leer los términos y políticas'));
      await tester.pump();

      verify(harness.navigation.push<void>(AppRoutes.terms)).called(1);
      harness.flow.reset();
    });

    testWidgets('the arrow goes back to the username', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      verify(harness.navigation.pop<Object?>()).called(1);
      harness.flow.reset();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text('Accept the terms and policies'), findsOneWidget);
      expect(find.text('I agree'), findsOneWidget);
      harness.flow.reset();
    });
  });
}
