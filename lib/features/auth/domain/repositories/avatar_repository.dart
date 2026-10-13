import 'dart:typed_data';

import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for the profile picture of the signed-in user.
abstract interface class AvatarRepository {
  /// Uploads [jpeg] and returns the user with the picture flag updated.
  Future<Either<Failure, User>> uploadAvatar(Uint8List jpeg);
}
