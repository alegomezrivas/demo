import 'package:demo/app/locator.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/core/widgets/email_suffix_suggestions.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/step_error_text.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 1: the e-mail address, with domain suggestions.
class SignUpEmailView extends StatelessWidget {
  /// Creates the view.
  const SignUpEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        return ReactiveForm(
          formGroup: viewModel.forms.email,
          child: AppStepScaffold(
            title: l10n.signUpEmailTitle,
            description: l10n.signUpEmailDescription,
            onBack: viewModel.back,
            keyboardAccessory: ReactiveValueListenableBuilder<String>(
              formControlName: SignUpForms.emailField,
              builder: (context, control, _) => EmailSuffixSuggestions(
                input: control.value ?? '',
                onSelected: (address) => control.value = address,
              ),
            ),
            bottomLink: TextButton(
              onPressed: viewModel.goToLogin,
              child: Text(l10n.welcomeHaveAccount),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.signUpNext,
                isLoading: viewModel.isBusy,
                onPressed: viewModel.submitEmail,
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  formControlName: SignUpForms.emailField,
                  label: l10n.authEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autofocus: true,
                  showClearButton: true,
                  onSubmitted: viewModel.submitEmail,
                  validationMessages: ValidationMessages.of(l10n),
                ),
                StepErrorText(failure: viewModel.failure),
              ],
            ),
          ),
        );
      },
    );
  }
}
