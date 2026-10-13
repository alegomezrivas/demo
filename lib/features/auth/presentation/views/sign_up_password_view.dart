import 'package:demo/app/locator.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/remember_session_tile.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 3: the password and "remember me".
///
/// The screen is hidden from captures while it is open.
class SignUpPasswordView extends StatefulWidget {
  /// Creates the view.
  const SignUpPasswordView({super.key});

  @override
  State<SignUpPasswordView> createState() => _SignUpPasswordViewState();
}

class _SignUpPasswordViewState extends State<SignUpPasswordView> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      onViewModelReady: (viewModel) => viewModel.protectScreen(enabled: true),
      onDispose: (viewModel) => viewModel.protectScreen(enabled: false),
      builder: (context, viewModel, _) {
        return ReactiveForm(
          formGroup: viewModel.forms.password,
          child: AppStepScaffold(
            title: l10n.signUpPasswordTitle,
            description: l10n.signUpPasswordDescription,
            onBack: viewModel.back,
            bottomLink: TextButton(
              onPressed: viewModel.goToLogin,
              child: Text(l10n.welcomeHaveAccount),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.signUpNext,
                onPressed: viewModel.submitPassword,
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  formControlName: SignUpForms.passwordField,
                  label: l10n.authPasswordLabel,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  autofocus: true,
                  onSubmitted: viewModel.submitPassword,
                  validationMessages: ValidationMessages.of(l10n),
                  suffixIcon: IconButton(
                    tooltip: l10n.authTogglePassword,
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const RememberSessionTile(
                  formControlName: SignUpForms.rememberField,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
