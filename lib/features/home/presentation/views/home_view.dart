import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/widgets/app_button.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Landing screen of the app.
class HomeView extends StatelessWidget {
  /// Creates the view.
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => locator<HomeViewModel>(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, _) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: context.spacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viewModel.user case final user?)
                  Text(l10n.homeGreeting(user.name), style: context.text.title),
                Text(l10n.homeTitle, style: context.text.display),
                SizedBox(height: context.spacing.sm),
                Text(l10n.homeSubtitle, style: context.text.bodySmall),
                SizedBox(height: context.spacing.xl),
                AppButton(
                  label: l10n.homeGetStarted,
                  onPressed: viewModel.openAbout,
                ),
                SizedBox(height: context.spacing.sm),
                TextButton(
                  onPressed: viewModel.logout,
                  child: Text(l10n.homeLogout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
