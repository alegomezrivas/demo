import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/error/guarded_call.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/avatar_remote_data_source.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/avatar_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [AvatarRepository] that uploads the picture and refreshes the cached user.
class AvatarRepositoryImpl implements AvatarRepository {
  /// Creates the repository.
  const AvatarRepositoryImpl({
    required AvatarRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final AvatarRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, User>> uploadAvatar(Uint8List jpeg) {
    return guardedCall(() async {
      final current = await _local.readUser();
      if (current == null) throw const UnauthorizedException();

      await _remote.upload(jpeg);

      final updated = current.copyWith(hasAvatar: true);
      await _local.updateUser(updated);
      return updated.toEntity();
    });
  }
}
