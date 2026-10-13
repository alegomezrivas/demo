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
  String get navDashboard => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardSubtitle => 'Here is how your work is going';

  @override
  String dashboardCompletion(int percent) {
    return '$percent% completed';
  }

  @override
  String get dashboardStatTotal => 'Total';

  @override
  String get dashboardStatDone => 'Completed';

  @override
  String get dashboardStatOverdue => 'Overdue';

  @override
  String get dashboardStatHighPriority => 'High priority open';

  @override
  String get dashboardViewTasks => 'View tasks';

  @override
  String get dashboardNewTask => 'New task';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksSearchLabel => 'Search tasks';

  @override
  String get tasksFilterAll => 'All';

  @override
  String get tasksFilterPending => 'Pending';

  @override
  String get tasksFilterDone => 'Completed';

  @override
  String get tasksPriorityAny => 'Any priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get tasksEmpty => 'You have no tasks yet';

  @override
  String get tasksEmptyFiltered => 'No task matches the filters';

  @override
  String tasksDueDate(String date) {
    return 'Due: $date';
  }

  @override
  String get tasksOverdue => 'Overdue';

  @override
  String get tasksDeleteTitle => 'Delete task';

  @override
  String tasksDeleteMessage(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get tasksNew => 'New task';

  @override
  String get tasksEdit => 'Edit task';

  @override
  String get tasksFieldTitle => 'Title';

  @override
  String get tasksFieldDescription => 'Description';

  @override
  String get tasksFieldPriority => 'Priority';

  @override
  String get tasksFieldDueDate => 'Due date';

  @override
  String get tasksFieldDone => 'Completed';

  @override
  String get tasksClearDate => 'Clear date';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsBiometric => 'Confirm with biometrics';

  @override
  String get settingsBiometricHint =>
      'Asks for your fingerprint, face or screen lock before deleting tasks or signing out';

  @override
  String get settingsBiometricUnavailable =>
      'This device has no fingerprint, face or screen lock set up';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get biometricReasonDelete =>
      'Confirm your identity to delete the task';

  @override
  String get biometricReasonLogout => 'Confirm your identity to sign out';

  @override
  String validationMaxLength(int length) {
    return 'Cannot exceed $length characters';
  }

  @override
  String get biometricReasonToggle =>
      'Confirm your identity to change this option';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClose => 'Close';

  @override
  String get commonEdit => 'Edit';

  @override
  String get fieldValidIndicator => 'Valid';

  @override
  String otpSemanticsLabel(int entered, int total) {
    return 'Confirmation code, $entered of $total digits';
  }

  @override
  String get avatarSemanticsEmpty => 'No profile picture';

  @override
  String get avatarSemanticsFilled => 'Profile picture';
}
