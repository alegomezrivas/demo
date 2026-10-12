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
}
