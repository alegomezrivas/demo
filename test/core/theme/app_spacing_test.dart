import 'package:demo/core/theme/app_spacing.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing', () {
    test('exposes a strictly increasing scale', () {
      const s = AppSpacing();

      final scale = [s.xxs, s.xs, s.sm, s.md, s.lg, s.xl, s.xxl];

      expect(scale, orderedEquals([...scale]..sort()));
      expect(scale.toSet().length, scale.length);
    });

    test('derives border radii and screen padding from tokens', () {
      const s = AppSpacing();

      expect(s.borderRadiusMd, BorderRadius.circular(s.radiusMd));
      expect(s.screenPadding, EdgeInsets.all(s.md));
    });

    test('copyWith overrides only the given field', () {
      final copy = const AppSpacing().copyWith(md: 20);

      expect(copy.md, 20);
      expect(copy.lg, const AppSpacing().lg);
    });

    test('lerp switches at the midpoint', () {
      const a = AppSpacing();
      final b = a.copyWith(md: 99);

      expect(a.lerp(b, 0.2).md, a.md);
      expect(a.lerp(b, 0.8).md, 99);
      expect(a.lerp(null, 0.8), a);
    });
  });
}
