import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignUpStep', () {
    test('goes through the steps in the order of the flow', () {
      expect(SignUpStep.values, [
        SignUpStep.email,
        SignUpStep.code,
        SignUpStep.password,
        SignUpStep.name,
        SignUpStep.username,
        SignUpStep.terms,
        SignUpStep.avatar,
        SignUpStep.done,
      ]);
    });

    test('every step has its own route under /signup', () {
      final routes = SignUpStep.values.map((step) => step.route);

      expect(routes.toSet(), hasLength(SignUpStep.values.length));
      expect(routes, everyElement(startsWith('/signup/')));
      expect(SignUpStep.email.route, AppRoutes.signUpEmail);
      expect(SignUpStep.done.route, AppRoutes.signUpDone);
    });

    test('maps a location back to its step', () {
      for (final step in SignUpStep.values) {
        expect(SignUpStep.fromLocation(step.route), step);
      }
    });

    test('returns null for any other location', () {
      for (final location in [
        '/',
        AppRoutes.login,
        AppRoutes.welcome,
        AppRoutes.terms,
        '/signup',
        '/signup/unknown',
      ]) {
        expect(SignUpStep.fromLocation(location), isNull, reason: location);
      }
    });
  });
}
