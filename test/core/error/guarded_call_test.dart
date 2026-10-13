import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/error/guarded_call.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('guardedCall', () {
    test('wraps the result on the right', () async {
      expect(await guardedCall(() async => 42), right<Failure, int>(42));
    });

    test('maps AppExceptions to their failures', () async {
      final cases = <AppException, Failure>{
        const NetworkException(): const NetworkFailure(),
        const UnauthorizedException(): const UnauthorizedFailure(),
        const ServerException(code: 'boom'): const ServerFailure('boom'),
        const CacheException('x'): const CacheFailure('x'),
      };
      for (final entry in cases.entries) {
        final result = await guardedCall<int>(() async => throw entry.key);

        expect(result, left<Failure, int>(entry.value));
      }
    });

    test('hides unexpected exceptions behind UnexpectedFailure', () async {
      final result = await guardedCall<int>(
        () async => throw const FormatException('secret'),
      );

      expect(result, left<Failure, int>(const UnexpectedFailure()));
    });
  });
}
