import 'package:demo/core/utils/logging/log_redactor.dart';
import 'package:flutter/foundation.dart';

/// Verbosity of the logger, from most to least verbose.
enum LogLevel {
  /// Development diagnostics.
  debug,

  /// Normal events.
  info,

  /// Recoverable problems.
  warning,

  /// Failures.
  error,

  /// Logging disabled.
  none,
}

/// Logging abstraction; implementations must never print secrets.
abstract interface class AppLogger {
  /// Logs a development diagnostic.
  void debug(String message);

  /// Logs a normal event.
  void info(String message);

  /// Logs a recoverable problem.
  void warning(String message);

  /// Logs a failure; only the runtime type of [error] is recorded.
  void error(String message, {Object? error});
}

/// [AppLogger] that prints redacted lines through a sink.
class ConsoleAppLogger implements AppLogger {
  /// Creates a logger that ignores messages below [minLevel].
  ConsoleAppLogger({
    this.minLevel = LogLevel.debug,
    void Function(String line)? sink,
  }) : _sink = sink ?? debugPrint;

  /// Verbose in debug builds, errors only in release builds.
  factory ConsoleAppLogger.forMode({
    bool isRelease = kReleaseMode,
    void Function(String line)? sink,
  }) {
    return ConsoleAppLogger(
      minLevel: isRelease ? LogLevel.error : LogLevel.debug,
      sink: sink,
    );
  }

  /// Lowest level that is printed.
  final LogLevel minLevel;

  final void Function(String line) _sink;

  @override
  void debug(String message) => _log(LogLevel.debug, message);

  @override
  void info(String message) => _log(LogLevel.info, message);

  @override
  void warning(String message) => _log(LogLevel.warning, message);

  @override
  void error(String message, {Object? error}) {
    final suffix = error == null ? '' : ' (${error.runtimeType})';
    _log(LogLevel.error, '$message$suffix');
  }

  void _log(LogLevel level, String message) {
    if (level.index < minLevel.index || minLevel == LogLevel.none) return;
    _sink('[${level.name.toUpperCase()}] ${LogRedactor.redact(message)}');
  }
}
