import 'package:meta/meta.dart';

/// Authenticated person, as the domain sees them.
@immutable
class User {
  /// Creates a user.
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.hasAvatar = false,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// E-mail address.
  final String email;

  /// Public, unique handle (lower case).
  final String username;

  /// Whether a profile picture can be downloaded for this user.
  final bool hasAvatar;

  /// Copy with the given fields replaced.
  User copyWith({bool? hasAvatar}) => User(
    id: id,
    name: name,
    email: email,
    username: username,
    hasAvatar: hasAvatar ?? this.hasAvatar,
  );

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.username == username &&
      other.hasAvatar == hasAvatar;

  @override
  int get hashCode => Object.hash(id, name, email, username, hasAvatar);

  @override
  String toString() => 'User($id)';
}
