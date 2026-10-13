import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_button_content.dart';
import 'package:flutter/material.dart';

/// Secondary action: an outlined pill that sits next to a primary button.
class AppSecondaryButton extends StatelessWidget {
  /// Creates a button; [onPressed] is ignored while [isLoading] is true.
  const AppSecondaryButton({
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
    final isEnabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      onTap: isEnabled ? onPressed : null,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        child: AppButtonContent(
          label: label,
          isLoading: isLoading,
          progressColor: context.colors.textPrimary,
        ),
      ),
    );
  }
}
