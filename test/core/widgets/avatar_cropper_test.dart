import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/avatar_cropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  final source = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 400, height: 300)..clear(img.ColorRgb8(200, 60, 60)),
    ),
  );

  Future<void> pumpCropper(
    WidgetTester tester,
    CropController controller, {
    ValueChanged<Uint8List>? onCropped,
    ValueChanged<Object>? onFailed,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: AvatarCropper(
                image: source,
                controller: controller,
                onCropped: onCropped ?? (_) {},
                onFailed: onFailed ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AvatarCropper', () {
    testWidgets('is a fixed circular, square-ratio, interactive cropper', (
      tester,
    ) async {
      await pumpCropper(tester, CropController());

      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.aspectRatio, 1);
      expect(crop.withCircleUi, isTrue);
      expect(crop.interactive, isTrue);
      expect(crop.fixCropRect, isTrue);
      expect(crop.image, source);
    });

    testWidgets('shows a progress indicator while the image loads', (
      tester,
    ) async {
      await pumpCropper(tester, CropController());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('returns a square picture when asked to crop', (tester) async {
      final controller = CropController();
      final done = Completer<Uint8List>();
      await pumpCropper(
        tester,
        controller,
        onCropped: done.complete,
        onFailed: done.completeError,
      );

      // Decoding runs on real isolates, so alternate real waits and frames.
      for (var i = 0; i < 30 && !done.isCompleted; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if (i == 5) controller.crop();
      }
      final bytes = await tester.runAsync(
        () => done.future.timeout(const Duration(seconds: 10)),
      );

      final cropped = img.decodeImage(bytes!);
      expect(cropped, isNotNull);
      expect(cropped!.width, cropped.height);
    });
  });
}
