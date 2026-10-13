import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Label of a button, or a progress indicator while it is loading.
///
/// Shared by the primary and secondary buttons so both behave the same.
class AppButtonContent extends StatelessWidget {
  /// Creates the content.
  const AppButtonContent({
    required this.label,
    required this.isLoading,
    required this.progressColor,
    super.key,
  });

  /// Text shown when idle.
  final String label;

  /// Replaces the label with a progress indicator.
  final bool isLoading;

  /// Color of the progress indicator.
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Text(label);
    final spacing = context.spacing;
    return SizedBox.square(
      dimension: spacing.md,
      child: CircularProgressIndicator(
        strokeWidth: spacing.xxs,
        color: progressColor,
      ),
    );
  }
}
