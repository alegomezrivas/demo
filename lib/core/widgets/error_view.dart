import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Centered error message with a retry button.
class ErrorView extends StatelessWidget {
  /// Creates the view.
  const ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  /// Generic, localized explanation.
  final String message;

  /// Label of the retry button.
  final String retryLabel;

  /// Called when the user taps retry.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: context.spacing.illustrationSize,
              color: context.colors.error,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              message,
              style: context.text.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.md),
            AppButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
