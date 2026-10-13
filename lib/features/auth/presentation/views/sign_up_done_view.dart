import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/avatar_picker.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Sign-up final step: a greeting with the new username.
class SignUpDoneView extends StatelessWidget {
  /// Creates the view.
  const SignUpDoneView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        final username = viewModel.state.user?.username ?? '';
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: spacing.screenPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: spacing.formMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: AvatarPicker(
                          imageBytes: viewModel.state.avatar,
                          diameter: spacing.avatarLg,
                        ),
                      ),
                      SizedBox(height: spacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.signUpDoneTitle(username),
                          textAlign: TextAlign.center,
                          style: context.text.headline,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        l10n.signUpDoneDescription,
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall,
                      ),
                      SizedBox(height: spacing.xl),
                      AppPrimaryButton(
                        label: l10n.signUpDoneButton,
                        onPressed: viewModel.finish,
                      ),
                    ],
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
