import 'dart:async';

/// Broadcasts that user data changed (a task was created, edited or deleted).
///
/// Screens that keep derived data alive in other tabs, such as the dashboard,
/// listen to it and reload.
class DataChangeNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Emits once for every change.
  Stream<void> get onChanged => _controller.stream;

  /// Announces that data changed.
  void notifyChanged() {
    if (!_controller.isClosed) _controller.add(null);
  }

  /// Releases the underlying stream.
  Future<void> dispose() => _controller.close();
}
