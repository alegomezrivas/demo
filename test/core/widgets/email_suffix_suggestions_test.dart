import 'package:demo/core/widgets/email_suffix_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EmailSuffixSuggestions.completionsFor', () {
    const domains = ['gmail.com', 'outlook.com', 'yahoo.com'];

    List<String> complete(String input) =>
        EmailSuffixSuggestions.completionsFor(input, domains: domains);

    test('offers every domain after the local part', () {
      expect(complete('ana'), [
        'ana@gmail.com',
        'ana@outlook.com',
        'ana@yahoo.com',
      ]);
    });

    test('offers every domain right after the @', () {
      expect(complete('ana@'), [
        'ana@gmail.com',
        'ana@outlook.com',
        'ana@yahoo.com',
      ]);
    });

    test('narrows by the typed domain prefix, ignoring case', () {
      expect(complete('ana@G'), ['ana@gmail.com']);
      expect(complete('ana@ou'), ['ana@outlook.com']);
    });

    test('offers nothing once the domain is complete', () {
      expect(complete('ana@gmail.com'), isEmpty);
    });

    test('offers nothing when no domain starts with the typed text', () {
      expect(complete('ana@empresa'), isEmpty);
    });

    test('offers nothing for empty or blank input', () {
      expect(complete(''), isEmpty);
      expect(complete('   '), isEmpty);
    });

    test('offers nothing without a local part', () {
      expect(complete('@gmail'), isEmpty);
    });

    test('offers nothing for a second @ or for spaces', () {
      expect(complete('a@b@'), isEmpty);
      expect(complete('ana perez'), isEmpty);
    });

    test('trims surrounding spaces', () {
      expect(complete('  ana '), hasLength(3));
    });
  });

  group('EmailSuffixSuggestions widget', () {
    Future<void> pumpRow(
      WidgetTester tester,
      String input,
      ValueChanged<String> onSelected,
    ) {
      return pumpLocalized(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: EmailSuffixSuggestions(
              input: input,
              onSelected: onSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('shows the suffixes as chips', (tester) async {
      await pumpRow(tester, 'ana', (_) {});

      expect(find.text('@gmail.com'), findsOneWidget);
      expect(find.text('@outlook.com'), findsOneWidget);
    });

    testWidgets('returns the complete address when a chip is tapped', (
      tester,
    ) async {
      final selected = <String>[];
      await pumpRow(tester, 'ana', selected.add);

      await tester.tap(find.text('@gmail.com'));

      expect(selected, ['ana@gmail.com']);
    });

    testWidgets('renders nothing when there is nothing to suggest', (
      tester,
    ) async {
      await pumpRow(tester, 'ana@gmail.com', (_) {});

      expect(find.byType(ActionChip), findsNothing);
      expect(tester.getSize(find.byType(EmailSuffixSuggestions)).height, 0);
    });

    testWidgets('updates when the input changes', (tester) async {
      await pumpRow(tester, 'ana', (_) {});
      await pumpRow(tester, 'ana@o', (_) {});
      await tester.pump();

      expect(find.text('@outlook.com'), findsOneWidget);
      expect(find.text('@gmail.com'), findsNothing);
    });

    testWidgets('chips are reachable by their full address', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRow(tester, 'ana', (_) {});

      expect(find.bySemanticsLabel('ana@gmail.com'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('keeps chips at least 48 dp tall and scrolls sideways', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(240, 600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpRow(tester, 'ana', (_) {});

      expect(
        tester.getSize(find.byType(ActionChip).first).height,
        greaterThanOrEqualTo(48),
      );
      await tester.drag(find.byType(ListView), const Offset(-200, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
