import 'package:demo/core/widgets/empty_view.dart';
import 'package:demo/core/widgets/error_view.dart';
import 'package:demo/core/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StatCard', () {
    testWidgets('shows value, label and icon', (tester) async {
      await pumpLocalized(
        tester,
        const Scaffold(
          body: StatCard(label: 'Done', value: '7', icon: Icons.check),
        ),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('works without an icon', (tester) async {
      await pumpLocalized(
        tester,
        const Scaffold(
          body: StatCard(label: 'L', value: '1'),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });

  group('ErrorView', () {
    testWidgets('shows the message and calls retry', (tester) async {
      var retried = 0;
      await pumpLocalized(
        tester,
        Scaffold(
          body: ErrorView(
            message: 'Boom',
            retryLabel: 'Retry',
            onRetry: () => retried++,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));

      expect(find.text('Boom'), findsOneWidget);
      expect(retried, 1);
    });
  });

  group('EmptyView', () {
    testWidgets('shows the message and the chosen icon', (tester) async {
      await pumpLocalized(
        tester,
        const Scaffold(
          body: EmptyView(message: 'Nothing', icon: Icons.search_off),
        ),
      );

      expect(find.text('Nothing'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });
}
