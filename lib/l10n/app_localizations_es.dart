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

  @override
  String get validationRequired => 'Este campo es obligatorio';

  @override
  String get validationEmail => 'Ingresa un correo electrónico válido';

  @override
  String get validationStrongPassword =>
      'Usa al menos 8 caracteres con mayúscula, minúscula, número y símbolo';

  @override
  String get validationPhone => 'Ingresa un teléfono válido';

  @override
  String validationMinLength(int length) {
    return 'Debe tener al menos $length caracteres';
  }

  @override
  String get validationMustMatch => 'Los valores no coinciden';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorNetwork =>
      'No hay conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorServer =>
      'El servicio no está disponible por ahora. Inténtalo más tarde.';

  @override
  String get errorUnauthorized => 'Tu sesión expiró. Inicia sesión de nuevo.';

  @override
  String get integrityWarning =>
      'Este dispositivo parece modificado (root/jailbreak o depuración). Algunas protecciones de seguridad podrían no ser efectivas.';

  @override
  String get integrityBlockedTitle => 'Dispositivo no compatible';

  @override
  String get integrityBlockedMessage =>
      'Por seguridad, la aplicación no puede ejecutarse en dispositivos modificados.';

  @override
  String get commonDismiss => 'Entendido';
}
