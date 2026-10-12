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
  group('AppEnvironment.tryParse', () {
    test('returns null for unknown values', () {
      expect(AppEnvironment.tryParse('qa'), isNull);
      expect(AppEnvironment.tryParse(' Staging '), AppEnvironment.staging);
    });
  });

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
      expect(
        build(environment: 'staging', isRelease: true).useMockApi,
        isFalse,
      );
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

  group('AppConfig release validation', () {
    test(
      'refuses to start without ENV (default dev) or with an unknown one',
      () {
        expect(() => build(isRelease: true), throwsStateError);
        expect(
          () => build(environment: 'qa', isRelease: true),
          throwsStateError,
        );
        expect(() => build(environment: '', isRelease: true), throwsStateError);
      },
    );

    test('accepts staging and prod', () {
      expect(
        build(environment: 'staging', isRelease: true).environment,
        AppEnvironment.staging,
      );
      expect(
        build(environment: 'PROD', isRelease: true).environment,
        AppEnvironment.prod,
      );
    });

    test('prod must enable certificate pinning', () {
      expect(
        () => AppConfig.fromValues(
          environment: 'prod',
          apiBaseUrl: 'https://api.test',
          useMockApi: false,
          pinningEnabled: false,
          pinnedSha256: 'aaa,bbb',
          rootPolicy: 'block',
          isRelease: true,
        ),
        throwsStateError,
      );
    });

    test(
      'an unknown root policy becomes strict in release and lenient otherwise',
      () {
        expect(
          build(
            environment: 'prod',
            rootPolicy: 'typo',
            isRelease: true,
          ).rootPolicy,
          SecurityPolicy.block,
        );
        expect(build(rootPolicy: 'typo').rootPolicy, SecurityPolicy.warn);
      },
    );

    test('debug builds keep the lenient defaults', () {
      final config = build(environment: 'nonsense');

      expect(config.environment, AppEnvironment.dev);
    });

    test('screen protection is on by default and can be switched off', () {
      expect(build().protectScreens, isTrue);
      expect(
        AppConfig.fromValues(
          environment: 'dev',
          apiBaseUrl: 'https://api.test',
          useMockApi: false,
          pinningEnabled: false,
          pinnedSha256: '',
          rootPolicy: 'warn',
          isRelease: false,
          protectScreens: false,
        ).protectScreens,
        isFalse,
      );
    });

    test(
      'fromEnvironment refuses to run a release build without its config',
      () {
        expect(
          () => AppConfig.fromEnvironment(isRelease: true),
          throwsStateError,
        );
      },
    );
  });
}
