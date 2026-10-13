import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Where the action buttons of an [AppStepScaffold] sit.
enum StepActionsPlacement {
  /// Right under the content (single-field steps, terms).
  inline,

  /// Fixed at the bottom of the screen (welcome, profile picture).
  pinned,
}

/// Layout of one step of a multi-step flow: back arrow, title, description,
/// content and actions.
///
/// The content scrolls when it does not fit (small screens, large text,
/// keyboard open). The bottom link is hidden while the keyboard is open and the
/// [keyboardAccessory] is only shown then.
class AppStepScaffold extends StatelessWidget {
  /// Creates a step.
  const AppStepScaffold({
    required this.title,
    this.description,
    this.child,
    this.actions = const [],
    this.actionsPlacement = StepActionsPlacement.inline,
    this.bottomLink,
    this.keyboardAccessory,
    this.onBack,
    super.key,
  });

  /// The one question this step asks.
  final String title;

  /// Short explanation under the title.
  final String? description;

  /// Main content (fields, text, picture).
  final Widget? child;

  /// Buttons of the step, top to bottom (primary first).
  final List<Widget> actions;

  /// Whether [actions] follow the content or stick to the bottom.
  final StepActionsPlacement actionsPlacement;

  /// Persistent link at the foot of the screen (for example "I already have an
  /// account").
  final Widget? bottomLink;

  /// Widget glued to the top of the keyboard (for example suggestions).
  final Widget? keyboardAccessory;

  /// Shows a back arrow when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final actionColumn = _Actions(actions: actions);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // `onBack!`: non-null, checked by the condition on this line.
                if (onBack != null) _BackButton(onPressed: onBack!),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.md,
                            vertical: spacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: context.text.headline,
                                ),
                              ),
                              if (description != null) ...[
                                SizedBox(height: spacing.sm),
                                Text(
                                  // non-null: guarded by the `if` above
                                  description!,
                                  style: context.text.bodySmall,
                                ),
                              ],
                              if (child != null) ...[
                                SizedBox(height: spacing.lg),
                                // non-null: guarded by the `if` above
                                child!,
                              ],
                              if (actionsPlacement ==
                                  StepActionsPlacement.inline) ...[
                                SizedBox(height: spacing.md),
                                actionColumn,
                              ],
                              const Spacer(),
                              if (actionsPlacement ==
                                  StepActionsPlacement.pinned) ...[
                                SizedBox(height: spacing.md),
                                actionColumn,
                              ],
                              if (bottomLink != null && !isKeyboardOpen) ...[
                                SizedBox(height: spacing.sm),
                                Center(child: bottomLink),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (keyboardAccessory != null && isKeyboardOpen)
                  // non-null: guarded by the condition above
                  keyboardAccessory!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) gap,
          actions[i],
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.xs),
        child: IconButton(
          tooltip: AppLocalizations.of(context).commonBack,
          icon: const Icon(Icons.arrow_back_ios_new),
          iconSize: spacing.iconMd,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
