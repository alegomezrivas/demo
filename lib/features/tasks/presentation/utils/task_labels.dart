import 'package:demo/core/theme/app_colors.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/painting.dart';

/// Localized text and color of a [TaskPriority].
extension TaskPriorityPresentation on TaskPriority {
  /// Text shown in chips and selectors.
  String label(AppLocalizations l10n) => switch (this) {
    TaskPriority.low => l10n.priorityLow,
    TaskPriority.medium => l10n.priorityMedium,
    TaskPriority.high => l10n.priorityHigh,
  };

  /// Semantic color taken from the palette.
  Color color(AppColors colors) => switch (this) {
    TaskPriority.low => colors.success,
    TaskPriority.medium => colors.warning,
    TaskPriority.high => colors.error,
  };
}

/// Localized text of a [TaskStatusFilter].
extension TaskStatusFilterLabel on TaskStatusFilter {
  /// Text shown in filter chips.
  String label(AppLocalizations l10n) => switch (this) {
    TaskStatusFilter.all => l10n.tasksFilterAll,
    TaskStatusFilter.pending => l10n.tasksFilterPending,
    TaskStatusFilter.done => l10n.tasksFilterDone,
  };
}
