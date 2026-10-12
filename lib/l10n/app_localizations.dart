import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Visible application name
  ///
  /// In es, this message translates to:
  /// **'Stark Showcase'**
  String get appName;

  /// No description provided for @aboutTitle.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In es, this message translates to:
  /// **'Aplicación de demostración que muestra Clean Architecture, Stacked, GoRouter, formularios reactivos y pruebas unitarias.'**
  String get aboutBody;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get commonBack;

  /// No description provided for @validationRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get validationEmail;

  /// No description provided for @validationStrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres con mayúscula, minúscula, número y símbolo'**
  String get validationStrongPassword;

  /// No description provided for @validationPhone.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un teléfono válido'**
  String get validationPhone;

  /// No description provided for @validationMinLength.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos {length} caracteres'**
  String validationMinLength(int length);

  /// No description provided for @validationMustMatch.
  ///
  /// In es, this message translates to:
  /// **'Los valores no coinciden'**
  String get validationMustMatch;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Inténtalo de nuevo.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión. Revisa tu red e inténtalo de nuevo.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In es, this message translates to:
  /// **'El servicio no está disponible por ahora. Inténtalo más tarde.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Inicia sesión de nuevo.'**
  String get errorUnauthorized;

  /// No description provided for @integrityWarning.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo parece modificado (root/jailbreak o depuración). Algunas protecciones de seguridad podrían no ser efectivas.'**
  String get integrityWarning;

  /// No description provided for @integrityBlockedTitle.
  ///
  /// In es, this message translates to:
  /// **'Dispositivo no compatible'**
  String get integrityBlockedTitle;

  /// No description provided for @integrityBlockedMessage.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, la aplicación no puede ejecutarse en dispositivos modificados.'**
  String get integrityBlockedMessage;

  /// No description provided for @commonDismiss.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonDismiss;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Accede con tu cuenta para continuar'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// No description provided for @authLoginButton.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get authLoginButton;

  /// No description provided for @authNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get authNoAccount;

  /// No description provided for @authGoToRegister.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authGoToRegister;

  /// No description provided for @authRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Completa tus datos para registrarte'**
  String get authRegisterSubtitle;

  /// No description provided for @authNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get authNameLabel;

  /// No description provided for @authPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get authPhoneLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get authRegisterButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get authHaveAccount;

  /// No description provided for @authGoToLogin.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authGoToLogin;

  /// No description provided for @authTogglePassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar u ocultar contraseña'**
  String get authTogglePassword;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con ese correo'**
  String get authEmailTaken;

  /// No description provided for @navDashboard.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navDashboard;

  /// No description provided for @navTasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get navTasks;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @dashboardGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Así va tu trabajo'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardCompletion.
  ///
  /// In es, this message translates to:
  /// **'{percent}% completado'**
  String dashboardCompletion(int percent);

  /// No description provided for @dashboardStatTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get dashboardStatTotal;

  /// No description provided for @dashboardStatDone.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get dashboardStatDone;

  /// No description provided for @dashboardStatOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencidas'**
  String get dashboardStatOverdue;

  /// No description provided for @dashboardStatHighPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad alta pendientes'**
  String get dashboardStatHighPriority;

  /// No description provided for @dashboardViewTasks.
  ///
  /// In es, this message translates to:
  /// **'Ver tareas'**
  String get dashboardViewTasks;

  /// No description provided for @dashboardNewTask.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get dashboardNewTask;

  /// No description provided for @tasksTitle.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tasksTitle;

  /// No description provided for @tasksSearchLabel.
  ///
  /// In es, this message translates to:
  /// **'Buscar tareas'**
  String get tasksSearchLabel;

  /// No description provided for @tasksFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get tasksFilterAll;

  /// No description provided for @tasksFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get tasksFilterPending;

  /// No description provided for @tasksFilterDone.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get tasksFilterDone;

  /// No description provided for @tasksPriorityAny.
  ///
  /// In es, this message translates to:
  /// **'Cualquier prioridad'**
  String get tasksPriorityAny;

  /// No description provided for @priorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @tasksEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes tareas'**
  String get tasksEmpty;

  /// No description provided for @tasksEmptyFiltered.
  ///
  /// In es, this message translates to:
  /// **'Ninguna tarea coincide con los filtros'**
  String get tasksEmptyFiltered;

  /// No description provided for @tasksDueDate.
  ///
  /// In es, this message translates to:
  /// **'Vence: {date}'**
  String tasksDueDate(String date);

  /// No description provided for @tasksOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get tasksOverdue;

  /// No description provided for @tasksDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tarea'**
  String get tasksDeleteTitle;

  /// No description provided for @tasksDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{title}\"?'**
  String tasksDeleteMessage(String title);

  /// No description provided for @tasksNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get tasksNew;

  /// No description provided for @tasksEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get tasksEdit;

  /// No description provided for @tasksFieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get tasksFieldTitle;

  /// No description provided for @tasksFieldDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get tasksFieldDescription;

  /// No description provided for @tasksFieldPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get tasksFieldPriority;

  /// No description provided for @tasksFieldDueDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite'**
  String get tasksFieldDueDate;

  /// No description provided for @tasksFieldDone.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get tasksFieldDone;

  /// No description provided for @tasksClearDate.
  ///
  /// In es, this message translates to:
  /// **'Quitar fecha'**
  String get tasksClearDate;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get settingsProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get settingsSecurity;

  /// No description provided for @settingsBiometric.
  ///
  /// In es, this message translates to:
  /// **'Confirmar con biometría'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricHint.
  ///
  /// In es, this message translates to:
  /// **'Pide tu huella, rostro o bloqueo de pantalla antes de eliminar tareas o cerrar sesión'**
  String get settingsBiometricHint;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este dispositivo no tiene huella, rostro ni bloqueo de pantalla configurado'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAbout;

  /// No description provided for @settingsLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogout;

  /// No description provided for @biometricReasonDelete.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para eliminar la tarea'**
  String get biometricReasonDelete;

  /// No description provided for @biometricReasonLogout.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para cerrar sesión'**
  String get biometricReasonLogout;

  /// No description provided for @validationMaxLength.
  ///
  /// In es, this message translates to:
  /// **'No puede superar {length} caracteres'**
  String validationMaxLength(int length);

  /// No description provided for @biometricReasonToggle.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para cambiar esta opción'**
  String get biometricReasonToggle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
