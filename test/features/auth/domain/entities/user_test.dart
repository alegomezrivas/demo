import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    phone: '+57300',
  );

  group('User', () {
    test('has value equality', () {
      expect(
        user,
        const User(
          id: '1',
          name: 'Ana',
          email: 'ana@test.com',
          phone: '+57300',
        ),
      );
      expect(
        user.hashCode,
        const User(
          id: '1',
          name: 'Ana',
          email: 'ana@test.com',
          phone: '+57300',
        ).hashCode,
      );
      expect(
        user,
        isNot(const User(id: '2', name: 'Ana', email: 'ana@test.com')),
      );
    });

    test('toString exposes only the id (no PII)', () {
      expect(user.toString(), 'User(1)');
    });
  });
}
