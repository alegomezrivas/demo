import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/token_storage.dart';

/// [TokenStorage] that keeps tokens in a [SecureStorage].
class SecureTokenStorage implements TokenStorage {
  /// Creates the storage around [_storage].
  const SecureTokenStorage(this._storage);

  static const String _accessKey = 'auth.access_token';
  static const String _refreshKey = 'auth.refresh_token';

  final SecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(_accessKey);
    final refresh = await _storage.read(_refreshKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(_accessKey, tokens.accessToken);
    await _storage.write(_refreshKey, tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
  }
}
