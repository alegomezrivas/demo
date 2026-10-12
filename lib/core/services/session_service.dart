import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks whether the user is signed in; the router listens to it.
class SessionService extends ChangeNotifier {
  /// Creates the service, signed out by default.
  SessionService({bool isAuthenticated = false})
    : _isAuthenticated = isAuthenticated;

  bool _isAuthenticated;
  StreamSubscription<void>? _expiredSubscription;

  /// Whether a session is active.
  bool get isAuthenticated => _isAuthenticated;

  /// Marks the user as signed in.
  void markSignedIn() => _update(true);

  /// Marks the user as signed out.
  void markSignedOut() => _update(false);

  /// Signs the user out whenever [sessionExpired] emits.
  void attach(Stream<void> sessionExpired) {
    unawaited(_expiredSubscription?.cancel());
    _expiredSubscription = sessionExpired.listen((_) => markSignedOut());
  }

  void _update(bool value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_expiredSubscription?.cancel());
    super.dispose();
  }
}
