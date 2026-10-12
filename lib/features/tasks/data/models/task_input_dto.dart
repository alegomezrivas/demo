import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_input_dto.freezed.dart';
part 'task_input_dto.g.dart';

/// Body of the create and update endpoints.
@freezed
abstract class TaskInputDto with _$TaskInputDto {
  /// Creates the request body.
  const factory TaskInputDto({
    required String title,
    required String description,
    required String priority,
    required bool isDone,
    String? dueDate,
  }) = _TaskInputDto;

  /// Parses the JSON representation.
  factory TaskInputDto.fromJson(Map<String, dynamic> json) =>
      _$TaskInputDtoFromJson(json);

  /// Builds the body from a [draft], already sanitized.
  factory TaskInputDto.fromDraft(
    TaskDraft draft, {
    required String title,
    required String description,
  }) {
    return TaskInputDto(
      title: title,
      description: description,
      priority: draft.priority.name,
      isDone: draft.isDone,
      dueDate: draft.dueDate?.toUtc().toIso8601String(),
    );
  }

  /// Builds the body from a [task], already sanitized.
  factory TaskInputDto.fromItem(
    TaskItem task, {
    required String title,
    required String description,
  }) {
    return TaskInputDto.fromDraft(
      TaskDraft(
        title: title,
        description: description,
        priority: task.priority,
        isDone: task.isDone,
        dueDate: task.dueDate,
      ),
      title: title,
      description: description,
    );
  }
}
