import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/data/repositories/avatar_repository_impl.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockAvatarRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AvatarRepositoryImpl repository;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xFF, 0xD9]);

  const stored = UserDto(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );

  setUp(() {
    remote = MockAvatarRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AvatarRepositoryImpl(remote: remote, local: local);
  });

  group('uploadAvatar', () {
    test('uploads, flags the cached user and returns it', () async {
      when(local.readUser()).thenAnswer((_) async => stored);

      final result = await repository.uploadAvatar(jpeg);

      final expected = stored.copyWith(hasAvatar: true);
      expect(result, right<Failure, User>(expected.toEntity()));
      verifyInOrder([remote.upload(jpeg), local.updateUser(expected)]);
    });

    test('does not touch the cache when the upload fails', () async {
      when(local.readUser()).thenAnswer((_) async => stored);
      when(remote.upload(any)).thenThrow(
        const ServerException(code: 'invalid_image', statusCode: 422),
      );

      final result = await repository.uploadAvatar(jpeg);

      expect(result, left<Failure, User>(const ServerFailure('invalid_image')));
      verifyNever(local.updateUser(any));
    });

    test('is unauthorized without a stored session', () async {
      when(local.readUser()).thenAnswer((_) async => null);

      final result = await repository.uploadAvatar(jpeg);

      expect(result, left<Failure, User>(const UnauthorizedFailure()));
      verifyNever(remote.upload(any));
    });

    test('reports connectivity problems', () async {
      when(local.readUser()).thenAnswer((_) async => stored);
      when(remote.upload(any)).thenThrow(const NetworkException());

      expect(
        await repository.uploadAvatar(jpeg),
        left<Failure, User>(const NetworkFailure()),
      );
    });

    test('reports storage failures while saving the flag', () async {
      when(local.readUser()).thenAnswer((_) async => stored);
      when(local.updateUser(any)).thenThrow(const CacheException());

      expect(
        await repository.uploadAvatar(jpeg),
        left<Failure, User>(const CacheFailure()),
      );
    });
  });
}
