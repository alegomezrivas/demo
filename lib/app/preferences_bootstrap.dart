import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';

/// Loads the saved preferences before the first frame.
///
/// If they cannot be read the defaults stay in place.
Future<void> loadPreferences({
  required GetSettingsUseCase getSettings,
  required AppPreferences preferences,
}) async {
  final result = await getSettings(const NoParams());
  result.fold((_) {}, preferences.apply);
}
