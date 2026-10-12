import 'dart:async';

import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/core/widgets/empty_view.dart';
import 'package:demo/core/widgets/error_view.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/presentation/utils/task_labels.dart';
import 'package:demo/features/tasks/presentation/viewmodels/tasks_view_model.dart';
import 'package:demo/features/tasks/presentation/widgets/task_tile.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Task list tab: search, filters, infinite scroll and quick actions.
class TasksView extends StatelessWidget {
  /// Creates the view; [clock] can be replaced in tests.
  const TasksView({this.clock = DateTime.now, super.key});

  /// Source of the current time.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<TasksViewModel>.reactive(
      viewModelBuilder: () => locator<TasksViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, _) {
        _showPendingError(context, viewModel, l10n);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.tasksTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: viewModel.openCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.tasksNew),
          ),
          body: Column(
            children: [
              _Filters(viewModel: viewModel, l10n: l10n),
              if (viewModel.isBusy && viewModel.items.isNotEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: _Content(viewModel: viewModel, clock: clock),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPendingError(
    BuildContext context,
    TasksViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final failure = viewModel.takeActionFailure();
    if (failure == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.viewModel, required this.l10n});

  final TasksViewModel viewModel;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReactiveForm(
            formGroup: viewModel.form,
            child: AppTextField(
              formControlName: TasksViewModel.searchField,
              label: l10n.tasksSearchLabel,
              prefixIcon: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
            ),
          ),
          SizedBox(height: spacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in TaskStatusFilter.values)
                  Padding(
                    padding: EdgeInsets.only(right: spacing.sm),
                    child: ChoiceChip(
                      label: Text(status.label(l10n)),
                      selected: viewModel.query.status == status,
                      onSelected: (_) => viewModel.setStatus(status),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: spacing.sm),
                  child: ChoiceChip(
                    label: Text(l10n.tasksPriorityAny),
                    selected: viewModel.query.priority == null,
                    onSelected: (_) => viewModel.setPriority(null),
                  ),
                ),
                for (final priority in TaskPriority.values)
                  Padding(
                    padding: EdgeInsets.only(right: spacing.sm),
                    child: ChoiceChip(
                      label: Text(priority.label(l10n)),
                      selected: viewModel.query.priority == priority,
                      onSelected: (_) => viewModel.setPriority(priority),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.viewModel, required this.clock});

  final TasksViewModel viewModel;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = viewModel.items;
    final failure = viewModel.failure;

    if (viewModel.isBusy && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (failure != null) {
      return ErrorView(
        message: failure.message(l10n),
        retryLabel: l10n.commonRetry,
        onRetry: viewModel.refresh,
      );
    }
    if (items.isEmpty) {
      return EmptyView(
        message: viewModel.hasActiveFilters
            ? l10n.tasksEmptyFiltered
            : l10n.tasksEmpty,
        icon: Icons.checklist_outlined,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 240) {
          unawaited(viewModel.loadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView.builder(
          padding: EdgeInsets.all(context.spacing.md),
          itemCount: items.length + (viewModel.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return Padding(
                padding: EdgeInsets.all(context.spacing.md),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final task = items[index];
            return TaskTile(
              key: ValueKey(task.id),
              task: task,
              now: clock(),
              onToggle: () => viewModel.toggleDone(task),
              onTap: () => viewModel.openEdit(task),
              onDelete: () => _confirmDelete(context, task),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TaskItem task) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tasksDeleteTitle),
        content: Text(l10n.tasksDeleteMessage(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await viewModel.delete(task, reason: l10n.biometricReasonDelete);
    }
  }
}
