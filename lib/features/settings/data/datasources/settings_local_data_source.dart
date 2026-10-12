import 'dart:convert';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/features/settings/data/models/settings_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence of preferences; throws [AppException]s only.
///
/// Preferences are not secrets, so plain `SharedPreferences` is appropriate.
abstract interface class SettingsLocalDataSource {
  /// Returns the stored settings, or null when nothing was saved.
  Future<SettingsDto?> read();

  /// Stores [settings].
  Future<void> write(SettingsDto settings);
}

/// [SettingsLocalDataSource] backed by `shared_preferences`.
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  /// Creates the data source.
  const SettingsLocalDataSourceImpl(this._preferences);

  static const String _key = 'settings.v1';

  final SharedPreferences _preferences;

  @override
  Future<SettingsDto?> read() async {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    try {
      return SettingsDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      throw const CacheException('invalid_settings');
      // ignore: avoid_catching_errors, generated fromJson throws TypeError on bad data
    } on TypeError {
      throw const CacheException('invalid_settings');
    }
  }

  @override
  Future<void> write(SettingsDto settings) async {
    final saved = await _preferences.setString(
      _key,
      jsonEncode(settings.toJson()),
    );
    if (!saved) throw const CacheException('settings_not_saved');
  }
}
