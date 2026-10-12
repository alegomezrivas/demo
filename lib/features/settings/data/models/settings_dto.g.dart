// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsDto _$SettingsDtoFromJson(Map<String, dynamic> json) => _SettingsDto(
  themeMode: json['themeMode'] as String? ?? 'system',
  language: json['language'] as String? ?? 'system',
  biometricConfirmation: json['biometricConfirmation'] as bool? ?? false,
);

Map<String, dynamic> _$SettingsDtoToJson(_SettingsDto instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'language': instance.language,
      'biometricConfirmation': instance.biometricConfirmation,
    };
