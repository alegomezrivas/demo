import 'package:demo/features/tasks/data/models/task_dto.dart';
import 'package:demo/features/tasks/data/models/task_input_dto.dart';
import 'package:demo/features/tasks/data/models/task_page_dto.dart';
import 'package:demo/features/tasks/data/models/task_stats_dto.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/task_fixtures.dart';

void main() {
  final json = {
    'id': 't1',
    'title': 'Write tests',
    'description': 'details',
    'priority': 'high',
    'isDone': true,
    'createdAt': '2026-01-10T00:00:00.000Z',
    'dueDate': '2026-01-20T00:00:00.000Z',
  };

  group('TaskDto', () {
    test('parses the wire format and maps to the entity', () {
      final task = TaskDto.fromJson(json).toEntity();

      expect(task.id, 't1');
      expect(task.priority, TaskPriority.high);
      expect(task.isDone, isTrue);
      expect(task.dueDate, DateTime.utc(2026, 1, 20));
      expect(task.createdAt, DateTime.utc(2026, 1, 10));
    });

    test('handles a missing deadline and unknown priorities', () {
      final task = TaskDto.fromJson({
        ...json,
        'dueDate': null,
        'priority': 'weird',
      }).toEntity();

      expect(task.dueDate, isNull);
      expect(task.priority, TaskPriority.medium);
    });

    test('throws on malformed dates and missing fields', () {
      expect(
        () => TaskDto.fromJson({...json, 'createdAt': 'nope'}).toEntity(),
        throwsFormatException,
      );
      expect(() => TaskDto.fromJson({'id': 'x'}), throwsA(isA<TypeError>()));
    });
  });

  group('TaskInputDto', () {
    test('builds from a draft using the provided sanitized text', () {
      final dto = TaskInputDto.fromDraft(
        TaskDraft(
          title: 'raw',
          priority: TaskPriority.low,
          dueDate: DateTime.utc(2026, 2),
        ),
        title: 'clean',
        description: 'desc',
      );

      expect(dto.toJson(), {
        'title': 'clean',
        'description': 'desc',
        'priority': 'low',
        'isDone': false,
        'dueDate': '2026-02-01T00:00:00.000Z',
      });
    });

    test('builds from an existing item keeping state', () {
      final dto = TaskInputDto.fromItem(
        buildTask(isDone: true, priority: TaskPriority.high),
        title: 't',
        description: '',
      );

      expect(dto.isDone, isTrue);
      expect(dto.priority, 'high');
      expect(dto.dueDate, isNull);
    });

    test('parses back from JSON', () {
      expect(
        TaskInputDto.fromJson({
          'title': 'a',
          'description': '',
          'priority': 'low',
          'isDone': false,
        }).title,
        'a',
      );
    });
  });

  group('TaskPageDto and TaskStatsDto', () {
    test('maps a page to a PagedResult', () {
      final page = TaskPageDto.fromJson({
        'items': [json],
        'page': 2,
        'pageSize': 1,
        'total': 5,
      }).toEntity();

      expect(page.items.single.id, 't1');
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
    });

    test('maps statistics', () {
      final stats = TaskStatsDto.fromJson({
        'total': 4,
        'done': 1,
        'overdue': 2,
        'highPriorityPending': 3,
      }).toEntity();

      expect(stats.pending, 3);
      expect(stats.overdue, 2);
      expect(stats.highPriorityPending, 3);
    });
  });
}
