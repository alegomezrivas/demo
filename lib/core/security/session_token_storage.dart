import 'package:demo/core/security/token_storage.dart';

/// [TokenStorage] whose persistence can be switched per session.
///
/// A signed-in person who unchecks "remember me" must leave nothing on the
/// device: their tokens stay in memory and vanish with the process.
abstract interface class SessionTokenStorage implements TokenStorage {
  /// Chooses where tokens saved from now on live.
  ///
  /// `true` keeps them in secure storage; `false` keeps them in memory only
  /// and removes any token persisted by an earlier session.
  Future<void> usePersistence({required bool persist});
}
