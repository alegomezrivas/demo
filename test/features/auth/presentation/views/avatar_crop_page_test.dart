import 'dart:async';
import 'dart:typed_data';

import 'package:demo/core/widgets/avatar_cropper.dart';
import 'package:demo/features/auth/presentation/views/avatar_crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../../../helpers/pump_app.dart';
import 'sign_up_harness.dart';

void main() {
  final source = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 400, height: 300)..clear(img.ColorRgb8(200, 60, 60)),
    ),
  );

  /// Opens the page from a button and returns what it pops with.
  Future<Completer<Uint8List?>> openPage(WidgetTester tester) async {
    usePhone(tester);
    final result = Completer<Uint8List?>();
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                result.complete(await AvatarCropPage.open(context, source)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The cropper shows an endless progress indicator while it decodes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return result;
  }

  group('AvatarCropPage', () {
    testWidgets('shows the cropper, the title and a "Listo" button', (
      tester,
    ) async {
      await openPage(tester);

      expect(find.text('Recorta tu foto'), findsOneWidget);
      expect(find.byType(AvatarCropper), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
    });

    testWidgets('the arrow closes it without a result', (tester) async {
      final result = await openPage(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AvatarCropPage), findsNothing);
      expect(await result.future, isNull);
    });

    testWidgets('"Listo" returns a square picture', (tester) async {
      final result = await openPage(tester);

      // Decoding runs off the fake clock: alternate real waits and frames.
      for (var i = 0; i < 30 && !result.isCompleted; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if (i == 5) await tester.tap(find.text('Listo'));
      }
      final bytes = await tester.runAsync(
        () => result.future.timeout(const Duration(seconds: 10)),
      );

      final decoded = img.decodeImage(bytes!);
      expect(decoded, isNotNull);
      expect(decoded!.width, decoded.height);
    });
  });
}
