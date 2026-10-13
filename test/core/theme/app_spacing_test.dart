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

  group('AppSpacing layout tokens', () {
    test(
      'exposes sane defaults for forms, illustrations and progress bars',
      () {
        const s = AppSpacing();

        expect(s.formMaxWidth, greaterThan(s.xxl));
        expect(s.illustrationSize, s.xxl);
        expect(s.progressHeight, s.sm);
      },
    );

    test('copyWith overrides them', () {
      final s = const AppSpacing().copyWith(
        formMaxWidth: 500,
        illustrationSize: 64,
        progressHeight: 12,
      );

      expect(s.formMaxWidth, 500);
      expect(s.illustrationSize, 64);
      expect(s.progressHeight, 12);
    });
  });

  group('AppSpacing step-flow tokens', () {
    test('the minimum tap target follows the 48 dp guideline', () {
      expect(const AppSpacing().minTouchTarget, 48);
    });

    test('emphasised outlines are thicker than hairlines', () {
      const s = AppSpacing();

      expect(s.borderThick, greaterThan(s.borderThin));
    });

    test('a code box is tall enough to tap', () {
      expect(const AppSpacing().otpBoxHeight, greaterThanOrEqualTo(48));
    });

    test('avatars grow from the form size to the welcome size', () {
      const s = AppSpacing();

      expect(s.avatarLg, greaterThan(s.avatarMd));
    });

    test('copyWith overrides the new tokens', () {
      final copy = const AppSpacing().copyWith(
        minTouchTarget: 56,
        borderThin: 2,
        borderThick: 4,
        otpBoxHeight: 60,
        avatarMd: 100,
        avatarLg: 200,
        iconMd: 28,
        sheetHandleWidth: 50,
        sheetHandleHeight: 6,
        heroSize: 300,
      );

      expect(copy.minTouchTarget, 56);
      expect(copy.borderThin, 2);
      expect(copy.borderThick, 4);
      expect(copy.otpBoxHeight, 60);
      expect(copy.avatarMd, 100);
      expect(copy.avatarLg, 200);
      expect(copy.iconMd, 28);
      expect(copy.sheetHandleWidth, 50);
      expect(copy.sheetHandleHeight, 6);
      expect(copy.heroSize, 300);
      expect(copy.md, const AppSpacing().md);
    });
  });
}
