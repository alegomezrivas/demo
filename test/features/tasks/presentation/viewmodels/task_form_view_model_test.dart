import 'dart:async';

import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/presentation/viewmodels/task_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../helpers/task_fixtures.dart';
import '../../helpers/tasks_mocks.dart';

void main() {
  late MockGetTaskUseCase getTask;
  late MockCreateTaskUseCase createTask;
  late MockUpdateTaskUseCase updateTask;
  late MockNavigationService navigation;
  late DataChangeNotifier changes;
  late TaskFormViewModel viewModel;

  setUp(() {
    getTask = MockGetTaskUseCase();
    createTask = MockCreateTaskUseCase();
    updateTask = MockUpdateTaskUseCase();
    navigation = MockNavigationService();
    changes = DataChangeNotifier();
    viewModel = TaskFormViewModel(
      getTask: getTask,
      createTask: createTask,
      updateTask: updateTask,
      navigation: navigation,
      changes: changes,
    );
  });

  tearDown(() => viewModel.dispose());

  void fillTitle(String title) =>
      viewModel.form.control(TaskFormViewModel.titleField).value = title;

  group('validation', () {
    test('requires a title', () async {
      await viewModel.init();

      await viewModel.submit();

      expect(
        viewModel.form.control(TaskFormViewModel.titleField).errors,
        contains(ValidationKeys.required),
      );
      verifyZeroInteractions(createTask);
    });

    test('rejects a title over 120 characters', () {
      fillTitle('a' * 121);

      expect(
        viewModel.form.control(TaskFormViewModel.titleField).errors,
        contains(ValidationKeys.maxLength),
      );
    });

    test('accepts a title of exactly 120 characters', () {
      fillTitle('a' * 120);

      expect(viewModel.form.valid, isTrue);
    });

    test('rejects a description over 1000 characters', () {
      fillTitle('ok');
      viewModel.form.control(TaskFormViewModel.descriptionField).value =
          'a' * 1001;

      expect(viewModel.form.valid, isFalse);
    });
  });

  group('create', () {
    test('creates the task with every field and closes with true', () async {
      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await viewModel.init();
      final due = DateTime(2026, 5, 20);
      viewModel.form.patchValue({
        TaskFormViewModel.titleField: 'Ship it',
        TaskFormViewModel.descriptionField: 'now',
        TaskFormViewModel.priorityField: TaskPriority.high,
        TaskFormViewModel.dueDateField: due,
      });

      await viewModel.submit();

      final draft = verify(createTask(captureAny)).captured.single as TaskDraft;
      expect(draft.title, 'Ship it');
      expect(draft.description, 'now');
      expect(draft.priority, TaskPriority.high);
      expect(draft.dueDate, due);
      verify(navigation.pop<bool>(true)).called(1);
    });

    test('defaults to medium priority, no deadline and not editing', () async {
      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await viewModel.init();
      fillTitle('Minimal');

      await viewModel.submit();

      final draft = verify(createTask(captureAny)).captured.single as TaskDraft;
      expect(draft.priority, TaskPriority.medium);
      expect(draft.dueDate, isNull);
      expect(viewModel.isEditing, isFalse);
    });

    test('stays open and exposes the failure when creation fails', () async {
      when(
        createTask(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await viewModel.init();
      fillTitle('x');

      await viewModel.submit();

      expect(viewModel.submitFailure, const NetworkFailure());
      expect(viewModel.isBusy, isFalse);
      verifyNever(navigation.pop<bool>(any));
    });

    test('ignores a second submit while saving', () async {
      final completer = Completer<Either<Failure, TaskItem>>();
      when(createTask(any)).thenAnswer((_) => completer.future);
      await viewModel.init();
      fillTitle('x');

      final first = viewModel.submit();
      await Future<void>.delayed(Duration.zero);
      await viewModel.submit();
      completer.complete(right(buildTask()));
      await first;

      verify(createTask(any)).called(1);
    });

    test('cancel closes with false', () {
      viewModel.cancel();

      verify(navigation.pop<bool>(false)).called(1);
    });
  });

  group('edit', () {
    final existing = buildTask(
      id: 't9',
      title: 'Old',
      description: 'desc',
      priority: TaskPriority.low,
      isDone: true,
      dueDate: DateTime.utc(2026, 6, 1, 15),
    );

    test('loads the task into the form', () async {
      when(getTask('t9')).thenAnswer((_) async => right(existing));

      await viewModel.init(taskId: 't9');

      expect(viewModel.isEditing, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.form.control(TaskFormViewModel.titleField).value, 'Old');
      expect(
        viewModel.form.control(TaskFormViewModel.priorityField).value,
        TaskPriority.low,
      );
      expect(
        viewModel.form.control(TaskFormViewModel.isDoneField).value,
        isTrue,
      );
      expect(
        viewModel.form.control(TaskFormViewModel.dueDateField).value,
        DateTime.utc(2026, 6, 1, 15).toLocal(),
      );
    });

    test('is loading while the task is fetched', () async {
      final completer = Completer<Either<Failure, TaskItem>>();
      when(getTask(any)).thenAnswer((_) => completer.future);

      final future = viewModel.init(taskId: 't9');
      expect(viewModel.isLoading, isTrue);
      completer.complete(right(existing));
      await future;

      expect(viewModel.isLoading, isFalse);
    });

    test('saves changes on top of the original task', () async {
      when(getTask(any)).thenAnswer((_) async => right(existing));
      when(updateTask(any)).thenAnswer((_) async => right(existing));
      await viewModel.init(taskId: 't9');
      fillTitle('New title');
      viewModel.form.control(TaskFormViewModel.isDoneField).value = false;

      await viewModel.submit();

      final saved = verify(updateTask(captureAny)).captured.single as TaskItem;
      expect(saved.id, 't9');
      expect(saved.title, 'New title');
      expect(saved.isDone, isFalse);
      expect(saved.createdAt, existing.createdAt);
      verify(navigation.pop<bool>(true)).called(1);
      verifyNever(createTask(any));
    });

    test('clearing the deadline removes it from the saved task', () async {
      when(getTask(any)).thenAnswer((_) async => right(existing));
      when(updateTask(any)).thenAnswer((_) async => right(existing));
      await viewModel.init(taskId: 't9');

      viewModel.clearDueDate();
      await viewModel.submit();

      final saved = verify(updateTask(captureAny)).captured.single as TaskItem;
      expect(saved.dueDate, isNull);
    });

    test('exposes the load failure and can retry', () async {
      when(
        getTask(any),
      ).thenAnswer((_) async => left(const ServerFailure('not_found')));
      await viewModel.init(taskId: 't9');
      expect(viewModel.loadFailure, const ServerFailure('not_found'));

      when(getTask(any)).thenAnswer((_) async => right(existing));
      await viewModel.retryLoad();

      expect(viewModel.loadFailure, isNull);
      expect(viewModel.form.control(TaskFormViewModel.titleField).value, 'Old');
    });

    test('does not save when the task could not be loaded', () async {
      when(getTask(any)).thenAnswer((_) async => left(const NetworkFailure()));
      await viewModel.init(taskId: 't9');
      fillTitle('x');

      await viewModel.submit();

      verifyZeroInteractions(updateTask);
      verifyNever(navigation.pop<bool>(any));
    });

    test('keeps the form open when the update fails', () async {
      when(getTask(any)).thenAnswer((_) async => right(existing));
      when(
        updateTask(any),
      ).thenAnswer((_) async => left(const ServerFailure()));
      await viewModel.init(taskId: 't9');

      await viewModel.submit();

      expect(viewModel.submitFailure, const ServerFailure());
      verifyNever(navigation.pop<bool>(any));
    });
  });

  group('data change notifications', () {
    test('announces a saved task and stays silent when saving fails', () async {
      var notified = 0;
      changes.onChanged.listen((_) => notified++);
      await viewModel.init();
      fillTitle('x');
      when(
        createTask(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await viewModel.submit();
      await Future<void>.delayed(Duration.zero);
      expect(notified, 0);

      when(createTask(any)).thenAnswer((_) async => right(buildTask()));
      await viewModel.submit();
      await Future<void>.delayed(Duration.zero);

      expect(notified, 1);
    });
  });

  group('while loading', () {
    test('ignores a submit made before the task finished loading', () async {
      final completer = Completer<Either<Failure, TaskItem>>();
      when(getTask(any)).thenAnswer((_) => completer.future);
      final loading = viewModel.init(taskId: 't9');
      fillTitle('typed too early');

      await viewModel.submit();

      verifyZeroInteractions(updateTask);
      verifyZeroInteractions(createTask);
      completer.complete(right(buildTask(id: 't9')));
      await loading;
    });
  });
}
