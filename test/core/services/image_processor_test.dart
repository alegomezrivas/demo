import 'dart:math';
import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/services/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const processor = JpegAvatarProcessor();

  Uint8List jpeg(img.Image image) =>
      Uint8List.fromList(img.encodeJpg(image, quality: 95));

  img.Image solid(int width, int height) =>
      img.Image(width: width, height: height)
        ..clear(img.ColorRgb8(30, 120, 220));

  /// True when the JPEG carries an APP1 (EXIF / XMP) segment.
  bool hasApp1(Uint8List bytes) {
    for (var i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xE1) return true;
    }
    return false;
  }

  Future<img.Image> run(Uint8List source, [ImageProcessor? p]) async {
    final out = await (p ?? processor).toAvatarJpeg(source);
    final decoded = img.decodeJpg(out);
    expect(decoded, isNotNull);
    return decoded!;
  }

  group('JpegAvatarProcessor sizing', () {
    test('downscales a wide picture to the maximum side', () async {
      final out = await run(jpeg(solid(2000, 1000)));

      expect(out.width, 512);
      expect(out.height, 256);
    });

    test('downscales a tall picture to the maximum side', () async {
      final out = await run(jpeg(solid(900, 1800)));

      expect(out.height, 512);
      expect(out.width, 256);
    });

    test('never upscales a small picture', () async {
      final out = await run(jpeg(solid(100, 80)));

      expect((out.width, out.height), (100, 80));
    });

    test('honors a custom maximum side', () async {
      final out = await run(
        jpeg(solid(1000, 1000)),
        const JpegAvatarProcessor(maxSide: 128),
      );

      expect(out.width, 128);
    });

    test('always returns a JPEG', () async {
      final png = Uint8List.fromList(img.encodePng(solid(64, 64)));

      final out = await processor.toAvatarJpeg(png);

      expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    });
  });

  group('JpegAvatarProcessor metadata', () {
    test('removes EXIF data', () async {
      final image = solid(200, 200);
      image.exif.imageIfd.make = 'SecretCamera';
      final source = jpeg(image);
      expect(hasApp1(source), isTrue, reason: 'fixture must carry EXIF');

      final out = await processor.toAvatarJpeg(source);

      expect(hasApp1(out), isFalse);
      expect(String.fromCharCodes(out).contains('SecretCamera'), isFalse);
      expect(img.decodeJpg(out)!.exif.isEmpty, isTrue);
    });

    test(
      'applies the EXIF orientation to the pixels before dropping it',
      () async {
        final image = solid(40, 20);
        image.exif.imageIfd.orientation = 6;

        final out = await run(jpeg(image));

        expect((out.width, out.height), (20, 40));
      },
    );
  });

  group('JpegAvatarProcessor pixels', () {
    test('flattens transparency onto white instead of black', () async {
      final transparent = img.Image(width: 32, height: 32, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));
      final png = Uint8List.fromList(img.encodePng(transparent));

      final out = await run(png);

      final pixel = out.getPixel(16, 16);
      expect(pixel.r, greaterThan(240));
      expect(pixel.g, greaterThan(240));
      expect(pixel.b, greaterThan(240));
    });
  });

  group('JpegAvatarProcessor size limit', () {
    img.Image noise(int side) {
      final random = Random(7);
      final image = img.Image(width: side, height: side);
      for (final pixel in image) {
        pixel
          ..r = random.nextInt(256)
          ..g = random.nextInt(256)
          ..b = random.nextInt(256);
      }
      return image;
    }

    test('lowers the quality until the result fits', () async {
      final source = jpeg(noise(600));
      const limit = 60 * 1024;
      final defaultSize = (await const JpegAvatarProcessor().toAvatarJpeg(
        source,
      )).length;
      expect(defaultSize, greaterThan(limit), reason: 'fixture must be heavy');

      final out = await const JpegAvatarProcessor(
        maxBytes: limit,
      ).toAvatarJpeg(source);

      expect(out.length, lessThanOrEqualTo(limit));
      expect(img.decodeJpg(out), isNotNull);
    });

    test('rejects a picture that cannot be made small enough', () async {
      await expectLater(
        const JpegAvatarProcessor(maxBytes: 100).toAvatarJpeg(jpeg(noise(300))),
        throwsA(
          isA<InvalidImageException>().having(
            (e) => e.code,
            'code',
            'too_large',
          ),
        ),
      );
    });

    test('keeps results under the default 200 KB limit', () async {
      final out = await processor.toAvatarJpeg(jpeg(noise(900)));

      expect(out.length, lessThanOrEqualTo(200 * 1024));
    });
  });

  group('JpegAvatarProcessor invalid input', () {
    test('rejects bytes that are not a picture', () async {
      await expectLater(
        processor.toAvatarJpeg(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(
          isA<InvalidImageException>().having(
            (e) => e.code,
            'code',
            'unsupported_image',
          ),
        ),
      );
    });

    test('rejects empty input', () async {
      await expectLater(
        processor.toAvatarJpeg(Uint8List(0)),
        throwsA(isA<InvalidImageException>()),
      );
    });

    test('rejects text pretending to be a picture', () async {
      await expectLater(
        processor.toAvatarJpeg(Uint8List.fromList('<svg></svg>'.codeUnits)),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });
}
