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
}
