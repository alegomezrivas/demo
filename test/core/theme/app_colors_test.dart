import 'dart:ui';

import 'package:demo/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
