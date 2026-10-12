import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/data_change_notifier.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_stats_use_case.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the dashboard: greeting and task statistics.
class DashboardViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  DashboardViewModel({
    required this._getCurrentUser,
    required this._getStats,
    required this._navigation,
    required this._changes,
  });

  final GetCurrentUserUseCase _getCurrentUser;
  final GetTaskStatsUseCase _getStats;
  final NavigationService _navigation;
  final DataChangeNotifier _changes;
  StreamSubscription<void>? _subscription;

  User? _user;
  TaskStats? _stats;
  Failure? _failure;
  int _requestId = 0;

  /// The signed-in user, once loaded.
  User? get user => _user;

  /// Task statistics, once loaded.
  TaskStats? get stats => _stats;

  /// Failure while loading the statistics.
  Failure? get failure => _failure;

  /// Loads the user and the statistics, and reloads them whenever tasks change
  /// elsewhere in the app.
  Future<void> init() async {
    _subscription ??= _changes.onChanged.listen(
      (_) => unawaited(_load(showSpinner: false)),
    );
    await _load(showSpinner: true);
  }

  Future<void> _load({required bool showSpinner}) async {
    final requestId = ++_requestId;
    _failure = null;
    if (showSpinner) setBusy(true);
    final results = await (
      _getCurrentUser(const NoParams()),
      _getStats(const NoParams()),
    ).wait;
    // A newer load owns the state; also nothing to update after dispose.
    if (requestId != _requestId || disposed) return;

    _user = results.$1.fold((_) => null, (user) => user);
    // Previous statistics are kept on failure so a refresh error does not
    // blank the screen; the view only shows the error when there are none.
    results.$2.fold((failure) => _failure = failure, (stats) => _stats = stats);
    if (isBusy) {
      setBusy(false);
    } else {
      notifyListeners();
    }
  }

  /// Reloads everything (pull to refresh / retry).
  Future<void> refresh() => _load(showSpinner: true);

  /// Switches to the task list.
  void openTasks() => _navigation.go(AppRoutes.tasks);

  /// Opens the task form and reloads the statistics if a task was created.
  Future<void> createTask() async {
    final created = await _navigation.push<bool>(AppRoutes.taskNew);
    if (created ?? false) await refresh();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
