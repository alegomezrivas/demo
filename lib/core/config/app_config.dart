import 'package:demo/core/security/security_policy.dart';
import 'package:flutter/foundation.dart';

/// Deployment environment the app runs in.
enum AppEnvironment {
  /// Local development.
  dev,

  /// Pre-production.
  staging,

  /// Production.
  prod;

  /// Parses [value] (case-insensitive); unknown values fall back to [dev].
  static AppEnvironment parse(String value) {
    final normalized = value.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (env) => env.name == normalized,
      orElse: () => AppEnvironment.dev,
    );
  }
}

/// Immutable runtime configuration read from `--dart-define-from-file`.
///
/// No secrets live here: only non-sensitive environment settings.
@immutable
class AppConfig {
  /// Creates a configuration explicitly (used by tests).
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.useMockApi,
    required this.pinningEnabled,
    required this.pinnedSha256,
    required this.rootPolicy,
  });

  /// Reads the configuration compiled into the app via `--dart-define`.
  ///
  /// The mock API can never be active in release builds, whatever the flag says.
  factory AppConfig.fromEnvironment({bool isRelease = kReleaseMode}) {
    return AppConfig.fromValues(
      environment: const String.fromEnvironment('ENV', defaultValue: 'dev'),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.example.com',
      ),
      useMockApi: const bool.fromEnvironment('USE_MOCK_API'),
      pinningEnabled: const bool.fromEnvironment('PINNING_ENABLED'),
      pinnedSha256: const String.fromEnvironment('PINNING_SHA256'),
      rootPolicy: const String.fromEnvironment(
        'ROOT_POLICY',
        defaultValue: 'warn',
      ),
      isRelease: isRelease,
    );
  }

  /// Builds a configuration from raw string values.
  factory AppConfig.fromValues({
    required String environment,
    required String apiBaseUrl,
    required bool useMockApi,
    required bool pinningEnabled,
    required String pinnedSha256,
    required String rootPolicy,
    required bool isRelease,
  }) {
    return AppConfig(
      environment: AppEnvironment.parse(environment),
      apiBaseUrl: apiBaseUrl,
      useMockApi: useMockApi && !isRelease,
      pinningEnabled: pinningEnabled,
      pinnedSha256: pinnedSha256
          .split(',')
          .map((fingerprint) => fingerprint.trim())
          .where((fingerprint) => fingerprint.isNotEmpty)
          .toList(growable: false),
      rootPolicy: SecurityPolicy.parse(rootPolicy),
    );
  }

  /// Current deployment environment.
  final AppEnvironment environment;

  /// Base URL of the backend; the only value to change when leaving the mock.
  final String apiBaseUrl;

  /// Whether the Dio mock interceptor is active (never true in release).
  final bool useMockApi;

  /// Whether certificate pinning is enforced.
  final bool pinningEnabled;

  /// Allowed certificate SHA-256 fingerprints (base64).
  final List<String> pinnedSha256;

  /// Reaction to rooted / jailbroken / debugged devices.
  final SecurityPolicy rootPolicy;
}
