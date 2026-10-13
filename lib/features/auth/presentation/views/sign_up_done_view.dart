import 'dart:typed_data';

import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/avatar_picker.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Sign-up final step: a greeting with the new username.
///
/// It keeps its own copy of the username and picture: entering the app resets
/// the flow while this page is still animating out, and it must not flash
/// empty.
class SignUpDoneView extends StatefulWidget {
  /// Creates the view.
  const SignUpDoneView({super.key});

  @override
  State<SignUpDoneView> createState() => _SignUpDoneViewState();
}

class _SignUpDoneViewState extends State<SignUpDoneView> {
  String? _username;
  Uint8List? _avatar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return ViewModelBuilder<SignUpFlowViewModel>.reactive(
      viewModelBuilder: () => locator<SignUpFlowViewModel>(),
      disposeViewModel: false,
      builder: (context, viewModel, _) {
        // Captured on the first build, while the flow still holds them.
        _username ??= viewModel.state.user?.username ?? '';
        _avatar ??= viewModel.state.avatar;
        final username = _username ?? '';
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
                          imageBytes: _avatar,
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
