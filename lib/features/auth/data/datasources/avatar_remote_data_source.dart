import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_exception_mapper.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:dio/dio.dart';

/// Remote access to the profile picture; throws [AppException]s only.
abstract interface class AvatarRemoteDataSource {
  /// Uploads [jpeg] as the picture of the signed-in user.
  Future<void> upload(Uint8List jpeg);
}

/// [AvatarRemoteDataSource] backed by Dio.
class AvatarRemoteDataSourceImpl implements AvatarRemoteDataSource {
  /// Creates the data source.
  const AvatarRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<void> upload(Uint8List jpeg) async {
    try {
      await _dio.put<void>(
        AuthEndpoints.avatar,
        // Raw bytes (not JSON); a Uint8List is also safe to resend after a
        // token refresh, unlike a one-shot stream.
        data: jpeg,
        options: Options(
          contentType: 'image/jpeg',
          headers: {Headers.contentLengthHeader: jpeg.length},
        ),
      );
    } on DioException catch (error) {
      throw DioExceptionMapper.map(error);
    }
  }
}
