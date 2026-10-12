import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/token_storage.dart';

/// Simple [TokenStorage] for tests.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;
  int clearCount = 0;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async {
    tokens = null;
    clearCount++;
  }
}
