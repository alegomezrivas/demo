import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// "Remember me" checkbox bound to a boolean control of the surrounding form.
///
/// The whole row is the tap target and it explains what unchecking does.
class RememberSessionTile extends StatelessWidget {
  /// Creates the tile for the control named [formControlName].
  const RememberSessionTile({required this.formControlName, super.key});

  /// Name of the `FormControl<bool>` in the surrounding `ReactiveForm`.
  final String formControlName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ReactiveValueListenableBuilder<bool>(
      formControlName: formControlName,
      builder: (context, control, _) {
        final checked = control.value ?? true;
        void toggle() => control.value = !checked;
        return Semantics(
          container: true,
          checked: checked,
          label: l10n.authRememberSession,
          hint: l10n.authRememberSessionHint,
          onTap: toggle,
          excludeSemantics: true,
          child: InkWell(
            onTap: toggle,
            borderRadius: context.spacing.borderRadiusSm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: checked, onChanged: (_) => toggle()),
                SizedBox(width: context.spacing.xs),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.authRememberSession,
                          style: context.text.body,
                        ),
                        Text(
                          l10n.authRememberSessionHint,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
