import 'package:demo/core/error/failures.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Generic, localized error line shown under the field of a step.
///
/// It is announced to screen readers when it appears (live region) and shows
/// nothing for a null [failure].
class StepErrorText extends StatelessWidget {
  /// Creates the line for [failure].
  const StepErrorText({required this.failure, super.key});

  /// The failure to describe, or null for no message.
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final current = failure;
    if (current == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          current.authMessage(AppLocalizations.of(context)),
          key: const Key('step_error'),
          style: context.text.bodySmall.copyWith(color: context.colors.error),
        ),
      ),
    );
  }
}
