// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Stark Showcase';

  @override
  String get homeTitle => 'Stark Showcase';

  @override
  String get homeSubtitle =>
      'A Flutter engineering portfolio built with clean architecture';

  @override
  String get homeGetStarted => 'Learn more';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody =>
      'Demo application showcasing Clean Architecture, Stacked, GoRouter, reactive forms and unit tests.';

  @override
  String get commonBack => 'Back';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Enter a valid email address';

  @override
  String get validationStrongPassword =>
      'Use at least 8 characters with upper case, lower case, a number and a symbol';

  @override
  String get validationPhone => 'Enter a valid phone number';

  @override
  String validationMinLength(int length) {
    return 'Must be at least $length characters';
  }

  @override
  String get validationMustMatch => 'Values do not match';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorServer =>
      'The service is unavailable right now. Please try again later.';

  @override
  String get errorUnauthorized => 'Your session expired. Please sign in again.';

  @override
  String get integrityWarning =>
      'This device looks modified (root/jailbreak or debugging). Some security protections may not be effective.';

  @override
  String get integrityBlockedTitle => 'Unsupported device';

  @override
  String get integrityBlockedMessage =>
      'For security reasons the app cannot run on modified devices.';

  @override
  String get commonDismiss => 'Got it';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle => 'Use your account to continue';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authGoToRegister => 'Create account';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle => 'Fill in your details to sign up';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authPhoneLabel => 'Phone (optional)';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authRegisterButton => 'Sign up';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authGoToLogin => 'Sign in';

  @override
  String get authTogglePassword => 'Show or hide password';

  @override
  String get authInvalidCredentials => 'Incorrect email or password';

  @override
  String get authEmailTaken => 'An account with that email already exists';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeLogout => 'Sign out';
}
