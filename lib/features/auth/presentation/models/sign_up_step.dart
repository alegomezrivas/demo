import 'package:demo/app/router/app_routes.dart';

/// Steps of the account creation, in the order the person goes through them.
enum SignUpStep {
  /// E-mail address.
  email(AppRoutes.signUpEmail),

  /// Confirmation code received by e-mail.
  code(AppRoutes.signUpCode),

  /// Password and "remember me".
  password(AppRoutes.signUpPassword),

  /// Full name.
  name(AppRoutes.signUpName),

  /// Public username.
  username(AppRoutes.signUpUsername),

  /// Terms and policies; accepting them creates the account.
  terms(AppRoutes.signUpTerms),

  /// Optional profile picture (the account already exists).
  avatar(AppRoutes.signUpAvatar),

  /// Final welcome.
  done(AppRoutes.signUpDone)
  ;

  const SignUpStep(this.route);

  /// Path of the screen for this step.
  final String route;

  /// The step shown at [location], or null when it is not a sign-up route.
  static SignUpStep? fromLocation(String location) {
    for (final step in values) {
      if (step.route == location) return step;
    }
    return null;
  }
}
