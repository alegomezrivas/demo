import 'dart:typed_data';

import 'package:demo/core/theme/app_spacing.dart';
import 'package:demo/core/widgets/avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../helpers/pump_app.dart';

void main() {
  final png = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 8, height: 8)..clear(img.ColorRgb8(10, 90, 200)),
    ),
  );

  Future<void> pumpPicker(WidgetTester tester, AvatarPicker picker) {
    return pumpLocalized(tester, Scaffold(body: Center(child: picker)));
  }

  group('AvatarPicker placeholder', () {
    testWidgets('shows a person icon and no edit button', (tester) async {
      await pumpPicker(tester, AvatarPicker(onEdit: () {}));

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('uses the form avatar size by default', (tester) async {
      await pumpPicker(tester, const AvatarPicker());

      final size = tester.getSize(find.byType(Container).first);
      expect(size, Size.square(const AppSpacing().avatarMd));
    });

    testWidgets('honors a custom diameter', (tester) async {
      await pumpPicker(tester, const AvatarPicker(diameter: 64));

      expect(tester.getSize(find.byType(Container).first), const Size(64, 64));
    });

    testWidgets('reports taps on the picture', (tester) async {
      var taps = 0;
      await pumpPicker(tester, AvatarPicker(onTap: () => taps++));

      await tester.tap(find.byIcon(Icons.person));

      expect(taps, 1);
    });

    testWidgets('announces that there is no picture', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPicker(tester, AvatarPicker(onTap: () {}));

      expect(
        find.bySemanticsLabel('Sin foto de perfil'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('AvatarPicker with an image', () {
    testWidgets('shows the picture, clipped to a circle', (tester) async {
      await pumpPicker(tester, AvatarPicker(imageBytes: png, onEdit: () {}));

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
      final decoration =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('shows the edit button and reports taps', (tester) async {
      var edits = 0;
      await pumpPicker(
        tester,
        AvatarPicker(imageBytes: png, onEdit: () => edits++),
      );

      await tester.tap(find.text('Editar'));

      expect(edits, 1);
      expect(find.byIcon(Icons.crop), findsOneWidget);
    });

    testWidgets('hides the edit button when nothing can be edited', (
      tester,
    ) async {
      await pumpPicker(tester, AvatarPicker(imageBytes: png));

      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('announces the picture and is one accessibility node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPicker(
        tester,
        AvatarPicker(imageBytes: png, onTap: () {}, onEdit: () {}),
      );

      expect(find.bySemanticsLabel('Foto de perfil'), findsOneWidget);
      expect(
        tester.getSize(find.text('Editar')).height,
        greaterThan(0),
      );
      handle.dispose();
    });

    testWidgets('edit button meets the minimum tap target', (tester) async {
      await pumpPicker(tester, AvatarPicker(imageBytes: png, onEdit: () {}));

      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(const AppSpacing().minTouchTarget),
      );
    });

    testWidgets('falls back to the placeholder for undecodable bytes', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        AvatarPicker(imageBytes: Uint8List.fromList([1, 2, 3])),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      tester.takeException();
    });
  });
}
