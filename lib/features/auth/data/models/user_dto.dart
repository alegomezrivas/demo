import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Wire representation of a [User].
@freezed
abstract class UserDto with _$UserDto {
  /// Creates a DTO.
  const factory UserDto({
    required String id,
    required String name,
    required String email,
    String? phone,
  }) = _UserDto;

  /// Parses the backend JSON.
  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  /// Builds a DTO from a domain [User].
  factory UserDto.fromEntity(User user) => UserDto(
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
  );
}

/// Mapping to the domain layer.
extension UserDtoMapper on UserDto {
  /// Converts this DTO to a domain [User].
  User toEntity() => User(id: id, name: name, email: email, phone: phone);
}
