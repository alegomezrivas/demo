import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_request_dto.freezed.dart';
part 'email_request_dto.g.dart';

/// Body of the sign-up e-mail and resend endpoints.
@freezed
abstract class EmailRequestDto with _$EmailRequestDto {
  /// Creates the DTO.
  const factory EmailRequestDto({
    required String email,
  }) = _EmailRequestDto;

  /// Parses the JSON representation.
  factory EmailRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EmailRequestDtoFromJson(json);
}
