import 'package:demo/app/locator.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/step_error_text.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 6: accepting the terms creates the account.
class SignUpTermsView extends StatelessWidget {
  /// Creates the view.
  const SignUpTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        return AppStepScaffold(
          title: l10n.signUpTermsTitle,
          description: l10n.signUpTermsDescription,
          onBack: viewModel.back,
          bottomLink: TextButton(
            onPressed: viewModel.goToLogin,
            child: Text(l10n.welcomeHaveAccount),
          ),
          actions: [
            AppPrimaryButton(
              label: l10n.signUpTermsAccept,
              isLoading: viewModel.isBusy,
              onPressed: viewModel.acceptTerms,
            ),
            TextButton(
              onPressed: viewModel.openTerms,
              child: Text(l10n.signUpTermsRead),
            ),
          ],
          child: StepErrorText(failure: viewModel.failure),
        );
      },
    );
  }
}
