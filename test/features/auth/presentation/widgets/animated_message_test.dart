import 'package:demo/core/theme/app_motion.dart';
import 'package:demo/features/auth/presentation/widgets/animated_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Widget message(String text) => Text(text, key: ValueKey(text));

  Future<void> pumpMessage(WidgetTester tester, Widget? child) {
    return pumpLocalized(tester, Align(child: AnimatedMessage(child: child)));
  }

  group('AnimatedMessage', () {
    testWidgets('shows nothing without a message', (tester) async {
      await pumpMessage(tester, null);

      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(AnimatedMessage)).height, 0);
    });

    testWidgets('grows into place when a message appears', (tester) async {
      await pumpMessage(tester, null);

      await pumpMessage(tester, message('hello'));
      await tester.pump(const Duration(milliseconds: 40));
      final midway = tester.getSize(find.byType(AnimatedMessage)).height;
      await tester.pumpAndSettle();
      final settled = tester.getSize(find.byType(AnimatedMessage)).height;

      expect(find.text('hello'), findsOneWidget);
      expect(midway, lessThan(settled));
    });

    testWidgets('cross-fades when the text changes', (tester) async {
      await pumpMessage(tester, message('first'));
      await tester.pumpAndSettle();

      await pumpMessage(tester, message('second'));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('settles within a few fast-token durations', (tester) async {
      await pumpMessage(tester, null);
      await pumpMessage(tester, message('hello'));

      const step = Duration(milliseconds: 16);
      final frames = await tester.pumpAndSettle(step);

      expect(step * frames, lessThanOrEqualTo(const AppMotion().fast * 3));
    });

    testWidgets('appears at once when the system reduces motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpMessage(tester, null);

      await pumpMessage(tester, message('hello'));
      final frames = await tester.pumpAndSettle(
        const Duration(milliseconds: 16),
      );

      expect(frames, lessThanOrEqualTo(2));
      expect(find.text('hello'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AnimatedMessage)).height,
        greaterThan(0),
      );
    });

    testWidgets('removes the old message at once when motion is reduced', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpMessage(tester, message('first'));
      await tester.pump();

      await pumpMessage(tester, message('second'));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('first'), findsNothing);
    });
  });
}
