import 'dart:async';

import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

/// Runs before every test file: registers mockito dummies for `Either` types
/// returned by mocked use cases and repositories.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  provideDummy<Either<Failure, User>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, User?>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, Unit>>(left(const UnexpectedFailure()));
  await testMain();
}
