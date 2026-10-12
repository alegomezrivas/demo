import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig build({
  String environment = 'dev',
  bool useMockApi = true,
  String pins = '',
  String rootPolicy = 'warn',
  bool isRelease = false,
}) {
  return AppConfig.fromValues(
    environment: environment,
    apiBaseUrl: 'https://api.test',
    useMockApi: useMockApi,
    pinningEnabled: true,
    pinnedSha256: pins,
    rootPolicy: rootPolicy,
    isRelease: isRelease,
  );
}

void main() {
  group('AppEnvironment.parse', () {
    test('parses known environments ignoring case', () {
      expect(AppEnvironment.parse('PROD'), AppEnvironment.prod);
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    });

    test('falls back to dev for unknown values', () {
      expect(AppEnvironment.parse('qa'), AppEnvironment.dev);
    });
  });

  group('AppConfig.fromValues', () {
    test('keeps the mock API enabled outside release builds', () {
      expect(build().useMockApi, isTrue);
    });

    test('never enables the mock API in release builds', () {
      expect(build(isRelease: true).useMockApi, isFalse);
    });

    test('splits, trims and filters certificate pins', () {
      final config = build(pins: ' aaa, bbb ,, ');

      expect(config.pinnedSha256, ['aaa', 'bbb']);
    });

    test('yields an empty pin list for an empty value', () {
      expect(build().pinnedSha256, isEmpty);
    });

    test('parses environment and root policy', () {
      final config = build(environment: 'prod', rootPolicy: 'block');

      expect(config.environment, AppEnvironment.prod);
      expect(config.rootPolicy, SecurityPolicy.block);
    });
  });

  group('AppConfig.fromEnvironment', () {
    test('uses safe defaults when no dart-define is provided', () {
      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.dev);
      expect(config.rootPolicy, SecurityPolicy.warn);
      expect(config.pinningEnabled, isFalse);
    });
  });
}
