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

  @override
  String get authLoginTitle => 'Iniciar sesión';

  @override
  String get authLoginSubtitle => 'Accede con tu cuenta para continuar';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authLoginButton => 'Entrar';

  @override
  String get authNoAccount => '¿No tienes cuenta?';

  @override
  String get authGoToRegister => 'Crear cuenta';

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authRegisterSubtitle => 'Completa tus datos para registrarte';

  @override
  String get authNameLabel => 'Nombre';

  @override
  String get authPhoneLabel => 'Teléfono (opcional)';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authRegisterButton => 'Registrarme';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authGoToLogin => 'Iniciar sesión';

  @override
  String get authTogglePassword => 'Mostrar u ocultar contraseña';

  @override
  String get authInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get authEmailTaken => 'Ya existe una cuenta con ese correo';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeLogout => 'Cerrar sesión';
}
