import 'package:freezed_annotation/freezed_annotation.dart';

part 'complete_sign_up_request_dto.freezed.dart';
part 'complete_sign_up_request_dto.g.dart';

/// Body of `POST /auth/register`.
@freezed
abstract class CompleteSignUpRequestDto with _$CompleteSignUpRequestDto {
  /// Creates the DTO.
  const factory CompleteSignUpRequestDto({
    required String verificationToken,
    required String name,
    required String username,
    required String password,
  }) = _CompleteSignUpRequestDto;

  /// Parses the JSON representation.
  factory CompleteSignUpRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CompleteSignUpRequestDtoFromJson(json);
}
