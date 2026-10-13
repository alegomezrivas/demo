// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_code_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerifyCodeRequestDto _$VerifyCodeRequestDtoFromJson(
  Map<String, dynamic> json,
) => _VerifyCodeRequestDto(
  email: json['email'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$VerifyCodeRequestDtoToJson(
  _VerifyCodeRequestDto instance,
) => <String, dynamic>{'email': instance.email, 'code': instance.code};
