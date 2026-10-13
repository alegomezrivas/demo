import 'dart:typed_data';

import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/image_processor.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:demo/features/auth/presentation/viewmodels/avatar_step_view_model.dart';
import 'package:demo/features/auth/presentation/views/sign_up_avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import 'sign_up_harness.dart';

void main() {
  late SignUpHarness harness;
  late MockImageSourceService source;
  late MockImageProcessor processor;

  final png = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 40, height: 40)..clear(img.ColorRgb8(10, 120, 200)),
    ),
  );
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xFF, 0xD9]);

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
    source = MockImageSourceService();
    processor = MockImageProcessor();
    locator
      ..registerSingleton<ImageSourceService>(source)
      ..registerSingleton<ImageProcessor>(processor)
      ..registerFactory<AvatarStepViewModel>(
        () => AvatarStepViewModel(
          source: source,
          processor: processor,
          flow: harness.flow,
        ),
      );
    when(source.pick(any)).thenAnswer((_) async => png);
    when(processor.toAvatarJpeg(any)).thenAnswer((_) async => jpeg);
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await harness.pump(
      tester,
      const SignUpAvatarView(),
      locale: locale,
      dark: dark,
    );
  }

  Future<void> choose(WidgetTester tester, String option) async {
    await tester.tap(find.text('Agregar una foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  group('SignUpAvatarView', () {
    testWidgets('starts empty, optional and without a back arrow', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Agrega una foto de perfil'), findsOneWidget);
      expect(find.text('Agregar una foto'), findsOneWidget);
      expect(find.text('Omitir'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('the sheet offers the gallery and the camera', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Agregar una foto'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar foto de perfil'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);
      expect(find.text('Tomar una foto'), findsOneWidget);
    });

    testWidgets('tapping the avatar opens the same sheet', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('Elegir de la galería'), findsOneWidget);
    });

    testWidgets('dismissing the sheet picks nothing', (tester) async {
      await pumpView(tester);
      await tester.tap(find.text('Agregar una foto'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      verifyZeroInteractions(source);
      expect(find.text('Agregar una foto'), findsOneWidget);
    });

    testWidgets(
      'a gallery pick shows the preview with "Editar" and "Siguiente"',
      (
        tester,
      ) async {
        await pumpView(tester);

        await choose(tester, 'Elegir de la galería');

        verify(source.pick(PhotoSource.gallery)).called(1);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Editar'), findsOneWidget);
        expect(find.text('Siguiente'), findsOneWidget);
        expect(find.text('Agregar una foto'), findsNothing);
      },
    );

    testWidgets('the camera option uses the camera', (tester) async {
      await pumpView(tester);

      await choose(tester, 'Tomar una foto');

      verify(source.pick(PhotoSource.camera)).called(1);
    });

    testWidgets('"Siguiente" compresses, uploads and moves on', (tester) async {
      await pumpView(tester);
      await choose(tester, 'Elegir de la galería');

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verify(processor.toAvatarJpeg(png)).called(1);
      verify(harness.uploadAvatar(jpeg)).called(1);
      verify(harness.navigation.go(AppRoutes.signUpDone)).called(1);
    });

    testWidgets('"Omitir" continues without a picture', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      verifyZeroInteractions(harness.uploadAvatar);
      verify(harness.navigation.go(AppRoutes.signUpDone)).called(1);
    });

    testWidgets('a denied library permission shows a clear message', (
      tester,
    ) async {
      when(source.pick(any)).thenThrow(
        const PermissionDeniedException('photo_permission_denied'),
      );
      await pumpView(tester);

      await choose(tester, 'Elegir de la galería');

      expect(
        find.text(
          'Necesitamos permiso para acceder a tus fotos. Puedes activarlo en los ajustes del sistema.',
        ),
        findsOneWidget,
      );
      expect(find.text('Agregar una foto'), findsOneWidget);
    });

    testWidgets('a denied camera permission shows a clear message', (
      tester,
    ) async {
      when(source.pick(any)).thenThrow(
        const PermissionDeniedException('camera_permission_denied'),
      );
      await pumpView(tester);

      await choose(tester, 'Tomar una foto');

      expect(
        find.text(
          'Necesitamos permiso para usar la cámara. Puedes activarlo en los ajustes del sistema.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the person can skip after a denial', (tester) async {
      when(source.pick(any)).thenThrow(
        const PermissionDeniedException('photo_permission_denied'),
      );
      await pumpView(tester);
      await choose(tester, 'Elegir de la galería');

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      verify(harness.navigation.go(AppRoutes.signUpDone)).called(1);
    });

    testWidgets('an unusable file shows the generic picture message', (
      tester,
    ) async {
      when(source.pick(any)).thenThrow(const InvalidImageException());
      await pumpView(tester);

      await choose(tester, 'Elegir de la galería');

      expect(
        find.text('No pudimos usar esa imagen. Prueba con otra.'),
        findsOneWidget,
      );
    });

    testWidgets('a picture that is too large is reported', (tester) async {
      when(
        processor.toAvatarJpeg(any),
      ).thenThrow(const InvalidImageException('too_large'));
      await pumpView(tester);
      await choose(tester, 'Elegir de la galería');

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('La imagen es demasiado grande'), findsOneWidget);
      verifyNever(harness.navigation.go(any));
    });

    testWidgets('a server rejection is shown on the step', (tester) async {
      when(harness.uploadAvatar(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_image')),
      );
      await pumpView(tester);
      await choose(tester, 'Elegir de la galería');

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_error')), findsOneWidget);
      expect(
        find.text('No pudimos usar esa imagen. Prueba con otra.'),
        findsOneWidget,
      );
    });

    testWidgets('the avatar is labelled for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester);
      expect(find.bySemanticsLabel('Sin foto de perfil'), findsOneWidget);

      await choose(tester, 'Elegir de la galería');

      expect(find.bySemanticsLabel('Foto de perfil'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text('Add a profile picture'), findsOneWidget);
      expect(find.text('Add a picture'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });
  });
}
