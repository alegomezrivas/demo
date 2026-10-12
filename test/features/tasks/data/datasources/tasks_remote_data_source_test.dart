import 'package:demo/core/error/exceptions.dart';
import 'package:demo/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:demo/features/tasks/data/models/task_input_dto.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_adapter.dart';

void main() {
  final taskJson = {
    'id': 't1',
    'title': 'A',
    'description': '',
    'priority': 'low',
    'isDone': false,
    'createdAt': '2026-01-10T00:00:00.000Z',
    'dueDate': null,
  };
  const input = TaskInputDto(
    title: 'A',
    description: '',
    priority: 'low',
    isDone: false,
  );

  late FakeHttpAdapter adapter;

  TasksRemoteDataSourceImpl build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return TasksRemoteDataSourceImpl(dio);
  }

  group('getTasks', () {
    test('sends only the active filters as query parameters', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({
          'items': [taskJson],
          'page': 2,
          'pageSize': 5,
          'total': 9,
        }),
      );

      final page = await source.getTasks(
        const TaskQuery(
          page: 2,
          pageSize: 5,
          search: 'buy',
          status: TaskStatusFilter.pending,
          priority: TaskPriority.high,
        ),
      );

      expect(page.total, 9);
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/tasks');
      expect(request.queryParameters, {
        'page': 2,
        'pageSize': 5,
        'q': 'buy',
        'status': 'pending',
        'priority': 'high',
      });
    });

    test('omits empty search and "all" status', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({
          'items': <dynamic>[],
          'page': 1,
          'pageSize': 10,
          'total': 0,
        }),
      );

      await source.getTasks(const TaskQuery());

      expect(adapter.requests.single.queryParameters, {
        'page': 1,
        'pageSize': 10,
      });
    });
  });

  group('single task endpoints', () {
    test('getTask encodes the id in the path', () async {
      final source = build((_) => FakeHttpAdapter.json(taskJson));

      await source.getTask('a/b');

      expect(adapter.requests.single.uri.path, '/tasks/a%2Fb');
    });

    test('createTask posts the input and parses the result', () async {
      final source = build((_) => FakeHttpAdapter.json(taskJson, status: 201));

      final dto = await source.createTask(input);

      expect(dto.id, 't1');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, input.toJson());
    });

    test('updateTask puts the input to the task path', () async {
      final source = build((_) => FakeHttpAdapter.json(taskJson));

      await source.updateTask('t1', input);

      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.path, '/tasks/t1');
    });

    test('deleteTask completes on an empty 204 response', () async {
      final source = build((_) => ResponseBody.fromString('', 204));

      await expectLater(source.deleteTask('t1'), completes);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('getStats parses the statistics', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({
          'total': 3,
          'done': 1,
          'overdue': 0,
          'highPriorityPending': 1,
        }),
      );

      expect((await source.getStats()).total, 3);
      expect(adapter.requests.single.path, '/tasks/stats');
    });
  });

  group('errors', () {
    test('maps HTTP errors to typed exceptions', () async {
      var status = 401;
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'nope'}, status: status),
      );

      await expectLater(
        source.getTask('t1'),
        throwsA(isA<UnauthorizedException>()),
      );
      status = 404;
      await expectLater(
        source.getTask('t1'),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });

    test('rejects empty and malformed bodies', () async {
      var empty = true;
      final source = build(
        (_) => empty
            ? ResponseBody.fromString('', 200)
            : FakeHttpAdapter.json({'id': 1}),
      );

      await expectLater(
        source.getTask('t1'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'empty_response',
          ),
        ),
      );
      empty = false;
      await expectLater(
        source.getTask('t1'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    });
  });
}
