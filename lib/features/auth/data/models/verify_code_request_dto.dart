import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_code_request_dto.freezed.dart';
part 'verify_code_request_dto.g.dart';

/// Body of `POST /auth/signup/verify`.
@freezed
abstract class VerifyCodeRequestDto with _$VerifyCodeRequestDto {
  /// Creates the DTO.
  const factory VerifyCodeRequestDto({
    required String email,
    required String code,
  }) = _VerifyCodeRequestDto;

  /// Parses the JSON representation.
  factory VerifyCodeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$VerifyCodeRequestDtoFromJson(json);
}
