import 'package:demo/core/security/screen_protection.dart';
import 'package:screen_protector/screen_protector.dart';

/// [ScreenProtection] backed by the `screen_protector` plugin.
///
/// Android: blocks screenshots and blurs the recents preview (FLAG_SECURE).
/// iOS: blurs the app-switcher snapshot (screenshots cannot be blocked).
///
/// Calls are reference-counted so stacked sensitive screens (for example
/// sign-in with sign-up on top) keep the protection until the last one closes.
/// Keep a single instance in the locator.
class ScreenProtectorService implements ScreenProtection {
  /// Creates the service.
  ScreenProtectorService();

  int _activeScreens = 0;

  @override
  Future<void> enable() async {
    _activeScreens++;
    if (_activeScreens > 1) return;
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  @override
  Future<void> disable() async {
    if (_activeScreens == 0) return;
    _activeScreens--;
    if (_activeScreens > 0) return;
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    await ScreenProtector.protectDataLeakageWithBlurOff();
  }
}
