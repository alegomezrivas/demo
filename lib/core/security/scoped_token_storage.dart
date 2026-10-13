import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/session_token_storage.dart';
import 'package:demo/core/security/token_storage.dart';

/// [SessionTokenStorage] that delegates to a persistent store or to memory.
///
/// Token refreshes call save again, so they land in the same place as the
/// login that started the session.
class ScopedTokenStorage implements SessionTokenStorage {
  /// Creates the storage on top of the persistent store.
  ScopedTokenStorage(this._persistent);

  final TokenStorage _persistent;

  bool _persist = true;
  AuthTokens? _memory;

  @override
  Future<void> usePersistence({required bool persist}) async {
    _persist = persist;
    _memory = null;
    if (!persist) await _persistent.clear();
  }

  @override
  Future<AuthTokens?> read() async =>
      _persist ? _persistent.read() : Future.value(_memory);

  @override
  Future<void> save(AuthTokens tokens) async {
    if (_persist) {
      await _persistent.save(tokens);
    } else {
      _memory = tokens;
    }
  }

  @override
  Future<void> clear() async {
    _memory = null;
    // Back to the default so a later plain `save` is persisted again.
    _persist = true;
    await _persistent.clear();
  }
}
