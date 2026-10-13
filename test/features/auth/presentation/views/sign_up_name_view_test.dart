import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_name_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'sign_up_harness.dart';

void main() {
  late SignUpHarness harness;

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
    harness.flow.start();
    clearInteractions(harness.navigation);
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  Finder field() => find.widgetWithText(TextField, 'Nombre completo');

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await harness.pump(
      tester,
      const SignUpNameView(),
      locale: locale,
      dark: dark,
    );
  }

  group('SignUpNameView', () {
    testWidgets('asks for the name with a name keyboard and autofill', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      final input = tester.widget<EditableText>(
        find.descendant(of: field(), matching: find.byType(EditableText)),
      );
      expect(input.keyboardType, TextInputType.name);
      expect(input.textCapitalization, TextCapitalization.words);
      expect(input.autofillHints, contains(AutofillHints.name));
    });

    testWidgets('a blank name is required', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), '   ');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsOneWidget);
      verifyNever(harness.navigation.push<void>(AppRoutes.signUpUsername));
    });

    testWidgets('a name over 100 characters is rejected', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'n' * 101);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('No puede superar 100 caracteres'), findsOneWidget);
    });

    testWidgets('a valid name opens the username step', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'Lucía Gómez');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(
        SignUpForms.textOf(harness.flow.forms.name, SignUpForms.nameField),
        'Lucía Gómez',
      );
      verify(harness.navigation.push<void>(AppRoutes.signUpUsername)).called(1);
    });

    testWidgets('the field can be cleared with the X', (tester) async {
      await pumpView(tester);
      await tester.enterText(field(), 'Lucía');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(
        SignUpForms.textOf(harness.flow.forms.name, SignUpForms.nameField),
        isEmpty,
      );
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text("What's your name?"), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);
    });
  });
}
