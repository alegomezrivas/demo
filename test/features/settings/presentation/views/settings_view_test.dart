import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:demo/features/settings/presentation/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
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

  setUp(() async {
    await resetLocator();
    getCurrentUser = MockGetCurrentUserUseCase();
    saveSettings = MockSaveSettingsUseCase();
    logout = MockLogoutUseCase();
    authenticator = MockBiometricAuthenticator();
    guard = MockSensitiveActionGuard();
    navigation = MockNavigationService();
    session = SessionService(isAuthenticated: true);
    preferences = AppPreferences();
    when(getCurrentUser(any)).thenAnswer(
      (_) async =>
          right(const User(id: '1', name: 'Ana Pérez', email: 'ana@test.com')),
    );
    when(saveSettings(any)).thenAnswer((_) async => right(unit));
    when(logout(any)).thenAnswer((_) async => right(unit));
    when(authenticator.isAvailable()).thenAnswer((_) async => true);
    when(authenticator.authenticate(reason: anyNamed('reason')))
        .thenAnswer((_) async => true);
    when(guard.confirm(reason: anyNamed('reason')))
        .thenAnswer((_) async => true);
    locator.registerFactory<SettingsViewModel>(
      () => SettingsViewModel(
        getCurrentUser: getCurrentUser,
        saveSettings: saveSettings,
        logout: logout,
        preferences: preferences,
        authenticator: authenticator,
        guard: guard,
        navigation: navigation,
        session: session,
      ),
    );
  });

  tearDown(resetLocator);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(tester, const SettingsView());
    await tester.pumpAndSettle();
  }

  group('SettingsView', () {
    testWidgets('shows the profile and every section', (tester) async {
      await pumpView(tester);

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('ana@test.com'), findsOneWidget);
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Confirmar con biometría'), findsOneWidget);
      expect(find.text('Acerca de'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('changing the theme applies and saves it', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byType(DropdownButton<AppThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oscuro').last);
      await tester.pumpAndSettle();

      expect(preferences.themeMode, ThemeMode.dark);
      verify(saveSettings(any)).called(1);
    });

    testWidgets('changing the language applies and saves it', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byType(DropdownButton<AppLanguage>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(preferences.locale, const Locale('en'));
      verify(saveSettings(any)).called(1);
    });

    testWidgets('enabling biometrics asks the device and turns the option on', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(
        authenticator.authenticate(
          reason: 'Confirma tu identidad para cambiar esta opción',
        ),
      ).called(1);
      expect(preferences.biometricConfirmation, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets(
      'explains when the device cannot authenticate and keeps the switch off',
      (tester) async {
        when(authenticator.isAvailable()).thenAnswer((_) async => false);
        await pumpView(tester);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('biometric_unavailable')), findsOneWidget);
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(preferences.biometricConfirmation, isFalse);
      },
    );

    testWidgets('opens the about screen', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Acerca de'));
      await tester.pump();

      verify(navigation.push<void>(AppRoutes.about)).called(1);
    });

    testWidgets('signs out through the confirmation guard', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(guard.confirm(reason: 'Confirma tu identidad para cerrar sesión'))
          .called(1);
      verify(logout(any)).called(1);
      expect(session.isAuthenticated, isFalse);
      verify(navigation.go(AppRoutes.login)).called(1);
    });

    testWidgets('keeps the session when the confirmation is denied', (
      tester,
    ) async {
      when(guard.confirm(reason: anyNamed('reason')))
          .thenAnswer((_) async => false);
      await pumpView(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verifyNever(logout(any));
      expect(session.isAuthenticated, isTrue);
    });
  });
}
