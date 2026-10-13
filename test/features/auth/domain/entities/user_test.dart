import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );

  group('User', () {
    test('has value equality over every field', () {
      expect(
        user,
        const User(
          id: '1',
          name: 'Ana',
          email: 'ana@test.com',
          username: 'ana',
        ),
      );
      expect(
        user.hashCode,
        const User(
          id: '1',
          name: 'Ana',
          email: 'ana@test.com',
          username: 'ana',
        ).hashCode,
      );
      expect(user, isNot(user.copyWith(hasAvatar: true)));
      expect(
        user,
        isNot(
          const User(
            id: '2',
            name: 'Ana',
            email: 'ana@test.com',
            username: 'ana',
          ),
        ),
      );
    });

    test('has no avatar by default', () {
      expect(user.hasAvatar, isFalse);
    });

    test('copyWith changes only the avatar flag', () {
      final copy = user.copyWith(hasAvatar: true);

      expect(copy.hasAvatar, isTrue);
      expect(copy.id, user.id);
      expect(copy.username, user.username);
      expect(user.copyWith(), user);
    });

    test('toString exposes only the id (no PII)', () {
      expect(user.toString(), 'User(1)');
    });
  });
}
