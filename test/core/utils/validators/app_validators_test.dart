import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

FormControl<String> control(String? value, Validator<dynamic> validator) =>
    FormControl<String>(value: value, validators: [validator]);

void main() {
  group('AppValidators.required', () {
    test('fails for null, blank and whitespace', () {
      for (final value in <String?>[null, '', '   ']) {
        expect(
          control(value, AppValidators.required).errors,
          contains(ValidationKeys.required),
        );
      }
    });

    test('passes for a real value', () {
      expect(control('x', AppValidators.required).valid, isTrue);
    });

    test('fails for an empty list', () {
      final list = FormControl<List<String>>(
        value: const [],
        validators: [AppValidators.required],
      );

      expect(list.errors, contains(ValidationKeys.required));
    });
  });

  group('AppValidators.email', () {
    test('accepts valid addresses', () {
      for (final value in ['a@b.co', 'ana.perez+tag@mail.example.com']) {
        expect(
          control(value, AppValidators.email).valid,
          isTrue,
          reason: value,
        );
      }
    });

    test('rejects malformed addresses', () {
      for (final value in [
        'plain',
        'a@',
        '@b.co',
        'a@b',
        'a b@c.co',
        'a@@b.co',
      ]) {
        expect(
          control(value, AppValidators.email).errors,
          contains(ValidationKeys.email),
          reason: value,
        );
      }
    });

    test('treats empty values as valid (use required for that)', () {
      expect(control('', AppValidators.email).valid, isTrue);
      expect(control(null, AppValidators.email).valid, isTrue);
    });

    test('rejects addresses longer than 254 characters', () {
      final long = '${'a' * 250}@b.co';

      expect(control(long, AppValidators.email).valid, isFalse);
    });
  });

  group('AppValidators.strongPassword', () {
    test('accepts a password meeting every rule', () {
      expect(control('Abcdef1!', AppValidators.strongPassword).valid, isTrue);
    });

    test('reports each missing rule', () {
      final errors = control('abc', AppValidators.strongPassword).errors;

      expect(
        errors[ValidationKeys.strongPassword],
        containsAll(['length', 'uppercase', 'digit', 'symbol']),
      );
      expect(
        errors[ValidationKeys.strongPassword],
        isNot(contains('lowercase')),
      );
    });

    test('rejects a password without symbol', () {
      expect(control('Abcdefg1', AppValidators.strongPassword).valid, isFalse);
    });

    test('treats empty values as valid', () {
      expect(control('', AppValidators.strongPassword).valid, isTrue);
    });
  });

  group('AppValidators.phone', () {
    test('accepts numbers with separators and optional plus', () {
      for (final value in ['+57 300 123 4567', '(300) 123-4567', '3001234']) {
        expect(
          control(value, AppValidators.phone).valid,
          isTrue,
          reason: value,
        );
      }
    });

    test('rejects letters, too short and too long numbers', () {
      for (final value in ['abc1234567', '12345', '1234567890123456']) {
        expect(
          control(value, AppValidators.phone).errors,
          contains(ValidationKeys.phone),
          reason: value,
        );
      }
    });

    test('treats empty values as valid', () {
      expect(control(' ', AppValidators.phone).valid, isTrue);
    });
  });

  group('AppValidators.mustMatch', () {
    test('flags the confirmation control when values differ', () {
      final form = FormGroup(
        {
          'password': FormControl<String>(value: 'a'),
          'confirm': FormControl<String>(value: 'b'),
        },
        validators: [AppValidators.mustMatch('password', 'confirm')],
      );

      expect(
        form.control('confirm').errors,
        contains(ValidationKeys.mustMatch),
      );
    });

    test('passes when values are equal', () {
      final form = FormGroup(
        {
          'password': FormControl<String>(value: 'a'),
          'confirm': FormControl<String>(value: 'a'),
        },
        validators: [AppValidators.mustMatch('password', 'confirm')],
      );

      expect(form.valid, isTrue);
    });
  });
}
