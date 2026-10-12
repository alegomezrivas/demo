import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockDeviceIntegrityChecker checker;

  setUp(() => checker = MockDeviceIntegrityChecker());

  Future<IntegrityDecision> run(
    SecurityPolicy policy,
    Set<IntegrityIssue> issues,
  ) {
    when(checker.check()).thenAnswer((_) async => issues);
    return DeviceIntegrityService(checker, policy).evaluate();
  }

  group('DeviceIntegrityService.evaluate', () {
    test('allows a healthy device under any policy', () async {
      for (final policy in SecurityPolicy.values) {
        expect(await run(policy, {}), IntegrityDecision.allow);
      }
    });

    test('warns on a compromised device with the warn policy', () async {
      expect(
        await run(SecurityPolicy.warn, {IntegrityIssue.rootedOrJailbroken}),
        IntegrityDecision.warn,
      );
    });

    test('blocks a compromised device with the block policy', () async {
      expect(
        await run(SecurityPolicy.block, {IntegrityIssue.debuggerAttached}),
        IntegrityDecision.block,
      );
    });
  });
}
