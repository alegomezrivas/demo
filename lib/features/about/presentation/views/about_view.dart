import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Screen describing the purpose of the app.
class AboutView extends StatelessWidget {
  /// Creates the view.
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<AboutViewModel>.nonReactive(
      viewModelBuilder: () => locator<AboutViewModel>(),
      builder: (context, viewModel, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.aboutTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.commonBack,
            onPressed: viewModel.goBack,
          ),
        ),
        body: Padding(
          padding: context.spacing.screenPadding,
          child: Text(l10n.aboutBody, style: context.text.body),
        ),
      ),
    );
  }
}
