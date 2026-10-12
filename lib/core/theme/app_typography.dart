import 'package:flutter/material.dart';

/// Text style tokens exposed through [ThemeExtension].
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// Creates a type scale.
  const AppTextStyles({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodySmall,
    required this.label,
  });

  /// Hero text.
  final TextStyle display;

  /// Section headings.
  final TextStyle headline;

  /// Card / app bar titles.
  final TextStyle title;

  /// Default paragraph text.
  final TextStyle body;

  /// Secondary paragraph text.
  final TextStyle bodySmall;

  /// Buttons and captions.
  final TextStyle label;

  @override
  AppTextStyles copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? label,
  }) {
    return AppTextStyles(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t) ?? a;
    return AppTextStyles(
      display: mix(display, other.display),
      headline: mix(headline, other.headline),
      title: mix(title, other.title),
      body: mix(body, other.body),
      bodySmall: mix(bodySmall, other.bodySmall),
      label: mix(label, other.label),
    );
  }
}

/// Typography definition: the font family and the type scale live here only.
abstract final class AppTypography {
  /// Bundled font family (declared in `pubspec.yaml`).
  static const String fontFamily = 'Inter';

  /// Builds the type scale using [primary] and [secondary] text colors.
  static AppTextStyles build({
    required Color primary,
    required Color secondary,
  }) {
    TextStyle style(
      double size,
      FontWeight weight,
      Color color,
      double height,
    ) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }

    return AppTextStyles(
      display: style(36, FontWeight.w700, primary, 1.2),
      headline: style(24, FontWeight.w600, primary, 1.3),
      title: style(18, FontWeight.w600, primary, 1.3),
      body: style(16, FontWeight.w400, primary, 1.5),
      bodySmall: style(14, FontWeight.w400, secondary, 1.5),
      label: style(14, FontWeight.w500, primary, 1.2),
    );
  }

  /// Maps the scale onto Material's [TextTheme] so stock widgets match.
  static TextTheme toTextTheme(AppTextStyles styles) {
    return TextTheme(
      displayLarge: styles.display,
      headlineMedium: styles.headline,
      titleLarge: styles.title,
      bodyLarge: styles.body,
      bodyMedium: styles.body,
      bodySmall: styles.bodySmall,
      labelLarge: styles.label,
    );
  }
}
