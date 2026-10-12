import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/task_fixtures.dart';

void main() {
  group('TaskItem', () {
    test('is overdue only when open and past its deadline', () {
      final past = fixtureNow.subtract(const Duration(days: 1));
      final future = fixtureNow.add(const Duration(days: 1));

      expect(buildTask(dueDate: past).isOverdue(fixtureNow), isTrue);
      expect(buildTask(dueDate: future).isOverdue(fixtureNow), isFalse);
      expect(
        buildTask(dueDate: past, isDone: true).isOverdue(fixtureNow),
        isFalse,
      );
      expect(buildTask().isOverdue(fixtureNow), isFalse);
    });

    test(
      'copyWith replaces only the given fields and keeps id and createdAt',
      () {
        final task = buildTask(dueDate: fixtureNow);

        final copy = task.copyWith(title: 'New', isDone: true);

        expect(copy.title, 'New');
        expect(copy.isDone, isTrue);
        expect(copy.id, task.id);
        expect(copy.createdAt, task.createdAt);
        expect(copy.dueDate, fixtureNow);
      },
    );

    test('copyWith can clear the deadline', () {
      expect(
        buildTask(dueDate: fixtureNow).copyWith(clearDueDate: true).dueDate,
        isNull,
      );
    });

    test('has value equality and a PII-free toString', () {
      expect(buildTask(), buildTask());
      expect(buildTask().hashCode, buildTask().hashCode);
      expect(buildTask(), isNot(buildTask(title: 'Other')));
      expect(buildTask(title: 'Secret plan').toString(), 'TaskItem(t1)');
    });
  });

  group('TaskPriority.parse', () {
    test('parses known names and falls back to medium', () {
      expect(TaskPriority.parse('high'), TaskPriority.high);
      expect(TaskPriority.parse('low'), TaskPriority.low);
      expect(TaskPriority.parse('urgent'), TaskPriority.medium);
    });
  });

  group('TaskQuery', () {
    test('defaults to the first unfiltered page', () {
      const query = TaskQuery();

      expect(query.page, 1);
      expect(query.pageSize, TaskQuery.defaultPageSize);
      expect(query.status, TaskStatusFilter.all);
      expect(query.priority, isNull);
    });

    test('copyWith changes fields and can clear the priority', () {
      const query = TaskQuery(priority: TaskPriority.high, search: 'a');

      final next = query.copyWith(page: 2, status: TaskStatusFilter.done);

      expect(next.page, 2);
      expect(next.status, TaskStatusFilter.done);
      expect(next.priority, TaskPriority.high);
      expect(query.copyWith(clearPriority: true).priority, isNull);
    });

    test('has value equality', () {
      expect(const TaskQuery(search: 'x'), const TaskQuery(search: 'x'));
      expect(const TaskQuery().hashCode, const TaskQuery().hashCode);
      expect(const TaskQuery(), isNot(const TaskQuery(page: 2)));
    });
  });

  group('TaskStats', () {
    test('derives pending tasks and the completion rate', () {
      const stats = TaskStats(
        total: 8,
        done: 2,
        overdue: 1,
        highPriorityPending: 3,
      );

      expect(stats.pending, 6);
      expect(stats.completionRate, 0.25);
    });

    test('has a zero completion rate without tasks', () {
      const stats = TaskStats(
        total: 0,
        done: 0,
        overdue: 0,
        highPriorityPending: 0,
      );

      expect(stats.completionRate, 0);
    });

    test('has value equality', () {
      const a = TaskStats(
        total: 1,
        done: 1,
        overdue: 0,
        highPriorityPending: 0,
      );
      const b = TaskStats(
        total: 1,
        done: 1,
        overdue: 0,
        highPriorityPending: 0,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
