import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/presentation/utils/task_labels.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row of the task list.
class TaskTile extends StatelessWidget {
  /// Creates the tile; [now] decides whether the deadline is overdue.
  const TaskTile({
    required this.task,
    required this.now,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  /// Task to show.
  final TaskItem task;

  /// Reference time for the overdue check.
  final DateTime now;

  /// Called when the checkbox is tapped.
  final VoidCallback onToggle;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Called when the delete button is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final dueDate = task.dueDate?.toLocal();
    final overdue = task.isOverdue(now);
    final dateText = dueDate == null
        ? null
        : l10n.tasksDueDate(
            DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(dueDate),
          );

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: task.isDone, onChanged: (_) => onToggle()),
        title: Text(
          task.title,
          style: context.text.body.copyWith(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? colors.textSecondary : colors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: context.spacing.xs),
          child: Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                task.priority.label(l10n),
                style: context.text.label.copyWith(
                  color: task.priority.color(colors),
                ),
              ),
              if (dateText != null)
                Text(
                  overdue ? '${l10n.tasksOverdue} · $dateText' : dateText,
                  style: context.text.bodySmall.copyWith(
                    color: overdue ? colors.error : colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
