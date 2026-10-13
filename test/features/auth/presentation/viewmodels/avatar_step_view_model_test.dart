import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:demo/features/auth/presentation/viewmodels/avatar_step_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../views/sign_up_harness.dart';

void main() {
  late SignUpHarness harness;
  late MockImageSourceService source;
  late MockImageProcessor processor;
  late AvatarStepViewModel viewModel;

  final picked = Uint8List.fromList([1, 2, 3]);
  final cropped = Uint8List.fromList([4, 5, 6]);
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xFF, 0xD9]);

  setUp(() {
    harness = SignUpHarness();
    source = MockImageSourceService();
    processor = MockImageProcessor();
    viewModel = AvatarStepViewModel(
      source: source,
      processor: processor,
      flow: harness.flow,
    );
    when(source.pick(any)).thenAnswer((_) async => picked);
    when(processor.toAvatarJpeg(any)).thenAnswer((_) async => jpeg);
  });

  tearDown(() {
    viewModel.dispose();
    harness.flow.dispose();
  });

  group('pick', () {
    test('keeps the chosen picture as original and preview', () async {
      await viewModel.pick(PhotoSource.gallery);

      expect(viewModel.original, picked);
      expect(viewModel.preview, picked);
      expect(viewModel.hasPicture, isTrue);
      expect(viewModel.issue, AvatarIssue.none);
      verify(source.pick(PhotoSource.gallery)).called(1);
    });

    test('cancelling changes nothing', () async {
      when(source.pick(any)).thenAnswer((_) async => null);

      await viewModel.pick(PhotoSource.camera);

      expect(viewModel.hasPicture, isFalse);
      expect(viewModel.issue, AvatarIssue.none);
    });

    test('cancelling keeps a picture chosen before', () async {
      await viewModel.pick(PhotoSource.gallery);
      when(source.pick(any)).thenAnswer((_) async => null);

      await viewModel.pick(PhotoSource.gallery);

      expect(viewModel.preview, picked);
    });

    test('a denied library permission is reported', () async {
      when(
        source.pick(any),
      ).thenThrow(const PermissionDeniedException('photo_permission_denied'));

      await viewModel.pick(PhotoSource.gallery);

      expect(viewModel.issue, AvatarIssue.galleryDenied);
      expect(viewModel.hasPicture, isFalse);
    });

    test('a denied camera permission is reported', () async {
      when(
        source.pick(any),
      ).thenThrow(const PermissionDeniedException('camera_permission_denied'));

      await viewModel.pick(PhotoSource.camera);

      expect(viewModel.issue, AvatarIssue.cameraDenied);
    });

    test('a file that is not a picture is reported', () async {
      when(
        source.pick(any),
      ).thenThrow(const InvalidImageException('pick_failed'));

      await viewModel.pick(PhotoSource.gallery);

      expect(viewModel.issue, AvatarIssue.invalidImage);
    });

    test('a later success clears the issue', () async {
      when(
        source.pick(any),
      ).thenThrow(const PermissionDeniedException('camera_permission_denied'));
      await viewModel.pick(PhotoSource.camera);

      when(source.pick(any)).thenAnswer((_) async => picked);
      await viewModel.pick(PhotoSource.gallery);

      expect(viewModel.issue, AvatarIssue.none);
    });

    test('notifies listeners', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.pick(PhotoSource.gallery);

      expect(notified, 1);
    });
  });

  group('applyCrop', () {
    test('replaces the preview but keeps the original to re-crop', () async {
      await viewModel.pick(PhotoSource.gallery);

      viewModel.applyCrop(cropped);

      expect(viewModel.preview, cropped);
      expect(viewModel.original, picked);
    });
  });

  group('submit', () {
    test('does nothing without a picture', () async {
      await viewModel.submit();

      verifyZeroInteractions(processor);
      verifyZeroInteractions(harness.uploadAvatar);
    });

    test('compresses the preview and uploads the JPEG', () async {
      await viewModel.pick(PhotoSource.gallery);
      viewModel.applyCrop(cropped);

      await viewModel.submit();

      verify(processor.toAvatarJpeg(cropped)).called(1);
      verify(harness.uploadAvatar(jpeg)).called(1);
      expect(viewModel.isWorking, isFalse);
    });

    test('moves on when the upload works', () async {
      await viewModel.pick(PhotoSource.gallery);

      await viewModel.submit();

      verify(harness.navigation.go('/signup/done')).called(1);
    });

    test('is working while it prepares and uploads', () async {
      await viewModel.pick(PhotoSource.gallery);
      final states = <bool>[];
      viewModel.addListener(() => states.add(viewModel.isWorking));

      await viewModel.submit();

      expect(states.first, isTrue);
      expect(states.last, isFalse);
    });

    test('a picture that cannot be compressed is reported, not sent', () async {
      when(
        processor.toAvatarJpeg(any),
      ).thenThrow(const InvalidImageException('too_large'));
      await viewModel.pick(PhotoSource.gallery);

      await viewModel.submit();

      expect(viewModel.issue, AvatarIssue.tooLarge);
      verifyZeroInteractions(harness.uploadAvatar);
      expect(viewModel.isWorking, isFalse);
    });

    test('an unreadable picture is reported', () async {
      when(
        processor.toAvatarJpeg(any),
      ).thenThrow(const InvalidImageException('unsupported_image'));
      await viewModel.pick(PhotoSource.gallery);

      await viewModel.submit();

      expect(viewModel.issue, AvatarIssue.invalidImage);
    });

    test(
      'a server rejection stays on the step with the flow failure',
      () async {
        when(harness.uploadAvatar(any)).thenAnswer(
          (_) async => left(const ServerFailure('invalid_image')),
        );
        await viewModel.pick(PhotoSource.gallery);

        await viewModel.submit();

        expect(harness.flow.failure, const ServerFailure('invalid_image'));
        verifyNever(harness.navigation.go(any));
        expect(viewModel.hasPicture, isTrue);
      },
    );

    test('ignores picking while it is uploading', () async {
      await viewModel.pick(PhotoSource.gallery);
      clearInteractions(source);

      final upload = viewModel.submit();
      await viewModel.pick(PhotoSource.camera);
      await upload;

      verifyNever(source.pick(any));
    });
  });

  group('skip', () {
    test('continues without uploading', () {
      viewModel.skip();

      verifyZeroInteractions(harness.uploadAvatar);
      verify(harness.navigation.go('/signup/done')).called(1);
    });
  });
}
