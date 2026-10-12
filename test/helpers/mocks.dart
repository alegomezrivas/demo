import 'package:demo/core/network/token_refresher.dart';
import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NavigationService>(),
  MockSpec<FlutterSecureStorage>(),
  MockSpec<JailbreakRootDetection>(),
  MockSpec<LocalAuthentication>(),
  MockSpec<TokenRefresher>(),
  MockSpec<TokenStorage>(),
  MockSpec<DeviceIntegrityChecker>(),
  MockSpec<DeviceIntegrityService>(),
])
void main() {}
