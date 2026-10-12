import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.dart';

void main() {
  late AppPreferences preferences;
  late GoRouter router;

  IntegrityGateViewModel integrityViewModel([
    IntegrityDecision decision = IntegrityDecision.allow,
  ]) {
    final service = MockDeviceIntegrityService();
    when(service.evaluate()).thenAnswer((_) async => decision);
    return IntegrityGateViewModel(service);
  }

  setUp(() {
    preferences = AppPreferences();
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) =>
              Scaffold(body: Text(AppLocalizations.of(context).navDashboard)),
        ),
      ],
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String language = 'es',
    IntegrityDecision decision = IntegrityDecision.allow,
  }) async {
    tester.platformDispatcher.localesTestValue = [Locale(language)];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      App(
        routerConfig: router,
        integrityViewModelBuilder: () => integrityViewModel(decision),
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('App localization', () {
    testWidgets('shows Spanish when the device is Spanish', (tester) async {
      await pumpApp(tester);

      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('shows English when the device is English', (tester) async {
      await pumpApp(tester, language: 'en');

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('falls back to Spanish for unsupported languages', (
      tester,
    ) async {
      await pumpApp(tester, language: 'fr');

      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('the saved language wins over the device language', (
      tester,
    ) async {
      preferences.apply(const AppSettings(language: AppLanguage.english));

      await pumpApp(tester);

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('changing the language at runtime rebuilds the app', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('Inicio'), findsOneWidget);

      preferences.apply(const AppSettings(language: AppLanguage.english));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('App theme', () {
    testWidgets('follows the saved theme mode', (tester) async {
      preferences.apply(const AppSettings(themeMode: AppThemeMode.dark));

      await pumpApp(tester);

      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('switches to light at runtime', (tester) async {
      preferences.apply(const AppSettings(themeMode: AppThemeMode.dark));
      await pumpApp(tester);

      preferences.apply(const AppSettings(themeMode: AppThemeMode.light));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });

  group('App shell', () {
    testWidgets('clamps the text scale factor', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester);

      final context = tester.element(find.byType(Scaffold));

      expect(MediaQuery.textScalerOf(context).scale(10), lessThanOrEqualTo(16));
    });

    testWidgets('blocks the app when the integrity policy says so', (
      tester,
    ) async {
      await pumpApp(tester, decision: IntegrityDecision.block);

      expect(find.text('Inicio'), findsNothing);
      expect(find.text('Dispositivo no compatible'), findsOneWidget);
    });
  });

  group('AppRouter', () {
    setUp(() async {
      await resetLocator();
    });

    tearDown(resetLocator);

    test('starts at the home route', () {
      final appRouter = AppRouter.create();

      expect(appRouter.routeInformationProvider.value.uri.path, AppRoutes.home);
    });

    testWidgets('applies the redirect guard', (tester) async {
      final guarded = AppRouter.create(
        redirect: (_, state) =>
            state.uri.path == AppRoutes.home ? AppRoutes.about : null,
      );
      await setupLocator(router: guarded);
      tester.platformDispatcher.localesTestValue = [const Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(
        App(
          routerConfig: guarded,
          integrityViewModelBuilder: integrityViewModel,
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acerca de'), findsOneWidget);
    });
  });
}
