import 'package:demo/core/security/screen_protector_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('screen_protector');
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ScreenProtectorService', () {
    test(
      'enable blocks screenshots and hides the app-switcher preview',
      () async {
        await const ScreenProtectorService().enable();

        expect(calls, [
          'preventScreenshotOn',
          'protectDataLeakageOn',
          'protectDataLeakageWithBlur',
        ]);
      },
    );

    test('disable turns every protection off', () async {
      await const ScreenProtectorService().disable();

      expect(calls, [
        'preventScreenshotOff',
        'protectDataLeakageOff',
        'protectDataLeakageWithBlurOff',
      ]);
    });
  });
}
