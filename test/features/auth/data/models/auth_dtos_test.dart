import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/register_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'user': {'id': '1', 'name': 'Ana', 'email': 'ana@test.com', 'phone': null},
    'accessToken': 'a',
    'refreshToken': 'r',
  };

  group('UserDto', () {
    test('round-trips JSON and maps to the entity', () {
      final dto = UserDto.fromJson({
        'id': '1',
        'name': 'Ana',
        'email': 'a@b.co',
        'phone': '3001234',
      });

      expect(dto.toJson()['phone'], '3001234');
      expect(
        dto.toEntity(),
        const User(id: '1', name: 'Ana', email: 'a@b.co', phone: '3001234'),
      );
    });

    test('builds from an entity', () {
      const user = User(id: '1', name: 'Ana', email: 'a@b.co');

      expect(UserDto.fromEntity(user).toEntity(), user);
    });

    test('has value equality', () {
      expect(
        const UserDto(id: '1', name: 'A', email: 'a@b.co'),
        const UserDto(id: '1', name: 'A', email: 'a@b.co'),
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

    test('RegisterRequestDto serializes every field', () {
      expect(
        const RegisterRequestDto(
          name: 'Ana',
          email: 'a@b.co',
          password: 'pw',
          phone: '300',
        ).toJson(),
        {'name': 'Ana', 'email': 'a@b.co', 'password': 'pw', 'phone': '300'},
      );
    });

    test('request DTOs parse back from JSON', () {
      expect(
        LoginRequestDto.fromJson({'email': 'a', 'password': 'b'}).password,
        'b',
      );
      expect(
        RegisterRequestDto.fromJson({
          'name': 'n',
          'email': 'e',
          'password': 'p',
        }).phone,
        isNull,
      );
    });
  });
}
