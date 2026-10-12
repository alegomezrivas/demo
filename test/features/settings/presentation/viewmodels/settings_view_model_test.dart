import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../auth/helpers/auth_mocks.dart';
import '../../helpers/settings_mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockSaveSettingsUseCase saveSettings;
  late MockLogoutUseCase logout;
  late MockBiometricAuthenticator authenticator;
  late MockSensitiveActionGuard guard;
  late MockNavigationService navigation;
  late SessionService session;
  late AppPreferences preferences;
  late SettingsViewModel viewModel;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');

  setUp(() {
    getCurrentUser = MockGetCurrentUserUseCase();
    saveSettings = MockSaveSettingsUseCase();
    logout = MockLogoutUseCase();
    authenticator = MockBiometricAuthenticator();
    guard = MockSensitiveActionGuard();
    navigation = MockNavigationService();
    session = SessionService(isAuthenticated: true);
    preferences = AppPreferences();
    when(getCurrentUser(any)).thenAnswer((_) async => right(user));
    when(saveSettings(any)).thenAnswer((_) async => right(unit));
    when(logout(any)).thenAnswer((_) async => right(unit));
    when(authenticator.isAvailable()).thenAnswer((_) async => true);
    when(authenticator.authenticate(reason: anyNamed('reason')))
        .thenAnswer((_) async => true);
    when(guard.confirm(reason: anyNamed('reason')))
        .thenAnswer((_) async => true);
    viewModel = SettingsViewModel(
      getCurrentUser: getCurrentUser,
      saveSettings: saveSettings,
      logout: logout,
      preferences: preferences,
      authenticator: authenticator,
      guard: guard,
      navigation: navigation,
      session: session,
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> ready() => viewModel.init(toggleReason: 'confirm');

  group('init', () {
    test('loads the profile', () async {
      await ready();

      expect(viewModel.user, user);
    });

    test('starts the form from the live preferences', () async {
      preferences.apply(
        const AppSettings(
          themeMode: AppThemeMode.dark,
          language: AppLanguage.english,
          biometricConfirmation: true,
        ),
      );
      viewModel.dispose();
      viewModel = SettingsViewModel(
        getCurrentUser: getCurrentUser,
        saveSettings: saveSettings,
        logout: logout,
        preferences: preferences,
        authenticator: authenticator,
        guard: guard,
        navigation: navigation,
        session: session,
      );

      expect(
        viewModel.form.control(SettingsViewModel.themeField).value,
        AppThemeMode.dark,
      );
      expect(
        viewModel.form.control(SettingsViewModel.languageField).value,
        AppLanguage.english,
      );
      expect(
        viewModel.form.control(SettingsViewModel.biometricField).value,
        isTrue,
      );
    });

    test('keeps the profile empty when loading fails', () async {
      when(getCurrentUser(any))
          .thenAnswer((_) async => left(const CacheFailure()));

      await ready();

      expect(viewModel.user, isNull);
    });
  });

  group('appearance', () {
    test('changing the theme applies it at once and persists it', () async {
      await ready();

      viewModel.form.control(SettingsViewModel.themeField).value =
          AppThemeMode.dark;
      await settle();

      expect(preferences.settings.themeMode, AppThemeMode.dark);
      final saved =
          verify(saveSettings(captureAny)).captured.single as AppSettings;
      expect(saved.themeMode, AppThemeMode.dark);
    });

    test('changing the language applies it and persists it', () async {
      await ready();

      viewModel.form.control(SettingsViewModel.languageField).value =
          AppLanguage.english;
      await settle();

      expect(preferences.settings.language, AppLanguage.english);
      verify(saveSettings(any)).called(1);
    });

    test(
      'keeps the new value but reports a failure when saving fails',
      () async {
        when(saveSettings(any))
            .thenAnswer((_) async => left(const CacheFailure()));
        await ready();

        viewModel.form.control(SettingsViewModel.themeField).value =
            AppThemeMode.light;
        await settle();

        expect(preferences.settings.themeMode, AppThemeMode.light);
        expect(viewModel.failure, const CacheFailure());
      },
    );

    test('clears the failure after a successful save', () async {
      when(saveSettings(any))
          .thenAnswer((_) async => left(const CacheFailure()));
      await ready();
      viewModel.form.control(SettingsViewModel.themeField).value =
          AppThemeMode.light;
      await settle();
      when(saveSettings(any)).thenAnswer((_) async => right(unit));

      viewModel.form.control(SettingsViewModel.themeField).value =
          AppThemeMode.dark;
      await settle();

      expect(viewModel.failure, isNull);
    });
  });

  group('biometric confirmation', () {
    test('turns on after the user authenticates', () async {
      await ready();

      viewModel.form.control(SettingsViewModel.biometricField).value = true;
      await settle();

      verify(authenticator.authenticate(reason: 'confirm')).called(1);
      expect(preferences.biometricConfirmation, isTrue);
      expect(viewModel.biometricUnavailable, isFalse);
    });

    test('stays off when the device cannot authenticate', () async {
      when(authenticator.isAvailable()).thenAnswer((_) async => false);
      await ready();

      viewModel.form.control(SettingsViewModel.biometricField).value = true;
      await settle();

      expect(
        viewModel.form.control(SettingsViewModel.biometricField).value,
        isFalse,
      );
      expect(viewModel.biometricUnavailable, isTrue);
      expect(preferences.biometricConfirmation, isFalse);
      verifyNever(authenticator.authenticate(reason: anyNamed('reason')));
      verifyNever(saveSettings(any));
    });

    test('stays off when the user fails to authenticate', () async {
      when(authenticator.authenticate(reason: anyNamed('reason')))
          .thenAnswer((_) async => false);
      await ready();

      viewModel.form.control(SettingsViewModel.biometricField).value = true;
      await settle();

      expect(
        viewModel.form.control(SettingsViewModel.biometricField).value,
        isFalse,
      );
      expect(preferences.biometricConfirmation, isFalse);
      verifyNever(saveSettings(any));
    });

    test('turning it off asks for confirmation first', () async {
      preferences.apply(const AppSettings(biometricConfirmation: true));
      viewModel.dispose();
      viewModel = SettingsViewModel(
        getCurrentUser: getCurrentUser,
        saveSettings: saveSettings,
        logout: logout,
        preferences: preferences,
        authenticator: authenticator,
        guard: guard,
        navigation: navigation,
        session: session,
      );
      await ready();

      viewModel.form.control(SettingsViewModel.biometricField).value = false;
      await settle();

      verify(guard.confirm(reason: 'confirm')).called(1);
      expect(preferences.biometricConfirmation, isFalse);
    });

    test('turning it off is reverted when confirmation is denied', () async {
      preferences.apply(const AppSettings(biometricConfirmation: true));
      when(guard.confirm(reason: anyNamed('reason')))
          .thenAnswer((_) async => false);
      viewModel.dispose();
      viewModel = SettingsViewModel(
        getCurrentUser: getCurrentUser,
        saveSettings: saveSettings,
        logout: logout,
        preferences: preferences,
        authenticator: authenticator,
        guard: guard,
        navigation: navigation,
        session: session,
      );
      await ready();

      viewModel.form.control(SettingsViewModel.biometricField).value = false;
      await settle();

      expect(
        viewModel.form.control(SettingsViewModel.biometricField).value,
        isTrue,
      );
      expect(preferences.biometricConfirmation, isTrue);
      verifyNever(saveSettings(any));
    });
  });

  group('navigation and sign-out', () {
    test('openAbout pushes the about route', () async {
      await viewModel.openAbout();

      verify(navigation.push<void>(AppRoutes.about)).called(1);
    });

    test('logout clears the session and goes to login', () async {
      await viewModel.logout(reason: 'r');

      verify(guard.confirm(reason: 'r')).called(1);
      verify(logout(any)).called(1);
      expect(session.isAuthenticated, isFalse);
      verify(navigation.go(AppRoutes.login)).called(1);
    });

    test('logout is cancelled when the confirmation is denied', () async {
      when(guard.confirm(reason: anyNamed('reason')))
          .thenAnswer((_) async => false);

      await viewModel.logout(reason: 'r');

      verifyNever(logout(any));
      expect(session.isAuthenticated, isTrue);
      verifyZeroInteractions(navigation);
    });
  });
}
