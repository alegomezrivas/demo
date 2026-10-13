import 'dart:async';
import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/services/image_processor.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:stacked/stacked.dart';

/// What went wrong while choosing the picture.
enum AvatarIssue {
  /// Nothing.
  none,

  /// The photo library is not accessible.
  galleryDenied,

  /// The camera is not accessible.
  cameraDenied,

  /// The file cannot be used as a picture.
  invalidImage,

  /// Even compressed, the picture does not fit the size limit.
  tooLarge,
}

/// ViewModel of the optional profile-picture step.
///
/// It picks, keeps the cropped preview and prepares the JPEG; sending it (and
/// moving on) belongs to [SignUpFlowViewModel].
class AvatarStepViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  AvatarStepViewModel({
    required ImageSourceService source,
    required ImageProcessor processor,
    required SignUpFlowViewModel flow,
  }) : _source = source,
       _processor = processor,
       _flow = flow;

  final ImageSourceService _source;
  final ImageProcessor _processor;
  final SignUpFlowViewModel _flow;

  Uint8List? _original;
  Uint8List? _preview;
  AvatarIssue _issue = AvatarIssue.none;
  bool _isUploading = false;

  /// The picture as chosen, before cropping (what the cropper starts from).
  Uint8List? get original => _original;

  /// The picture to show; null until one is chosen.
  Uint8List? get preview => _preview;

  /// The picture problem to explain, if any.
  AvatarIssue get issue => _issue;

  /// Whether a picture is ready to be used.
  bool get hasPicture => _preview != null;

  /// Whether the picture is being prepared or sent.
  bool get isWorking => isBusy || _isUploading || _flow.isBusy;

  /// Asks the system for a picture; cancelling leaves things as they were.
  Future<void> pick(PhotoSource source) async {
    if (isWorking) return;
    _issue = AvatarIssue.none;
    try {
      final bytes = await _source.pick(source);
      if (bytes == null) {
        notifyListeners();
        return;
      }
      _original = bytes;
      _preview = bytes;
    } on PermissionDeniedException {
      _issue = source == PhotoSource.camera
          ? AvatarIssue.cameraDenied
          : AvatarIssue.galleryDenied;
    } on InvalidImageException catch (error) {
      _issue = _issueFor(error);
    }
    notifyListeners();
  }

  /// Replaces the preview with the cropped picture.
  void applyCrop(Uint8List cropped) {
    _preview = cropped;
    _issue = AvatarIssue.none;
    notifyListeners();
  }

  /// Compresses the picture and uploads it; moves on when it worked.
  Future<void> submit() async {
    final picture = _preview;
    if (picture == null || isWorking) return;
    _isUploading = true;
    _issue = AvatarIssue.none;
    notifyListeners();
    try {
      final jpeg = await _processor.toAvatarJpeg(picture);
      await _flow.submitAvatar(jpeg);
    } on InvalidImageException catch (error) {
      _issue = _issueFor(error);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  AvatarIssue _issueFor(InvalidImageException error) =>
      error.code == 'too_large'
      ? AvatarIssue.tooLarge
      : AvatarIssue.invalidImage;

  /// Continues without a picture.
  void skip() => _flow.skipAvatar();
}
