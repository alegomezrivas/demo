import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full text of the terms and policies (generic sample text for the demo).
class TermsView extends StatelessWidget {
  /// Creates the view.
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.text;
    final sections = [
      (l10n.termsUseTitle, l10n.termsUseBody),
      (l10n.termsPrivacyTitle, l10n.termsPrivacyBody),
      (l10n.termsDataTitle, l10n.termsDataBody),
    ];
    return AppStepScaffold(
      title: l10n.termsScreenTitle,
      description: l10n.termsDemoNotice,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.home),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (title, body) in sections) ...[
            Semantics(header: true, child: Text(title, style: text.title)),
            SizedBox(height: context.spacing.xs),
            Text(body, style: text.body),
            SizedBox(height: context.spacing.lg),
          ],
        ],
      ),
    );
  }
}
