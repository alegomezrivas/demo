import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/presentation/views/sign_up_username_view.dart';
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

  Finder field() => find.widgetWithText(TextField, 'Nombre de usuario');

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    // Started here so its timers belong to the test's fake clock.
    harness.flow.start();
    clearInteractions(harness.navigation);
    await harness.pump(
      tester,
      const SignUpUsernameView(),
      locale: locale,
      dark: dark,
    );
  }

  /// Types [text] and lets the debounce and the check finish.
  Future<void> typeAndCheck(WidgetTester tester, String text) async {
    await tester.enterText(field(), text);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  group('SignUpUsernameView', () {
    testWidgets('explains that it is a public handle', (tester) async {
      await pumpView(tester);

      expect(find.text('Elige un nombre de usuario'), findsOneWidget);
      expect(find.text('Será tu identificador público.'), findsOneWidget);
      expect(find.byKey(const Key('username_status')), findsNothing);
    });

    testWidgets('a free username shows the check and the confirmation', (
      tester,
    ) async {
      await pumpView(tester);

      await typeAndCheck(tester, 'Lucia');

      expect(find.text('lucia está disponible'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      verify(harness.checkUsername('Lucia')).called(1);
    });

    testWidgets('a taken username is reported as an error', (tester) async {
      when(harness.checkUsername(any)).thenAnswer((_) async => right(false));
      await pumpView(tester);

      await typeAndCheck(tester, 'demo');

      expect(find.text('Ese nombre de usuario ya está en uso'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows that it is checking while it waits', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'lucia');
      await tester.pump();

      expect(find.text('Comprobando disponibilidad…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('malformed text explains the rule without asking the server', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.enterText(field(), 'a');
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text(
          'Usa de 3 a 30 letras, números, puntos o guiones bajos, sin punto al inicio ni al final',
        ),
        findsOneWidget,
      );
      verifyZeroInteractions(harness.checkUsername);
    });

    testWidgets('spaces cannot be typed', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'lu cia');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: field(), matching: find.byType(EditableText)),
            )
            .controller
            .text,
        'lucia',
      );
    });

    testWidgets('an unknown result lets the person continue', (tester) async {
      when(
        harness.checkUsername(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await typeAndCheck(tester, 'lucia');
      expect(
        find.text('No pudimos comprobarlo ahora. Puedes continuar.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verify(harness.navigation.push<void>(AppRoutes.signUpTerms)).called(1);
    });

    testWidgets('a free username opens the terms step', (tester) async {
      await pumpView(tester);

      await typeAndCheck(tester, 'lucia');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verify(harness.navigation.push<void>(AppRoutes.signUpTerms)).called(1);
    });

    testWidgets('a taken username does not advance', (tester) async {
      when(harness.checkUsername(any)).thenAnswer((_) async => right(false));
      await pumpView(tester);

      await typeAndCheck(tester, 'demo');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verifyNever(harness.navigation.push<void>(AppRoutes.signUpTerms));
    });

    testWidgets('an empty field is required', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsOneWidget);
    });

    testWidgets('the live status is announced to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester);
      await typeAndCheck(tester, 'lucia');

      final node = tester.getSemantics(
        find.byKey(const Key('username_status')),
      );

      expect(node.label, 'lucia está disponible');
      handle.dispose();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      await tester.enterText(
        find.widgetWithText(TextField, 'Username'),
        'lucia',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.text('lucia is available'), findsOneWidget);
    });
  });
}
