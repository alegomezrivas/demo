import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/presentation/viewmodels/tasks_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../settings/helpers/settings_mocks.dart';
import '../../helpers/task_fixtures.dart';
import '../../helpers/tasks_mocks.dart';

void main() {
  late MockGetTasksUseCase getTasks;
  late MockUpdateTaskUseCase updateTask;
  late MockDeleteTaskUseCase deleteTask;
  late MockSensitiveActionGuard guard;
  late MockNavigationService navigation;
  late DataChangeNotifier changes;
  late TasksViewModel viewModel;

  void stubPages(Map<int, PagedResult<TaskItem>> pages) {
    when(getTasks(any)).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as TaskQuery;
      return right(pages[query.page] ?? buildPage(const [], page: query.page));
    });
  }

  TasksViewModel build({Duration debounce = const Duration(milliseconds: 30)}) {
    return TasksViewModel(
      getTasks: getTasks,
      updateTask: updateTask,
      deleteTask: deleteTask,
      guard: guard,
      navigation: navigation,
      changes: changes,
      searchDebounce: debounce,
    );
  }

  setUp(() {
    getTasks = MockGetTasksUseCase();
    updateTask = MockUpdateTaskUseCase();
    deleteTask = MockDeleteTaskUseCase();
    guard = MockSensitiveActionGuard();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    when(
      guard.confirm(reason: anyNamed('reason')),
    ).thenAnswer((_) async => true);
    viewModel = build();
  });

  tearDown(() => viewModel.dispose());

  Future<void> wait([int ms = 80]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  group('loading', () {
    test('init loads the first page', () async {
      stubPages({1: buildPage(buildTasks(10), total: 25)});

      await viewModel.init();

      expect(viewModel.items, hasLength(10));
      expect(viewModel.hasMore, isTrue);
      expect(viewModel.total, 25);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.failure, isNull);
    });

    test('is busy while the first page is loading', () async {
      final completer = Completer<Either<Failure, PagedResult<TaskItem>>>();
      when(getTasks(any)).thenAnswer((_) => completer.future);

      final future = viewModel.init();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isBusy, isTrue);
      completer.complete(right(buildPage(const [])));
      await future;

      expect(viewModel.isBusy, isFalse);
    });

    test(
      'exposes the failure and clears the list when loading fails',
      () async {
        stubPages({1: buildPage(buildTasks(3))});
        await viewModel.init();
        when(
          getTasks(any),
        ).thenAnswer((_) async => left(const NetworkFailure()));

        await viewModel.refresh();

        expect(viewModel.failure, const NetworkFailure());
        expect(viewModel.items, isEmpty);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test('refresh keeps the filters and goes back to page 1', () async {
      stubPages({
        1: buildPage(buildTasks(10), total: 30),
        2: buildPage(buildTasks(10, start: 10), page: 2, total: 30),
      });
      await viewModel.init();
      await viewModel.loadMore();
      await viewModel.setStatus(TaskStatusFilter.pending);

      await viewModel.refresh();

      final last = verify(getTasks(captureAny)).captured.last as TaskQuery;
      expect(last.page, 1);
      expect(last.status, TaskStatusFilter.pending);
    });
  });

  group('pagination', () {
    test('loadMore appends the next page', () async {
      stubPages({
        1: buildPage(buildTasks(10), total: 15),
        2: buildPage(buildTasks(5, start: 10), page: 2, total: 15),
      });
      await viewModel.init();

      await viewModel.loadMore();

      expect(viewModel.items, hasLength(15));
      expect(viewModel.query.page, 2);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('does not request more once everything is loaded', () async {
      stubPages({1: buildPage(buildTasks(3))});
      await viewModel.init();
      clearInteractions(getTasks);

      await viewModel.loadMore();

      verifyNever(getTasks(any));
    });

    test('ignores duplicated items returned by the next page', () async {
      stubPages({
        1: buildPage(buildTasks(10), total: 20),
        2: buildPage(buildTasks(10, start: 5), page: 2, total: 20),
      });
      await viewModel.init();

      await viewModel.loadMore();

      expect(
        viewModel.items.map((t) => t.id).toSet(),
        hasLength(viewModel.items.length),
      );
      expect(viewModel.items, hasLength(15));
    });

    test('a second loadMore while one is running is ignored', () async {
      final completer = Completer<Either<Failure, PagedResult<TaskItem>>>();
      stubPages({1: buildPage(buildTasks(10), total: 30)});
      await viewModel.init();
      clearInteractions(getTasks);
      when(getTasks(any)).thenAnswer((_) => completer.future);

      final first = viewModel.loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoadingMore, isTrue);
      await viewModel.loadMore();
      completer.complete(
        right(buildPage(buildTasks(10, start: 10), page: 2, total: 30)),
      );
      await first;

      verify(getTasks(any)).called(1);
    });

    test(
      'a failed loadMore keeps the list, reports the error and allows retry',
      () async {
        stubPages({1: buildPage(buildTasks(10), total: 30)});
        await viewModel.init();
        when(
          getTasks(any),
        ).thenAnswer((_) async => left(const NetworkFailure()));

        await viewModel.loadMore();

        expect(viewModel.items, hasLength(10));
        expect(viewModel.hasMore, isTrue);
        expect(viewModel.query.page, 1);
        expect(viewModel.takeActionFailure(), const NetworkFailure());
      },
    );

    test(
      'discards a late next page when the filters changed meanwhile',
      () async {
        final late = Completer<Either<Failure, PagedResult<TaskItem>>>();
        stubPages({1: buildPage(buildTasks(10), total: 30)});
        await viewModel.init();
        when(getTasks(any)).thenAnswer((invocation) {
          final query = invocation.positionalArguments.first as TaskQuery;
          return query.page == 2
              ? late.future
              : Future.value(
                  right(buildPage(buildTasks(2, start: 100), total: 2)),
                );
        });

        final pending = viewModel.loadMore();
        await Future<void>.delayed(Duration.zero);
        await viewModel.setStatus(TaskStatusFilter.done);
        late.complete(
          right(buildPage(buildTasks(10, start: 10), page: 2, total: 30)),
        );
        await pending;

        expect(viewModel.items.map((t) => t.id), ['t100', 't101']);
        expect(viewModel.isLoadingMore, isFalse);
      },
    );
  });

  group('filters and search', () {
    setUp(() => stubPages({1: buildPage(buildTasks(2))}));

    test('setStatus reloads from page 1 with the new status', () async {
      await viewModel.init();

      await viewModel.setStatus(TaskStatusFilter.done);

      final query = verify(getTasks(captureAny)).captured.last as TaskQuery;
      expect(query.status, TaskStatusFilter.done);
      expect(query.page, 1);
      expect(viewModel.hasActiveFilters, isTrue);
    });

    test('setting the same status again does not reload', () async {
      await viewModel.init();
      clearInteractions(getTasks);

      await viewModel.setStatus(TaskStatusFilter.all);

      verifyNever(getTasks(any));
    });

    test('setPriority applies and clears the priority filter', () async {
      await viewModel.init();

      await viewModel.setPriority(TaskPriority.high);
      expect(viewModel.query.priority, TaskPriority.high);
      await viewModel.setPriority(null);

      expect(viewModel.query.priority, isNull);
      expect(viewModel.hasActiveFilters, isFalse);
    });

    test(
      'search waits for the user to stop typing and sends a single request',
      () async {
        await viewModel.init();
        clearInteractions(getTasks);

        for (final text in ['m', 'mi', 'milk']) {
          viewModel.form.control(TasksViewModel.searchField).value = text;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await wait();

        final queries = verify(getTasks(captureAny)).captured.cast<TaskQuery>();
        expect(queries, hasLength(1));
        expect(queries.single.search, 'milk');
        expect(viewModel.hasActiveFilters, isTrue);
      },
    );

    test(
      'search text is trimmed and an unchanged search does not reload',
      () async {
        await viewModel.init();
        viewModel.form.control(TasksViewModel.searchField).value = '  milk ';
        await wait();
        clearInteractions(getTasks);

        viewModel.form.control(TasksViewModel.searchField).value = 'milk';
        await wait();

        verifyNever(getTasks(any));
        expect(viewModel.query.search, 'milk');
      },
    );

    test('clearing the search reloads without it', () async {
      await viewModel.init();
      viewModel.form.control(TasksViewModel.searchField).value = 'milk';
      await wait();

      viewModel.form.control(TasksViewModel.searchField).value = '';
      await wait();

      expect(viewModel.query.search, isEmpty);
    });

    test('only the latest of overlapping loads updates the list', () async {
      final slow = Completer<Either<Failure, PagedResult<TaskItem>>>();
      var call = 0;
      when(getTasks(any)).thenAnswer((_) {
        call++;
        return call == 1
            ? slow.future
            : Future.value(right(buildPage(buildTasks(1, start: 7))));
      });

      final first = viewModel.refresh();
      await Future<void>.delayed(Duration.zero);
      await viewModel.refresh();
      slow.complete(right(buildPage(buildTasks(5))));
      await first;

      expect(viewModel.items.map((t) => t.id), ['t7']);
      expect(viewModel.isBusy, isFalse);
    });
  });

  group('toggleDone', () {
    final task = buildTask(id: 't0', title: 'Task 0');

    setUp(() async {
      stubPages({
        1: buildPage([task, buildTask()]),
      });
      await viewModel.init();
    });

    test('updates optimistically and keeps the saved task', () async {
      final saved = task.copyWith(isDone: true, title: 'Task 0 (saved)');
      when(updateTask(any)).thenAnswer((_) async => right(saved));

      final future = viewModel.toggleDone(task);
      expect(viewModel.items.first.isDone, isTrue);
      await future;

      expect(viewModel.items.first, saved);
      verify(updateTask(task.copyWith(isDone: true))).called(1);
    });

    test('rolls back and reports the error when saving fails', () async {
      when(
        updateTask(any),
      ).thenAnswer((_) async => left(const ServerFailure()));

      await viewModel.toggleDone(task);

      expect(viewModel.items.first.isDone, isFalse);
      expect(viewModel.takeActionFailure(), const ServerFailure());
    });

    test(
      'removes the task when it no longer matches the status filter',
      () async {
        await viewModel.setStatus(TaskStatusFilter.pending);
        when(
          updateTask(any),
        ).thenAnswer((_) async => right(task.copyWith(isDone: true)));

        await viewModel.toggleDone(viewModel.items.first);

        expect(viewModel.items.map((t) => t.id), ['t1']);
      },
    );

    test('ignores tasks that are not in the list', () async {
      await viewModel.toggleDone(buildTask(id: 'ghost'));

      verifyNever(updateTask(any));
    });
  });

  group('delete', () {
    final task = buildTask(id: 't0');

    setUp(() async {
      stubPages({
        1: buildPage([task, buildTask()], total: 2),
      });
      await viewModel.init();
    });

    test('removes the task after confirmation', () async {
      when(deleteTask('t0')).thenAnswer((_) async => right(unit));

      await viewModel.delete(task, reason: 'why');

      verify(guard.confirm(reason: 'why')).called(1);
      expect(viewModel.items.map((t) => t.id), ['t1']);
      expect(viewModel.total, 1);
    });

    test('does nothing when the confirmation is denied', () async {
      when(
        guard.confirm(reason: anyNamed('reason')),
      ).thenAnswer((_) async => false);

      await viewModel.delete(task, reason: 'why');

      verifyNever(deleteTask(any));
      expect(viewModel.items, hasLength(2));
    });

    test('keeps the task and reports the error when deleting fails', () async {
      when(
        deleteTask(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));

      await viewModel.delete(task, reason: 'why');

      expect(viewModel.items, hasLength(2));
      expect(viewModel.takeActionFailure(), const NetworkFailure());
    });
  });

  group('navigation', () {
    setUp(() => stubPages({1: buildPage(buildTasks(1))}));

    test('openCreate refreshes when a task was created', () async {
      when(navigation.push<bool>(any)).thenAnswer((_) async => true);
      await viewModel.init();

      await viewModel.openCreate();

      verify(navigation.push<bool>(AppRoutes.taskNew)).called(1);
      verify(getTasks(any)).called(2);
    });

    test('openCreate does not refresh when the form was cancelled', () async {
      when(navigation.push<bool>(any)).thenAnswer((_) async => false);
      await viewModel.init();

      await viewModel.openCreate();

      verify(getTasks(any)).called(1);
    });

    test('openEdit pushes the task route and refreshes on change', () async {
      when(navigation.push<bool>(any)).thenAnswer((_) async => true);
      await viewModel.init();

      await viewModel.openEdit(buildTask(id: 'a b'));

      verify(navigation.push<bool>('/tasks/a%20b')).called(1);
      verify(getTasks(any)).called(2);
    });

    test('a null result (back button) does not refresh', () async {
      await viewModel.init();

      await viewModel.openEdit(buildTask());

      verify(getTasks(any)).called(1);
    });
  });

  group('action failures', () {
    test('takeActionFailure returns the error once', () async {
      stubPages({
        1: buildPage([buildTask()]),
      });
      await viewModel.init();
      when(
        updateTask(any),
      ).thenAnswer((_) async => left(const ServerFailure()));
      await viewModel.toggleDone(buildTask());

      expect(viewModel.takeActionFailure(), const ServerFailure());
      expect(viewModel.takeActionFailure(), isNull);
    });
  });

  test('dispose cancels a pending search without errors', () async {
    stubPages({1: buildPage(buildTasks(1))});
    await viewModel.init();
    viewModel.form.control(TasksViewModel.searchField).value = 'x';

    viewModel.dispose();
    await wait();

    verify(getTasks(any)).called(1);
    viewModel = build();
  });

  group('data change notifications', () {
    late int notified;

    setUp(() async {
      notified = 0;
      changes.onChanged.listen((_) => notified++);
      stubPages({
        1: buildPage([buildTask(id: 't0')]),
      });
      await viewModel.init();
    });

    Future<void> flush() => Future<void>.delayed(Duration.zero);

    test('announces a successful completion toggle', () async {
      when(
        updateTask(any),
      ).thenAnswer((_) async => right(buildTask(id: 't0', isDone: true)));

      await viewModel.toggleDone(buildTask(id: 't0'));
      await flush();

      expect(notified, 1);
    });

    test('stays silent when the toggle fails', () async {
      when(
        updateTask(any),
      ).thenAnswer((_) async => left(const ServerFailure()));

      await viewModel.toggleDone(buildTask(id: 't0'));
      await flush();

      expect(notified, 0);
    });

    test(
      'announces a successful delete and stays silent when it fails',
      () async {
        when(
          deleteTask(any),
        ).thenAnswer((_) async => left(const ServerFailure()));
        await viewModel.delete(buildTask(id: 't0'), reason: 'r');
        await flush();
        expect(notified, 0);

        when(deleteTask(any)).thenAnswer((_) async => right(unit));
        await viewModel.delete(buildTask(id: 't0'), reason: 'r');
        await flush();
        expect(notified, 1);
      },
    );
  });
}
