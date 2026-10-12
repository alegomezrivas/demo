import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:demo/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_stats_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_tasks_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/task_fixtures.dart';
import '../../helpers/tasks_mocks.dart';

void main() {
  late MockTaskRepository repository;
  final task = buildTask();

  setUp(() => repository = MockTaskRepository());

  group('GetTasksUseCase', () {
    test('returns the page from the repository', () async {
      final page = PagedResult<TaskItem>(
        items: [task],
        page: 1,
        pageSize: 10,
        total: 1,
      );
      when(repository.getTasks(any)).thenAnswer((_) async => right(page));

      final result = await GetTasksUseCase(repository)(const TaskQuery());

      expect(result, right<Failure, PagedResult<TaskItem>>(page));
    });

    test('rejects invalid pagination without calling the repository', () async {
      for (final query in const [TaskQuery(page: 0), TaskQuery(pageSize: 0)]) {
        final result = await GetTasksUseCase(repository)(query);

        expect(result.isLeft(), isTrue);
      }
      verifyZeroInteractions(repository);
    });

    test('forwards failures', () async {
      when(
        repository.getTasks(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));

      final result = await GetTasksUseCase(repository)(const TaskQuery());

      expect(result.getLeft().toNullable(), const NetworkFailure());
    });
  });

  group('GetTaskUseCase', () {
    test('loads a task by id', () async {
      when(repository.getTask('t1')).thenAnswer((_) async => right(task));

      expect(
        await GetTaskUseCase(repository)('t1'),
        right<Failure, TaskItem>(task),
      );
    });

    test('rejects a blank id', () async {
      expect((await GetTaskUseCase(repository)('  ')).isLeft(), isTrue);
      verifyZeroInteractions(repository);
    });
  });

  group('CreateTaskUseCase', () {
    const draft = TaskDraft(title: 'Ship it', priority: TaskPriority.high);

    test('creates the task', () async {
      when(repository.createTask(any)).thenAnswer((_) async => right(task));

      final result = await CreateTaskUseCase(repository)(draft);

      expect(result.isRight(), isTrue);
      verify(repository.createTask(draft)).called(1);
    });

    test('rejects blank and too long titles', () async {
      for (final title in ['   ', 'a' * 121]) {
        final result = await CreateTaskUseCase(repository)(
          TaskDraft(title: title, priority: TaskPriority.low),
        );

        expect(
          result.getLeft().toNullable(),
          const ValidationFailure('invalid_title'),
        );
      }
      verifyZeroInteractions(repository);
    });

    test('accepts a title of exactly the maximum length', () async {
      when(repository.createTask(any)).thenAnswer((_) async => right(task));

      final result = await CreateTaskUseCase(repository)(
        TaskDraft(title: 'a' * 120, priority: TaskPriority.low),
      );

      expect(result.isRight(), isTrue);
    });
  });

  group('UpdateTaskUseCase', () {
    test('saves the task', () async {
      when(repository.updateTask(any)).thenAnswer((_) async => right(task));

      expect((await UpdateTaskUseCase(repository)(task)).isRight(), isTrue);
      verify(repository.updateTask(task)).called(1);
    });

    test('rejects an invalid title', () async {
      final result = await UpdateTaskUseCase(repository)(
        task.copyWith(title: ' '),
      );

      expect(result.isLeft(), isTrue);
      verifyZeroInteractions(repository);
    });
  });

  group('DeleteTaskUseCase', () {
    test('deletes by id', () async {
      when(repository.deleteTask('t1')).thenAnswer((_) async => right(unit));

      expect(
        await DeleteTaskUseCase(repository)('t1'),
        right<Failure, Unit>(unit),
      );
    });

    test('rejects a blank id', () async {
      expect((await DeleteTaskUseCase(repository)('')).isLeft(), isTrue);
      verifyZeroInteractions(repository);
    });
  });

  group('GetTaskStatsUseCase', () {
    test('returns the statistics', () async {
      const stats = TaskStats(
        total: 2,
        done: 1,
        overdue: 0,
        highPriorityPending: 0,
      );
      when(repository.getStats()).thenAnswer((_) async => right(stats));

      expect(
        await GetTaskStatsUseCase(repository)(const NoParams()),
        right<Failure, TaskStats>(stats),
      );
    });
  });
}
