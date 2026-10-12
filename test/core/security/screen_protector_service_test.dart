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
        final service = ScreenProtectorService();
        await service.enable();

        expect(calls, [
          'preventScreenshotOn',
          'protectDataLeakageOn',
          'protectDataLeakageWithBlur',
        ]);
      },
    );

    test('disable turns every protection off', () async {
      final service = ScreenProtectorService();
      await service.enable();
      calls.clear();

      await service.disable();

      expect(calls, [
        'preventScreenshotOff',
        'protectDataLeakageOff',
        'protectDataLeakageWithBlurOff',
      ]);
    });

    test('keeps the protection while another screen still needs it', () async {
      final service = ScreenProtectorService();
      await service.enable();
      await service.enable();
      calls.clear();

      await service.disable();
      expect(calls, isEmpty);

      await service.disable();
      expect(calls, contains('preventScreenshotOff'));
    });

    test('enabling twice calls the plugin only once', () async {
      final service = ScreenProtectorService();

      await service.enable();
      await service.enable();

      expect(calls.where((c) => c == 'preventScreenshotOn'), hasLength(1));
    });

    test('an unbalanced disable does nothing', () async {
      await ScreenProtectorService().disable();

      expect(calls, isEmpty);
    });
  });
}
