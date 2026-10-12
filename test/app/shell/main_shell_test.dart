import 'package:demo/app/shell/main_shell.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import '../../features/auth/helpers/auth_mocks.dart';

void main() {
  late MockScreenProtection protection;
  late GoRouter router;

  GoRouter buildRouter({required bool protectScreens}) {
    Widget page(String name) => Center(child: Text(name));
    return GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(
            navigationShell: shell,
            screenProtection: protection,
            protectScreens: protectScreens,
          ),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/', builder: (_, _) => page('one'))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/two', builder: (_, _) => page('two'))],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/three', builder: (_, _) => page('three')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    bool protectScreens = true,
  }) async {
    router = buildRouter(protectScreens: protectScreens);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => protection = MockScreenProtection());

  group('MainShell navigation', () {
    testWidgets('shows the three localized destinations', (tester) async {
      await pumpShell(tester);

      for (final label in ['Inicio', 'Tareas', 'Ajustes']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('one'), findsOneWidget);
    });

    testWidgets('switches branches with the bar', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Tareas'));
      await tester.pumpAndSettle();
      expect(find.text('two'), findsOneWidget);

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('three'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('tapping the active tab again keeps it selected', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(find.text('one'), findsOneWidget);
    });
  });

  group('MainShell screen protection', () {
    testWidgets(
      'turns the protection on while it is shown and off afterwards',
      (tester) async {
        await pumpShell(tester);
        verify(protection.enable()).called(1);
        verifyNever(protection.disable());

        await tester.pumpWidget(const SizedBox());

        verify(protection.disable()).called(1);
      },
    );

    testWidgets('does nothing when protection is switched off by config', (
      tester,
    ) async {
      await pumpShell(tester, protectScreens: false);
      await tester.pumpWidget(const SizedBox());

      verifyZeroInteractions(protection);
    });

    testWidgets('survives a plugin failure', (tester) async {
      when(protection.enable()).thenThrow(Exception('plugin missing'));
      when(protection.disable()).thenThrow(Exception('plugin missing'));

      await pumpShell(tester);
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });
}
