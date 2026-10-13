import 'package:demo/app/locator.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_secondary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/otp_input.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 2: the six-digit code received by e-mail.
class SignUpCodeView extends StatelessWidget {
  /// Creates the view.
  const SignUpCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        final failure = viewModel.failure;
        final seconds = viewModel.resendSecondsLeft;
        return ReactiveForm(
          formGroup: viewModel.forms.code,
          child: AppStepScaffold(
            title: l10n.signUpCodeTitle,
            description: l10n.signUpCodeDescription(viewModel.state.email),
            onBack: viewModel.back,
            bottomLink: TextButton(
              onPressed: viewModel.goToLogin,
              child: Text(l10n.welcomeHaveAccount),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.signUpNext,
                isLoading: viewModel.isBusy,
                onPressed: viewModel.submitCode,
              ),
              AppSecondaryButton(
                label: seconds > 0
                    ? l10n.signUpCodeResendIn(seconds)
                    : l10n.signUpCodeNotReceived,
                onPressed: viewModel.canResendCode
                    ? viewModel.resendCode
                    : null,
              ),
            ],
            child: OtpInput(
              formControlName: SignUpForms.codeField,
              hasError: failure != null,
              errorText: failure?.authMessage(l10n),
              onCompleted: (_) => viewModel.submitCode(),
            ),
          ),
        );
      },
    );
  }
}
