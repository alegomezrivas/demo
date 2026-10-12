import 'dart:async';

/// Broadcasts that the session ended (refresh failed or tokens were rejected).
///
/// The app listens to this stream to send the user back to the login screen.
class SessionExpiredNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Emits once for every expired session.
  Stream<void> get onExpired => _controller.stream;

  /// Announces that the session expired.
  void notifyExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  /// Releases the underlying stream.
  Future<void> dispose() => _controller.close();
}
