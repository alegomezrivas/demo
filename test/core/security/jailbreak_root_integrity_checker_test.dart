import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:demo/core/security/jailbreak_root_integrity_checker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockJailbreakRootDetection detector;
  late JailbreakRootIntegrityChecker checker;

  setUp(() {
    detector = MockJailbreakRootDetection();
    checker = JailbreakRootIntegrityChecker(detector);
  });

  void stub({bool jailbroken = false, bool debugged = false}) {
    when(detector.isJailBroken).thenAnswer((_) async => jailbroken);
    when(detector.isDebugged).thenAnswer((_) async => debugged);
  }

  group('JailbreakRootIntegrityChecker', () {
    test('reports no issues on a healthy device', () async {
      stub();

      expect(await checker.check(), isEmpty);
    });

    test('reports a rooted / jailbroken device', () async {
      stub(jailbroken: true);

      expect(await checker.check(), {IntegrityIssue.rootedOrJailbroken});
    });

    test('reports an attached debugger', () async {
      stub(debugged: true);

      expect(await checker.check(), {IntegrityIssue.debuggerAttached});
    });

    test('reports both issues together', () async {
      stub(jailbroken: true, debugged: true);

      expect(await checker.check(), {
        IntegrityIssue.rootedOrJailbroken,
        IntegrityIssue.debuggerAttached,
      });
    });

    test('reports a failed detection instead of hiding it', () async {
      when(detector.isJailBroken).thenThrow(PlatformException(code: 'x'));

      expect(await checker.check(), {IntegrityIssue.checkFailed});
    });
  });
}
