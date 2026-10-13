import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:demo/core/widgets/avatar_cropper.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Full-screen crop of the chosen picture; pops with the cropped bytes, or
/// with null when the person goes back.
class AvatarCropPage extends StatefulWidget {
  /// Creates the page for [image].
  const AvatarCropPage({required this.image, super.key});

  /// Encoded picture to crop.
  final Uint8List image;

  /// Opens the page and completes with the cropped picture, if any.
  static Future<Uint8List?> open(BuildContext context, Uint8List image) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AvatarCropPage(image: image),
      ),
    );
  }

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  void _crop() {
    setState(() => _isCropping = true);
    _controller.crop();
  }

  void _onCropped(Uint8List bytes) => Navigator.of(context).pop(bytes);

  void _onFailed(Object _) {
    // Keep the picture as chosen when the crop cannot be produced.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppStepScaffold(
      title: l10n.photoCropTitle,
      onBack: () => Navigator.of(context).pop(),
      actionsPlacement: StepActionsPlacement.pinned,
      actions: [
        AppPrimaryButton(
          label: l10n.photoCropDone,
          isLoading: _isCropping,
          onPressed: _crop,
        ),
      ],
      child: SizedBox(
        height: context.spacing.heroSize + context.spacing.xxl * 2,
        child: AvatarCropper(
          image: widget.image,
          controller: _controller,
          onCropped: _onCropped,
          onFailed: _onFailed,
        ),
      ),
    );
  }
}
