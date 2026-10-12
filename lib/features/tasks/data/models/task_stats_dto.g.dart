// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_stats_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskStatsDto _$TaskStatsDtoFromJson(Map<String, dynamic> json) =>
    _TaskStatsDto(
      total: (json['total'] as num).toInt(),
      done: (json['done'] as num).toInt(),
      overdue: (json['overdue'] as num).toInt(),
      highPriorityPending: (json['highPriorityPending'] as num).toInt(),
    );

Map<String, dynamic> _$TaskStatsDtoToJson(_TaskStatsDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'done': instance.done,
      'overdue': instance.overdue,
      'highPriorityPending': instance.highPriorityPending,
    };
