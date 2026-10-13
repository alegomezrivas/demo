import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Square, circle-guided cropping area for a profile picture.
///
/// The circle stays fixed and the user moves and zooms the image underneath.
/// Call [CropController.crop] on [controller] (for example from a "Done"
/// button) to receive the result in [onCropped] or [onFailed].
class AvatarCropper extends StatelessWidget {
  /// Creates the cropper for [image].
  const AvatarCropper({
    required this.image,
    required this.controller,
    required this.onCropped,
    required this.onFailed,
    super.key,
  });

  /// Encoded source image.
  final Uint8List image;

  /// Triggers the crop from outside.
  final CropController controller;

  /// Called with the cropped, encoded square image.
  final ValueChanged<Uint8List> onCropped;

  /// Called when cropping fails.
  final ValueChanged<Object> onFailed;

  @override
  Widget build(BuildContext context) {
    return Crop(
      image: image,
      controller: controller,
      aspectRatio: 1,
      withCircleUi: true,
      interactive: true,
      fixCropRect: true,
      baseColor: context.colors.background,
      progressIndicator: const Center(child: CircularProgressIndicator()),
      onCropped: (result) {
        switch (result) {
          case CropSuccess(:final croppedImage):
            onCropped(croppedImage);
          case CropFailure(:final cause):
            onFailed(cause);
        }
      },
    );
  }
}
