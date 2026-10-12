import 'dart:convert';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';

/// Local persistence of the session; throws [AppException]s only.
abstract interface class AuthLocalDataSource {
  /// Stores the tokens and the signed-in user.
  Future<void> saveSession({required AuthTokens tokens, required UserDto user});

  /// Returns the stored user when a token pair exists, otherwise null.
  Future<UserDto?> readUser();

  /// Removes every piece of session data.
  Future<void> clear();
}

/// [AuthLocalDataSource] that keeps everything in secure storage.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Creates the data source.
  const AuthLocalDataSourceImpl(this._tokens, this._storage);

  static const String _userKey = 'auth.user';

  final TokenStorage _tokens;
  final SecureStorage _storage;

  @override
  Future<void> saveSession({
    required AuthTokens tokens,
    required UserDto user,
  }) async {
    await _tokens.save(tokens);
    await _storage.write(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserDto?> readUser() async {
    if (await _tokens.read() == null) return null;
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
  Future<void> clear() async {
    await _tokens.clear();
    await _storage.delete(_userKey);
  }
}
