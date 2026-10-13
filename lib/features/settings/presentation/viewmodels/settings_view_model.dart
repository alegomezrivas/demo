import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:demo/core/security/sensitive_action_guard.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the settings tab: profile, appearance, security and sign-out.
class SettingsViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  SettingsViewModel({
    required GetCurrentUserUseCase getCurrentUser,
    required SaveSettingsUseCase saveSettings,
    required LogoutUseCase logout,
    required AppPreferences preferences,
    required BiometricAuthenticator authenticator,
    required SensitiveActionGuard guard,
    required NavigationService navigation,
    required SessionService session,
  }) : _getCurrentUser = getCurrentUser,
       _saveSettings = saveSettings,
       _logout = logout,
       _preferences = preferences,
       _authenticator = authenticator,
       _guard = guard,
       _navigation = navigation,
       _session = session {
    final settings = _preferences.settings;
    _theme = FormControl<AppThemeMode>(value: settings.themeMode);
    _language = FormControl<AppLanguage>(value: settings.language);
    _biometric = FormControl<bool>(value: settings.biometricConfirmation);
    form = FormGroup({
      themeField: _theme,
      languageField: _language,
      biometricField: _biometric,
    });
  }

  /// Name of the theme control.
  static const String themeField = 'theme';

  /// Name of the language control.
  static const String languageField = 'language';

  /// Name of the biometric confirmation control.
  static const String biometricField = 'biometric';

  final GetCurrentUserUseCase _getCurrentUser;
  final SaveSettingsUseCase _saveSettings;
  final LogoutUseCase _logout;
  final AppPreferences _preferences;
  final BiometricAuthenticator _authenticator;
  final SensitiveActionGuard _guard;
  final NavigationService _navigation;
  final SessionService _session;

  late final FormControl<AppThemeMode> _theme;
  late final FormControl<AppLanguage> _language;
  late final FormControl<bool> _biometric;

  /// The settings form.
  late final FormGroup form;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  String _toggleReason = '';
  bool _handlingBiometric = false;
  User? _user;
  bool _biometricUnavailable = false;
  Failure? _failure;

  /// The signed-in user, once loaded.
  User? get user => _user;

  /// Whether the biometric option can be offered.
  ///
  /// A session that is not remembered lives in memory only, so there is no
  /// stored session for biometrics to protect and the option is hidden.
  bool get offersBiometric => _session.isPersistent;

  /// True after the user tried to enable biometrics on an unsupported device.
  bool get biometricUnavailable => _biometricUnavailable;

  /// Last failure while saving preferences, if any.
  Failure? get failure => _failure;

  /// Loads the profile and starts persisting form changes.
  ///
  /// [toggleReason] is the localized prompt shown when the biometric option is
  /// changed.
  Future<void> init({required String toggleReason}) async {
    _toggleReason = toggleReason;
    // Subscribe only once so a second call cannot persist twice or prompt twice.
    if (_subscriptions.isEmpty) {
      _subscriptions
        ..add(_theme.valueChanges.listen((_) => unawaited(_persist())))
        ..add(_language.valueChanges.listen((_) => unawaited(_persist())))
        ..add(_biometric.valueChanges.listen(_onBiometricChanged));
    }

    final result = await _getCurrentUser(const NoParams());
    if (disposed) return;
    _user = result.fold((_) => null, (user) => user);
    notifyListeners();
  }

  /// Opens the "about" screen.
  Future<void> openAbout() => _navigation.push<void>(AppRoutes.about);

  /// Ends the session after the optional biometric confirmation.
  Future<void> logout({required String reason}) async {
    if (!await _guard.confirm(reason: reason)) return;
    final result = await _logout(const NoParams());
    if (disposed) return;
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      // Local session data could not be wiped: stay signed in and say so.
      _failure = failure;
      notifyListeners();
      return;
    }
    _session.markSignedOut();
    _navigation.go(AppRoutes.login);
  }

  AppSettings _currentSettings() {
    return AppSettings(
      themeMode: _theme.value ?? AppThemeMode.system,
      language: _language.value ?? AppLanguage.system,
      biometricConfirmation: _biometric.value ?? false,
    );
  }

  Future<void> _persist() async {
    final settings = _currentSettings();
    // Apply first so the UI reacts instantly; saving can fail independently.
    _preferences.apply(settings);
    final result = await _saveSettings(settings);
    if (disposed) return;
    _failure = result.fold((failure) => failure, (_) => null);
    notifyListeners();
  }

  Future<void> _onBiometricChanged(bool? enabled) async {
    final wantsOn = enabled ?? false;
    // A revert re-emits the already confirmed value; nothing to do then.
    if (wantsOn == _preferences.biometricConfirmation) return;
    // One prompt at a time: toggles made while a prompt is open are undone
    // when it finishes.
    if (_handlingBiometric) return;

    _handlingBiometric = true;
    try {
      await _confirmBiometricChange(wantsOn: wantsOn);
    } finally {
      _handlingBiometric = false;
      _syncBiometricControl();
    }
  }

  Future<void> _confirmBiometricChange({required bool wantsOn}) async {
    if (wantsOn) {
      if (!await _authenticator.isAvailable()) {
        _biometricUnavailable = true;
        return;
      }
      if (!await _authenticator.authenticate(reason: _toggleReason)) return;
    } else if (!await _guard.confirm(reason: _toggleReason)) {
      // Turning protection off needs the same confirmation.
      return;
    }
    if (disposed) return;
    _biometricUnavailable = false;
    await _persist();
  }

  /// Puts the switch back to the confirmed value when a change was denied.
  void _syncBiometricControl() {
    if (disposed) return;
    final confirmed = _preferences.biometricConfirmation;
    if (_biometric.value != confirmed) _biometric.updateValue(confirmed);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    form.dispose();
    super.dispose();
  }
}
