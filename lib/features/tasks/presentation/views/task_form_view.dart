import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_text_field.dart';
import 'package:demo/core/widgets/error_view.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:demo/features/tasks/presentation/utils/task_labels.dart';
import 'package:demo/features/tasks/presentation/viewmodels/task_form_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Create / edit task screen (`taskId` null means create).
class TaskFormView extends StatelessWidget {
  /// Creates the view.
  const TaskFormView({this.taskId, super.key});

  /// Id of the task to edit, or null to create one.
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<TaskFormViewModel>.reactive(
      viewModelBuilder: () => locator<TaskFormViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(taskId: taskId),
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(viewModel.isEditing ? l10n.tasksEdit : l10n.tasksNew),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.commonCancel,
              onPressed: viewModel.cancel,
            ),
          ),
          body: _body(context, viewModel, l10n),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    TaskFormViewModel viewModel,
    AppLocalizations l10n,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loadFailure = viewModel.loadFailure;
    if (loadFailure != null) {
      return ErrorView(
        message: loadFailure.message(l10n),
        retryLabel: l10n.commonRetry,
        onRetry: viewModel.retryLoad,
      );
    }

    final messages = ValidationMessages.of(l10n);
    final submitFailure = viewModel.submitFailure;
    return SingleChildScrollView(
      padding: context.spacing.screenPadding,
      child: ReactiveForm(
        formGroup: viewModel.form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              formControlName: TaskFormViewModel.titleField,
              label: l10n.tasksFieldTitle,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              validationMessages: messages,
            ),
            SizedBox(height: context.spacing.md),
            AppTextField(
              formControlName: TaskFormViewModel.descriptionField,
              label: l10n.tasksFieldDescription,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validationMessages: messages,
            ),
            SizedBox(height: context.spacing.md),
            ReactiveDropdownField<TaskPriority>(
              formControlName: TaskFormViewModel.priorityField,
              decoration: InputDecoration(labelText: l10n.tasksFieldPriority),
              items: [
                for (final priority in TaskPriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label(l10n)),
                  ),
              ],
            ),
            SizedBox(height: context.spacing.md),
            ReactiveDatePicker<DateTime>(
              formControlName: TaskFormViewModel.dueDateField,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, picker, child) {
                final value = picker.control.value;
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.tasksFieldDueDate,
                    suffixIcon: value == null
                        ? const Icon(Icons.calendar_today_outlined)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.tasksClearDate,
                            onPressed: viewModel.clearDueDate,
                          ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: picker.showPicker,
                    child: Text(
                      value == null
                          ? ' '
                          : DateFormat.yMMMd(
                              Localizations.localeOf(context).toString(),
                            ).format(value),
                      style: context.text.body,
                    ),
                  ),
                );
              },
            ),
            if (viewModel.isEditing) ...[
              SizedBox(height: context.spacing.sm),
              ReactiveSwitchListTile(
                formControlName: TaskFormViewModel.isDoneField,
                title: Text(l10n.tasksFieldDone),
              ),
            ],
            if (submitFailure != null) ...[
              SizedBox(height: context.spacing.md),
              Text(
                submitFailure.message(l10n),
                key: const Key('task_form_error'),
                style: context.text.bodySmall.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            SizedBox(height: context.spacing.lg),
            AppPrimaryButton(
              label: l10n.commonSave,
              isLoading: viewModel.isBusy,
              onPressed: viewModel.submit,
            ),
          ],
        ),
      ),
    );
  }
}
