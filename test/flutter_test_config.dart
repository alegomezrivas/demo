import 'dart:async';

import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs before every test file: registers mockito dummies for `Either` types
/// returned by mocked use cases and repositories.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  provideDummy<Either<Failure, User>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, User?>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, Unit>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, TaskItem>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, PagedResult<TaskItem>>>(
    left(const UnexpectedFailure()),
  );
  provideDummy<Either<Failure, TaskStats>>(left(const UnexpectedFailure()));
  provideDummy<Either<Failure, AppSettings>>(left(const UnexpectedFailure()));
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
