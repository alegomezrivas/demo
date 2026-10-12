import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

/// Decides whether a server certificate matches the pinned fingerprints.
///
/// A fingerprint is the base64 encoding of the SHA-256 digest of the
/// certificate (DER). When pinning is [enabled] with an empty pin list the
/// pinner **fails closed**: nothing is trusted.
///
/// Limitation: Dio evaluates the certificate once the response headers have
/// arrived, so the request itself was already transmitted. The response is
/// still discarded, but sensitive payloads rely on TLS validation plus this
/// check; moving to a socket-level check is tracked for the security review.
@immutable
class CertificatePinner {
  /// Creates a pinner.
  const CertificatePinner({required this.enabled, required this.pinnedSha256});

  /// Builds a pinner from the app configuration.
  factory CertificatePinner.fromConfig(AppConfig config) {
    return CertificatePinner(
      enabled: config.pinningEnabled,
      pinnedSha256: config.pinnedSha256,
    );
  }

  /// Whether pinning is enforced.
  final bool enabled;

  /// Allowed base64 SHA-256 fingerprints.
  final List<String> pinnedSha256;

  /// Computes the fingerprint of a DER-encoded certificate.
  static String fingerprint(List<int> der) =>
      base64.encode(sha256.convert(der).bytes);

  /// Whether [certificate] may be trusted.
  bool isTrusted(X509Certificate? certificate) =>
      isTrustedDer(certificate?.der);

  /// Whether the DER-encoded certificate may be trusted.
  bool isTrustedDer(List<int>? der) {
    if (!enabled) return true;
    if (der == null || pinnedSha256.isEmpty) return false;
    return pinnedSha256.contains(fingerprint(der));
  }
}
