import 'package:demo/core/theme/app_colors.dart';
import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Builds the light and dark [ThemeData] from the design tokens.
abstract final class AppTheme {
  /// Light theme.
  static ThemeData light() =>
      _build(brightness: Brightness.light, colors: AppColors.light);

  /// Dark theme.
  static ThemeData dark() =>
      _build(brightness: Brightness.dark, colors: AppColors.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
  }) {
    const spacing = AppSpacing();
    final text = AppTypography.build(
      primary: colors.textPrimary,
      secondary: colors.textSecondary,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.toTextTheme(text),
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: spacing.elevationNone,
        titleTextStyle: text.title,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: spacing.elevationLow,
        shape: RoundedRectangleBorder(borderRadius: spacing.borderRadiusMd),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: text.label,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: spacing.borderRadiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: spacing.borderRadiusMd,
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, text, spacing],
    );
  }
}

/// Short accessors for the design tokens: `context.colors`, etc.
extension AppThemeContext on BuildContext {
  /// Color tokens of the active theme.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  /// Text style tokens of the active theme.
  AppTextStyles get text =>
      Theme.of(this).extension<AppTextStyles>() ??
      AppTypography.build(
        primary: AppColors.light.textPrimary,
        secondary: AppColors.light.textSecondary,
      );

  /// Spacing, radius and elevation tokens of the active theme.
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? const AppSpacing();
}
