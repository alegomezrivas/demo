import 'dart:async';

import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/presentation/viewmodels/tasks_view_model.dart';
import 'package:demo/features/tasks/presentation/views/tasks_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
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

  setUp(() async {
    await resetLocator();
    getTasks = MockGetTasksUseCase();
    updateTask = MockUpdateTaskUseCase();
    deleteTask = MockDeleteTaskUseCase();
    guard = MockSensitiveActionGuard();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    when(
      guard.confirm(reason: anyNamed('reason')),
    ).thenAnswer((_) async => true);
    locator.registerFactory<TasksViewModel>(
      () => TasksViewModel(
        getTasks: getTasks,
        updateTask: updateTask,
        deleteTask: deleteTask,
        guard: guard,
        navigation: navigation,
        changes: changes,
        searchDebounce: const Duration(milliseconds: 10),
      ),
    );
  });

  tearDown(resetLocator);

  void stubPages(List<TaskItem> all, {int pageSize = 10}) {
    when(getTasks(any)).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as TaskQuery;
      final start = (query.page - 1) * pageSize;
      final items = all.skip(start).take(pageSize).toList();
      return right(
        PagedResult(
          items: items,
          page: query.page,
          pageSize: pageSize,
          total: all.length,
        ),
      );
    });
  }

  Future<void> pumpView(WidgetTester tester) async {
    await pumpLocalized(tester, TasksView(clock: () => fixtureNow));
    await tester.pumpAndSettle();
  }

  group('content', () {
    testWidgets('lists tasks with filters and a create button', (tester) async {
      stubPages([
        buildTask(id: 'a', title: 'Alpha'),
        buildTask(id: 'b', title: 'Beta'),
      ]);

      await pumpView(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      for (final label in [
        'Todas',
        'Pendientes',
        'Completadas',
        'Cualquier prioridad',
        'Baja',
        'Media',
        'Alta',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.text('Nueva tarea'), findsOneWidget);
    });

    testWidgets('shows a progress indicator while loading', (tester) async {
      final completer = Completer<Either<Failure, PagedResult<TaskItem>>>();
      when(getTasks(any)).thenAnswer((_) => completer.future);
      await pumpLocalized(tester, TasksView(clock: () => fixtureNow));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(right(buildPage(const [])));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'shows an empty state, and a different one when filters hide everything',
      (tester) async {
        stubPages(const []);
        await pumpView(tester);
        expect(find.text('Aún no tienes tareas'), findsOneWidget);

        await tester.tap(find.text('Pendientes'));
        await tester.pumpAndSettle();

        expect(
          find.text('Ninguna tarea coincide con los filtros'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows a generic error with retry', (tester) async {
      when(getTasks(any)).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);
      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );

      stubPages([buildTask(title: 'Recovered')]);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered'), findsOneWidget);
    });
  });

  group('filters and search', () {
    setUp(() => stubPages([buildTask(title: 'Alpha')]));

    testWidgets('tapping a status chip reloads with that status', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.text('Completadas'));
      await tester.pumpAndSettle();

      final query = verify(getTasks(captureAny)).captured.last as TaskQuery;
      expect(query.status, TaskStatusFilter.done);
    });

    testWidgets('tapping a priority chip reloads with that priority', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Alta'));
      await tester.pumpAndSettle();

      final query = verify(getTasks(captureAny)).captured.last as TaskQuery;
      expect(query.priority, TaskPriority.high);
    });

    testWidgets('typing in the search box searches after the debounce', (
      tester,
    ) async {
      await pumpView(tester);
      clearInteractions(getTasks);

      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar tareas'),
        'milk',
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final query = verify(getTasks(captureAny)).captured.single as TaskQuery;
      expect(query.search, 'milk');
    });
  });

  group('actions', () {
    setUp(() => stubPages([buildTask(id: 't0', title: 'Alpha')]));

    testWidgets('the add button opens the create form', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Nueva tarea'));
      await tester.pump();

      verify(navigation.push<bool>(AppRoutes.taskNew)).called(1);
    });

    testWidgets('tapping a task opens its edit form', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Alpha'));
      await tester.pump();

      verify(navigation.push<bool>('/tasks/t0')).called(1);
    });

    testWidgets('the checkbox toggles completion', (tester) async {
      when(updateTask(any)).thenAnswer(
        (_) async => right(buildTask(id: 't0', title: 'Alpha', isDone: true)),
      );
      await pumpView(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      verify(updateTask(any)).called(1);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('deleting asks for confirmation and then deletes', (
      tester,
    ) async {
      when(deleteTask(any)).thenAnswer((_) async => right(unit));
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar tarea'), findsOneWidget);
      expect(find.textContaining('Alpha'), findsWidgets);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(
        guard.confirm(reason: 'Confirma tu identidad para eliminar la tarea'),
      ).called(1);
      verify(deleteTask('t0')).called(1);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('cancelling the dialog keeps the task', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(deleteTask(any));
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('shows a snack bar when an action fails', (tester) async {
      when(
        updateTask(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });
  });

  group('pagination', () {
    testWidgets('loads the next page when the user scrolls near the end', (
      tester,
    ) async {
      stubPages(buildTasks(15));
      await pumpView(tester);
      expect(find.text('Task 14'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Task 14'),
        300,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task 14'), findsOneWidget);
      final pages = verify(
        getTasks(captureAny),
      ).captured.cast<TaskQuery>().map((q) => q.page);
      expect(pages, [1, 2]);
    });
  });
}
