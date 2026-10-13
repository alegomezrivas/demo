import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/presentation/widgets/remember_session_tile.dart';
import 'package:demo/features/auth/presentation/widgets/step_error_text.dart';
import 'package:demo/features/auth/presentation/widgets/welcome_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../helpers/form_host.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StepErrorText', () {
    testWidgets('shows nothing without a failure', (tester) async {
      await pumpLocalized(tester, const StepErrorText(failure: null));

      expect(find.byKey(const Key('step_error')), findsNothing);
    });

    testWidgets('shows the generic localized message of the failure', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const StepErrorText(failure: ServerFailure('db_exploded')),
      );

      expect(
        find.text(
          'El servicio no está disponible por ahora. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('db_exploded'), findsNothing);
    });

    testWidgets('is a live region so it is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLocalized(
        tester,
        const StepErrorText(failure: NetworkFailure()),
      );

      expect(
        tester.getSemantics(find.byKey(const Key('step_error'))),
        matchesSemantics(
          label: 'No hay conexión. Revisa tu red e inténtalo de nuevo.',
          isLiveRegion: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('uses the error color from the theme', (tester) async {
      await pumpLocalized(
        tester,
        const StepErrorText(failure: NetworkFailure()),
        dark: true,
      );

      final text = tester.widget<Text>(find.byKey(const Key('step_error')));
      expect(text.style?.color, isNotNull);
    });
  });

  group('RememberSessionTile', () {
    late FormGroup form;

    setUp(() => form = FormGroup({'remember': FormControl<bool>(value: true)}));
    tearDown(() => form.dispose());

    testWidgets('reflects and changes the control', (tester) async {
      await pumpForm(
        tester,
        form,
        const RememberSessionTile(formControlName: 'remember'),
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(form.control('remember').value, isFalse);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('the label toggles it too', (tester) async {
      await pumpForm(
        tester,
        form,
        const RememberSessionTile(formControlName: 'remember'),
      );

      await tester.tap(find.text('Recordar sesión'));
      await tester.pump();

      expect(form.control('remember').value, isFalse);
    });

    testWidgets('follows changes made from outside', (tester) async {
      await pumpForm(
        tester,
        form,
        const RememberSessionTile(formControlName: 'remember'),
      );

      form.control('remember').value = false;
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('exposes a checked state and its hint to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpForm(
        tester,
        form,
        const RememberSessionTile(formControlName: 'remember'),
      );

      expect(
        tester.getSemantics(find.text('Recordar sesión')),
        matchesSemantics(
          label: 'Recordar sesión',
          hint:
              'Si lo desactivas, tendrás que iniciar sesión cada vez que abras la app.',
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the tap target is at least 48 dp tall', (tester) async {
      await pumpForm(
        tester,
        form,
        const RememberSessionTile(formControlName: 'remember'),
      );

      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('WelcomeIllustration', () {
    testWidgets('is one labelled image with no readable children', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpLocalized(tester, const WelcomeIllustration());

      expect(
        find.bySemanticsLabel('Ilustración de tareas completadas'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('draws three cards, two of them checked', (tester) async {
      await pumpLocalized(tester, const WelcomeIllustration());

      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('renders in light and dark without overflowing', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        await pumpLocalized(tester, const WelcomeIllustration(), dark: dark);

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('fits a 320 dp wide screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpLocalized(tester, const Center(child: WelcomeIllustration()));

      expect(tester.takeException(), isNull);
    });
  });
}
