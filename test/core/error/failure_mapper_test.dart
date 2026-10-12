import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failure_mapper.dart';
import 'package:demo/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureMapper.fromError', () {
    test('maps every AppException to its failure keeping the code', () {
      expect(
        FailureMapper.fromError(const ServerException(code: 'boom')),
        const ServerFailure('boom'),
      );
      expect(
        FailureMapper.fromError(const NetworkException('offline')),
        const NetworkFailure('offline'),
      );
      expect(
        FailureMapper.fromError(const UnauthorizedException()),
        const UnauthorizedFailure(),
      );
      expect(
        FailureMapper.fromError(const CacheException()),
        const CacheFailure(),
      );
      expect(
        FailureMapper.fromError(const ValidationException('bad')),
        const ValidationFailure('bad'),
      );
    });

    test('hides unknown errors behind UnexpectedFailure', () {
      final failure = FailureMapper.fromError(StateError('secret details'));

      expect(failure, const UnexpectedFailure());
      expect(failure.code, isNot(contains('secret')));
    });
  });

  group('Failure equality', () {
    test('compares by type and code', () {
      expect(const ServerFailure('a'), const ServerFailure('a'));
      expect(const ServerFailure('a'), isNot(const NetworkFailure('a')));
      expect(const ServerFailure('a'), isNot(const ServerFailure('b')));
      expect(
        const ServerFailure('a').hashCode,
        const ServerFailure('a').hashCode,
      );
    });

    test('toString exposes the code only', () {
      expect(const CacheFailure('x').toString(), 'Failure(x)');
      expect(const CacheException('x').toString(), 'AppException(x)');
    });
  });
}
