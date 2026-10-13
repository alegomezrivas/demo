import 'package:demo/core/error/failures.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/l10n/app_localizations.dart';

/// Maps auth failures to localized, generic messages.
extension AuthFailureMessage on Failure {
  /// User-facing text for a failure raised by sign-in or sign-up.
  String authMessage(AppLocalizations l10n) {
    return switch (this) {
      UnauthorizedFailure() => l10n.authInvalidCredentials,
      ServerFailure(:final code) ||
      ValidationFailure(:final code) => _knownCode(code, l10n) ?? message(l10n),
      _ => message(l10n),
    };
  }
}

/// Text for the machine-readable codes the sign-up steps can produce, or null
/// when the code has no dedicated message.
String? _knownCode(String code, AppLocalizations l10n) {
  return switch (code) {
    'email_taken' => l10n.authEmailTaken,
    'invalid_code' => l10n.authCodeInvalid,
    'code_expired' => l10n.authCodeExpired,
    'too_many_attempts' => l10n.authCodeTooManyAttempts,
    'resend_too_soon' => l10n.authResendTooSoon,
    'username_taken' => l10n.authUsernameTaken,
    'invalid_verification_token' => l10n.authVerificationExpired,
    'invalid_image' || 'unsupported_image' => l10n.authImageInvalid,
    'image_too_large' ||
    'too_large' ||
    'payload_too_large' => l10n.authImageTooLarge,
    _ => null,
  };
}
