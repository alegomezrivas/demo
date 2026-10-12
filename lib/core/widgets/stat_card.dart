import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Compact card showing one number and its label.
class StatCard extends StatelessWidget {
  /// Creates the card; [accent] defaults to the primary color.
  const StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    super.key,
  });

  /// Text under the number.
  final String label;

  /// Number (or short text) to highlight.
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Color of the icon and number.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.colors.primary;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color),
              SizedBox(height: context.spacing.sm),
            ],
            Text(value, style: context.text.headline.copyWith(color: color)),
            SizedBox(height: context.spacing.xs),
            Text(label, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
