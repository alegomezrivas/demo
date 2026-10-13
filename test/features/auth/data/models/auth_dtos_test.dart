import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/complete_sign_up_request_dto.dart';
import 'package:demo/features/auth/data/models/email_request_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/data/models/username_availability_dto.dart';
import 'package:demo/features/auth/data/models/verification_response_dto.dart';
import 'package:demo/features/auth/data/models/verify_code_request_dto.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'user': {
      'id': '1',
      'name': 'Ana',
      'email': 'ana@test.com',
      'username': 'ana',
      'hasAvatar': true,
    },
    'accessToken': 'a',
    'refreshToken': 'r',
  };

  group('UserDto', () {
    test('round-trips JSON and maps to the entity', () {
      final dto = UserDto.fromJson({
        'id': '1',
        'name': 'Ana',
        'email': 'a@b.co',
        'username': 'ana',
        'hasAvatar': true,
      });

      expect(dto.toJson()['username'], 'ana');
      expect(
        dto.toEntity(),
        const User(
          id: '1',
          name: 'Ana',
          email: 'a@b.co',
          username: 'ana',
          hasAvatar: true,
        ),
      );
    });

    test('defaults hasAvatar to false when the server omits it', () {
      final dto = UserDto.fromJson({
        'id': '1',
        'name': 'Ana',
        'email': 'a@b.co',
        'username': 'ana',
      });

      expect(dto.hasAvatar, isFalse);
    });

    test('ignores the removed phone field of old caches', () {
      final dto = UserDto.fromJson({
        'id': '1',
        'name': 'Ana',
        'email': 'a@b.co',
        'username': 'ana',
        'phone': '+57300',
      });

      expect(dto.toJson().containsKey('phone'), isFalse);
    });

    test('requires a username', () {
      expect(
        () => UserDto.fromJson({'id': '1', 'name': 'Ana', 'email': 'a@b.co'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('builds from an entity', () {
      const user = User(id: '1', name: 'Ana', email: 'a@b.co', username: 'ana');

      expect(UserDto.fromEntity(user).toEntity(), user);
    });

    test('has value equality', () {
      expect(
        const UserDto(id: '1', name: 'A', email: 'a@b.co', username: 'ana'),
        const UserDto(id: '1', name: 'A', email: 'a@b.co', username: 'ana'),
      );
    });

    test('throws a TypeError when a required field is missing', () {
      expect(() => UserDto.fromJson({'id': '1'}), throwsA(isA<TypeError>()));
    });
  });

  group('AuthResponseDto', () {
    test('parses nested user and exposes the token pair', () {
      final dto = AuthResponseDto.fromJson(json);

      expect(dto.user.email, 'ana@test.com');
      expect(dto.user.hasAvatar, isTrue);
      expect(dto.tokens, const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    });
  });

  group('request DTOs', () {
    test('LoginRequestDto serializes to the wire format', () {
      expect(const LoginRequestDto(email: 'a@b.co', password: 'pw').toJson(), {
        'email': 'a@b.co',
        'password': 'pw',
      });
    });

    test('CompleteSignUpRequestDto serializes every field', () {
      expect(
        const CompleteSignUpRequestDto(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'pw',
        ).toJson(),
        {
          'verificationToken': 'tok',
          'name': 'Ana',
          'username': 'ana',
          'password': 'pw',
        },
      );
    });

    test('the register body carries no e-mail, phone or birthdate', () {
      final keys = const CompleteSignUpRequestDto(
        verificationToken: 't',
        name: 'n',
        username: 'u',
        password: 'p',
      ).toJson().keys;

      expect(keys, isNot(contains('email')));
      expect(keys, isNot(contains('phone')));
      expect(keys, isNot(contains('birthdate')));
    });

    test('sign-up step DTOs serialize to the wire format', () {
      expect(const EmailRequestDto(email: 'a@b.co').toJson(), {
        'email': 'a@b.co',
      });
      expect(
        const VerifyCodeRequestDto(email: 'a@b.co', code: '123456').toJson(),
        {'email': 'a@b.co', 'code': '123456'},
      );
    });

    test('sign-up response DTOs parse the wire format', () {
      expect(
        VerificationResponseDto.fromJson({
          'verificationToken': 'tok',
        }).verificationToken,
        'tok',
      );
      expect(
        UsernameAvailabilityDto.fromJson({'available': false}).available,
        isFalse,
      );
    });

    test('request DTOs parse back from JSON', () {
      expect(
        LoginRequestDto.fromJson({'email': 'a', 'password': 'b'}).password,
        'b',
      );
      expect(
        CompleteSignUpRequestDto.fromJson({
          'verificationToken': 't',
          'name': 'n',
          'username': 'u',
          'password': 'p',
        }).username,
        'u',
      );
    });
  });
}
