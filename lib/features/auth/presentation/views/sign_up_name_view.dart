import 'package:demo/app/locator.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 4: the full name.
class SignUpNameView extends StatelessWidget {
  /// Creates the view.
  const SignUpNameView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        return ReactiveForm(
          formGroup: viewModel.forms.name,
          child: AppStepScaffold(
            title: l10n.signUpNameTitle,
            description: l10n.signUpNameDescription,
            onBack: viewModel.back,
            bottomLink: TextButton(
              onPressed: viewModel.goToLogin,
              child: Text(l10n.welcomeHaveAccount),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.signUpNext,
                onPressed: viewModel.submitName,
              ),
            ],
            child: AppTextField(
              formControlName: SignUpForms.nameField,
              label: l10n.authFullNameLabel,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              autofocus: true,
              showClearButton: true,
              onSubmitted: viewModel.submitName,
              validationMessages: ValidationMessages.of(l10n),
            ),
          ),
        );
      },
    );
  }
}
