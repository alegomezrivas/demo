// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_input_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskInputDto _$TaskInputDtoFromJson(Map<String, dynamic> json) =>
    _TaskInputDto(
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      isDone: json['isDone'] as bool,
      dueDate: json['dueDate'] as String?,
    );

Map<String, dynamic> _$TaskInputDtoToJson(_TaskInputDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'isDone': instance.isDone,
      'dueDate': instance.dueDate,
    };
