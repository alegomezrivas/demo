import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/core/widgets/app_secondary_button.dart';
import 'package:demo/core/widgets/app_step_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/form_host.dart';
import '../../helpers/pump_app.dart';

void main() {
  const phone = Size(390, 800);

  AppStepScaffold step({
    VoidCallback? onBack,
    StepActionsPlacement placement = StepActionsPlacement.inline,
    Widget? link,
    Widget? accessory,
    Widget? child,
  }) {
    return AppStepScaffold(
      title: 'Tu correo',
      description: 'Dónde podemos escribirte',
      onBack: onBack,
      actionsPlacement: placement,
      bottomLink: link,
      keyboardAccessory: accessory,
      actions: [
        AppPrimaryButton(label: 'Siguiente', onPressed: () {}),
        AppSecondaryButton(label: 'Otra opción', onPressed: () {}),
      ],
      child: child ?? const SizedBox(key: Key('content'), height: 56),
    );
  }

  group('AppStepScaffold content', () {
    testWidgets('shows title, description, content and actions', (
      tester,
    ) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, step());

      expect(find.text('Tu correo'), findsOneWidget);
      expect(find.text('Dónde podemos escribirte'), findsOneWidget);
      expect(find.byKey(const Key('content')), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
      expect(find.text('Otra opción'), findsOneWidget);
    });

    testWidgets('the title is a header for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      useViewSize(tester, phone);
      await pumpLocalized(tester, step());

      expect(
        tester.getSemantics(find.text('Tu correo')),
        matchesSemantics(label: 'Tu correo', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('works without description, content or actions', (
      tester,
    ) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, const AppStepScaffold(title: 'Solo título'));

      expect(find.text('Solo título'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppStepScaffold back arrow', () {
    testWidgets('is hidden without onBack', (tester) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, step());

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('calls onBack, has a tooltip and a 48 dp target', (
      tester,
    ) async {
      useViewSize(tester, phone);
      var backs = 0;
      await pumpLocalized(tester, step(onBack: () => backs++));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));

      expect(backs, 1);
      expect(find.byTooltip('Volver'), findsOneWidget);
      expect(
        tester
            .getSize(find.widgetWithIcon(IconButton, Icons.arrow_back_ios_new))
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('AppStepScaffold action placement', () {
    testWidgets('inline actions sit right under the content', (tester) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, step());

      final contentBottom = tester.getBottomLeft(
        find.byKey(const Key('content')),
      );
      final buttonTop = tester.getTopLeft(find.byType(AppPrimaryButton));
      expect(buttonTop.dy - contentBottom.dy, lessThan(48));
    });

    testWidgets('pinned actions stick to the bottom of the screen', (
      tester,
    ) async {
      useViewSize(tester, phone);
      await pumpLocalized(
        tester,
        step(placement: StepActionsPlacement.pinned),
      );

      final screenBottom = tester.getSize(find.byType(Scaffold)).height;
      final lastButton = tester.getBottomLeft(find.byType(AppSecondaryButton));
      final contentBottom = tester.getBottomLeft(
        find.byKey(const Key('content')),
      );
      expect(screenBottom - lastButton.dy, lessThan(48));
      expect(lastButton.dy - contentBottom.dy, greaterThan(200));
    });
  });

  group('AppStepScaffold keyboard behaviour', () {
    testWidgets('shows the bottom link while the keyboard is closed', (
      tester,
    ) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, step(link: const Text('Ya tengo cuenta')));

      expect(find.text('Ya tengo cuenta'), findsOneWidget);
      final link = tester.getBottomLeft(find.text('Ya tengo cuenta'));
      expect(
        tester.getSize(find.byType(Scaffold)).height - link.dy,
        lessThan(48),
      );
    });

    testWidgets('hides the bottom link and shows the accessory when open', (
      tester,
    ) async {
      useViewSize(tester, phone);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await pumpLocalized(
        tester,
        step(
          link: const Text('Ya tengo cuenta'),
          accessory: const Text('Sugerencias'),
        ),
      );

      expect(find.text('Ya tengo cuenta'), findsNothing);
      expect(find.text('Sugerencias'), findsOneWidget);
    });

    testWidgets('hides the accessory while the keyboard is closed', (
      tester,
    ) async {
      useViewSize(tester, phone);
      await pumpLocalized(tester, step(accessory: const Text('Sugerencias')));

      expect(find.text('Sugerencias'), findsNothing);
    });
  });

  group('AppStepScaffold small screens', () {
    testWidgets('scrolls instead of overflowing with large text', (
      tester,
    ) async {
      useViewSize(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpLocalized(
        tester,
        step(
          onBack: () {},
          placement: StepActionsPlacement.pinned,
          link: const Text('Ya tengo cuenta'),
          child: const SizedBox(key: Key('content'), height: 300),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Otra opción'),
        100,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Otra opción'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow with the keyboard open on a small phone', (
      tester,
    ) async {
      useViewSize(tester, const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);

      await pumpLocalized(
        tester,
        step(onBack: () {}, accessory: const SizedBox(height: 56)),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps a readable column on wide screens', (tester) async {
      useViewSize(tester, const Size(1200, 800));
      await pumpLocalized(tester, step());

      final width = tester.getSize(find.byType(AppPrimaryButton)).width;
      expect(width, lessThanOrEqualTo(420));
    });
  });

  testWidgets('semantics tree stays valid', (tester) async {
    final handle = tester.ensureSemantics();
    useViewSize(tester, phone);
    await pumpLocalized(tester, step(onBack: () {}));

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('Siguiente'),
      findsOneWidget,
      reason: 'primary action is reachable by label',
    );
    handle.dispose();
  });
}
