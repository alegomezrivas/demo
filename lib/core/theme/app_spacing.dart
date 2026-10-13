import 'package:flutter/material.dart';

/// Spacing, radius and elevation tokens exposed through [ThemeExtension].
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  /// Creates a spacing scale.
  const AppSpacing({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 20,
    this.radiusFull = 999,
    this.elevationNone = 0,
    this.elevationLow = 1,
    this.elevationMedium = 3,
    this.elevationHigh = 8,
    this.formMaxWidth = 420,
    this.illustrationSize = 48,
    this.progressHeight = 8,
    this.minTouchTarget = 48,
    this.borderThin = 1,
    this.borderThick = 2,
    this.otpBoxHeight = 56,
    this.avatarMd = 120,
    this.avatarLg = 144,
    this.iconMd = 24,
    this.sheetHandleWidth = 40,
    this.sheetHandleHeight = 4,
    this.heroSize = 220,
  });

  /// Smallest gap.
  final double xxs;

  /// Extra small gap.
  final double xs;

  /// Small gap.
  final double sm;

  /// Default gap.
  final double md;

  /// Large gap.
  final double lg;

  /// Extra large gap.
  final double xl;

  /// Largest gap.
  final double xxl;

  /// Small corner radius.
  final double radiusSm;

  /// Medium corner radius.
  final double radiusMd;

  /// Large corner radius.
  final double radiusLg;

  /// Fully rounded (pill) radius.
  final double radiusFull;

  /// No elevation.
  final double elevationNone;

  /// Low elevation.
  final double elevationLow;

  /// Medium elevation.
  final double elevationMedium;

  /// High elevation.
  final double elevationHigh;

  /// Widest a centered form may grow (tablets, landscape).
  final double formMaxWidth;

  /// Size of the large icon shown in empty / error / blocked states.
  final double illustrationSize;

  /// Thickness of linear progress bars.
  final double progressHeight;

  /// Smallest comfortable tap target (accessibility guideline).
  final double minTouchTarget;

  /// Hairline outline width.
  final double borderThin;

  /// Emphasised outline width (focus, active code box).
  final double borderThick;

  /// Height of one code box in the confirmation code input.
  final double otpBoxHeight;

  /// Diameter of the avatar in forms.
  final double avatarMd;

  /// Diameter of the avatar on welcome screens.
  final double avatarLg;

  /// Default icon size.
  final double iconMd;

  /// Width of the drag handle of bottom sheets.
  final double sheetHandleWidth;

  /// Height of the drag handle of bottom sheets.
  final double sheetHandleHeight;

  /// Edge of the square that holds the welcome illustration.
  final double heroSize;

  /// Small [BorderRadius].
  BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);

  /// Medium [BorderRadius].
  BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);

  /// Large [BorderRadius].
  BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  /// Default padding for a screen.
  EdgeInsets get screenPadding => EdgeInsets.all(md);

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusFull,
    double? elevationNone,
    double? elevationLow,
    double? elevationMedium,
    double? elevationHigh,
    double? formMaxWidth,
    double? illustrationSize,
    double? progressHeight,
    double? minTouchTarget,
    double? borderThin,
    double? borderThick,
    double? otpBoxHeight,
    double? avatarMd,
    double? avatarLg,
    double? iconMd,
    double? sheetHandleWidth,
    double? sheetHandleHeight,
    double? heroSize,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusFull: radiusFull ?? this.radiusFull,
      elevationNone: elevationNone ?? this.elevationNone,
      elevationLow: elevationLow ?? this.elevationLow,
      elevationMedium: elevationMedium ?? this.elevationMedium,
      elevationHigh: elevationHigh ?? this.elevationHigh,
      formMaxWidth: formMaxWidth ?? this.formMaxWidth,
      illustrationSize: illustrationSize ?? this.illustrationSize,
      progressHeight: progressHeight ?? this.progressHeight,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      borderThin: borderThin ?? this.borderThin,
      borderThick: borderThick ?? this.borderThick,
      otpBoxHeight: otpBoxHeight ?? this.otpBoxHeight,
      avatarMd: avatarMd ?? this.avatarMd,
      avatarLg: avatarLg ?? this.avatarLg,
      iconMd: iconMd ?? this.iconMd,
      sheetHandleWidth: sheetHandleWidth ?? this.sheetHandleWidth,
      sheetHandleHeight: sheetHandleHeight ?? this.sheetHandleHeight,
      heroSize: heroSize ?? this.heroSize,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    // Spacing is identical in light and dark, so there is nothing to blend.
    if (other is! AppSpacing) return this;
    return t < 0.5 ? this : other;
  }
}
