import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/presentation/utils/auth_failure_message.dart';
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

    test('other failures fall back to the generic messages', () {
      expect(const NetworkFailure().authMessage(l10n), l10n.errorNetwork);
      expect(const ServerFailure('boom').authMessage(l10n), l10n.errorServer);
      expect(const UnexpectedFailure().authMessage(l10n), l10n.errorGeneric);
    });
  });
}
