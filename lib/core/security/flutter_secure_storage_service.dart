import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [SecureStorage] backed by `flutter_secure_storage` (Keychain / Keystore).
class FlutterSecureStorageService implements SecureStorage {
  /// Creates the service around a [FlutterSecureStorage] instance.
  const FlutterSecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _guard(() => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  @override
  Future<void> deleteAll() => _guard(_storage.deleteAll);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Exception {
      // Platform errors may carry sensitive details; expose only a code.
      throw const CacheException('secure_storage_error');
    }
  }
}
