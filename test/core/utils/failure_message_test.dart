import 'package:demo/core/error/failures.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('FailureMessage.message', () {
    test('returns specific generic texts for network, auth and server', () {
      expect(const NetworkFailure().message(l10n), l10n.errorNetwork);
      expect(const UnauthorizedFailure().message(l10n), l10n.errorUnauthorized);
      expect(const ServerFailure().message(l10n), l10n.errorServer);
    });

    test('falls back to the generic text for everything else', () {
      for (final failure in <Failure>[
        const CacheFailure(),
        const ValidationFailure(),
        const UnexpectedFailure(),
      ]) {
        expect(failure.message(l10n), l10n.errorGeneric);
      }
    });

    test('never includes the technical code', () {
      expect(
        const ServerFailure('secret_code').message(l10n),
        isNot(contains('secret')),
      );
    });
  });
}
