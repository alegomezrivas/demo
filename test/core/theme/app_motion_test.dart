import 'package:demo/core/theme/app_motion.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotion', () {
    test('durations grow from fast to slow', () {
      const m = AppMotion();

      expect(m.fast, lessThan(m.normal));
      expect(m.normal, lessThan(m.slow));
    });

    test('copyWith overrides only the given field', () {
      final copy = const AppMotion().copyWith(
        fast: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );

      expect(copy.fast, const Duration(milliseconds: 1));
      expect(copy.curve, Curves.linear);
      expect(copy.normal, const AppMotion().normal);
      expect(copy.slow, const AppMotion().slow);
    });

    test('copyWith can override every field', () {
      final copy = const AppMotion().copyWith(
        normal: const Duration(milliseconds: 2),
        slow: const Duration(milliseconds: 3),
      );

      expect(copy.normal, const Duration(milliseconds: 2));
      expect(copy.slow, const Duration(milliseconds: 3));
    });

    test('lerp switches at the midpoint', () {
      const a = AppMotion();
      final b = a.copyWith(fast: const Duration(seconds: 9));

      expect(a.lerp(b, 0.2).fast, a.fast);
      expect(a.lerp(b, 0.8).fast, const Duration(seconds: 9));
      expect(a.lerp(null, 0.8), a);
    });
  });

  group('AppMotion in the theme', () {
    test('both themes register it', () {
      expect(AppTheme.light().extension<AppMotion>(), isNotNull);
      expect(AppTheme.dark().extension<AppMotion>(), isNotNull);
    });

    testWidgets('context.motion resolves the active theme', (tester) async {
      late AppMotion motion;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              motion = context.motion;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(motion.normal, const AppMotion().normal);
    });

    testWidgets('context.motion falls back to defaults without a theme', (
      tester,
    ) async {
      late AppMotion motion;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              motion = context.motion;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(motion.fast, const AppMotion().fast);
    });

    testWidgets('durations collapse to zero when animations are disabled', (
      tester,
    ) async {
      late Duration normalMode;
      late Duration reducedMode;
      Widget probe({
        required bool disabled,
        required void Function(Duration) save,
      }) {
        return MediaQuery(
          data: MediaQueryData(disableAnimations: disabled),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) {
                save(context.motionDuration(context.motion.normal));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(
        probe(disabled: false, save: (d) => normalMode = d),
      );
      await tester.pumpWidget(
        probe(disabled: true, save: (d) => reducedMode = d),
      );

      expect(normalMode, const AppMotion().normal);
      expect(reducedMode, Duration.zero);
    });
  });
}
