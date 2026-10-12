import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Centered "nothing here" message.
class EmptyView extends StatelessWidget {
  /// Creates the view.
  const EmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  /// Localized explanation.
  final String message;

  /// Illustration icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.spacing.xxl,
              color: context.colors.textSecondary,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              message,
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
