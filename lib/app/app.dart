import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

/// Root widget: wires router, themes and localization.
class App extends StatelessWidget {
  /// Creates the app around an injected [routerConfig].
  const App({
    required this.routerConfig,
    required this.integrityViewModelBuilder,
    required this.preferences,
    super.key,
  });

  /// Router configuration used by [MaterialApp.router].
  final GoRouter routerConfig;

  /// Live user preferences (theme and language).
  final AppPreferences preferences;

  /// Creates the ViewModel of the device integrity gate.
  final IntegrityGateViewModel Function() integrityViewModelBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => _buildApp(),
    );
  }

  Widget _buildApp() {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      routerConfig: routerConfig,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences.themeMode,
      locale: preferences.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppConstants.maxTextScaleFactor,
        child: IntegrityGate(
          viewModelBuilder: integrityViewModelBuilder,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Uses the device language when supported, otherwise Spanish.
  static Locale _resolveLocale(Locale? device, Iterable<Locale> supported) {
    return supported.firstWhere(
      (locale) => locale.languageCode == device?.languageCode,
      orElse: () => AppConstants.defaultLocale,
    );
  }
}
