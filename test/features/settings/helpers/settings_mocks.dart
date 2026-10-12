import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:demo/core/security/sensitive_action_guard.dart';
import 'package:demo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:demo/features/settings/domain/repositories/settings_repository.dart';
import 'package:demo/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:demo/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:mockito/annotations.dart';

export 'settings_mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsRepository>(),
  MockSpec<SettingsLocalDataSource>(),
  MockSpec<GetSettingsUseCase>(),
  MockSpec<SaveSettingsUseCase>(),
  MockSpec<BiometricAuthenticator>(),
  MockSpec<SensitiveActionGuard>(),
])
void main() {}
