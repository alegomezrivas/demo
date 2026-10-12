import 'package:demo/core/services/go_router_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  late GoRouterNavigationService service;
  Object? lastExtra;

  Widget page(String name) => Scaffold(body: Text(name));

  setUp(() {
    lastExtra = null;
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => page('home')),
        GoRoute(path: '/a', builder: (_, _) => page('a')),
        GoRoute(
          path: '/b',
          builder: (_, state) {
            lastExtra = state.extra;
            return page('b');
          },
        ),
      ],
    );
    service = GoRouterNavigationService(router);
  });

  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp.router(routerConfig: router));

  group('GoRouterNavigationService', () {
    testWidgets('go replaces the stack and forwards extra', (tester) async {
      await pumpApp(tester);

      service.go('/b', extra: 'payload');
      await tester.pumpAndSettle();

      expect(find.text('b'), findsOneWidget);
      expect(lastExtra, 'payload');
      expect(service.canPop, isFalse);
    });

    testWidgets('push stacks a route and pop returns its result', (
      tester,
    ) async {
      await pumpApp(tester);

      final result = service.push<String>('/a');
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      expect(service.canPop, isTrue);

      service.pop<String>('done');
      await tester.pumpAndSettle();

      expect(await result, 'done');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('replace swaps the current route', (tester) async {
      await pumpApp(tester);

      service.replace('/a');
      await tester.pumpAndSettle();

      expect(find.text('a'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });
  });
}
