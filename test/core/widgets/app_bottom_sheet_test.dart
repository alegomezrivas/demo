import 'package:demo/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/form_host.dart';
import '../../helpers/pump_app.dart';

enum _Pick { gallery, camera }

void main() {
  _Pick? result;
  var resultReady = false;

  Future<void> pumpOpener(WidgetTester tester) async {
    result = null;
    resultReady = false;
    await pumpLocalized(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showAppBottomSheet<_Pick>(
                  context: context,
                  title: 'Añadir foto',
                  options: const [
                    AppSheetOption(
                      label: 'Elegir de la galería',
                      value: _Pick.gallery,
                      icon: Icons.photo_library_outlined,
                    ),
                    AppSheetOption(
                      label: 'Tomar foto',
                      value: _Pick.camera,
                      icon: Icons.photo_camera_outlined,
                    ),
                  ],
                );
                resultReady = true;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  group('AppBottomSheet', () {
    testWidgets('shows the title and every option', (tester) async {
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      expect(find.text('Añadir foto'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('returns the value of the tapped option and closes', (
      tester,
    ) async {
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(resultReady, isTrue);
      expect(result, _Pick.camera);
      expect(find.text('Añadir foto'), findsNothing);
    });

    testWidgets('the close button dismisses it with no result', (tester) async {
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(resultReady, isTrue);
      expect(result, isNull);
      expect(find.text('Añadir foto'), findsNothing);
    });

    testWidgets('dragging it down dismisses it with no result', (tester) async {
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      await tester.drag(find.text('Añadir foto'), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(resultReady, isTrue);
      expect(result, isNull);
    });

    testWidgets('options are at least 48 dp tall', (tester) async {
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      for (final label in ['Elegir de la galería', 'Tomar foto']) {
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .getSize(find.widgetWithIcon(IconButton, Icons.close))
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('options are announced as buttons and the title as header', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useViewSize(tester, const Size(390, 800));
      await pumpOpener(tester);

      expect(
        tester.getSemantics(find.text('Tomar foto')),
        matchesSemantics(
          label: 'Tomar foto',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Añadir foto')),
        matchesSemantics(label: 'Añadir foto', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('fits a small phone with large text', (tester) async {
      useViewSize(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpOpener(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Tomar foto'), findsOneWidget);
    });
  });
}
