import 'dart:typed_data';

import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/avatar_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// Uploads the profile picture, which must already be a small JPEG.
class UploadAvatarUseCase implements UseCase<User, Uint8List> {
  /// Creates the use case.
  const UploadAvatarUseCase(this._repository);

  final AvatarRepository _repository;

  @override
  Future<Either<Failure, User>> call(Uint8List jpeg) async {
    if (jpeg.isEmpty) return left(const ValidationFailure('invalid_image'));
    if (jpeg.length > AuthRules.maxAvatarBytes) {
      return left(const ValidationFailure('image_too_large'));
    }
    return _repository.uploadAvatar(jpeg);
  }
}
