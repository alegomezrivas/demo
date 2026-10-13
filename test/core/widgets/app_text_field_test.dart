import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../helpers/form_host.dart';

void main() {
  const field = 'field';

  FormGroup form({String? value, List<Validator<dynamic>>? validators}) {
    return FormGroup({
      field: FormControl<String>(value: value, validators: validators ?? []),
    });
  }

  AppTextField textField({
    bool showClearButton = false,
    bool showValidIndicator = false,
    Widget? suffixIcon,
    String? helperText,
    int? maxLength,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    Map<String, ValidationMessageFunction>? messages,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AppTextField(
      formControlName: field,
      label: 'Correo',
      showClearButton: showClearButton,
      showValidIndicator: showValidIndicator,
      suffixIcon: suffixIcon,
      helperText: helperText,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged,
      validationMessages: messages,
      inputFormatters: inputFormatters,
    );
  }

  TextField inner(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  group('AppTextField basics', () {
    testWidgets('shows the label and the helper text', (tester) async {
      await pumpForm(tester, form(), textField(helperText: 'Te escribiremos'));

      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Te escribiremos'), findsOneWidget);
    });

    testWidgets('writes typed text to the control and reports changes', (
      tester,
    ) async {
      final group = form();
      final changes = <String>[];
      await pumpForm(tester, group, textField(onChanged: changes.add));

      await tester.enterText(find.byType(TextField), 'ana');

      expect(group.control(field).value, 'ana');
      expect(changes, ['ana']);
    });

    testWidgets('shows the validation message of an invalid touched control', (
      tester,
    ) async {
      final group = form(validators: [AppValidators.required]);
      await pumpForm(
        tester,
        group,
        textField(messages: {'required': (_) => 'Obligatorio'}),
      );

      group.control(field).markAsTouched();
      await tester.pump();

      expect(find.text('Obligatorio'), findsOneWidget);
    });

    testWidgets('hides the typed text when obscured', (tester) async {
      await pumpForm(tester, form(), textField(obscureText: true));

      expect(inner(tester).obscureText, isTrue);
    });

    testWidgets('limits the length without showing a counter', (tester) async {
      final group = form();
      await pumpForm(tester, group, textField(maxLength: 5));

      await tester.enterText(find.byType(TextField), '1234567890');

      expect(group.control(field).value, '12345');
      expect(find.text('5/5'), findsNothing);
    });

    testWidgets('applies input formatters', (tester) async {
      final group = form();
      await pumpForm(
        tester,
        group,
        textField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      );

      await tester.enterText(find.byType(TextField), 'a1b2');

      expect(group.control(field).value, '12');
    });

    testWidgets('a custom suffix wins over the clear button', (tester) async {
      await pumpForm(
        tester,
        form(value: 'ana'),
        textField(
          showClearButton: true,
          suffixIcon: const Icon(Icons.visibility_outlined),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('AppTextField clear button', () {
    testWidgets('appears only while focused with text', (tester) async {
      await pumpForm(
        tester,
        form(value: 'ana'),
        textField(showClearButton: true),
      );
      expect(find.byIcon(Icons.close), findsNothing, reason: 'not focused');

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('is hidden for an empty field', (tester) async {
      await pumpForm(tester, form(), textField(showClearButton: true));

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('is not offered unless requested', (tester) async {
      await pumpForm(tester, form(value: 'ana'), textField());

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('clears the text, keeps the focus and disappears', (
      tester,
    ) async {
      final group = form(value: 'ana');
      await pumpForm(tester, group, textField(showClearButton: true));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(group.control(field).value, '');
      expect(inner(tester).focusNode?.hasFocus, isTrue);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('has a localized tooltip and a 48 dp target', (tester) async {
      await pumpForm(
        tester,
        form(value: 'ana'),
        textField(showClearButton: true),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.byTooltip('Borrar'), findsOneWidget);
      final size = tester.getSize(find.byTooltip('Borrar'));
      expect(
        size.shortestSide,
        greaterThanOrEqualTo(const AppSpacing().minTouchTarget),
      );
    });

    testWidgets('is not offered for a disabled control', (tester) async {
      final group = form(value: 'ana');
      await pumpForm(tester, group, textField(showClearButton: true));
      group.control(field).markAsDisabled();
      await tester.pump();

      expect(inner(tester).enabled, isFalse);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('AppTextField valid indicator', () {
    testWidgets('shows a check for a valid value', (tester) async {
      await pumpForm(
        tester,
        form(value: 'ana', validators: [AppValidators.required]),
        textField(showValidIndicator: true),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('is announced to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpForm(
        tester,
        form(value: 'ana'),
        textField(showValidIndicator: true),
      );

      expect(find.bySemanticsLabel('Válido'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is hidden for empty and invalid values', (tester) async {
      final group = form(validators: [AppValidators.email]);
      await pumpForm(tester, group, textField(showValidIndicator: true));
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      group.control(field).value = 'no-email';
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      group.control(field).value = 'ana@test.com';
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('is hidden while a check is pending', (tester) async {
      final group = form(value: 'ana');
      await pumpForm(tester, group, textField(showValidIndicator: true));

      group.control(field).markAsPending();
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('is not shown unless requested', (tester) async {
      await pumpForm(tester, form(value: 'ana'), textField());

      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });
  });

  group('AppTextField disabled look', () {
    testWidgets('a disabled control cannot be edited', (tester) async {
      final group = form(value: 'ana');
      await pumpForm(tester, group, textField());

      group.control(field).markAsDisabled();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'otro');

      expect(inner(tester).enabled, isFalse);
      expect(group.control(field).value, 'ana');
    });
  });
}
