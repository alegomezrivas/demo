import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../auth/helpers/auth_mocks.dart';
import '../../../tasks/helpers/tasks_mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockGetTaskStatsUseCase getStats;
  late MockNavigationService navigation;
  late DataChangeNotifier changes;
  late DashboardViewModel viewModel;
  const user = User(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );
  const stats = TaskStats(
    total: 10,
    done: 4,
    overdue: 2,
    highPriorityPending: 3,
  );

  setUp(() {
    getCurrentUser = MockGetCurrentUserUseCase();
    getStats = MockGetTaskStatsUseCase();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    when(getCurrentUser(any)).thenAnswer((_) async => right(user));
    when(getStats(any)).thenAnswer((_) async => right(stats));
    viewModel = DashboardViewModel(
      getCurrentUser: getCurrentUser,
      getStats: getStats,
      navigation: navigation,
      changes: changes,
    );
  });

  group('init', () {
    test('starts empty and not busy', () {
      expect(viewModel.user, isNull);
      expect(viewModel.stats, isNull);
      expect(viewModel.isBusy, isFalse);
    });

    test('loads the user and the statistics', () async {
      await viewModel.init();

      expect(viewModel.user, user);
      expect(viewModel.stats, stats);
      expect(viewModel.failure, isNull);
      expect(viewModel.isBusy, isFalse);
    });

    test('reports a statistics failure but still shows the user', () async {
      when(getStats(any)).thenAnswer((_) async => left(const NetworkFailure()));

      await viewModel.init();

      expect(viewModel.failure, const NetworkFailure());
      expect(viewModel.stats, isNull);
      expect(viewModel.user, user);
    });

    test('keeps the user empty when it cannot be restored', () async {
      when(
        getCurrentUser(any),
      ).thenAnswer((_) async => left(const CacheFailure()));

      await viewModel.init();

      expect(viewModel.user, isNull);
      expect(viewModel.stats, stats);
    });

    test('a successful refresh clears a previous failure', () async {
      when(getStats(any)).thenAnswer((_) async => left(const NetworkFailure()));
      await viewModel.init();
      when(getStats(any)).thenAnswer((_) async => right(stats));

      await viewModel.refresh();

      expect(viewModel.failure, isNull);
      expect(viewModel.stats, stats);
    });
  });

  group('navigation', () {
    test('openTasks switches to the tasks tab', () {
      viewModel.openTasks();

      verify(navigation.go(AppRoutes.tasks)).called(1);
    });

    test(
      'createTask reloads the statistics after a task was created',
      () async {
        when(navigation.push<bool>(any)).thenAnswer((_) async => true);

        await viewModel.createTask();

        verify(navigation.push<bool>(AppRoutes.taskNew)).called(1);
        verify(getStats(any)).called(1);
      },
    );

    test('createTask does not reload when the form was cancelled', () async {
      when(navigation.push<bool>(any)).thenAnswer((_) async => false);

      await viewModel.createTask();

      verifyNever(getStats(any));
    });
  });

  group('reacting to task changes', () {
    test('reloads silently (no spinner) when tasks change elsewhere', () async {
      await viewModel.init();
      const updated = TaskStats(
        total: 11,
        done: 4,
        overdue: 2,
        highPriorityPending: 3,
      );
      when(getStats(any)).thenAnswer((_) async => right(updated));
      var busyDuringReload = false;
      viewModel.addListener(
        () => busyDuringReload = busyDuringReload || viewModel.isBusy,
      );

      changes.notifyChanged();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.stats, updated);
      expect(busyDuringReload, isFalse);
    });

    test('subscribes only once even if init is called again', () async {
      await viewModel.init();
      await viewModel.init();
      clearInteractions(getStats);

      changes.notifyChanged();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(getStats(any)).called(1);
    });

    test('stops reacting after dispose', () async {
      await viewModel.init();
      viewModel.dispose();
      clearInteractions(getStats);

      changes.notifyChanged();
      await Future<void>.delayed(Duration.zero);

      verifyNever(getStats(any));
    });
  });

  group('overlapping loads', () {
    const fresh = TaskStats(
      total: 20,
      done: 10,
      overdue: 0,
      highPriorityPending: 0,
    );

    test('a slow older response never overwrites a newer one', () async {
      final slow = Completer<Either<Failure, TaskStats>>();
      var call = 0;
      when(getStats(any)).thenAnswer((_) {
        call++;
        return call == 1 ? slow.future : Future.value(right(fresh));
      });

      final first = viewModel.refresh();
      await Future<void>.delayed(Duration.zero);
      await viewModel.refresh();
      slow.complete(right(stats));
      await first;

      expect(viewModel.stats, fresh);
      expect(viewModel.isBusy, isFalse);
    });

    test(
      'a silent reload that supersedes a spinner load still clears the spinner',
      () async {
        await viewModel.init();
        final slow = Completer<Either<Failure, TaskStats>>();
        var call = 0;
        when(getStats(any)).thenAnswer((_) {
          call++;
          return call == 1 ? slow.future : Future.value(right(fresh));
        });

        final spinner = viewModel.refresh();
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.isBusy, isTrue);
        changes.notifyChanged();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        slow.complete(right(stats));
        await spinner;

        expect(viewModel.isBusy, isFalse);
        expect(viewModel.stats, fresh);
      },
    );

    test('keeps the previous statistics when a refresh fails', () async {
      await viewModel.init();
      when(getStats(any)).thenAnswer((_) async => left(const NetworkFailure()));

      await viewModel.refresh();

      expect(viewModel.stats, stats);
      expect(viewModel.failure, const NetworkFailure());
    });

    test('ignores a response that arrives after dispose', () async {
      final slow = Completer<Either<Failure, TaskStats>>();
      when(getStats(any)).thenAnswer((_) => slow.future);

      final future = viewModel.init();
      await Future<void>.delayed(Duration.zero);
      viewModel.dispose();
      slow.complete(right(stats));
      await future;

      expect(viewModel.stats, isNull);
    });
  });
}
