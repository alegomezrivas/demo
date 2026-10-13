import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_button_content.dart';
import 'package:flutter/material.dart';

/// Primary call-to-action button that only consumes design tokens.
///
/// It is announced by its label even while loading, so screen readers do not
/// lose the context when the label is replaced by a progress indicator.
class AppPrimaryButton extends StatelessWidget {
  /// Creates a button; [onPressed] is ignored while [isLoading] is true.
  const AppPrimaryButton({
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
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        child: AppButtonContent(
          label: label,
          isLoading: isLoading,
          progressColor: context.colors.onPrimary,
        ),
      ),
    );
  }
}
