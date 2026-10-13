import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/widgets/animated_message.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 5: the public username, checked while it is typed.
class SignUpUsernameView extends StatelessWidget {
  /// Creates the view.
  const SignUpUsernameView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        final status = viewModel.state.usernameStatus;
        return ReactiveForm(
          formGroup: viewModel.forms.username,
          child: AppStepScaffold(
            title: l10n.signUpUsernameTitle,
            description: l10n.signUpUsernameDescription,
            onBack: viewModel.back,
            bottomLink: TextButton(
              onPressed: viewModel.goToLogin,
              child: Text(l10n.welcomeHaveAccount),
            ),
            actions: [
              AppPrimaryButton(
                label: l10n.signUpNext,
                isLoading:
                    viewModel.isBusy || status == UsernameStatus.checking,
                onPressed: viewModel.submitUsername,
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  formControlName: SignUpForms.usernameField,
                  label: l10n.authUsernameLabel,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newUsername],
                  autofocus: true,
                  showClearButton: true,
                  showValidIndicator: status == UsernameStatus.available,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onSubmitted: viewModel.submitUsername,
                  validationMessages: ValidationMessages.of(l10n),
                ),
                _StatusLine(
                  status: status,
                  username: SignUpForms.textOf(
                    viewModel.forms.username,
                    SignUpForms.usernameField,
                  ).trim().toLowerCase(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, required this.username});

  final UsernameStatus status;
  final String username;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    // Text colors are the ones that pass AA on the background; availability
    // is signalled by the check icon, not by color alone.
    final (text, color) = switch (status) {
      UsernameStatus.idle => (null, colors.textSecondary),
      UsernameStatus.invalid => (l10n.validationUsername, colors.error),
      UsernameStatus.checking => (l10n.usernameChecking, colors.textSecondary),
      UsernameStatus.available => (
        l10n.usernameAvailable(username),
        colors.textSecondary,
      ),
      UsernameStatus.taken => (l10n.authUsernameTaken, colors.error),
      UsernameStatus.unknown => (l10n.usernameUnknown, colors.textSecondary),
    };
    return AnimatedMessage(
      child: text == null ? null : _line(context, text, color),
    );
  }

  Widget _line(BuildContext context, String text, Color color) {
    final colors = context.colors;
    return Padding(
      key: ValueKey('$status$text'),
      padding: EdgeInsets.only(top: context.spacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            if (status == UsernameStatus.available) ...[
              Icon(
                Icons.check_circle,
                size: context.spacing.iconMd - context.spacing.sm,
                color: colors.success,
              ),
              SizedBox(width: context.spacing.xs),
            ],
            Expanded(
              child: Text(
                text,
                key: const Key('username_status'),
                style: context.text.bodySmall.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
