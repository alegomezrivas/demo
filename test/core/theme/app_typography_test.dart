import 'dart:ui';

import 'package:demo/core/theme/app_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const primary = Color(0xFF111111);
  const secondary = Color(0xFF999999);

  group('AppTypography', () {
    test('builds every style with the shared font family', () {
      final styles = AppTypography.build(
        primary: primary,
        secondary: secondary,
      );

      for (final style in [
        styles.display,
        styles.headline,
        styles.title,
        styles.body,
        styles.bodySmall,
        styles.label,
      ]) {
        expect(style.fontFamily, AppTypography.fontFamily);
      }
    });

    test('uses the secondary color only for small body text', () {
      final styles = AppTypography.build(
        primary: primary,
        secondary: secondary,
      );

      expect(styles.body.color, primary);
      expect(styles.bodySmall.color, secondary);
    });

    test('keeps a descending size scale from display to label', () {
      final styles = AppTypography.build(
        primary: primary,
        secondary: secondary,
      );

      expect(styles.display.fontSize, greaterThan(styles.headline.fontSize!));
      expect(styles.headline.fontSize, greaterThan(styles.title.fontSize!));
      expect(styles.title.fontSize, greaterThan(styles.body.fontSize!));
    });

    test('maps the scale onto the Material text theme', () {
      final styles = AppTypography.build(
        primary: primary,
        secondary: secondary,
      );

      final theme = AppTypography.toTextTheme(styles);

      expect(theme.displayLarge, styles.display);
      expect(theme.bodySmall, styles.bodySmall);
    });

    test('copyWith and lerp behave like value transformations', () {
      final styles = AppTypography.build(
        primary: primary,
        secondary: secondary,
      );
      final other = styles.copyWith(body: styles.title);

      expect(other.body, styles.title);
      expect(styles.lerp(other, 0).body, styles.body);
      expect(styles.lerp(null, 0.5), styles);
    });
  });
}
