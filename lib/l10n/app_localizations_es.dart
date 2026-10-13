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
  String get navDashboard => 'Inicio';

  @override
  String get navTasks => 'Tareas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSave => 'Guardar';

  @override
  String dashboardGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get dashboardSubtitle => 'Así va tu trabajo';

  @override
  String dashboardCompletion(int percent) {
    return '$percent% completado';
  }

  @override
  String get dashboardStatTotal => 'Total';

  @override
  String get dashboardStatDone => 'Completadas';

  @override
  String get dashboardStatOverdue => 'Vencidas';

  @override
  String get dashboardStatHighPriority => 'Prioridad alta pendientes';

  @override
  String get dashboardViewTasks => 'Ver tareas';

  @override
  String get dashboardNewTask => 'Nueva tarea';

  @override
  String get tasksTitle => 'Tareas';

  @override
  String get tasksSearchLabel => 'Buscar tareas';

  @override
  String get tasksFilterAll => 'Todas';

  @override
  String get tasksFilterPending => 'Pendientes';

  @override
  String get tasksFilterDone => 'Completadas';

  @override
  String get tasksPriorityAny => 'Cualquier prioridad';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get tasksEmpty => 'Aún no tienes tareas';

  @override
  String get tasksEmptyFiltered => 'Ninguna tarea coincide con los filtros';

  @override
  String tasksDueDate(String date) {
    return 'Vence: $date';
  }

  @override
  String get tasksOverdue => 'Vencida';

  @override
  String get tasksDeleteTitle => 'Eliminar tarea';

  @override
  String tasksDeleteMessage(String title) {
    return '¿Seguro que quieres eliminar \"$title\"?';
  }

  @override
  String get tasksNew => 'Nueva tarea';

  @override
  String get tasksEdit => 'Editar tarea';

  @override
  String get tasksFieldTitle => 'Título';

  @override
  String get tasksFieldDescription => 'Descripción';

  @override
  String get tasksFieldPriority => 'Prioridad';

  @override
  String get tasksFieldDueDate => 'Fecha límite';

  @override
  String get tasksFieldDone => 'Completada';

  @override
  String get tasksClearDate => 'Quitar fecha';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsSecurity => 'Seguridad';

  @override
  String get settingsBiometric => 'Confirmar con biometría';

  @override
  String get settingsBiometricHint =>
      'Pide tu huella, rostro o bloqueo de pantalla antes de eliminar tareas o cerrar sesión';

  @override
  String get settingsBiometricUnavailable =>
      'Este dispositivo no tiene huella, rostro ni bloqueo de pantalla configurado';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get biometricReasonDelete =>
      'Confirma tu identidad para eliminar la tarea';

  @override
  String get biometricReasonLogout =>
      'Confirma tu identidad para cerrar sesión';

  @override
  String validationMaxLength(int length) {
    return 'No puede superar $length caracteres';
  }

  @override
  String get biometricReasonToggle =>
      'Confirma tu identidad para cambiar esta opción';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get fieldValidIndicator => 'Válido';

  @override
  String otpSemanticsLabel(int entered, int total) {
    return 'Código de confirmación, $entered de $total dígitos';
  }

  @override
  String get avatarSemanticsEmpty => 'Sin foto de perfil';

  @override
  String get avatarSemanticsFilled => 'Foto de perfil';
}
