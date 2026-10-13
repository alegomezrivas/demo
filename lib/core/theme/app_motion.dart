import 'package:flutter/material.dart';

/// Animation tokens exposed through [ThemeExtension]; the single source of
/// durations and curves.
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  /// Creates a motion scale.
  const AppMotion({
    this.fast = const Duration(milliseconds: 120),
    this.normal = const Duration(milliseconds: 220),
    this.slow = const Duration(milliseconds: 360),
    this.curve = Curves.easeOutCubic,
  });

  /// Micro-interactions (focus ring, check mark).
  final Duration fast;

  /// Default transitions (step changes, sheets).
  final Duration normal;

  /// Larger entrances (welcome hero).
  final Duration slow;

  /// Default easing.
  final Curve curve;

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Curve? curve,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
      curve: curve ?? this.curve,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    // Motion is identical in light and dark, so there is nothing to blend.
    if (other is! AppMotion) return this;
    return t < 0.5 ? this : other;
  }
}
