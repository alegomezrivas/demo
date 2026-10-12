import 'package:demo/core/security/security_policy.dart';
import 'package:flutter/foundation.dart';

/// Deployment environment the app runs in.
enum AppEnvironment {
  /// Local development.
  dev,

  /// Pre-production.
  staging,

  /// Production.
  prod
  ;

  /// Parses [value] (case-insensitive); unknown values fall back to [dev].
  static AppEnvironment parse(String value) =>
      tryParse(value) ?? AppEnvironment.dev;

  /// Parses [value] (case-insensitive), or returns null when it is unknown.
  static AppEnvironment? tryParse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final env in AppEnvironment.values) {
      if (env.name == normalized) return env;
    }
    return null;
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
    this.protectScreens = true,
  });

  /// Reads the configuration compiled into the app via `--dart-define`.
  ///
  /// The mock API can never be active in release builds, whatever the flag
  /// says. Release (and profile) builds also refuse to start with a missing or
  /// weak configuration; see [AppConfig.fromValues].
  factory AppConfig.fromEnvironment({
    bool isRelease = kReleaseMode || kProfileMode,
  }) {
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
  ///
  /// With [isRelease] the configuration is validated so a build made without
  /// its `--dart-define-from-file` cannot ship with weak defaults:
  /// * `ENV` must be `staging` or `prod` (a missing or unknown value throws);
  /// * `prod` must enable certificate pinning;
  /// * an unknown `ROOT_POLICY` resolves to the strict `block`.
  ///
  /// Throws a [StateError] when a release configuration is invalid.
  factory AppConfig.fromValues({
    required String environment,
    required String apiBaseUrl,
    required bool useMockApi,
    required bool pinningEnabled,
    required String pinnedSha256,
    required String rootPolicy,
    required bool isRelease,
    bool protectScreens = true,
  }) {
    final parsedEnvironment = AppEnvironment.tryParse(environment);
    if (isRelease) {
      if (parsedEnvironment == null ||
          parsedEnvironment == AppEnvironment.dev) {
        throw StateError(
          'Release builds need ENV=staging or ENV=prod. '
          'Build with --dart-define-from-file=config/<env>.json.',
        );
      }
      if (parsedEnvironment == AppEnvironment.prod && !pinningEnabled) {
        throw StateError('Production builds must set PINNING_ENABLED=true.');
      }
    }
    return AppConfig(
      environment: parsedEnvironment ?? AppEnvironment.dev,
      apiBaseUrl: apiBaseUrl,
      useMockApi: useMockApi && !isRelease,
      pinningEnabled: pinningEnabled,
      pinnedSha256: pinnedSha256
          .split(',')
          .map((fingerprint) => fingerprint.trim())
          .where((fingerprint) => fingerprint.isNotEmpty)
          .toList(growable: false),
      rootPolicy: SecurityPolicy.parse(
        rootPolicy,
        fallback: isRelease ? SecurityPolicy.block : SecurityPolicy.warn,
      ),
      protectScreens: protectScreens,
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

  /// Whether the authenticated app hides its content from screenshots and the
  /// app-switcher preview. Turn it off (`PROTECT_SCREENS=false`) only for
  /// demo builds that need screenshots.
  final bool protectScreens;
}
