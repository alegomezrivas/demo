import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Primary call-to-action button that only consumes design tokens.
class AppButton extends StatelessWidget {
  /// Creates a button; [onPressed] is ignored while [isLoading] is true.
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  /// Text shown inside the button.
  final String label;

  /// Tap callback; a null value disables the button.
  final VoidCallback? onPressed;

  /// Shows a progress indicator and blocks taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox.square(
              dimension: spacing.md,
              child: CircularProgressIndicator(
                strokeWidth: spacing.xxs,
                color: colors.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
