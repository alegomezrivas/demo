import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppPrimaryButton', () {
    testWidgets('shows the label and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppPrimaryButton(label: 'Go', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Go'));

      expect(taps, 1);
    });

    testWidgets('shows a progress indicator and ignores taps when loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          AppPrimaryButton(
            label: 'Go',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);
      expect(taps, 0);
    });

    testWidgets('is disabled without a callback', (tester) async {
      await tester.pumpWidget(
        wrap(const AppPrimaryButton(label: 'Go', onPressed: null)),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));

      expect(button.onPressed, isNull);
    });
  });
}
