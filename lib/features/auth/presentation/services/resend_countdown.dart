import 'dart:async';

import 'package:flutter/foundation.dart';

/// Counts down the wait before a new code may be requested.
///
/// The server enforces the same wait, so this only keeps the button honest.
class ResendCountdown {
  /// Creates a countdown of [seconds]; [onChanged] runs on every tick.
  ResendCountdown({
    required VoidCallback onChanged,
    this.seconds = 30,
    this.tick = const Duration(seconds: 1),
  }) : _onChanged = onChanged;

  /// Length of the wait.
  final int seconds;

  /// Time between two ticks (a second; tests shorten it).
  final Duration tick;

  final VoidCallback _onChanged;
  Timer? _timer;
  int _secondsLeft = 0;

  /// Seconds still to wait; zero when a new code may be requested.
  int get secondsLeft => _secondsLeft;

  /// Whether the wait is running.
  bool get isActive => _secondsLeft > 0;

  /// Starts (or restarts) the wait.
  void start() {
    _timer?.cancel();
    _secondsLeft = seconds;
    _timer = Timer.periodic(tick, (timer) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        timer.cancel();
      }
      _onChanged();
    });
    _onChanged();
  }

  /// Stops the wait without notifying.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _secondsLeft = 0;
  }
}
