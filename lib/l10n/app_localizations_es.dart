// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Stark Showcase';

  @override
  String get homeTitle => 'Stark Showcase';

  @override
  String get homeSubtitle =>
      'Portafolio de ingeniería Flutter con arquitectura limpia';

  @override
  String get homeGetStarted => 'Conocer más';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutBody =>
      'Aplicación de demostración que muestra Clean Architecture, Stacked, GoRouter, formularios reactivos y pruebas unitarias.';

  @override
  String get commonBack => 'Volver';
}
