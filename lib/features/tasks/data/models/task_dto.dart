import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

/// Wire representation of a [TaskItem].
@freezed
abstract class TaskDto with _$TaskDto {
  /// Creates a DTO.
  const factory TaskDto({
    required String id,
    required String title,
    required String description,
    required String priority,
    required bool isDone,
    required String createdAt,
    String? dueDate,
  }) = _TaskDto;

  /// Parses the backend JSON.
  factory TaskDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDtoFromJson(json);
}

/// Mapping to the domain layer.
extension TaskDtoMapper on TaskDto {
  /// Converts this DTO to a domain [TaskItem].
  TaskItem toEntity() {
    final due = dueDate;
    return TaskItem(
      id: id,
      title: title,
      description: description,
      priority: TaskPriority.parse(priority),
      isDone: isDone,
      createdAt: DateTime.parse(createdAt),
      dueDate: due == null ? null : DateTime.parse(due),
    );
  }
}
