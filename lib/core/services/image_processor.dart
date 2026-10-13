import 'dart:math' as math;
import 'package:demo/core/error/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Turns a picked picture into something safe and small enough to upload.
abstract interface class ImageProcessor {
  /// Returns [source] as a JPEG without any metadata, no longer than the
  /// configured side and no larger than the configured size.
  ///
  /// Throws [InvalidImageException] when [source] is not a decodable picture
  /// or cannot be brought under the size limit.
  Future<Uint8List> toAvatarJpeg(Uint8List source);
}

/// [ImageProcessor] built on the `image` package.
///
/// The work runs in a separate isolate so large photos never freeze the UI.
/// Decoding and re-encoding drops EXIF (location, device, timestamps), ICC
/// profiles and every other metadata block; the EXIF orientation is applied to
/// the pixels first so the picture does not end up rotated.
class JpegAvatarProcessor implements ImageProcessor {
  /// Creates the processor.
  const JpegAvatarProcessor({
    this.maxSide = 512,
    this.maxBytes = 200 * 1024,
    this.startQuality = 85,
  });

  /// Longest allowed side in pixels.
  final int maxSide;

  /// Largest allowed result in bytes.
  final int maxBytes;

  /// First JPEG quality tried (lowered when the result is too big).
  final int startQuality;

  /// Largest source file accepted, in bytes.
  static const int maxSourceBytes = 15 * 1024 * 1024;

  /// Largest source accepted, in pixels (a tiny file can declare huge sizes).
  static const int maxSourcePixels = 16 * 1000 * 1000;

  @override
  Future<Uint8List> toAvatarJpeg(Uint8List source) async {
    // Refuse huge inputs before spending memory on them.
    if (source.length > maxSourceBytes) {
      throw const InvalidImageException('too_large');
    }
    final job = _Job(
      source: source,
      maxSide: maxSide,
      maxBytes: maxBytes,
      startQuality: startQuality,
    );
    final (bytes, errorCode) = await compute(_process, job);
    if (bytes == null) {
      throw InvalidImageException(errorCode ?? 'invalid_image');
    }
    return bytes;
  }
}

class _Job {
  const _Job({
    required this.source,
    required this.maxSide,
    required this.maxBytes,
    required this.startQuality,
  });

  final Uint8List source;
  final int maxSide;
  final int maxBytes;
  final int startQuality;
}

const int _minQuality = 40;
const int _qualityStep = 15;
const int _maxShrinkRounds = 4;
const double _shrinkFactor = 0.8;

/// Runs inside the isolate; returns bytes or an error code.
(Uint8List?, String?) _process(_Job job) {
  try {
    return _convert(job);
  } on Exception {
    // A decoder failure on a damaged or hostile file is just "not a picture".
    return (null, 'unsupported_image');
  }
}

(Uint8List?, String?) _convert(_Job job) {
  // Read only the header first: dimensions are known before any pixel buffer
  // is allocated.
  final info = img.findDecoderForData(job.source)?.startDecode(job.source);
  if (info == null) return (null, 'unsupported_image');
  if (info.width * info.height > JpegAvatarProcessor.maxSourcePixels) {
    return (null, 'too_large');
  }

  final decoded = img.decodeImage(job.source);
  if (decoded == null) return (null, 'unsupported_image');

  // Pixels first (orientation), metadata never: encoding below starts from a
  // fresh image object so nothing but pixels can be written out.
  var image = _flattenOnWhite(img.bakeOrientation(decoded));
  image = _fit(image, job.maxSide);

  var quality = job.startQuality;
  for (var round = 0; round <= _maxShrinkRounds; round++) {
    while (quality >= _minQuality) {
      final bytes = img.encodeJpg(image, quality: quality);
      if (bytes.length <= job.maxBytes) {
        return (Uint8List.fromList(bytes), null);
      }
      quality -= _qualityStep;
    }
    quality = job.startQuality;
    image = img.copyResize(
      image,
      width: math.max(1, (image.width * _shrinkFactor).round()),
      interpolation: img.Interpolation.average,
    );
  }
  return (null, 'too_large');
}

/// A new image with the pixels of [source] over white and no metadata.
img.Image _flattenOnWhite(img.Image source) {
  final flat = img.Image(width: source.width, height: source.height)
    ..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(flat, source);
  return flat;
}

img.Image _fit(img.Image image, int maxSide) {
  if (math.max(image.width, image.height) <= maxSide) return image;
  return image.width >= image.height
      ? img.copyResize(
          image,
          width: maxSide,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          image,
          height: maxSide,
          interpolation: img.Interpolation.average,
        );
}
