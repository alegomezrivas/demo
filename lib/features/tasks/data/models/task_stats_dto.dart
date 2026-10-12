import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_stats_dto.freezed.dart';
part 'task_stats_dto.g.dart';

/// Response of the statistics endpoint.
@freezed
abstract class TaskStatsDto with _$TaskStatsDto {
  /// Creates a DTO.
  const factory TaskStatsDto({
    required int total,
    required int done,
    required int overdue,
    required int highPriorityPending,
  }) = _TaskStatsDto;

  /// Parses the backend JSON.
  factory TaskStatsDto.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsDtoFromJson(json);
}

/// Mapping to the domain layer.
extension TaskStatsDtoMapper on TaskStatsDto {
  /// Converts this DTO to domain [TaskStats].
  TaskStats toEntity() => TaskStats(
    total: total,
    done: done,
    overdue: overdue,
    highPriorityPending: highPriorityPending,
  );
}
