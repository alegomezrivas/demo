import 'package:demo/core/theme/app_colors.dart';
import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/widgets/otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../helpers/form_host.dart';

void main() {
  const control = 'code';

  FormGroup form() => FormGroup({control: FormControl<String>()});

  Future<void> pumpOtp(
    WidgetTester tester,
    FormGroup group, {
    bool autofocus = true,
    bool hasError = false,
    String? errorText,
    ValueChanged<String>? onCompleted,
  }) {
    return pumpForm(
      tester,
      group,
      Padding(
        padding: const EdgeInsets.all(16),
        child: OtpInput(
          formControlName: control,
          autofocus: autofocus,
          hasError: hasError,
          errorText: errorText,
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  List<BoxDecoration> boxes(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((box) => box.decoration! as BoxDecoration)
      .toList();

  double borderWidth(BoxDecoration box) => (box.border! as Border).top.width;

  Color borderColor(BoxDecoration box) => (box.border! as Border).top.color;

  group('OtpInput typing', () {
    testWidgets('draws one box per digit', (tester) async {
      await pumpOtp(tester, form());

      expect(boxes(tester), hasLength(6));
    });

    testWidgets('mirrors typed digits in the boxes', (tester) async {
      final group = form();
      await pumpOtp(tester, group);

      await tester.enterText(find.byType(EditableText), '482');
      await tester.pump();

      expect(group.control(control).value, '482');
      for (final digit in ['4', '8', '2']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('ignores everything that is not a digit', (tester) async {
      final group = form();
      await pumpOtp(tester, group);

      await tester.enterText(find.byType(EditableText), 'a1 b-2');

      expect(group.control(control).value, '12');
    });

    testWidgets('a pasted code with separators fills all boxes', (
      tester,
    ) async {
      final group = form();
      await pumpOtp(tester, group);

      await tester.enterText(find.byType(EditableText), '482-913');

      expect(group.control(control).value, '482913');
    });

    testWidgets('never accepts more digits than boxes', (tester) async {
      final group = form();
      await pumpOtp(tester, group);

      await tester.enterText(find.byType(EditableText), '12345678');

      expect(group.control(control).value, '123456');
    });

    testWidgets('reports completion once, with the full code', (tester) async {
      final completed = <String>[];
      await pumpOtp(tester, form(), onCompleted: completed.add);

      await tester.enterText(find.byType(EditableText), '12345');
      expect(completed, isEmpty);
      await tester.enterText(find.byType(EditableText), '123456');

      expect(completed, ['123456']);
    });

    testWidgets('asks for a numeric keyboard and one-time-code autofill', (
      tester,
    ) async {
      await pumpOtp(tester, form());

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.keyboardType, TextInputType.number);
      expect(editable.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(editable.autocorrect, isFalse);
    });
  });

  group('OtpInput focus and highlight', () {
    testWidgets('takes the focus on start when asked', (tester) async {
      await pumpOtp(tester, form());
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('does not steal the focus when autofocus is off', (
      tester,
    ) async {
      await pumpOtp(tester, form(), autofocus: false);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isFalse);
      expect(boxes(tester).map(borderWidth).toSet(), {
        const AppSpacing().borderThin,
      });
    });

    testWidgets('highlights the box that receives the next digit', (
      tester,
    ) async {
      await pumpOtp(tester, form());
      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump(const Duration(milliseconds: 300));

      final widths = boxes(tester).map(borderWidth).toList();
      const spacing = AppSpacing();
      expect(widths, [
        spacing.borderThin,
        spacing.borderThin,
        spacing.borderThick,
        spacing.borderThin,
        spacing.borderThin,
        spacing.borderThin,
      ]);
      expect(borderColor(boxes(tester)[2]), AppColors.light.primary);
    });

    testWidgets('keeps the last box active once the code is complete', (
      tester,
    ) async {
      await pumpOtp(tester, form());
      await tester.enterText(find.byType(EditableText), '123456');
      await tester.pump(const Duration(milliseconds: 300));

      final widths = boxes(tester).map(borderWidth).toList();
      expect(widths.last, const AppSpacing().borderThick);
      expect(
        widths.where((w) => w == const AppSpacing().borderThick),
        hasLength(1),
      );
    });
  });

  group('OtpInput error state', () {
    testWidgets('draws every box in the error color and shows the message', (
      tester,
    ) async {
      await pumpOtp(
        tester,
        form(),
        hasError: true,
        errorText: 'Código incorrecto',
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Código incorrecto'), findsOneWidget);
      expect(
        boxes(tester).map(borderColor).toSet(),
        {AppColors.light.error},
      );
    });

    testWidgets('shows no message by default', (tester) async {
      await pumpOtp(tester, form());

      expect(find.text('Código incorrecto'), findsNothing);
    });
  });

  group('OtpInput clipboard', () {
    void mockClipboard(WidgetTester tester, String? text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return text == null ? null : <String, dynamic>{'text': text};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('a long press pastes the digits of the clipboard', (
      tester,
    ) async {
      final group = form();
      final completed = <String>[];
      mockClipboard(tester, 'Tu código es 482 913');
      await pumpOtp(tester, group, onCompleted: completed.add);

      await tester.longPress(find.byType(OtpInput));
      await tester.pump();

      expect(group.control(control).value, '482913');
      expect(completed, ['482913']);
    });

    testWidgets('pastes at most the code length', (tester) async {
      final group = form();
      mockClipboard(tester, '1234567890');
      await pumpOtp(tester, group);

      await tester.longPress(find.byType(OtpInput));
      await tester.pump();

      expect(group.control(control).value, '123456');
    });

    testWidgets('ignores a clipboard without digits', (tester) async {
      final group = form();
      mockClipboard(tester, 'hola');
      await pumpOtp(tester, group);

      await tester.longPress(find.byType(OtpInput));
      await tester.pump();

      expect(group.control(control).value, isNull);
    });

    testWidgets('ignores an empty clipboard', (tester) async {
      final group = form();
      mockClipboard(tester, null);
      await pumpOtp(tester, group);

      await tester.longPress(find.byType(OtpInput));
      await tester.pump();

      expect(group.control(control).value, isNull);
    });
  });

  group('OtpInput accessibility', () {
    testWidgets('announces progress as one text field', (tester) async {
      final handle = tester.ensureSemantics();
      final group = form();
      await pumpOtp(tester, group);

      expect(
        find.bySemanticsLabel('Código de confirmación, 0 de 6 dígitos'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(EditableText), '123');
      await tester.pump();
      expect(
        find.bySemanticsLabel('Código de confirmación, 3 de 6 dígitos'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('boxes are at least 48 dp tall and fit a small phone', (
      tester,
    ) async {
      useViewSize(tester, const Size(320, 568));
      await pumpOtp(tester, form());

      expect(tester.takeException(), isNull);
      final box = tester.getSize(find.byType(AnimatedContainer).first);
      expect(box.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a disabled control cannot be edited', (tester) async {
      final group = form();
      await pumpOtp(tester, group);

      group.control(control).markAsDisabled();
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '123');

      expect(group.control(control).value, isNull);
    });
  });
}
