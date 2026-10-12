import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the create / edit task form.
class TaskFormViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  TaskFormViewModel({
    required GetTaskUseCase getTask,
    required CreateTaskUseCase createTask,
    required UpdateTaskUseCase updateTask,
    required NavigationService navigation,
    required DataChangeNotifier changes,
  }) : _getTask = getTask,
       _createTask = createTask,
       _updateTask = updateTask,
       _navigation = navigation,
       _changes = changes;

  /// Name of the title control.
  static const String titleField = 'title';

  /// Name of the description control.
  static const String descriptionField = 'description';

  /// Name of the priority control.
  static const String priorityField = 'priority';

  /// Name of the due date control.
  static const String dueDateField = 'dueDate';

  /// Name of the completion control.
  static const String isDoneField = 'isDone';

  /// Longest accepted title.
  static const int maxTitleLength = 120;

  /// Longest accepted description.
  static const int maxDescriptionLength = 1000;

  final GetTaskUseCase _getTask;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final NavigationService _navigation;
  final DataChangeNotifier _changes;

  final FormControl<String> _title = FormControl<String>(
    validators: [AppValidators.required, Validators.maxLength(maxTitleLength)],
  );
  final FormControl<String> _description = FormControl<String>(
    value: '',
    validators: [Validators.maxLength(maxDescriptionLength)],
  );
  final FormControl<TaskPriority> _priority = FormControl<TaskPriority>(
    value: TaskPriority.medium,
  );
  final FormControl<DateTime> _dueDate = FormControl<DateTime>();
  final FormControl<bool> _isDone = FormControl<bool>(value: false);

  /// The task form.
  late final FormGroup form = FormGroup({
    titleField: _title,
    descriptionField: _description,
    priorityField: _priority,
    dueDateField: _dueDate,
    isDoneField: _isDone,
  });

  String? _taskId;
  TaskItem? _original;
  bool _isLoading = false;
  Failure? _loadFailure;
  Failure? _submitFailure;

  /// Whether an existing task is being edited.
  bool get isEditing => _taskId != null;

  /// Whether the task to edit is being fetched.
  bool get isLoading => _isLoading;

  /// Failure while fetching the task to edit.
  Failure? get loadFailure => _loadFailure;

  /// Failure while saving.
  Failure? get submitFailure => _submitFailure;

  /// Prepares the form; loads the task when [taskId] is given.
  Future<void> init({String? taskId}) async {
    _taskId = taskId;
    if (taskId == null) return;

    _isLoading = true;
    _loadFailure = null;
    notifyListeners();
    final result = await _getTask(taskId);
    result.fold((failure) => _loadFailure = failure, (task) {
      _original = task;
      form.patchValue({
        titleField: task.title,
        descriptionField: task.description,
        priorityField: task.priority,
        dueDateField: task.dueDate?.toLocal(),
        isDoneField: task.isDone,
      });
    });
    _isLoading = false;
    notifyListeners();
  }

  /// Retries loading after a failure.
  Future<void> retryLoad() => init(taskId: _taskId);

  /// Removes the deadline.
  void clearDueDate() => _dueDate.value = null;

  /// Validates the form, saves and closes the screen with `true`.
  Future<void> submit() async {
    if (isBusy || _isLoading) return;
    if (form.invalid) {
      form.markAllAsTouched();
      notifyListeners();
      return;
    }
    final original = _original;
    if (isEditing && original == null) return;

    _submitFailure = null;
    setBusy(true);
    final title = _title.value ?? '';
    final description = _description.value ?? '';
    final priority = _priority.value ?? TaskPriority.medium;
    final dueDate = _dueDate.value;

    final result = original == null
        ? await _createTask(
            TaskDraft(
              title: title,
              description: description,
              priority: priority,
              dueDate: dueDate,
            ),
          )
        : await _updateTask(
            original.copyWith(
              title: title,
              description: description,
              priority: priority,
              isDone: _isDone.value ?? original.isDone,
              dueDate: dueDate,
              clearDueDate: dueDate == null,
            ),
          );
    setBusy(false);

    result.fold(
      (failure) {
        _submitFailure = failure;
        notifyListeners();
      },
      (_) {
        _changes.notifyChanged();
        _navigation.pop<bool>(true);
      },
    );
  }

  /// Closes the form without saving.
  void cancel() => _navigation.pop<bool>(false);

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }
}
