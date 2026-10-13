import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/remember_session_tile.dart';
import 'package:demo/features/auth/presentation/widgets/step_error_text.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-in screen.
class LoginView extends StatelessWidget {
  /// Creates the view.
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<LoginViewModel>.reactive(
      viewModelBuilder: () => locator<LoginViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, _) {
        return ReactiveForm(
          formGroup: viewModel.form,
          child: AppStepScaffold(
            title: l10n.authLoginTitle,
            description: l10n.authLoginSubtitle,
            onBack: viewModel.goToWelcome,
            bottomLink: TextButton(
              onPressed: viewModel.goToWelcome,
              child: Text(l10n.authNoAccountCreate),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.authLoginButton,
                isLoading: viewModel.isBusy,
                onPressed: viewModel.submit,
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  formControlName: LoginViewModel.emailField,
                  label: l10n.authEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  showClearButton: true,
                  validationMessages: ValidationMessages.of(l10n),
                ),
                SizedBox(height: context.spacing.md),
                AppTextField(
                  formControlName: LoginViewModel.passwordField,
                  label: l10n.authPasswordLabel,
                  obscureText: viewModel.obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: viewModel.submit,
                  validationMessages: ValidationMessages.of(l10n),
                  suffixIcon: IconButton(
                    tooltip: l10n.authTogglePassword,
                    icon: Icon(
                      viewModel.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: viewModel.togglePasswordVisibility,
                  ),
                ),
                const RememberSessionTile(
                  formControlName: LoginViewModel.rememberField,
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
