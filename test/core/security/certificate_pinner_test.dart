import 'dart:convert';

import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/certificate_pinner.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final der = utf8.encode('fake-certificate-bytes');
  final otherDer = utf8.encode('another-certificate');
  final pin = CertificatePinner.fingerprint(der);

  group('CertificatePinner', () {
    test('trusts everything when pinning is disabled', () {
      const pinner = CertificatePinner(enabled: false, pinnedSha256: []);

      expect(pinner.isTrustedDer(der), isTrue);
      expect(pinner.isTrustedDer(null), isTrue);
    });

    test('trusts a certificate whose fingerprint is pinned', () {
      final pinner = CertificatePinner(enabled: true, pinnedSha256: [pin]);

      expect(pinner.isTrustedDer(der), isTrue);
    });

    test('rejects a certificate that is not pinned', () {
      final pinner = CertificatePinner(enabled: true, pinnedSha256: [pin]);

      expect(pinner.isTrustedDer(otherDer), isFalse);
    });

    test('fails closed when enabled with an empty pin list', () {
      const pinner = CertificatePinner(enabled: true, pinnedSha256: []);

      expect(pinner.isTrustedDer(der), isFalse);
      expect(pinner.isTrustedDer(otherDer), isFalse);
    });

    test('rejects a missing certificate when enabled', () {
      final pinner = CertificatePinner(enabled: true, pinnedSha256: [pin]);

      expect(pinner.isTrusted(null), isFalse);
    });

    test('fromConfig copies the pinning settings', () {
      final pinner = CertificatePinner.fromConfig(
        AppConfig(
          environment: AppEnvironment.prod,
          apiBaseUrl: 'https://api.test',
          useMockApi: false,
          pinningEnabled: true,
          pinnedSha256: [pin],
          rootPolicy: SecurityPolicy.block,
        ),
      );

      expect(pinner.enabled, isTrue);
      expect(pinner.pinnedSha256, [pin]);
    });

    test('fingerprint is the base64 SHA-256 of the DER bytes', () {
      expect(
        CertificatePinner.fingerprint(der),
        isNot(CertificatePinner.fingerprint(otherDer)),
      );
      expect(base64.decode(pin), hasLength(32));
    });
  });
}
