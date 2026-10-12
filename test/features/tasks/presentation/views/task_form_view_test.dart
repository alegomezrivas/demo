import 'package:demo/app/locator.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/presentation/viewmodels/task_form_view_model.dart';
import 'package:demo/features/tasks/presentation/views/task_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../helpers/task_fixtures.dart';
import '../../helpers/tasks_mocks.dart';

void main() {
  late MockGetTaskUseCase getTask;
  late MockCreateTaskUseCase createTask;
  late MockUpdateTaskUseCase updateTask;
  late MockNavigationService navigation;
  late DataChangeNotifier changes;

  setUp(() async {
    await resetLocator();
    getTask = MockGetTaskUseCase();
    createTask = MockCreateTaskUseCase();
    updateTask = MockUpdateTaskUseCase();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    locator.registerFactory<TaskFormViewModel>(
      () => TaskFormViewModel(
        getTask: getTask,
        createTask: createTask,
        updateTask: updateTask,
        navigation: navigation,
        changes: changes,
      ),
    );
  });

  tearDown(resetLocator);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> pumpView(WidgetTester tester, {String? taskId}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(tester, TaskFormView(taskId: taskId));
    await tester.pumpAndSettle();
  }

  group('create', () {
    testWidgets('shows an empty form without the completion switch', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Nueva tarea'), findsOneWidget);
      expect(field('Título'), findsOneWidget);
      expect(field('Descripción'), findsOneWidget);
      expect(find.text('Prioridad'), findsOneWidget);
      expect(find.text('Fecha límite'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('requires a title', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsOneWidget);
      verifyZeroInteractions(createTask);
    });

    testWidgets('limits the title length', (tester) async {
      await pumpView(tester);

      await tester.enterText(field('Título'), 'a' * 121);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('No puede superar 120 caracteres'), findsOneWidget);
    });

    testWidgets('creates the task and closes the screen', (tester) async {
      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await pumpView(tester);

      await tester.enterText(field('Título'), 'Ship it');
      await tester.enterText(field('Descripción'), 'soon');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final draft = verify(createTask(captureAny)).captured.single as TaskDraft;
      expect(draft.title, 'Ship it');
      expect(draft.description, 'soon');
      expect(draft.priority, TaskPriority.medium);
      verify(navigation.pop<bool>(true)).called(1);
    });

    testWidgets('lets the user choose a priority', (tester) async {
      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await pumpView(tester);

      await tester.tap(find.byType(DropdownButton<TaskPriority>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('Título'), 'Urgent');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final draft = verify(createTask(captureAny)).captured.single as TaskDraft;
      expect(draft.priority, TaskPriority.high);
    });

    testWidgets('picks a due date with the date picker', (tester) async {
      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await pumpView(tester);

      await tester.tap(find.byType(InputDecorator).last);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('Título'), 'Dated');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final draft = verify(createTask(captureAny)).captured.single as TaskDraft;
      expect(draft.dueDate, isNotNull);
    });

    testWidgets('shows a generic error when saving fails', (tester) async {
      when(
        createTask(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await tester.enterText(field('Título'), 'x');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_form_error')), findsOneWidget);
      verifyNever(navigation.pop<bool>(any));
    });

    testWidgets('the close button cancels', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.close));

      verify(navigation.pop<bool>(false)).called(1);
    });
  });

  group('edit', () {
    final existing = buildTask(
      id: 't9',
      title: 'Old title',
      priority: TaskPriority.low,
      dueDate: DateTime.utc(2026, 6, 1, 12),
    );

    testWidgets('loads the task and shows the completion switch', (
      tester,
    ) async {
      when(getTask('t9')).thenAnswer((_) async => right(existing));

      await pumpView(tester, taskId: 't9');

      expect(find.text('Editar tarea'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Old title'), findsOneWidget);
      expect(find.text('Baja'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('can remove the deadline and saves the changes', (
      tester,
    ) async {
      when(getTask('t9')).thenAnswer((_) async => right(existing));
      when(updateTask(any)).thenAnswer((_) async => right(existing));
      await pumpView(tester, taskId: 't9');

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      await tester.enterText(field('Título'), 'Renamed');
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final saved = verify(updateTask(captureAny)).captured.single as TaskItem;
      expect(saved.title, 'Renamed');
      expect(saved.dueDate, isNull);
      expect(saved.isDone, isTrue);
      verify(navigation.pop<bool>(true)).called(1);
    });

    testWidgets('shows an error with retry when the task cannot be loaded', (
      tester,
    ) async {
      when(
        getTask(any),
      ).thenAnswer((_) async => left(const ServerFailure('not_found')));
      await pumpView(tester, taskId: 't9');
      expect(
        find.text(
          'El servicio no está disponible por ahora. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );
      expect(field('Título'), findsNothing);

      when(getTask(any)).thenAnswer((_) async => right(existing));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Old title'), findsOneWidget);
    });
  });
}
