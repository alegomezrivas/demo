import 'dart:typed_data';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/datasources/avatar_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 0xFF, 0xD9]);

  AvatarRemoteDataSourceImpl build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return AvatarRemoteDataSourceImpl(dio);
  }

  group('upload', () {
    test('puts the raw bytes as image/jpeg with the bearer allowed', () async {
      final source = build((_) => ResponseBody.fromString('', 204));

      await source.upload(jpeg);

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, AuthEndpoints.avatar);
      expect(request.data, jpeg);
      expect(request.contentType, 'image/jpeg');
      // It must carry (and be able to refresh) the bearer token.
      expect(request.extra.containsKey('skip_auth'), isFalse);
    });

    test('surfaces invalid pictures with the backend code', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'invalid_image'}, status: 422),
      );

      await expectLater(
        source.upload(jpeg),
        throwsA(
          isA<ServerException>().having((e) => e.code, 'code', 'invalid_image'),
        ),
      );
    });

    test('surfaces a too-large payload', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'payload_too_large'}, status: 413),
      );

      await expectLater(
        source.upload(jpeg),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'payload_too_large')
              .having((e) => e.statusCode, 'status', 413),
        ),
      );
    });

    test('maps 401 to UnauthorizedException', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'unauthorized'}, status: 401),
      );

      await expectLater(
        source.upload(jpeg),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('maps connection errors to NetworkException', () async {
      final source = build(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'down',
        ),
      );

      await expectLater(source.upload(jpeg), throwsA(isA<NetworkException>()));
    });
  });
}
