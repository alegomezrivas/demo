import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

/// Response of the login and register endpoints.
@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  /// Creates the response.
  const factory AuthResponseDto({
    required UserDto user,
    required String accessToken,
    required String refreshToken,
  }) = _AuthResponseDto;

  /// Parses the backend JSON.
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}

/// Helpers over [AuthResponseDto].
extension AuthResponseDtoTokens on AuthResponseDto {
  /// The token pair carried by the response.
  AuthTokens get tokens =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}
