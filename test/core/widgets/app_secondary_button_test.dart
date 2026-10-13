import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppSecondaryButton', () {
    testWidgets('shows the label and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppSecondaryButton(label: 'Skip', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Skip'));

      expect(taps, 1);
    });

    testWidgets('is an outlined pill, not a filled button', (tester) async {
      await tester.pumpWidget(
        wrap(AppSecondaryButton(label: 'Skip', onPressed: () {})),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      final themed = AppTheme.light().outlinedButtonTheme.style;
      expect(themed?.shape?.resolve({}), isA<StadiumBorder>());
    });

    testWidgets('shows progress and ignores taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          AppSecondaryButton(
            label: 'Skip',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('is disabled without a callback', (tester) async {
      await tester.pumpWidget(
        wrap(const AppSecondaryButton(label: 'Skip', onPressed: null)),
      );

      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
        isFalse,
      );
    });

    testWidgets('keeps its label for screen readers while loading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          AppSecondaryButton(label: 'Skip', isLoading: true, onPressed: () {}),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppSecondaryButton)),
        matchesSemantics(label: 'Skip', isButton: true, hasEnabledState: true),
      );
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(
        wrap(AppSecondaryButton(label: 'Skip', onPressed: () {})),
      );

      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(const AppSpacing().minTouchTarget),
      );
    });
  });
}
