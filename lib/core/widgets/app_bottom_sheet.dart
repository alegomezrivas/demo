import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One tappable row of an [AppBottomSheet]; tapping closes the sheet and
/// returns [value].
@immutable
class AppSheetOption<T> {
  /// Creates an option.
  const AppSheetOption({
    required this.label,
    required this.value,
    this.icon,
  });

  /// Text of the row.
  final String label;

  /// Result returned by the sheet when the row is tapped.
  final T value;

  /// Optional leading icon.
  final IconData? icon;
}

/// Opens an [AppBottomSheet] and completes with the tapped option's value, or
/// null when the sheet is dismissed.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppSheetOption<T>> options,
}) {
  final spacing = context.spacing;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(spacing.radiusLg),
      ),
    ),
    builder: (_) => AppBottomSheet<T>(title: title, options: options),
  );
}

/// Content of a modal bottom sheet: drag handle, close button, title and a
/// grouped list of options.
class AppBottomSheet<T> extends StatelessWidget {
  /// Creates the sheet content.
  const AppBottomSheet({
    required this.title,
    required this.options,
    super.key,
  });

  /// Heading of the sheet.
  final String title;

  /// Rows shown under the title.
  final List<AppSheetOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          spacing.md,
          spacing.sm,
          spacing.md,
          spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: spacing.sheetHandleWidth,
                  height: spacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(spacing.radiusFull),
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                tooltip: AppLocalizations.of(context).commonClose,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Semantics(
              header: true,
              child: Text(title, style: context.text.headline),
            ),
            SizedBox(height: spacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: spacing.borderRadiusMd,
                border: Border.all(
                  color: colors.border,
                  width: spacing.borderThin,
                ),
              ),
              child: ClipRRect(
                borderRadius: spacing.borderRadiusMd,
                child: Column(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const Divider(height: 0),
                      _OptionRow<T>(option: options[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({required this.option});

  final AppSheetOption<T> option;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: option.label,
      excludeSemantics: true,
      onTap: () => Navigator.of(context).pop(option.value),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(option.value),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: spacing.minTouchTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: spacing.iconMd),
                  SizedBox(width: spacing.md),
                ],
                Expanded(child: Text(option.label, style: context.text.body)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
