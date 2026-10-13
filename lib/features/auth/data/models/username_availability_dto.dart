import 'package:freezed_annotation/freezed_annotation.dart';

part 'username_availability_dto.freezed.dart';
part 'username_availability_dto.g.dart';

/// Response of `GET /auth/username-available`.
@freezed
abstract class UsernameAvailabilityDto with _$UsernameAvailabilityDto {
  /// Creates the DTO.
  const factory UsernameAvailabilityDto({
    required bool available,
  }) = _UsernameAvailabilityDto;

  /// Parses the JSON representation.
  factory UsernameAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      _$UsernameAvailabilityDtoFromJson(json);
}
