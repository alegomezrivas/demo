import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/views/terms_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';
import 'sign_up_harness.dart';

void main() {
  group('TermsView', () {
    testWidgets('marks the text as a demo sample and lists the sections', (
      tester,
    ) async {
      usePhone(tester);
      await pumpLocalized(tester, const TermsView());
      await tester.pumpAndSettle();

      expect(find.text('Términos y políticas'), findsOneWidget);
      expect(
        find.text(
          'Texto de ejemplo para esta demostración. No es un documento legal.',
        ),
        findsOneWidget,
      );
      expect(find.text('Uso de la app'), findsOneWidget);
      expect(find.text('Privacidad'), findsOneWidget);
      expect(find.text('Tus datos'), findsOneWidget);
    });

    testWidgets('section titles are headers for screen readers', (
      tester,
    ) async {
      usePhone(tester);
      final handle = tester.ensureSemantics();
      await pumpLocalized(tester, const TermsView());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Privacidad')),
        matchesSemantics(isHeader: true, label: 'Privacidad'),
      );
      handle.dispose();
    });

    testWidgets('scrolls on a small phone with large text', (tester) async {
      usePhone(tester, size: const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpLocalized(tester, const TermsView());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Tus datos'), 200);
      expect(find.text('Tus datos'), findsOneWidget);
    });

    testWidgets('is available in English', (tester) async {
      usePhone(tester);
      await pumpLocalized(
        tester,
        const TermsView(),
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms and policies'), findsOneWidget);
      expect(find.text('Your data'), findsOneWidget);
    });

    testWidgets('the arrow pops the screen when it was pushed', (tester) async {
      usePhone(tester);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('before')),
          GoRoute(path: AppRoutes.terms, builder: (_, _) => const TermsView()),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: pumpLocalizedDelegates,
          supportedLocales: pumpLocalizedLocales,
          locale: const Locale('es'),
        ),
      );
      unawaited(router.push<void>(AppRoutes.terms));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('before'), findsOneWidget);
    });

    testWidgets('the arrow goes home when it was opened directly', (
      tester,
    ) async {
      usePhone(tester);
      final router = GoRouter(
        initialLocation: AppRoutes.terms,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(path: AppRoutes.terms, builder: (_, _) => const TermsView()),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: pumpLocalizedDelegates,
          supportedLocales: pumpLocalizedLocales,
          locale: const Locale('es'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
