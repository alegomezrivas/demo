import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request_dto.freezed.dart';
part 'login_request_dto.g.dart';

/// Body of `POST /auth/login`.
@freezed
abstract class LoginRequestDto with _$LoginRequestDto {
  /// Creates the request body.
  const factory LoginRequestDto({
    required String email,
    required String password,
  }) = _LoginRequestDto;

  /// Parses the JSON representation.
  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
}
