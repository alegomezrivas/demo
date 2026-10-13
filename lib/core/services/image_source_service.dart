import 'package:demo/core/error/exceptions.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Where a profile picture can come from.
enum PhotoSource {
  /// The photo library.
  gallery,

  /// The camera.
  camera,
}

/// Lets the user pick a picture; permissions are requested only here, when
/// the user actually chooses a source.
abstract interface class ImageSourceService {
  /// Returns the picked picture, or null when the user cancels.
  ///
  /// Throws [PermissionDeniedException] when access was denied and
  /// [InvalidImageException] for any other picking problem.
  Future<Uint8List?> pick(PhotoSource source);
}

/// [ImageSourceService] backed by `image_picker`.
class ImagePickerSourceService implements ImageSourceService {
  /// Creates the service; pass [picker] to substitute the plugin in tests.
  ImagePickerSourceService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Pictures are downscaled to this side while picking to bound memory use.
  static const double maxPickedSide = 2048;

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          PhotoSource.gallery => ImageSource.gallery,
          PhotoSource.camera => ImageSource.camera,
        },
        maxWidth: maxPickedSide,
        maxHeight: maxPickedSide,
        // Skips the extra photo-library permission only needed for metadata.
        requestFullMetadata: false,
      );
      return file?.readAsBytes();
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'photo_access_denied' => const PermissionDeniedException(
          'photo_permission_denied',
        ),
        'camera_access_denied' => const PermissionDeniedException(
          'camera_permission_denied',
        ),
        _ => const InvalidImageException('pick_failed'),
      };
    }
  }
}
