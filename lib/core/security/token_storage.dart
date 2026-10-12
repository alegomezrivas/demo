import 'package:demo/core/security/auth_tokens.dart';

/// Persistence of the session tokens.
abstract interface class TokenStorage {
  /// Returns the stored tokens, or null when there is no session.
  Future<AuthTokens?> read();

  /// Replaces the stored tokens.
  Future<void> save(AuthTokens tokens);

  /// Removes the stored tokens (sign out).
  Future<void> clear();
}
