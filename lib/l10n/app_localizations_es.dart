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

  @override
  String get validationCode => 'Ingresa el código de 6 dígitos';

  @override
  String get validationUsername =>
      'Usa de 3 a 30 letras, números, puntos o guiones bajos, sin punto al inicio ni al final';

  @override
  String get authCodeInvalid => 'El código no es correcto';

  @override
  String get authCodeExpired => 'El código caducó. Pide uno nuevo.';

  @override
  String get authCodeTooManyAttempts =>
      'Demasiados intentos. Pide un código nuevo.';

  @override
  String get authResendTooSoon =>
      'Espera un momento antes de pedir otro código';

  @override
  String get authUsernameTaken => 'Ese nombre de usuario ya está en uso';

  @override
  String get authVerificationExpired =>
      'La verificación del correo caducó. Empieza de nuevo.';

  @override
  String get authImageInvalid => 'No pudimos usar esa imagen. Prueba con otra.';

  @override
  String get authImageTooLarge => 'La imagen es demasiado grande';

  @override
  String get welcomeTitle => 'Organiza tus tareas, sin ruido';

  @override
  String get welcomeSubtitle =>
      'Crea una cuenta en unos pasos y lleva todo en un solo lugar.';

  @override
  String get welcomeStart => 'Empezar';

  @override
  String get welcomeHaveAccount => 'Ya tengo cuenta';

  @override
  String get welcomeIllustrationLabel => 'Ilustración de tareas completadas';

  @override
  String get signUpNext => 'Siguiente';

  @override
  String get signUpEmailTitle => '¿Cuál es tu correo electrónico?';

  @override
  String get signUpEmailDescription =>
      'Te enviaremos un código para confirmar que es tuyo.';

  @override
  String get signUpCodeTitle => 'Escribe el código de confirmación';

  @override
  String signUpCodeDescription(String email) {
    return 'Ingresa el código de 6 dígitos que enviamos a $email.';
  }

  @override
  String get signUpCodeNotReceived => 'No recibí el código';

  @override
  String signUpCodeResendIn(int seconds) {
    return 'Podrás pedir otro código en $seconds s';
  }

  @override
  String get signUpPasswordTitle => 'Crea una contraseña';

  @override
  String get signUpPasswordDescription =>
      'Usa al menos 8 caracteres con mayúscula, minúscula, número y símbolo.';

  @override
  String get authRememberSession => 'Recordar sesión';

  @override
  String get authRememberSessionHint =>
      'Si lo desactivas, tendrás que iniciar sesión cada vez que abras la app.';

  @override
  String get signUpNameTitle => '¿Cómo te llamas?';

  @override
  String get signUpNameDescription =>
      'Agrega tu nombre para que otras personas te reconozcan.';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get signUpUsernameTitle => 'Elige un nombre de usuario';

  @override
  String get signUpUsernameDescription => 'Será tu identificador público.';

  @override
  String get authUsernameLabel => 'Nombre de usuario';

  @override
  String get usernameChecking => 'Comprobando disponibilidad…';

  @override
  String usernameAvailable(String username) {
    return '$username está disponible';
  }

  @override
  String get usernameUnknown =>
      'No pudimos comprobarlo ahora. Puedes continuar.';

  @override
  String get signUpTermsTitle => 'Acepta los términos y políticas';

  @override
  String get signUpTermsDescription =>
      'Al crear tu cuenta aceptas los términos de uso y la política de privacidad de esta demostración.';

  @override
  String get signUpTermsAccept => 'Acepto';

  @override
  String get signUpTermsRead => 'Leer los términos y políticas';

  @override
  String get termsScreenTitle => 'Términos y políticas';

  @override
  String get termsDemoNotice =>
      'Texto de ejemplo para esta demostración. No es un documento legal.';

  @override
  String get termsUseTitle => 'Uso de la app';

  @override
  String get termsUseBody =>
      'Esta app es una demostración técnica. Puedes crear tareas de prueba y borrarlas cuando quieras. No la uses para guardar información importante.';

  @override
  String get termsPrivacyTitle => 'Privacidad';

  @override
  String get termsPrivacyBody =>
      'Solo guardamos los datos que escribes al crear tu cuenta: correo, nombre, nombre de usuario y, si quieres, una foto. Nunca guardamos tu contraseña en texto plano.';

  @override
  String get termsDataTitle => 'Tus datos';

  @override
  String get termsDataBody =>
      'Los datos de la demostración viven en memoria y se borran cuando el servidor se reinicia. No los compartimos con nadie.';

  @override
  String get signUpAvatarTitle => 'Agrega una foto de perfil';

  @override
  String get signUpAvatarDescription =>
      'Añade una foto para que te reconozcan. Puedes omitir este paso.';

  @override
  String get signUpAvatarAdd => 'Agregar una foto';

  @override
  String get signUpAvatarSkip => 'Omitir';

  @override
  String get photoSheetTitle => 'Agregar foto de perfil';

  @override
  String get photoFromGallery => 'Elegir de la galería';

  @override
  String get photoFromCamera => 'Tomar una foto';

  @override
  String get photoGalleryDenied =>
      'Necesitamos permiso para acceder a tus fotos. Puedes activarlo en los ajustes del sistema.';

  @override
  String get photoCameraDenied =>
      'Necesitamos permiso para usar la cámara. Puedes activarlo en los ajustes del sistema.';

  @override
  String get photoCropTitle => 'Recorta tu foto';

  @override
  String get photoCropDone => 'Listo';

  @override
  String signUpDoneTitle(String username) {
    return 'Te damos la bienvenida, @$username';
  }

  @override
  String get signUpDoneDescription =>
      'Tu cuenta está lista. Empieza a organizar tus tareas.';

  @override
  String get signUpDoneButton => 'Continuar';

  @override
  String get settingsBiometricNeedsRememberedSession =>
      'La confirmación biométrica solo está disponible cuando la sesión se recuerda. Cierra sesión e inicia de nuevo con “Recordar sesión” activado.';

  @override
  String get authNoAccountCreate => '¿No tienes cuenta? Crear cuenta';
}
