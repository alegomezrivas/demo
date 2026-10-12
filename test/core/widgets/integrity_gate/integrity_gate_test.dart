import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.dart';

void main() {
  Future<void> pumpGate(WidgetTester tester, IntegrityDecision decision) async {
    final service = MockDeviceIntegrityService();
    when(service.evaluate()).thenAnswer((_) async => decision);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: IntegrityGate(
          viewModelBuilder: () => IntegrityGateViewModel(service),
          child: const Text('app content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('IntegrityGate', () {
    testWidgets('shows the app untouched on a healthy device', (tester) async {
      await pumpGate(tester, IntegrityDecision.allow);

      expect(find.text('app content'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsNothing);
    });

    testWidgets('shows a dismissible warning above the app', (tester) async {
      await pumpGate(tester, IntegrityDecision.warn);

      expect(find.text('app content'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsNothing);
      expect(find.text('app content'), findsOneWidget);
    });

    testWidgets('replaces the app with a blocking screen', (tester) async {
      await pumpGate(tester, IntegrityDecision.block);

      expect(find.text('app content'), findsNothing);
      expect(find.text('Unsupported device'), findsOneWidget);
    });

    testWidgets('hides the app while the check is running', (tester) async {
      final service = MockDeviceIntegrityService();
      when(service.evaluate()).thenAnswer(
        (_) => Future<IntegrityDecision>.delayed(
          const Duration(seconds: 1),
          () => IntegrityDecision.allow,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: IntegrityGate(
            viewModelBuilder: () => IntegrityGateViewModel(service),
            child: const Text('app content'),
          ),
        ),
      );

      expect(find.text('app content'), findsNothing);

      await tester.pump(const Duration(seconds: 2));

      expect(find.text('app content'), findsOneWidget);
    });
  });
}
