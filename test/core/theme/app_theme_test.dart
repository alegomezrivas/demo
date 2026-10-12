import 'package:demo/core/theme/app_colors.dart';
import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme registers all token extensions', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>(), AppColors.light);
      expect(theme.extension<AppTextStyles>(), isNotNull);
      expect(theme.extension<AppSpacing>(), isNotNull);
      expect(theme.scaffoldBackgroundColor, AppColors.light.background);
    });

    test('dark theme uses the dark palette', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppColors>(), AppColors.dark);
      expect(theme.colorScheme.primary, AppColors.dark.primary);
    });
  });

  group('AppThemeContext', () {
    testWidgets('resolves tokens from the active theme', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.colors, AppColors.dark);
      expect(captured.text.body.fontFamily, AppTypography.fontFamily);
      expect(captured.spacing.md, const AppSpacing().md);
    });

    testWidgets('falls back to defaults without extensions', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.colors, AppColors.light);
      expect(captured.spacing.md, const AppSpacing().md);
      expect(captured.text.body.fontFamily, AppTypography.fontFamily);
    });
  });
}
