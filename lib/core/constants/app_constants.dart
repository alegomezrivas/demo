import 'dart:ui';

/// Application-wide constants that are not part of the visual design tokens.
abstract final class AppConstants {
  /// Technical application name (user-facing names come from the ARB files).
  ///
  /// Change this and `appName` in `lib/l10n/app_*.arb` to rename the app.
  static const String appName = 'Stark Showcase';

  /// Upper bound for the system text scale so layouts stay usable.
  static const double maxTextScaleFactor = 1.6;

  /// Language used when the device language is not supported.
  static const Locale defaultLocale = Locale('es');
}
