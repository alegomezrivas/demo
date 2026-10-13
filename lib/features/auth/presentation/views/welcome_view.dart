import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_secondary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/welcome_illustration.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// First screen of a signed-out visit: start the sign-up or sign in.
class WelcomeView extends StatelessWidget {
  /// Creates the view.
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.nonReactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        return AppStepScaffold(
          title: l10n.welcomeTitle,
          description: l10n.welcomeSubtitle,
          actionsPlacement: StepActionsPlacement.pinned,
          actions: [
            AppPrimaryButton(
              label: l10n.welcomeStart,
              onPressed: viewModel.start,
            ),
            AppSecondaryButton(
              label: l10n.welcomeHaveAccount,
              onPressed: viewModel.goToLogin,
            ),
          ],
          child: Padding(
            padding: EdgeInsets.only(top: context.spacing.lg),
            child: const WelcomeIllustration(),
          ),
        );
      },
    );
  }
}
