import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_response_dto.freezed.dart';
part 'verification_response_dto.g.dart';

/// Response of `POST /auth/signup/verify`.
@freezed
abstract class VerificationResponseDto with _$VerificationResponseDto {
  /// Creates the DTO.
  const factory VerificationResponseDto({
    required String verificationToken,
  }) = _VerificationResponseDto;

  /// Parses the JSON representation.
  factory VerificationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$VerificationResponseDtoFromJson(json);
}
