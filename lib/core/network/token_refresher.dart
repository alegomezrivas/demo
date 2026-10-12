import 'package:demo/core/security/auth_tokens.dart';

/// Exchanges a refresh token for a new token pair.
abstract interface class TokenRefresher {
  /// Returns fresh tokens or throws when the refresh token is rejected.
  Future<AuthTokens> refresh(String refreshToken);
}
