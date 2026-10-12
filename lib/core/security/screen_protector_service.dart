import 'package:demo/core/security/screen_protection.dart';
import 'package:screen_protector/screen_protector.dart';

/// [ScreenProtection] backed by the `screen_protector` plugin.
///
/// Android: blocks screenshots and blurs the recents preview (FLAG_SECURE).
/// iOS: blurs the app-switcher snapshot (screenshots cannot be blocked).
class ScreenProtectorService implements ScreenProtection {
  /// Creates the service.
  const ScreenProtectorService();

  @override
  Future<void> enable() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  @override
  Future<void> disable() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    await ScreenProtector.protectDataLeakageWithBlurOff();
  }
}
