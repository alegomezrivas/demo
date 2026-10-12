import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/l10n/app_localizations.dart';

/// Localized labels of [AppThemeMode].
extension AppThemeModeLabel on AppThemeMode {
  /// Text shown in selectors.
  String label(AppLocalizations l10n) => switch (this) {
    AppThemeMode.system => l10n.themeSystem,
    AppThemeMode.light => l10n.themeLight,
    AppThemeMode.dark => l10n.themeDark,
  };
}

/// Localized labels of [AppLanguage].
extension AppLanguageLabel on AppLanguage {
  /// Text shown in selectors.
  String label(AppLocalizations l10n) => switch (this) {
    AppLanguage.system => l10n.languageSystem,
    AppLanguage.spanish => l10n.languageSpanish,
    AppLanguage.english => l10n.languageEnglish,
  };
}
