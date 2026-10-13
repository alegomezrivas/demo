import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Original illustration for the welcome screen: three stacked task cards,
/// drawn with widgets and the design tokens (no images, light and dark alike).
class WelcomeIllustration extends StatelessWidget {
  /// Creates the illustration.
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).welcomeIllustrationLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: spacing.heroSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _TaskCard(
              offset: Offset(-spacing.lg, -spacing.xl),
              tilt: -0.06,
              isDone: true,
              tone: context.colors.surfaceMuted,
            ),
            _TaskCard(
              offset: Offset(spacing.lg, 0),
              tilt: 0.05,
              isDone: false,
              tone: context.colors.surface,
            ),
            _TaskCard(
              offset: Offset(-spacing.sm, spacing.xl),
              tilt: -0.02,
              isDone: true,
              tone: context.colors.surface,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.offset,
    required this.tilt,
    required this.isDone,
    required this.tone,
  });

  final Offset offset;
  final double tilt;
  final bool isDone;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          width: spacing.heroSize,
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: tone,
            borderRadius: spacing.borderRadiusLg,
            border: Border.all(color: colors.border, width: spacing.borderThin),
          ),
          child: Row(
            children: [
              Container(
                width: spacing.iconMd,
                height: spacing.iconMd,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? colors.success : Colors.transparent,
                  border: Border.all(
                    color: isDone ? colors.success : colors.border,
                    width: spacing.borderThick,
                  ),
                ),
                child: isDone
                    ? Icon(
                        Icons.check,
                        size: spacing.iconMd - spacing.sm,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(widthFactor: 0.8, color: colors.textSecondary),
                    SizedBox(height: spacing.xs),
                    _Bar(widthFactor: 0.5, color: colors.border),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: spacing.xs,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(spacing.radiusFull),
        ),
      ),
    );
  }
}
