import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

void main() {
  late SignUpForms forms;

  setUp(() => forms = SignUpForms());
  tearDown(() => forms.dispose());

  void set(FormGroup group, String field, Object? value) =>
      group.control(field).value = value;

  group('email form', () {
    test('needs a valid e-mail', () {
      expect(forms.email.valid, isFalse);

      set(forms.email, SignUpForms.emailField, 'nope');
      expect(
        forms.email.control(SignUpForms.emailField).errors,
        contains(ValidationKeys.email),
      );

      set(forms.email, SignUpForms.emailField, 'ana@test.com');
      expect(forms.email.valid, isTrue);
    });
  });

  group('code form', () {
    test('needs exactly six digits', () {
      for (final bad in ['', '12345', '1234567', 'abcdef']) {
        set(forms.code, SignUpForms.codeField, bad);
        expect(forms.code.valid, isFalse, reason: bad);
      }
      set(forms.code, SignUpForms.codeField, '123456');
      expect(forms.code.valid, isTrue);
    });
  });

  group('password form', () {
    test('needs a strong password', () {
      set(forms.password, SignUpForms.passwordField, 'weak');
      expect(
        forms.password.control(SignUpForms.passwordField).errors,
        contains(ValidationKeys.strongPassword),
      );

      set(forms.password, SignUpForms.passwordField, 'Str0ng!Pass');
      expect(forms.password.valid, isTrue);
    });

    test('remembers the session by default', () {
      expect(forms.password.control(SignUpForms.rememberField).value, isTrue);
    });
  });

  group('name form', () {
    test('needs a name of at most 100 characters', () {
      set(forms.name, SignUpForms.nameField, '   ');
      expect(forms.name.valid, isFalse);

      set(forms.name, SignUpForms.nameField, 'n' * 101);
      expect(
        forms.name.control(SignUpForms.nameField).errors,
        contains(ValidationKeys.maxLength),
      );

      set(forms.name, SignUpForms.nameField, 'Lucía Gómez');
      expect(forms.name.valid, isTrue);
    });
  });

  group('username form', () {
    test('needs an acceptable username', () {
      for (final bad in ['', 'ab', 'two words', 'dot.', 'x' * 31]) {
        set(forms.username, SignUpForms.usernameField, bad);
        expect(forms.username.valid, isFalse, reason: bad);
      }
      set(forms.username, SignUpForms.usernameField, 'lucia.g_1');
      expect(forms.username.valid, isTrue);
    });

    test('reports the username error key', () {
      set(forms.username, SignUpForms.usernameField, 'bad name');

      expect(
        forms.username.control(SignUpForms.usernameField).errors,
        contains(ValidationKeys.username),
      );
    });
  });

  group('textOf', () {
    test('returns the typed text or an empty string', () {
      expect(SignUpForms.textOf(forms.email, SignUpForms.emailField), '');

      set(forms.email, SignUpForms.emailField, 'a@b.co');
      expect(SignUpForms.textOf(forms.email, SignUpForms.emailField), 'a@b.co');
    });
  });

  group('SignUpValidators', () {
    FormControl<String> control(Validator<dynamic> validator, String value) =>
        FormControl<String>(value: value, validators: [validator]);

    test('treat blank values as valid so they combine with required', () {
      expect(control(SignUpValidators.code, '  ').valid, isTrue);
      expect(control(SignUpValidators.username, '').valid, isTrue);
    });
  });
}
