import 'dart:io';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_exception_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/x');

  DioException error(
    DioExceptionType type, {
    Response<dynamic>? response,
    Object? inner,
  }) => DioException(
    requestOptions: request,
    type: type,
    response: response,
    error: inner,
  );

  Response<dynamic> response(int status, [Object? data]) => Response<dynamic>(
    requestOptions: request,
    statusCode: status,
    data: data,
  );

  group('DioExceptionMapper.map', () {
    test('returns an embedded AppException untouched', () {
      const inner = NetworkException('insecure_connection');

      final result = DioExceptionMapper.map(
        error(DioExceptionType.connectionError, inner: inner),
      );

      expect(result, same(inner));
    });

    test('maps timeouts and connection errors to NetworkException', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(DioExceptionMapper.map(error(type)), isA<NetworkException>());
      }
    });

    test('maps bad certificates and cancellations with specific codes', () {
      expect(
        DioExceptionMapper.map(error(DioExceptionType.badCertificate)).code,
        'bad_certificate',
      );
      expect(
        DioExceptionMapper.map(error(DioExceptionType.cancel)).code,
        'cancelled',
      );
    });

    test('maps 401 to UnauthorizedException', () {
      final result = DioExceptionMapper.map(
        error(DioExceptionType.badResponse, response: response(401)),
      );

      expect(result, isA<UnauthorizedException>());
    });

    test('maps other statuses to ServerException using the body code', () {
      final result = DioExceptionMapper.map(
        error(
          DioExceptionType.badResponse,
          response: response(422, {'code': 'email_taken'}),
        ),
      ) as ServerException;

      expect(result.code, 'email_taken');
      expect(result.statusCode, 422);
    });

    test('falls back to an http_<status> code without a body code', () {
      final result = DioExceptionMapper.map(
        error(DioExceptionType.badResponse, response: response(500, 'oops')),
      ) as ServerException;

      expect(result.code, 'http_500');
    });

    test('maps socket and handshake failures to NetworkException', () {
      expect(
        DioExceptionMapper.map(
          error(DioExceptionType.unknown, inner: const SocketException('down')),
        ),
        isA<NetworkException>(),
      );
      expect(
        DioExceptionMapper.map(
          error(
            DioExceptionType.unknown,
            inner: const HandshakeException('tls'),
          ),
        ),
        isA<NetworkException>(),
      );
    });

    test('maps anything else to a generic ServerException', () {
      final result = DioExceptionMapper.map(
        error(DioExceptionType.unknown, inner: StateError('x')),
      );

      expect(result, isA<ServerException>());
      expect(result.code, 'unknown');
    });
  });
}
