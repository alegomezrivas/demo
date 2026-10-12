import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Applies the device integrity policy around the app content.
///
/// * allow: shows [child] untouched.
/// * warn: shows [child] below a dismissible warning banner.
/// * block: replaces [child] with a "device not supported" screen.
class IntegrityGate extends StatelessWidget {
  /// Creates the gate; [viewModelBuilder] supplies the (injected) ViewModel.
  const IntegrityGate({
    required this.viewModelBuilder,
    required this.child,
    super.key,
  });

  /// Creates the ViewModel (resolved from the locator by the caller).
  final IntegrityGateViewModel Function() viewModelBuilder;

  /// App content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<IntegrityGateViewModel>.reactive(
      viewModelBuilder: viewModelBuilder,
      onViewModelReady: (viewModel) => viewModel.initialise(),
      builder: (context, viewModel, _) {
        if (!viewModel.isChecked) {
          return ColoredBox(color: context.colors.background);
        }
        if (viewModel.isBlocked) return const _BlockedScreen();
        if (!viewModel.showWarning) return child;
        return Column(
          children: [
            Material(
              child: MaterialBanner(
                backgroundColor: context.colors.surface,
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: context.colors.warning,
                ),
                content: Text(
                  AppLocalizations.of(context).integrityWarning,
                  style: context.text.bodySmall,
                ),
                actions: [
                  TextButton(
                    onPressed: viewModel.dismissWarning,
                    child: Text(AppLocalizations.of(context).commonDismiss),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: context.colors.background,
      child: Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gpp_bad_outlined,
              size: context.spacing.xxl,
              color: context.colors.error,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              l10n.integrityBlockedTitle,
              style: context.text.headline,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              l10n.integrityBlockedMessage,
              style: context.text.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
