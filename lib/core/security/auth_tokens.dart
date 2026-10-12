import 'package:flutter/foundation.dart';

/// Access / refresh token pair.
@immutable
class AuthTokens {
  /// Creates a token pair.
  const AuthTokens({required this.accessToken, required this.refreshToken});

  /// Short-lived token sent in the `Authorization` header.
  final String accessToken;

  /// Long-lived token used to obtain a new [accessToken].
  final String refreshToken;

  @override
  bool operator ==(Object other) =>
      other is AuthTokens &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);

  /// Never prints token values.
  @override
  String toString() => 'AuthTokens(***)';
}
