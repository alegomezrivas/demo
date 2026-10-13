import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
import 'package:demo/l10n/app_localizations_en.dart';
import 'package:demo/l10n/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEs();

  group('AuthFailureMessage.authMessage', () {
    test('unauthorized means invalid credentials', () {
      expect(
        const UnauthorizedFailure().authMessage(l10n),
        l10n.authInvalidCredentials,
      );
    });

    test('a taken e-mail has its own message', () {
      expect(
        const ServerFailure('email_taken').authMessage(l10n),
        l10n.authEmailTaken,
      );
    });

    test('every sign-up code has its own message', () {
      final cases = <String, String>{
        'invalid_code': l10n.authCodeInvalid,
        'code_expired': l10n.authCodeExpired,
        'too_many_attempts': l10n.authCodeTooManyAttempts,
        'resend_too_soon': l10n.authResendTooSoon,
        'username_taken': l10n.authUsernameTaken,
        'invalid_verification_token': l10n.authVerificationExpired,
        'invalid_image': l10n.authImageInvalid,
        'unsupported_image': l10n.authImageInvalid,
        'image_too_large': l10n.authImageTooLarge,
        'too_large': l10n.authImageTooLarge,
        'payload_too_large': l10n.authImageTooLarge,
      };
      for (final entry in cases.entries) {
        expect(
          ServerFailure(entry.key).authMessage(l10n),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('client-side validation failures use the same messages', () {
      expect(
        const ValidationFailure('invalid_code').authMessage(l10n),
        l10n.authCodeInvalid,
      );
      expect(
        const ValidationFailure('image_too_large').authMessage(l10n),
        l10n.authImageTooLarge,
      );
    });

    test('unknown codes never leak into the text', () {
      expect(
        const ServerFailure('db_exploded').authMessage(l10n),
        l10n.errorServer,
      );
      expect(
        const ValidationFailure('empty_credentials').authMessage(l10n),
        l10n.errorGeneric,
      );
    });

    test('messages are localized in English too', () {
      final en = AppLocalizationsEn();

      expect(
        const ServerFailure('username_taken').authMessage(en),
        'That username is already taken',
      );
    });

    test('other failures fall back to the generic messages', () {
      expect(const NetworkFailure().authMessage(l10n), l10n.errorNetwork);
      expect(const ServerFailure('boom').authMessage(l10n), l10n.errorServer);
      expect(const UnexpectedFailure().authMessage(l10n), l10n.errorGeneric);
    });
  });
}
