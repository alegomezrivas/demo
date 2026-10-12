import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/features/tasks/data/datasources/mock_tasks_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/task_fixtures.dart';

void main() {
  late Dio dio;
  late DateTime clock;

  setUp(() {
    clock = fixtureNow;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..interceptors.add(
        MockApiInterceptor(
          routes: MockTasksBackend(now: () => clock).routes,
          settings: const MockApiSettings(latency: Duration.zero),
        ),
      );
  });

  final auth = Options(headers: {'Authorization': 'Bearer token'});

  Future<Map<String, dynamic>> list(Map<String, dynamic> query) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: query,
      options: auth,
    );
    return response.data ?? {};
  }

  List<Map<String, dynamic>> items(Map<String, dynamic> page) =>
      (page['items'] as List<dynamic>).cast<Map<String, dynamic>>();

  TypeMatcher<DioException> status(int code) =>
      isA<DioException>().having((e) => e.response?.statusCode, 'status', code);

  Map<String, Object?> body({
    String title = 'New task',
    String priority = 'low',
  }) => {
    'title': title,
    'description': 'd',
    'priority': priority,
    'isDone': false,
    'dueDate': null,
  };

  group('authentication', () {
    test('rejects requests without a bearer token', () async {
      await expectLater(dio.get<dynamic>('/tasks'), throwsA(status(401)));
      await expectLater(dio.get<dynamic>('/tasks/stats'), throwsA(status(401)));
      await expectLater(
        dio.post<dynamic>('/tasks', data: body()),
        throwsA(status(401)),
      );
    });
  });

  group('listing', () {
    test('paginates newest first and reports totals', () async {
      final first = await list({'page': '1', 'pageSize': '10'});
      final third = await list({'page': '3', 'pageSize': '10'});

      expect(first['total'], 23);
      expect(items(first), hasLength(10));
      expect(items(third), hasLength(3));
      final dates = items(first).map((t) => t['createdAt'] as String).toList();
      final sorted = [...dates]..sort((a, b) => b.compareTo(a));
      expect(dates, orderedEquals(sorted));
    });

    test('returns an empty page beyond the last one', () async {
      expect(items(await list({'page': '9', 'pageSize': '10'})), isEmpty);
    });

    test('searches title and description case-insensitively', () async {
      final page = await list({'q': 'SEGURIDAD'});

      expect(items(page), isNotEmpty);
      expect(
        items(page).every(
          (t) => (t['title'] as String).toLowerCase().contains('seguridad'),
        ),
        isTrue,
      );
    });

    test('filters by status and priority', () async {
      final done = await list({'status': 'done', 'pageSize': '50'});
      final pendingHigh = await list({
        'status': 'pending',
        'priority': 'high',
        'pageSize': '50',
      });

      expect(items(done).every((t) => t['isDone'] == true), isTrue);
      expect(
        items(
          pendingHigh,
        ).every((t) => t['isDone'] == false && t['priority'] == 'high'),
        isTrue,
      );
      final pending = await list({'status': 'pending'});
      final all = await list({});
      expect((done['total'] as int) + (pending['total'] as int), all['total']);
    });

    test('falls back to defaults for invalid pagination values', () async {
      final page = await list({'page': 'abc', 'pageSize': '-5'});

      expect(page['page'], 1);
      expect(page['pageSize'], 1);
    });
  });

  group('CRUD', () {
    test('creates a task and finds it first in the listing', () async {
      clock = clock.add(const Duration(days: 1));

      final created = await dio.post<Map<String, dynamic>>(
        '/tasks',
        data: body(title: '  Brand new '),
        options: auth,
      );

      expect(created.statusCode, 201);
      expect(created.data?['title'], 'Brand new');
      final first = items(await list({}));
      expect(first.first['id'], created.data?['id']);
    });

    test('rejects invalid input with 422', () async {
      for (final data in [
        body(title: ' '),
        body(title: 'a' * 121),
        body(priority: 'urgent'),
        {'title': 'x'},
      ]) {
        await expectLater(
          dio.post<dynamic>('/tasks', data: data, options: auth),
          throwsA(status(422)),
        );
      }
      await expectLater(
        dio.post<dynamic>('/tasks', data: 'oops', options: auth),
        throwsA(status(422)),
      );
    });

    test('reads, updates and deletes a task', () async {
      final id = items(await list({})).first['id'] as String;

      final fetched = await dio.get<Map<String, dynamic>>(
        '/tasks/$id',
        options: auth,
      );
      expect(fetched.data?['id'], id);

      final updated = await dio.put<Map<String, dynamic>>(
        '/tasks/$id',
        data: {
          ...body(title: 'Edited'),
          'isDone': true,
        },
        options: auth,
      );
      expect(updated.data?['title'], 'Edited');
      expect(updated.data?['isDone'], true);

      final deleted = await dio.delete<dynamic>('/tasks/$id', options: auth);
      expect(deleted.statusCode, 204);
      await expectLater(
        dio.get<dynamic>('/tasks/$id', options: auth),
        throwsA(status(404)),
      );
    });

    test('answers 404 when updating or deleting unknown tasks', () async {
      await expectLater(
        dio.put<dynamic>('/tasks/ghost', data: body(), options: auth),
        throwsA(status(404)),
      );
      await expectLater(
        dio.delete<dynamic>('/tasks/ghost', options: auth),
        throwsA(status(404)),
      );
    });
  });

  group('statistics', () {
    test('counts tasks and reacts to changes', () async {
      Future<Map<String, dynamic>> stats() async =>
          (await dio.get<Map<String, dynamic>>(
            '/tasks/stats',
            options: auth,
          )).data ??
          {};

      final before = await stats();
      await dio.post<dynamic>(
        '/tasks',
        data: {...body(priority: 'high')},
        options: auth,
      );
      final after = await stats();

      expect(before['total'], 23);
      expect(after['total'], 24);
      expect(
        after['highPriorityPending'],
        (before['highPriorityPending'] as int) + 1,
      );
      expect(after['done'], before['done']);
    });

    test('counts overdue open tasks using the clock', () async {
      Future<int> overdue() async =>
          (await dio.get<Map<String, dynamic>>(
                '/tasks/stats',
                options: auth,
              )).data?['overdue']
              as int;

      final today = await overdue();
      clock = clock.add(const Duration(days: 30));

      expect(await overdue(), greaterThan(today));
    });
  });
}
