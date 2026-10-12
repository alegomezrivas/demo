import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_request_dto.freezed.dart';
part 'register_request_dto.g.dart';

/// Body of `POST /auth/register`.
@freezed
abstract class RegisterRequestDto with _$RegisterRequestDto {
  /// Creates the request body.
  const factory RegisterRequestDto({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) = _RegisterRequestDto;

  /// Parses the JSON representation.
  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);
}
