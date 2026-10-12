import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/sensitive_action_guard.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_tasks_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the task list: search, filters, pagination and quick actions.
class TasksViewModel extends BaseViewModel {
  /// Creates the ViewModel; [_searchDebounce] delays searches while typing.
  TasksViewModel({
    required this._getTasks,
    required this._updateTask,
    required this._deleteTask,
    required this._guard,
    required this._navigation,
    required this._changes,
    this._searchDebounce = defaultSearchDebounce,
  });

  /// Default wait after the last keystroke before searching.
  static const Duration defaultSearchDebounce = Duration(milliseconds: 400);

  /// Name of the search control.
  static const String searchField = 'search';

  final GetTasksUseCase _getTasks;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final SensitiveActionGuard _guard;
  final NavigationService _navigation;
  final DataChangeNotifier _changes;
  final Duration _searchDebounce;

  final FormControl<String> _search = FormControl<String>();

  /// The search form (a single text control).
  late final FormGroup form = FormGroup({searchField: _search});

  final List<TaskItem> _items = [];
  TaskQuery _query = const TaskQuery();
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _total = 0;
  int _requestId = 0;
  Failure? _failure;
  Failure? _actionFailure;
  Timer? _debounce;
  StreamSubscription<String?>? _searchSubscription;

  /// Tasks loaded so far (all pages).
  List<TaskItem> get items => List.unmodifiable(_items);

  /// Active search / filters / page.
  TaskQuery get query => _query;

  /// Whether more pages can be requested.
  bool get hasMore => _hasMore;

  /// Whether the next page is being fetched.
  bool get isLoadingMore => _isLoadingMore;

  /// Number of tasks matching the current filters on the server.
  int get total => _total;

  /// Failure of the last list load (shown as a full-screen error when empty).
  Failure? get failure => _failure;

  /// Whether any search text or filter is active.
  bool get hasActiveFilters =>
      _query.search.isNotEmpty ||
      _query.status != TaskStatusFilter.all ||
      _query.priority != null;

  /// Starts listening to the search box and loads the first page.
  Future<void> init() async {
    _searchSubscription ??= _search.valueChanges.listen(_onSearchChanged);
    await _loadFirstPage();
  }

  /// Reloads the first page keeping the current filters.
  Future<void> refresh() => _loadFirstPage();

  /// Requests the next page, if any.
  Future<void> loadMore() async {
    if (isBusy || _isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    _isLoadingMore = true;
    notifyListeners();

    final next = _query.copyWith(page: _query.page + 1);
    final result = await _getTasks(next);
    if (requestId != _requestId) return; // Filters changed meanwhile.

    result.fold((failure) => _actionFailure = failure, (page) {
      final known = _items.map((item) => item.id).toSet();
      _items.addAll(page.items.where((item) => !known.contains(item.id)));
      _query = next;
      _hasMore = page.hasMore;
      _total = page.total;
    });
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Filters by completion status.
  Future<void> setStatus(TaskStatusFilter status) {
    if (status == _query.status) return Future.value();
    _query = _query.copyWith(status: status);
    return _loadFirstPage();
  }

  /// Filters by priority; null removes the filter.
  Future<void> setPriority(TaskPriority? priority) {
    if (priority == _query.priority) return Future.value();
    _query = priority == null
        ? _query.copyWith(clearPriority: true)
        : _query.copyWith(priority: priority);
    return _loadFirstPage();
  }

  /// Completes or reopens [item], rolling back if the server refuses.
  Future<void> toggleDone(TaskItem item) async {
    final index = _indexOf(item.id);
    if (index == -1) return;
    _items[index] = item.copyWith(isDone: !item.isDone);
    notifyListeners();

    final result = await _updateTask(_items[index]);
    final current = _indexOf(item.id);
    if (current == -1) return;
    result.fold(
      (failure) {
        _items[current] = item;
        _actionFailure = failure;
      },
      (saved) {
        _changes.notifyChanged();
        if (_matchesStatus(saved)) {
          _items[current] = saved;
        } else {
          _items.removeAt(current);
          _total = _total > 0 ? _total - 1 : 0;
        }
      },
    );
    notifyListeners();
  }

  /// Deletes [item] after the optional biometric confirmation.
  Future<void> delete(TaskItem item, {required String reason}) async {
    if (!await _guard.confirm(reason: reason)) return;
    final result = await _deleteTask(item.id);
    result.fold((failure) => _actionFailure = failure, (_) {
      _items.removeWhere((candidate) => candidate.id == item.id);
      _total = _total > 0 ? _total - 1 : 0;
      _changes.notifyChanged();
    });
    notifyListeners();
  }

  /// Opens the creation form and refreshes the list if a task was created.
  Future<void> openCreate() async {
    final changed = await _navigation.push<bool>(AppRoutes.taskNew);
    if (changed ?? false) await refresh();
  }

  /// Opens the edit form and refreshes the list if the task changed.
  Future<void> openEdit(TaskItem item) async {
    final changed = await _navigation.push<bool>(AppRoutes.task(item.id));
    if (changed ?? false) await refresh();
  }

  /// Returns the pending action error once (for a snack bar) and clears it.
  Failure? takeActionFailure() {
    final failure = _actionFailure;
    _actionFailure = null;
    return failure;
  }

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  bool _matchesStatus(TaskItem item) => switch (_query.status) {
    TaskStatusFilter.all => true,
    TaskStatusFilter.pending => !item.isDone,
    TaskStatusFilter.done => item.isDone,
  };

  void _onSearchChanged(String? text) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final search = (text ?? '').trim();
      if (search == _query.search) return;
      _query = _query.copyWith(search: search);
      unawaited(_loadFirstPage());
    });
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    _failure = null;
    _isLoadingMore = false;
    _query = _query.copyWith(page: 1);
    setBusy(true);

    final result = await _getTasks(_query);
    if (requestId != _requestId) return; // A newer request owns the state.

    result.fold(
      (failure) {
        _failure = failure;
        _items.clear();
        _hasMore = false;
        _total = 0;
      },
      (page) {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _total = page.total;
      },
    );
    setBusy(false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_searchSubscription?.cancel());
    form.dispose();
    super.dispose();
  }
}
