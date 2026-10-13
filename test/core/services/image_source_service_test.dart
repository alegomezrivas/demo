import 'dart:io';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockImagePicker picker;
  late ImagePickerSourceService service;

  setUp(() {
    picker = MockImagePicker();
    service = ImagePickerSourceService(picker);
  });

  void stubPick(Future<XFile?> Function() answer) {
    when(
      picker.pickImage(
        source: anyNamed('source'),
        maxWidth: anyNamed('maxWidth'),
        maxHeight: anyNamed('maxHeight'),
        imageQuality: anyNamed('imageQuality'),
        preferredCameraDevice: anyNamed('preferredCameraDevice'),
        requestFullMetadata: anyNamed('requestFullMetadata'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('ImagePickerSourceService', () {
    test('returns the bytes of the picked picture', () async {
      stubPick(() async => XFile.fromData(Uint8List.fromList([1, 2, 3])));

      expect(await service.pick(PhotoSource.gallery), [1, 2, 3]);
    });

    test('returns null when the user cancels', () async {
      stubPick(() async => null);

      expect(await service.pick(PhotoSource.camera), isNull);
    });

    test('maps the sources and bounds the picked size', () async {
      stubPick(() async => null);

      await service.pick(PhotoSource.gallery);
      await service.pick(PhotoSource.camera);

      final calls = verifyInOrder([
        picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: ImagePickerSourceService.maxPickedSide,
          maxHeight: ImagePickerSourceService.maxPickedSide,
          requestFullMetadata: false,
        ),
        picker.pickImage(
          source: ImageSource.camera,
          maxWidth: ImagePickerSourceService.maxPickedSide,
          maxHeight: ImagePickerSourceService.maxPickedSide,
          requestFullMetadata: false,
        ),
      ]);
      expect(calls, isNotNull);
    });

    test('reports a denied photo library permission', () async {
      stubPick(
        () async => throw PlatformException(code: 'photo_access_denied'),
      );

      await expectLater(
        service.pick(PhotoSource.gallery),
        throwsA(
          isA<PermissionDeniedException>().having(
            (e) => e.code,
            'code',
            'photo_permission_denied',
          ),
        ),
      );
    });

    test('reports a denied camera permission', () async {
      stubPick(
        () async => throw PlatformException(code: 'camera_access_denied'),
      );

      await expectLater(
        service.pick(PhotoSource.camera),
        throwsA(
          isA<PermissionDeniedException>().having(
            (e) => e.code,
            'code',
            'camera_permission_denied',
          ),
        ),
      );
    });

    test('hides any other platform error behind a generic exception', () async {
      stubPick(
        () async => throw PlatformException(
          code: 'weird',
          message: '/private/path/secret.jpg',
        ),
      );

      await expectLater(
        service.pick(PhotoSource.gallery),
        throwsA(
          isA<InvalidImageException>().having(
            (e) => e.code,
            'code',
            'pick_failed',
          ),
        ),
      );
    });
  });

  group('ImagePickerSourceService unreadable files', () {
    test('a file that cannot be read becomes an invalid picture', () async {
      stubPick(() async => _UnreadableFile());

      await expectLater(
        service.pick(PhotoSource.gallery),
        throwsA(
          isA<InvalidImageException>().having(
            (e) => e.code,
            'code',
            'pick_failed',
          ),
        ),
      );
    });
  });
}

/// A picked file whose bytes cannot be read.
class _UnreadableFile extends XFile {
  _UnreadableFile() : super('/missing/picture.jpg');

  @override
  Future<Uint8List> readAsBytes() async =>
      throw const FileSystemException('cannot read');
}
