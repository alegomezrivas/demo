import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/core/utils/validators/validation_messages.dart';
import 'package:demo/l10n/app_localizations_en.dart';
import 'package:demo/l10n/app_localizations_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationMessages.of', () {
    test('has a message for every validation key', () {
      final messages = ValidationMessages.of(AppLocalizationsEs());

      for (final key in [
        ValidationKeys.required,
        ValidationKeys.email,
        ValidationKeys.strongPassword,
        ValidationKeys.phone,
        ValidationKeys.minLength,
        ValidationKeys.mustMatch,
      ]) {
        expect(messages, contains(key));
        expect(messages[key]?.call(<String, dynamic>{}), isNotEmpty);
      }
    });

    test('localizes the text', () {
      final es = ValidationMessages.of(AppLocalizationsEs());
      final en = ValidationMessages.of(AppLocalizationsEn());

      expect(
        es[ValidationKeys.required]?.call(true),
        'Este campo es obligatorio',
      );
      expect(en[ValidationKeys.required]?.call(true), 'This field is required');
    });

    test('injects the required length into minLength', () {
      final messages = ValidationMessages.of(AppLocalizationsEn());

      final text = messages[ValidationKeys.minLength]?.call(<String, dynamic>{
        'requiredLength': 8,
        'actualLength': 3,
      });

      expect(text, contains('8'));
    });
  });
}
