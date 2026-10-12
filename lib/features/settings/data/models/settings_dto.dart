import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_dto.freezed.dart';
part 'settings_dto.g.dart';

/// Stored representation of [AppSettings].
@freezed
abstract class SettingsDto with _$SettingsDto {
  /// Creates a DTO.
  const factory SettingsDto({
    @Default('system') String themeMode,
    @Default('system') String language,
    @Default(false) bool biometricConfirmation,
  }) = _SettingsDto;

  /// Parses the stored JSON.
  factory SettingsDto.fromJson(Map<String, dynamic> json) =>
      _$SettingsDtoFromJson(json);

  /// Builds a DTO from domain [AppSettings].
  factory SettingsDto.fromEntity(AppSettings settings) => SettingsDto(
    themeMode: settings.themeMode.name,
    language: settings.language.name,
    biometricConfirmation: settings.biometricConfirmation,
  );
}

/// Mapping to the domain layer.
extension SettingsDtoMapper on SettingsDto {
  /// Converts this DTO to domain [AppSettings].
  AppSettings toEntity() => AppSettings(
    themeMode: AppThemeMode.parse(themeMode),
    language: AppLanguage.parse(language),
    biometricConfirmation: biometricConfirmation,
  );
}
