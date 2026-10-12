import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/features/tasks/data/datasources/tasks_endpoints.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';

/// In-memory fake of the tasks API for the mock Dio backend.
///
/// Supports search, filters, pagination, CRUD and statistics. Like the real
/// API it answers 401 when the request carries no bearer token.
class MockTasksBackend {
  /// Creates the backend seeded with [seedCount] tasks relative to [now].
  MockTasksBackend({DateTime Function()? now, int seedCount = 23})
    : _now = now ?? DateTime.now {
    final base = _now();
    for (var i = 0; i < seedCount; i++) {
      _tasks.add(
        _MockTask(
          id: 'task-${_nextId++}',
          title:
              _titles[i % _titles.length] +
              (i >= _titles.length ? ' #${i ~/ _titles.length + 1}' : ''),
          description: i.isEven ? 'Detalle de la tarea ${i + 1}' : '',
          priority: TaskPriority.values[i % 3].name,
          isDone: i % 4 == 0,
          createdAt: base.subtract(Duration(hours: seedCount - i)),
          dueDate: i % 3 == 0 ? null : base.add(Duration(days: (i % 9) - 3)),
        ),
      );
    }
  }

  static const List<String> _titles = [
    'Preparar la demo',
    'Revisar pull requests',
    'Escribir pruebas unitarias',
    'Actualizar dependencias',
    'Diseñar la pantalla de ajustes',
    'Configurar el pipeline',
    'Documentar la arquitectura',
    'Auditar la seguridad',
    'Optimizar el arranque',
    'Planificar el sprint',
  ];

  final DateTime Function() _now;
  final List<_MockTask> _tasks = [];
  int _nextId = 0;

  /// Routes to pass to the mock interceptor (stats before `:id`).
  List<MockRoute> get routes => [
    MockRoute(
      method: 'GET',
      pattern: TasksEndpoints.stats,
      handler: _guarded(_stats),
    ),
    MockRoute(
      method: 'GET',
      pattern: TasksEndpoints.tasks,
      handler: _guarded(_list),
    ),
    MockRoute(
      method: 'POST',
      pattern: TasksEndpoints.tasks,
      handler: _guarded(_create),
    ),
    MockRoute(
      method: 'GET',
      pattern: TasksEndpoints.taskPattern,
      handler: _guarded(_get),
    ),
    MockRoute(
      method: 'PUT',
      pattern: TasksEndpoints.taskPattern,
      handler: _guarded(_update),
    ),
    MockRoute(
      method: 'DELETE',
      pattern: TasksEndpoints.taskPattern,
      handler: _guarded(_delete),
    ),
  ];

  MockHandler _guarded(MockHandler handler) {
    return (request) {
      final auth = request.headers['Authorization'];
      if (auth is! String || !auth.startsWith('Bearer ')) {
        return const MockResponse(
          statusCode: 401,
          data: {'code': 'unauthorized'},
        );
      }
      return handler(request);
    };
  }

  MockResponse _list(MockRequest request) {
    final query = request.queryParameters;
    final page = _int(query['page'], 1).clamp(1, 1 << 20);
    final pageSize = _int(query['pageSize'], 10).clamp(1, 100);
    final search = (query['q'] as String? ?? '').toLowerCase();
    final status = query['status'];
    final priority = query['priority'];

    final matches = _tasks.where((task) {
      if (search.isNotEmpty &&
          !task.title.toLowerCase().contains(search) &&
          !task.description.toLowerCase().contains(search)) {
        return false;
      }
      if (status == 'done' && !task.isDone) {
        return false;
      }
      if (status == 'pending' && task.isDone) {
        return false;
      }
      return priority == null || task.priority == priority;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (page - 1) * pageSize;
    final items = start >= matches.length
        ? <_MockTask>[]
        : matches.skip(start).take(pageSize).toList();
    return MockResponse(
      data: {
        'items': items.map((t) => t.toJson()).toList(),
        'page': page,
        'pageSize': pageSize,
        'total': matches.length,
      },
    );
  }

  MockResponse _get(MockRequest request) {
    final task = _find(request.pathParameters['id']);
    return task == null ? _notFound : MockResponse(data: task.toJson());
  }

  MockResponse _create(MockRequest request) {
    final input = _validInput(request.data);
    if (input == null) return _invalid;
    final task = _MockTask(
      id: 'task-${_nextId++}',
      title: input.title,
      description: input.description,
      priority: input.priority,
      isDone: input.isDone,
      createdAt: _now(),
      dueDate: input.dueDate,
    );
    _tasks.add(task);
    return MockResponse(statusCode: 201, data: task.toJson());
  }

  MockResponse _update(MockRequest request) {
    final task = _find(request.pathParameters['id']);
    if (task == null) return _notFound;
    final input = _validInput(request.data);
    if (input == null) return _invalid;
    task
      ..title = input.title
      ..description = input.description
      ..priority = input.priority
      ..isDone = input.isDone
      ..dueDate = input.dueDate;
    return MockResponse(data: task.toJson());
  }

  MockResponse _delete(MockRequest request) {
    final task = _find(request.pathParameters['id']);
    if (task == null) return _notFound;
    _tasks.remove(task);
    return const MockResponse(statusCode: 204);
  }

  MockResponse _stats(MockRequest request) {
    final now = _now();
    final open = _tasks.where((t) => !t.isDone);
    return MockResponse(
      data: {
        'total': _tasks.length,
        'done': _tasks.where((t) => t.isDone).length,
        'overdue': open.where((t) => t.dueDate?.isBefore(now) ?? false).length,
        'highPriorityPending': open.where((t) => t.priority == 'high').length,
      },
    );
  }

  static const MockResponse _notFound = MockResponse(
    statusCode: 404,
    data: {'code': 'not_found'},
  );
  static const MockResponse _invalid = MockResponse(
    statusCode: 422,
    data: {'code': 'validation_error'},
  );

  _MockTask? _find(String? id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  int _int(Object? value, int fallback) =>
      value is String ? int.tryParse(value) ?? fallback : fallback;

  _Input? _validInput(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final title = data['title'];
    final description = data['description'];
    final priority = data['priority'];
    final isDone = data['isDone'];
    final due = data['dueDate'];
    if (title is! String || title.trim().isEmpty || title.length > 120) {
      return null;
    }
    if (description is! String || priority is! String || isDone is! bool) {
      return null;
    }
    if (!TaskPriority.values.any((p) => p.name == priority)) return null;
    final dueDate = due is String ? DateTime.tryParse(due) : null;
    if (due != null && dueDate == null) return null;
    return _Input(
      title: title.trim(),
      description: description,
      priority: priority,
      isDone: isDone,
      dueDate: dueDate,
    );
  }
}

class _Input {
  const _Input({
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.dueDate,
  });

  final String title;
  final String description;
  final String priority;
  final bool isDone;
  final DateTime? dueDate;
}

class _MockTask {
  _MockTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.createdAt,
    this.dueDate,
  });

  final String id;
  String title;
  String description;
  String priority;
  bool isDone;
  final DateTime createdAt;
  DateTime? dueDate;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority,
    'isDone': isDone,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'dueDate': dueDate?.toUtc().toIso8601String(),
  };
}
