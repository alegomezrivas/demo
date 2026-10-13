import 'dart:async';

import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';

/// Wipes the stored profile (and anything else session related) as soon as a
/// session expires, so it does not outlive its tokens.
///
/// The auth interceptor already clears the tokens; this removes the rest.
/// Failures are ignored: the profile is unreadable without tokens anyway and
/// `readUser` deletes it on the next read.
StreamSubscription<void> wipeStoredSessionOnExpiry({
  required SessionExpiredNotifier notifier,
  required AuthLocalDataSource local,
}) {
  return notifier.onExpired.listen((_) async {
    try {
      await local.clear();
    } on Exception {
      // See above.
    }
  });
}
