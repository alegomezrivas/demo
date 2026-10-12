import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_button.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
import 'package:demo/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up screen.
class RegisterView extends StatelessWidget {
  /// Creates the view.
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<RegisterViewModel>.reactive(
      viewModelBuilder: () => locator<RegisterViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, _) {
        final failure = viewModel.failure;
        final messages = ValidationMessages.of(l10n);
        final toggle = IconButton(
          tooltip: l10n.authTogglePassword,
          icon: Icon(
            viewModel.obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: viewModel.togglePasswordVisibility,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.authRegisterTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.commonBack,
              onPressed: viewModel.goToLogin,
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: context.spacing.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ReactiveForm(
                    formGroup: viewModel.form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.authRegisterSubtitle,
                          style: context.text.bodySmall,
                        ),
                        SizedBox(height: context.spacing.lg),
                        AppTextField(
                          formControlName: RegisterViewModel.nameField,
                          label: l10n.authNameLabel,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validationMessages: messages,
                        ),
                        SizedBox(height: context.spacing.md),
                        AppTextField(
                          formControlName: RegisterViewModel.emailField,
                          label: l10n.authEmailLabel,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validationMessages: messages,
                        ),
                        SizedBox(height: context.spacing.md),
                        AppTextField(
                          formControlName: RegisterViewModel.phoneField,
                          label: l10n.authPhoneLabel,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validationMessages: messages,
                        ),
                        SizedBox(height: context.spacing.md),
                        AppTextField(
                          formControlName: RegisterViewModel.passwordField,
                          label: l10n.authPasswordLabel,
                          obscureText: viewModel.obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validationMessages: messages,
                          suffixIcon: toggle,
                        ),
                        SizedBox(height: context.spacing.md),
                        AppTextField(
                          formControlName:
                              RegisterViewModel.confirmPasswordField,
                          label: l10n.authConfirmPasswordLabel,
                          obscureText: viewModel.obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: viewModel.submit,
                          validationMessages: messages,
                        ),
                        if (failure != null) ...[
                          SizedBox(height: context.spacing.md),
                          Text(
                            failure.authMessage(l10n),
                            key: const Key('auth_error'),
                            style: context.text.bodySmall.copyWith(
                              color: context.colors.error,
                            ),
                          ),
                        ],
                        SizedBox(height: context.spacing.lg),
                        AppButton(
                          label: l10n.authRegisterButton,
                          isLoading: viewModel.isBusy,
                          onPressed: viewModel.submit,
                        ),
                        SizedBox(height: context.spacing.sm),
                        TextButton(
                          onPressed: viewModel.goToLogin,
                          child: Text(
                            '${l10n.authHaveAccount} ${l10n.authGoToLogin}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
