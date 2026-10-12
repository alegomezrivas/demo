import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/features/tasks/data/models/task_dto.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_page_dto.freezed.dart';
part 'task_page_dto.g.dart';

/// Response of the task listing endpoint.
@freezed
abstract class TaskPageDto with _$TaskPageDto {
  /// Creates a DTO.
  const factory TaskPageDto({
    required List<TaskDto> items,
    required int page,
    required int pageSize,
    required int total,
  }) = _TaskPageDto;

  /// Parses the backend JSON.
  factory TaskPageDto.fromJson(Map<String, dynamic> json) =>
      _$TaskPageDtoFromJson(json);
}

/// Mapping to the domain layer.
extension TaskPageDtoMapper on TaskPageDto {
  /// Converts this DTO to a [PagedResult] of [TaskItem]s.
  PagedResult<TaskItem> toEntity() {
    return PagedResult<TaskItem>(
      items: items.map((dto) => dto.toEntity()).toList(growable: false),
      page: page,
      pageSize: pageSize,
      total: total,
    );
  }
}
