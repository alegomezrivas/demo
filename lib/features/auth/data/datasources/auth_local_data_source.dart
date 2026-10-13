import 'dart:convert';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/session_token_storage.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';

/// Local persistence of the session; throws [AppException]s only.
abstract interface class AuthLocalDataSource {
  /// Stores the tokens and the signed-in user.
  ///
  /// With [persist] false everything stays in memory and nothing reaches
  /// secure storage; any session persisted earlier is removed.
  Future<void> saveSession({
    required AuthTokens tokens,
    required UserDto user,
    bool persist = true,
  });

  /// Replaces the stored user, keeping the tokens and where they live.
  Future<void> updateUser(UserDto user);

  /// Returns the stored user when a token pair exists, otherwise null.
  Future<UserDto?> readUser();

  /// Returns the stored refresh token, or null when there is no session.
  Future<String?> readRefreshToken();

  /// Removes every piece of session data, from memory and from storage.
  Future<void> clear();
}

/// [AuthLocalDataSource] that keeps persisted sessions in secure storage.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Creates the data source.
  AuthLocalDataSourceImpl(this._tokens, this._storage);

  static const String _userKey = 'auth.user';

  final SessionTokenStorage _tokens;
  final SecureStorage _storage;

  bool _persist = true;
  UserDto? _memoryUser;

  @override
  Future<void> saveSession({
    required AuthTokens tokens,
    required UserDto user,
    bool persist = true,
  }) async {
    _persist = persist;
    // Switching first clears whatever the previous session left behind.
    await _tokens.usePersistence(persist: persist);
    await _tokens.save(tokens);
    await _writeUser(user);
  }

  @override
  Future<void> updateUser(UserDto user) => _writeUser(user);

  @override
  Future<UserDto?> readUser() async {
    if (await _tokens.read() == null) return null;
    if (!_persist) return _memoryUser;
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    try {
      return UserDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      throw const CacheException('invalid_user_cache');
      // ignore: avoid_catching_errors, generated fromJson throws TypeError on bad data
    } on TypeError {
      throw const CacheException('invalid_user_cache');
    }
  }

  @override
  Future<String?> readRefreshToken() async =>
      (await _tokens.read())?.refreshToken;

  @override
  Future<void> clear() async {
    _memoryUser = null;
    _persist = true;
    await _tokens.clear();
    await _storage.delete(_userKey);
  }

  Future<void> _writeUser(UserDto user) async {
    if (_persist) {
      _memoryUser = null;
      await _storage.write(_userKey, jsonEncode(user.toJson()));
    } else {
      _memoryUser = user;
      await _storage.delete(_userKey);
    }
  }
}
