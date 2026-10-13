import 'package:demo/app/locator.dart';
import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/core/utils/failure_message.dart';
import 'package:demo/core/widgets/app_primary_button.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/utils/settings_labels.dart';
import 'package:demo/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// Settings tab.
class SettingsView extends StatelessWidget {
  /// Creates the view.
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<SettingsViewModel>.reactive(
      viewModelBuilder: () => locator<SettingsViewModel>(),
      onViewModelReady: (viewModel) =>
          viewModel.init(toggleReason: l10n.biometricReasonToggle),
      builder: (context, viewModel, _) {
        final user = viewModel.user;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            padding: context.spacing.screenPadding,
            children: [
              if (user != null) ...[
                _SectionTitle(l10n.settingsProfile),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                  ),
                ),
                SizedBox(height: context.spacing.lg),
              ],
              ReactiveForm(
                formGroup: viewModel.form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(l10n.settingsAppearance),
                    ReactiveDropdownField<AppThemeMode>(
                      formControlName: SettingsViewModel.themeField,
                      decoration: InputDecoration(
                        labelText: l10n.settingsTheme,
                      ),
                      items: [
                        for (final mode in AppThemeMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(mode.label(l10n)),
                          ),
                      ],
                    ),
                    SizedBox(height: context.spacing.md),
                    ReactiveDropdownField<AppLanguage>(
                      formControlName: SettingsViewModel.languageField,
                      decoration: InputDecoration(
                        labelText: l10n.settingsLanguage,
                      ),
                      items: [
                        for (final language in AppLanguage.values)
                          DropdownMenuItem(
                            value: language,
                            child: Text(language.label(l10n)),
                          ),
                      ],
                    ),
                    SizedBox(height: context.spacing.lg),
                    _SectionTitle(l10n.settingsSecurity),
                    if (viewModel.offersBiometric)
                      Card(
                        child: ReactiveSwitchListTile(
                          formControlName: SettingsViewModel.biometricField,
                          title: Text(l10n.settingsBiometric),
                          subtitle: Text(l10n.settingsBiometricHint),
                        ),
                      )
                    else
                      Text(
                        l10n.settingsBiometricNeedsRememberedSession,
                        key: const Key('biometric_needs_remembered_session'),
                        style: context.text.bodySmall,
                      ),
                    if (viewModel.biometricUnavailable)
                      Padding(
                        padding: EdgeInsets.only(top: context.spacing.sm),
                        child: Text(
                          l10n.settingsBiometricUnavailable,
                          key: const Key('biometric_unavailable'),
                          style: context.text.bodySmall.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: context.spacing.lg),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsAbout),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: viewModel.openAbout,
                ),
              ),
              if (viewModel.failure case final failure?) ...[
                SizedBox(height: context.spacing.md),
                Text(
                  failure.message(l10n),
                  key: const Key('settings_error'),
                  style: context.text.bodySmall.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
              SizedBox(height: context.spacing.lg),
              AppPrimaryButton(
                label: l10n.settingsLogout,
                onPressed: () =>
                    viewModel.logout(reason: l10n.biometricReasonLogout),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Text(text, style: context.text.title),
    );
  }
}
