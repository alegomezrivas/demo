import 'package:flutter/material.dart';

/// Color tokens exposed through [ThemeExtension]; the single source of colors.
///
/// Edit [light] and [dark] to change the whole palette of the app.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates a palette.
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  /// Light palette (blue / teal).
  static const AppColors light = AppColors(
    primary: Color(0xFF1565C0),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF00897B),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF6F8FB),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFED6C02),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    border: Color(0xFFD6DCE5),
  );

  /// Dark palette (blue / teal).
  static const AppColors dark = AppColors(
    primary: Color(0xFF90CAF9),
    onPrimary: Color(0xFF0A2540),
    secondary: Color(0xFF4DB6AC),
    onSecondary: Color(0xFF00302B),
    background: Color(0xFF0B1220),
    surface: Color(0xFF141C2E),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    textPrimary: Color(0xFFE6EAF2),
    textSecondary: Color(0xFF9AA7BD),
    border: Color(0xFF2A3550),
  );

  /// Main brand color.
  final Color primary;

  /// Content color on top of [primary].
  final Color onPrimary;

  /// Accent color.
  final Color secondary;

  /// Content color on top of [secondary].
  final Color onSecondary;

  /// Scaffold background.
  final Color background;

  /// Cards, sheets and inputs.
  final Color surface;

  /// Error state.
  final Color error;

  /// Content color on top of [error].
  final Color onError;

  /// Success state.
  final Color success;

  /// Warning state.
  final Color warning;

  /// Main text color.
  final Color textPrimary;

  /// Secondary / hint text color.
  final Color textSecondary;

  /// Dividers and outlines.
  final Color border;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppColors &&
          other.primary == primary &&
          other.onPrimary == onPrimary &&
          other.secondary == secondary &&
          other.onSecondary == onSecondary &&
          other.background == background &&
          other.surface == surface &&
          other.error == error &&
          other.onError == onError &&
          other.success == success &&
          other.warning == warning &&
          other.textPrimary == textPrimary &&
          other.textSecondary == textSecondary &&
          other.border == border;

  @override
  int get hashCode => Object.hash(
    primary,
    onPrimary,
    secondary,
    onSecondary,
    background,
    surface,
    error,
    onError,
    success,
    warning,
    textPrimary,
    textSecondary,
    border,
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? surface,
    Color? error,
    Color? onError,
    Color? success,
    Color? warning,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppColors(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      border: mix(border, other.border),
    );
  }
}
