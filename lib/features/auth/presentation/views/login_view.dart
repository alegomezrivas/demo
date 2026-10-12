import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_button.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
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
        final failure = viewModel.failure;
        return Scaffold(
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
                        Text(l10n.authLoginTitle, style: context.text.headline),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          l10n.authLoginSubtitle,
                          style: context.text.bodySmall,
                        ),
                        SizedBox(height: context.spacing.lg),
                        AppTextField(
                          formControlName: LoginViewModel.emailField,
                          label: l10n.authEmailLabel,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
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
                          label: l10n.authLoginButton,
                          isLoading: viewModel.isBusy,
                          onPressed: viewModel.submit,
                        ),
                        SizedBox(height: context.spacing.sm),
                        TextButton(
                          onPressed: viewModel.goToRegister,
                          child: Text(
                            '${l10n.authNoAccount} ${l10n.authGoToRegister}',
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
