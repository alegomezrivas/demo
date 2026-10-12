import 'package:meta/meta.dart';

/// Authenticated person, as the domain sees them.
@immutable
class User {
  /// Creates a user.
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// E-mail address.
  final String email;

  /// Optional phone number.
  final String? phone;

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(id, name, email, phone);

  @override
  String toString() => 'User($id)';
}
