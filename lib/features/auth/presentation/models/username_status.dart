/// Result of checking a username while the person types it.
enum UsernameStatus {
  /// Nothing typed yet.
  idle,

  /// The text cannot be a username; the server was not asked.
  invalid,

  /// Waiting for the server.
  checking,

  /// Free to take.
  available,

  /// Somebody else has it.
  taken,

  /// The check failed (offline, server error); sign-up may still try.
  unknown,
}
