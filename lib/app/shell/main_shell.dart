import 'dart:async';

import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold with the bottom navigation shared by the three main tabs.
///
/// While it is on screen (and therefore also under the full-screen routes
/// pushed above it) the content is hidden from screenshots and the
/// app-switcher preview, unless [protectScreens] is false.
class MainShell extends StatefulWidget {
  /// Creates the shell around the router's [navigationShell].
  const MainShell({
    required this.navigationShell,
    required this.screenProtection,
    required this.protectScreens,
    super.key,
  });

  /// Holds the state of every tab.
  final StatefulNavigationShell navigationShell;

  /// Hides the content from captures and previews.
  final ScreenProtection screenProtection;

  /// Whether the protection is switched on (`PROTECT_SCREENS`).
  final bool protectScreens;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    if (widget.protectScreens) unawaited(_run(widget.screenProtection.enable));
  }

  @override
  void dispose() {
    if (widget.protectScreens) unawaited(_run(widget.screenProtection.disable));
    super.dispose();
  }

  /// Protection is best effort: a plugin failure must not break navigation.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // Ignored on purpose.
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n.navTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
