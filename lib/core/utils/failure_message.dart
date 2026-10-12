import 'package:demo/core/error/failures.dart';
import 'package:demo/l10n/app_localizations.dart';

/// Maps failures to generic, localized messages (no technical details).
extension FailureMessage on Failure {
  /// User-facing text for this failure.
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure() => l10n.errorNetwork,
      UnauthorizedFailure() => l10n.errorUnauthorized,
      ServerFailure() => l10n.errorServer,
      CacheFailure() ||
      ValidationFailure() ||
      UnexpectedFailure() => l10n.errorGeneric,
    };
  }
}
