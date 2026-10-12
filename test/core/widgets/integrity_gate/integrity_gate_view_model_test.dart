import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDeviceIntegrityService service;
  late IntegrityGateViewModel viewModel;
  late int notifications;

  setUp(() {
    service = MockDeviceIntegrityService();
    viewModel = IntegrityGateViewModel(service);
    notifications = 0;
    viewModel.addListener(() => notifications++);
  });

  Future<void> initWith(IntegrityDecision decision) {
    when(service.evaluate()).thenAnswer((_) async => decision);
    return viewModel.initialise();
  }

  group('IntegrityGateViewModel', () {
    test('is unchecked, unblocked and silent before initialising', () {
      expect(viewModel.isChecked, isFalse);
      expect(viewModel.isBlocked, isFalse);
      expect(viewModel.showWarning, isFalse);
    });

    test('allow: nothing to show', () async {
      await initWith(IntegrityDecision.allow);

      expect(viewModel.isChecked, isTrue);
      expect(viewModel.isBlocked, isFalse);
      expect(viewModel.showWarning, isFalse);
      expect(notifications, 1);
    });

    test('warn: shows the warning until it is dismissed', () async {
      await initWith(IntegrityDecision.warn);
      expect(viewModel.showWarning, isTrue);
      expect(viewModel.isBlocked, isFalse);

      viewModel.dismissWarning();

      expect(viewModel.showWarning, isFalse);
      expect(notifications, 2);
    });

    test('block: blocks the app and never shows the warning', () async {
      await initWith(IntegrityDecision.block);

      expect(viewModel.isBlocked, isTrue);
      expect(viewModel.showWarning, isFalse);
    });
  });
}
