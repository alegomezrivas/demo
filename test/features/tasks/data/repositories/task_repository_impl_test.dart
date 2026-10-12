import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/tasks/data/models/task_dto.dart';
import 'package:demo/features/tasks/data/models/task_input_dto.dart';
import 'package:demo/features/tasks/data/models/task_page_dto.dart';
import 'package:demo/features/tasks/data/models/task_stats_dto.dart';
import 'package:demo/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/task_fixtures.dart';
import '../../helpers/tasks_mocks.dart';

void main() {
  late MockTasksRemoteDataSource remote;
  late TaskRepositoryImpl repository;

  const dto = TaskDto(
    id: 't1',
    title: 'Write tests',
    description: '',
    priority: 'medium',
    isDone: false,
    createdAt: '2026-01-10T00:00:00.000Z',
  );

  setUp(() {
    remote = MockTasksRemoteDataSource();
    repository = TaskRepositoryImpl(remote: remote);
  });

  group('getTasks', () {
    test('maps the page to entities', () async {
      when(remote.getTasks(any)).thenAnswer(
        (_) async =>
            const TaskPageDto(items: [dto], page: 1, pageSize: 10, total: 11),
      );

      final result = await repository.getTasks(const TaskQuery());

      final page = result.getRight().toNullable();
      expect(page?.items.single.title, 'Write tests');
      expect(page?.hasMore, isTrue);
    });

    test('sanitizes the search text before sending it', () async {
      when(remote.getTasks(any)).thenAnswer(
        (_) async =>
            const TaskPageDto(items: [], page: 1, pageSize: 10, total: 0),
      );

      await repository.getTasks(
        const TaskQuery(search: '  <b>milk</b>\u0000 '),
      );

      final sent =
          verify(remote.getTasks(captureAny)).captured.single as TaskQuery;
      expect(sent.search, 'milk');
    });

    test('maps exceptions to failures', () async {
      when(remote.getTasks(any)).thenThrow(const NetworkException());

      expect(
        (await repository.getTasks(const TaskQuery())).getLeft().toNullable(),
        const NetworkFailure(),
      );
    });

    test('hides malformed data behind an UnexpectedFailure', () async {
      when(remote.getTasks(any)).thenAnswer(
        (_) async => const TaskPageDto(
          items: [
            TaskDto(
              id: 'x',
              title: 't',
              description: '',
              priority: 'low',
              isDone: false,
              createdAt: 'not-a-date',
            ),
          ],
          page: 1,
          pageSize: 10,
          total: 1,
        ),
      );

      expect(
        (await repository.getTasks(const TaskQuery())).getLeft().toNullable(),
        const UnexpectedFailure(),
      );
    });
  });

  group('createTask', () {
    test('sanitizes text and sends the draft', () async {
      when(remote.createTask(any)).thenAnswer((_) async => dto);

      final result = await repository.createTask(
        TaskDraft(
          title: '  <i>Plan</i> ',
          description: ' <script>x</script>notes ',
          priority: TaskPriority.high,
          dueDate: DateTime.utc(2026, 3),
        ),
      );

      expect(result.isRight(), isTrue);
      final input =
          verify(remote.createTask(captureAny)).captured.single as TaskInputDto;
      expect(input.title, 'Plan');
      expect(input.description, 'xnotes');
      expect(input.priority, 'high');
      expect(input.dueDate, '2026-03-01T00:00:00.000Z');
    });

    test('caps title length at 120 characters', () async {
      when(remote.createTask(any)).thenAnswer((_) async => dto);

      await repository.createTask(
        TaskDraft(title: 'a' * 300, priority: TaskPriority.low),
      );

      final input =
          verify(remote.createTask(captureAny)).captured.single as TaskInputDto;
      expect(input.title, hasLength(120));
    });

    test('maps a validation error from the server', () async {
      when(remote.createTask(any)).thenThrow(
        const ServerException(code: 'validation_error', statusCode: 422),
      );

      final result = await repository.createTask(
        const TaskDraft(title: 'x', priority: TaskPriority.low),
      );

      expect(
        result.getLeft().toNullable(),
        const ServerFailure('validation_error'),
      );
    });
  });

  group('updateTask, getTask, deleteTask and getStats', () {
    test('updateTask sends the task state to its id', () async {
      when(remote.updateTask(any, any)).thenAnswer((_) async => dto);

      final result = await repository.updateTask(buildTask(isDone: true));

      expect(result.isRight(), isTrue);
      final captured = verify(
        remote.updateTask(captureAny, captureAny),
      ).captured;
      expect(captured.first, 't1');
      expect((captured.last as TaskInputDto).isDone, isTrue);
    });

    test('getTask returns the entity', () async {
      when(remote.getTask('t1')).thenAnswer((_) async => dto);

      expect(
        (await repository.getTask('t1')).getRight().toNullable()?.id,
        't1',
      );
    });

    test('getTask maps a missing task to a ServerFailure', () async {
      when(
        remote.getTask(any),
      ).thenThrow(const ServerException(code: 'not_found', statusCode: 404));

      expect(
        (await repository.getTask('nope')).getLeft().toNullable(),
        const ServerFailure('not_found'),
      );
    });

    test('deleteTask succeeds with unit', () async {
      expect(await repository.deleteTask('t1'), right<Failure, Unit>(unit));
      verify(remote.deleteTask('t1')).called(1);
    });

    test('deleteTask reports unauthorized sessions', () async {
      when(remote.deleteTask(any)).thenThrow(const UnauthorizedException());

      expect(
        (await repository.deleteTask('t1')).getLeft().toNullable(),
        const UnauthorizedFailure(),
      );
    });

    test('getStats maps the DTO', () async {
      when(remote.getStats()).thenAnswer(
        (_) async => const TaskStatsDto(
          total: 5,
          done: 2,
          overdue: 1,
          highPriorityPending: 1,
        ),
      );

      expect((await repository.getStats()).getRight().toNullable()?.pending, 3);
    });
  });
}
