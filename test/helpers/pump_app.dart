import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a localized, themed [MaterialApp] (Spanish by default).
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('es'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
