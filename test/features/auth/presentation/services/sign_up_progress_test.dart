import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SignUpProgress progress;

  setUp(() => progress = SignUpProgress());

  group('before the flow starts', () {
    test('nothing is unlocked', () {
      expect(progress.hasStarted, isFalse);
      expect(progress.furthest, isNull);
      expect(progress.resumeRoute, isNull);
      for (final step in SignUpStep.values) {
        expect(progress.canEnter(step), isFalse, reason: '$step');
      }
    });
  });

  group('unlock', () {
    test('lets people enter the unlocked step and the ones before it', () {
      progress.unlock(SignUpStep.password);

      expect(progress.hasStarted, isTrue);
      expect(progress.canEnter(SignUpStep.email), isTrue);
      expect(progress.canEnter(SignUpStep.code), isTrue);
      expect(progress.canEnter(SignUpStep.password), isTrue);
      expect(progress.canEnter(SignUpStep.name), isFalse);
      expect(progress.canEnter(SignUpStep.done), isFalse);
    });

    test('never moves backwards', () {
      progress
        ..unlock(SignUpStep.name)
        ..unlock(SignUpStep.code);

      expect(progress.furthest, SignUpStep.name);
    });

    test('resumes at the furthest step', () {
      progress
        ..unlock(SignUpStep.email)
        ..unlock(SignUpStep.code);

      expect(progress.resumeRoute, SignUpStep.code.route);
    });
  });

  group('rewindTo', () {
    test('locks every step after the given one', () {
      progress
        ..unlock(SignUpStep.username)
        ..rewindTo(SignUpStep.email);

      expect(progress.furthest, SignUpStep.email);
      expect(progress.canEnter(SignUpStep.code), isFalse);
      expect(progress.canEnter(SignUpStep.email), isTrue);
    });
  });

  group('lockBeforeAvatar', () {
    test('only the picture and the final step stay reachable', () {
      progress
        ..unlock(SignUpStep.avatar)
        ..lockBeforeAvatar();

      for (final step in [
        SignUpStep.email,
        SignUpStep.code,
        SignUpStep.password,
        SignUpStep.name,
        SignUpStep.username,
        SignUpStep.terms,
      ]) {
        expect(progress.canEnter(step), isFalse, reason: '$step');
      }
      expect(progress.canEnter(SignUpStep.avatar), isTrue);
      expect(progress.canEnter(SignUpStep.done), isFalse);

      progress.unlock(SignUpStep.done);
      expect(progress.canEnter(SignUpStep.done), isTrue);
    });
  });

  group('clear', () {
    test('forgets the progress and the lock', () {
      progress
        ..unlock(SignUpStep.done)
        ..lockBeforeAvatar()
        ..clear();

      expect(progress.hasStarted, isFalse);

      progress.unlock(SignUpStep.code);
      expect(progress.canEnter(SignUpStep.email), isTrue);
    });
  });
}
