/// Key-value storage for secrets, backed by the platform keystore.
abstract interface class SecureStorage {
  /// Reads the value stored under [key], or null.
  Future<String?> read(String key);

  /// Stores [value] under [key].
  Future<void> write(String key, String value);

  /// Removes [key].
  Future<void> delete(String key);

  /// Removes every stored entry.
  Future<void> deleteAll();
}
