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

  @override
  String get validationCode => 'Enter the 6-digit code';

  @override
  String get validationUsername =>
      'Use 3 to 30 letters, numbers, dots or underscores, with no dot at the start or end';

  @override
  String get authCodeInvalid => 'That code is not correct';

  @override
  String get authCodeExpired => 'The code expired. Request a new one.';

  @override
  String get authCodeTooManyAttempts =>
      'Too many attempts. Request a new code.';

  @override
  String get authResendTooSoon =>
      'Wait a moment before requesting another code';

  @override
  String get authUsernameTaken => 'That username is already taken';

  @override
  String get authVerificationExpired =>
      'E-mail verification expired. Start again.';

  @override
  String get authImageInvalid =>
      'We couldn\'t use that picture. Try another one.';

  @override
  String get authImageTooLarge => 'The picture is too large';

  @override
  String get welcomeTitle => 'Organize your tasks, noise-free';

  @override
  String get welcomeSubtitle =>
      'Create an account in a few steps and keep everything in one place.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get welcomeIllustrationLabel => 'Illustration of completed tasks';

  @override
  String get signUpNext => 'Next';

  @override
  String get signUpEmailTitle => 'What\'s your e-mail address?';

  @override
  String get signUpEmailDescription =>
      'We\'ll send you a code to confirm it\'s yours.';

  @override
  String get signUpCodeTitle => 'Enter the confirmation code';

  @override
  String signUpCodeDescription(String email) {
    return 'Enter the 6-digit code we sent to $email.';
  }

  @override
  String get signUpCodeNotReceived => 'I didn\'t get the code';

  @override
  String signUpCodeResendIn(int seconds) {
    return 'You can request another code in $seconds s';
  }

  @override
  String get signUpPasswordTitle => 'Create a password';

  @override
  String get signUpPasswordDescription =>
      'Use at least 8 characters with upper case, lower case, a number and a symbol.';

  @override
  String get authRememberSession => 'Remember me';

  @override
  String get authRememberSessionHint =>
      'If you turn it off, you\'ll have to sign in every time you open the app.';

  @override
  String get signUpNameTitle => 'What\'s your name?';

  @override
  String get signUpNameDescription =>
      'Add your name so people can recognize you.';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get signUpUsernameTitle => 'Choose a username';

  @override
  String get signUpUsernameDescription => 'It will be your public handle.';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get usernameChecking => 'Checking availability…';

  @override
  String usernameAvailable(String username) {
    return '$username is available';
  }

  @override
  String get usernameUnknown =>
      'We couldn\'t check it right now. You can continue.';

  @override
  String get signUpTermsTitle => 'Accept the terms and policies';

  @override
  String get signUpTermsDescription =>
      'By creating your account you accept the terms of use and the privacy policy of this demo.';

  @override
  String get signUpTermsAccept => 'I agree';

  @override
  String get signUpTermsRead => 'Read the terms and policies';

  @override
  String get termsScreenTitle => 'Terms and policies';

  @override
  String get termsDemoNotice =>
      'Sample text for this demo. It is not a legal document.';

  @override
  String get termsUseTitle => 'Using the app';

  @override
  String get termsUseBody =>
      'This app is a technical demo. You can create test tasks and delete them whenever you want. Do not use it to store important information.';

  @override
  String get termsPrivacyTitle => 'Privacy';

  @override
  String get termsPrivacyBody =>
      'We only store what you type when you create your account: e-mail, name, username and, if you want, a picture. We never store your password in plain text.';

  @override
  String get termsDataTitle => 'Your data';

  @override
  String get termsDataBody =>
      'Demo data lives in memory and is erased when the server restarts. We do not share it with anyone.';

  @override
  String get signUpAvatarTitle => 'Add a profile picture';

  @override
  String get signUpAvatarDescription =>
      'Add a picture so people recognize you. You can skip this step.';

  @override
  String get signUpAvatarAdd => 'Add a picture';

  @override
  String get signUpAvatarSkip => 'Skip';

  @override
  String get photoSheetTitle => 'Add profile picture';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get photoGalleryDenied =>
      'We need permission to access your photos. You can turn it on in the system settings.';

  @override
  String get photoCameraDenied =>
      'We need permission to use the camera. You can turn it on in the system settings.';

  @override
  String get photoCropTitle => 'Crop your picture';

  @override
  String get photoCropDone => 'Done';

  @override
  String signUpDoneTitle(String username) {
    return 'Welcome, @$username';
  }

  @override
  String get signUpDoneDescription =>
      'Your account is ready. Start organizing your tasks.';

  @override
  String get signUpDoneButton => 'Continue';

  @override
  String get settingsBiometricNeedsRememberedSession =>
      'Biometric confirmation is only available when the session is remembered. Sign out and sign in again with “Remember me” on.';

  @override
  String get authNoAccountCreate => 'Don\'t have an account? Create account';
}
