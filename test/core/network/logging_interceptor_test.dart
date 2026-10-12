import 'package:demo/core/network/logging_interceptor.dart';
import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late List<String> lines;
  late Dio dio;

  setUp(() {
    lines = [];
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..interceptors.add(LoggingInterceptor(ConsoleAppLogger(sink: lines.add)));
  });

  group('LoggingInterceptor', () {
    test('logs method, path and status of a successful call', () async {
      dio.httpClientAdapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({}));

      await dio.get<dynamic>('/tasks');

      expect(lines, ['[DEBUG] --> GET /tasks', '[DEBUG] <-- 200 GET /tasks']);
    });

    test('never logs query strings, headers or bodies', () async {
      dio.httpClientAdapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({}));

      await dio.post<dynamic>(
        '/login',
        queryParameters: {'email': 'ana@test.com'},
        data: {'password': 'hunter2'},
        options: Options(headers: {'Authorization': 'Bearer top-secret'}),
      );

      final output = lines.join('\n');
      expect(output, isNot(contains('ana@test.com')));
      expect(output, isNot(contains('hunter2')));
      expect(output, isNot(contains('top-secret')));
    });

    test('logs failures with their status code', () async {
      dio.httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({}, status: 500),
      );

      await expectLater(
        dio.get<dynamic>('/tasks'),
        throwsA(isA<DioException>()),
      );

      expect(lines.last, '[WARNING] <-- 500 GET /tasks');
    });
  });
}
