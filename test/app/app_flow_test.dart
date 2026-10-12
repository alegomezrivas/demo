import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mocks.dart';

void main() {
  late GoRouter router;

  IntegrityGateViewModel integrityViewModel() {
    final service = MockDeviceIntegrityService();
    when(service.evaluate()).thenAnswer((_) async => IntegrityDecision.allow);
    return IntegrityGateViewModel(service);
  }

  setUp(() async {
    await resetLocator();
    router = AppRouter.create();
    await setupLocator(router: router);
  });

  tearDown(resetLocator);

  Future<void> pumpApp(WidgetTester tester, {String language = 'es'}) async {
    tester.platformDispatcher.localesTestValue = [Locale(language)];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      App(routerConfig: router, integrityViewModelBuilder: integrityViewModel),
    );
    await tester.pumpAndSettle();
  }

  group('App', () {
    testWidgets('shows the Spanish home screen by default', (tester) async {
      await pumpApp(tester);

      expect(find.text('Stark Showcase'), findsOneWidget);
      expect(find.text('Conocer más'), findsOneWidget);
    });

    testWidgets('shows English when the device language is English', (
      tester,
    ) async {
      await pumpApp(tester, language: 'en');

      expect(find.text('Learn more'), findsOneWidget);
    });

    testWidgets('falls back to Spanish for unsupported languages', (
      tester,
    ) async {
      await pumpApp(tester, language: 'fr');

      expect(find.text('Conocer más'), findsOneWidget);
    });

    testWidgets('navigates to about and back through the ViewModels', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('Conocer más'));
      await tester.pumpAndSettle();
      expect(find.text('Acerca de'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Conocer más'), findsOneWidget);
    });

    testWidgets('clamps the text scale factor', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester);

      final context = tester.element(find.byType(Scaffold));

      expect(MediaQuery.textScalerOf(context).scale(10), lessThanOrEqualTo(16));
    });
  });

  group('AppRouter', () {
    test('starts at the home route', () {
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    });

    testWidgets('applies the redirect guard', (tester) async {
      final guarded = AppRouter.create(
        redirect: (_, state) =>
            state.uri.path == AppRoutes.home ? AppRoutes.about : null,
      );
      await resetLocator();
      await setupLocator(router: guarded);

      tester.platformDispatcher.localesTestValue = [const Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        App(
          routerConfig: guarded,
          integrityViewModelBuilder: integrityViewModel,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acerca de'), findsOneWidget);
    });
  });
}
