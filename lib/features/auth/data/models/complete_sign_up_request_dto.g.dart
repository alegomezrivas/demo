// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_sign_up_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompleteSignUpRequestDto _$CompleteSignUpRequestDtoFromJson(
  Map<String, dynamic> json,
) => _CompleteSignUpRequestDto(
  verificationToken: json['verificationToken'] as String,
  name: json['name'] as String,
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$CompleteSignUpRequestDtoToJson(
  _CompleteSignUpRequestDto instance,
) => <String, dynamic>{
  'verificationToken': instance.verificationToken,
  'name': instance.name,
  'username': instance.username,
  'password': instance.password,
};
