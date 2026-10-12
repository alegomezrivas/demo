import 'dart:io';

import 'package:demo/core/error/exceptions.dart';
import 'package:dio/dio.dart';

/// Converts [DioException]s into typed [AppException]s for datasources.
abstract final class DioExceptionMapper {
  /// Maps [error] without leaking URLs, headers or response bodies.
  static AppException map(DioException error) {
    final inner = error.error;
    if (inner is AppException) return inner;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError => const NetworkException(),
      DioExceptionType.badCertificate => const NetworkException(
        'bad_certificate',
      ),
      DioExceptionType.cancel => const NetworkException('cancelled'),
      DioExceptionType.badResponse => _fromResponse(error.response),
      DioExceptionType.unknown =>
        inner is SocketException || inner is HandshakeException
            ? const NetworkException()
            : const ServerException(code: 'unknown'),
    };
  }

  static AppException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    if (status == 401) return const UnauthorizedException();
    final data = response?.data;
    final code = data is Map<String, dynamic> && data['code'] is String
        ? data['code'] as String
        : 'http_${status ?? 'unknown'}';
    return ServerException(code: code, statusCode: status);
  }
}
