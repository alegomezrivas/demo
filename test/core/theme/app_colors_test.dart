import 'dart:ui';

import 'package:demo/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/contrast.dart';

void main() {
  group('AppColors', () {
    test('copyWith overrides only the given field', () {
      const override = Color(0xFF123456);

      final copy = AppColors.light.copyWith(primary: override);

      expect(copy.primary, override);
      expect(copy.secondary, AppColors.light.secondary);
    });

    test('lerp returns the endpoints at t = 0 and t = 1', () {
      expect(AppColors.light.lerp(AppColors.dark, 0), AppColors.light);
      expect(
        AppColors.light.lerp(AppColors.dark, 1).primary,
        AppColors.dark.primary,
      );
    });

    test('lerp returns itself when the other extension has another type', () {
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });

    test('light and dark palettes differ', () {
      expect(AppColors.light.background, isNot(AppColors.dark.background));
    });
  });

  group('AppColors surfaceMuted', () {
    test('differs from the surface in both palettes', () {
      expect(AppColors.light.surfaceMuted, isNot(AppColors.light.surface));
      expect(AppColors.dark.surfaceMuted, isNot(AppColors.dark.surface));
    });

    test('takes part in copyWith, equality and lerp', () {
      const override = Color(0xFF010203);

      final copy = AppColors.light.copyWith(surfaceMuted: override);

      expect(copy.surfaceMuted, override);
      expect(copy, isNot(AppColors.light));
      expect(copy.hashCode, isNot(AppColors.light.hashCode));
      expect(
        AppColors.light.lerp(AppColors.dark, 1).surfaceMuted,
        AppColors.dark.surfaceMuted,
      );
    });
  });

  group('AppColors contrast (WCAG AA for text, 4.5:1)', () {
    for (final entry in {
      'light': AppColors.light,
      'dark': AppColors.dark,
    }.entries) {
      final c = entry.value;
      final pairs = <String, (Color, Color)>{
        'primary text on background': (c.textPrimary, c.background),
        'primary text on surface': (c.textPrimary, c.surface),
        'secondary text on background': (c.textSecondary, c.background),
        'secondary text on surface': (c.textSecondary, c.surface),
        'secondary text on muted surface': (c.textSecondary, c.surfaceMuted),
        'primary text on muted surface': (c.textPrimary, c.surfaceMuted),
        'label on primary button': (c.onPrimary, c.primary),
        'link / accent on surface': (c.primary, c.surface),
        'error text on surface': (c.error, c.surface),
        'error text on background': (c.error, c.background),
        'label on error': (c.onError, c.error),
      };
      for (final pair in pairs.entries) {
        test('${entry.key}: ${pair.key}', () {
          expect(
            contrastRatio(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test(
        '${entry.key}: the valid check stands out from the surface (3:1)',
        () {
          expect(contrastRatio(c.success, c.surface), greaterThanOrEqualTo(3));
        },
      );
    }
  });
}
