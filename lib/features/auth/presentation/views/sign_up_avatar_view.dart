import 'package:demo/app/locator.dart';
import 'package:demo/core/services/image_processor.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_bottom_sheet.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_secondary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/avatar_picker.dart';
import 'package:demo/features/auth/presentation/viewmodels/avatar_step_view_model.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/auth/presentation/views/avatar_crop_page.dart';
import 'package:demo/features/auth/presentation/widgets/step_error_text.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Sign-up step 7: an optional profile picture (the account already exists).
class SignUpAvatarView extends StatelessWidget {
  /// Creates the view.
  const SignUpAvatarView({super.key});

  Future<void> _choose(
    BuildContext context,
    AvatarStepViewModel viewModel,
  ) async {
    final l10n = AppLocalizations.of(context);
    final source = await showAppBottomSheet<PhotoSource>(
      context: context,
      title: l10n.photoSheetTitle,
      options: [
        AppSheetOption(
          label: l10n.photoFromGallery,
          value: PhotoSource.gallery,
          icon: Icons.photo_library_outlined,
        ),
        AppSheetOption(
          label: l10n.photoFromCamera,
          value: PhotoSource.camera,
          icon: Icons.photo_camera_outlined,
        ),
      ],
    );
    if (source != null) await viewModel.pick(source);
  }

  Future<void> _edit(
    BuildContext context,
    AvatarStepViewModel viewModel,
  ) async {
    final original = viewModel.original;
    if (original == null) return;
    final cropped = await AvatarCropPage.open(context, original);
    if (cropped != null) viewModel.applyCrop(cropped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flow = locator<SignUpFlowViewModel>();
    return ViewModelBuilder<AvatarStepViewModel>.reactive(
      viewModelBuilder: () => AvatarStepViewModel(
        source: locator<ImageSourceService>(),
        processor: locator<ImageProcessor>(),
        flow: flow,
      ),
      builder: (context, viewModel, _) {
        // The flow ViewModel owns the upload failure; rebuild with it too.
        return ListenableBuilder(
          listenable: flow,
          builder: (context, _) {
            final isWorking = viewModel.isWorking;
            return AppStepScaffold(
              title: l10n.signUpAvatarTitle,
              description: l10n.signUpAvatarDescription,
              actionsPlacement: StepActionsPlacement.pinned,
              actions: [
                if (viewModel.hasPicture)
                  AppPrimaryButton(
                    label: l10n.signUpNext,
                    isLoading: isWorking,
                    onPressed: viewModel.submit,
                  )
                else
                  AppPrimaryButton(
                    label: l10n.signUpAvatarAdd,
                    onPressed: () => _choose(context, viewModel),
                  ),
                AppSecondaryButton(
                  label: l10n.signUpAvatarSkip,
                  onPressed: isWorking ? null : viewModel.skip,
                ),
              ],
              child: Padding(
                padding: EdgeInsets.only(top: context.spacing.lg),
                child: Column(
                  children: [
                    AvatarPicker(
                      imageBytes: viewModel.preview,
                      diameter: context.spacing.avatarLg,
                      onTap: isWorking
                          ? null
                          : () => _choose(context, viewModel),
                      onEdit: isWorking
                          ? null
                          : () => _edit(context, viewModel),
                    ),
                    _IssueText(issue: viewModel.issue),
                    StepErrorText(failure: flow.failure),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _IssueText extends StatelessWidget {
  const _IssueText({required this.issue});

  final AvatarIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (issue) {
      AvatarIssue.none => null,
      AvatarIssue.galleryDenied => l10n.photoGalleryDenied,
      AvatarIssue.cameraDenied => l10n.photoCameraDenied,
      AvatarIssue.invalidImage => l10n.authImageInvalid,
      AvatarIssue.tooLarge => l10n.authImageTooLarge,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          key: const Key('avatar_issue'),
          textAlign: TextAlign.center,
          style: context.text.bodySmall.copyWith(color: context.colors.error),
        ),
      ),
    );
  }
}
