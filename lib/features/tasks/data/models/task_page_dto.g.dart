// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskPageDto _$TaskPageDtoFromJson(Map<String, dynamic> json) => _TaskPageDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => TaskDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  page: (json['page'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$TaskPageDtoToJson(_TaskPageDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'page': instance.page,
      'pageSize': instance.pageSize,
      'total': instance.total,
    };
