import 'package:demo/core/error/failures.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/l10n/app_localizations.dart';

/// Maps auth failures to localized, generic messages.
extension AuthFailureMessage on Failure {
  /// User-facing text for a failure raised by sign-in or sign-up.
  String authMessage(AppLocalizations l10n) {
    return switch (this) {
      UnauthorizedFailure() => l10n.authInvalidCredentials,
      ServerFailure(:final code) when code == 'email_taken' =>
        l10n.authEmailTaken,
      _ => message(l10n),
    };
  }
}
