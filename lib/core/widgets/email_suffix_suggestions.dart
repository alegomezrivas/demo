import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Row of one-tap domain completions shown above the keyboard while an e-mail
/// address is typed (for example `ana` -> `@gmail.com`).
class EmailSuffixSuggestions extends StatelessWidget {
  /// Creates the row for the text typed so far in [input].
  const EmailSuffixSuggestions({
    required this.input,
    required this.onSelected,
    this.domains = defaultDomains,
    super.key,
  });

  /// Common providers offered by default.
  static const List<String> defaultDomains = [
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'icloud.com',
  ];

  /// Text typed so far.
  final String input;

  /// Called with the complete address when a suggestion is tapped.
  final ValueChanged<String> onSelected;

  /// Domains to suggest, in display order.
  final List<String> domains;

  /// Complete addresses that finish [input]; empty when nothing fits.
  ///
  /// Nothing is offered for empty input, a missing local part, a second `@`,
  /// spaces, or a domain that is already complete.
  static List<String> completionsFor(
    String input, {
    List<String> domains = defaultDomains,
  }) {
    final text = input.trim();
    final at = text.indexOf('@');
    final hasSecondAt = at != -1 && text.indexOf('@', at + 1) != -1;
    if (text.isEmpty || at == 0 || hasSecondAt || text.contains(' ')) {
      return const [];
    }
    final local = at == -1 ? text : text.substring(0, at);
    final typedDomain = at == -1 ? '' : text.substring(at + 1).toLowerCase();
    return [
      for (final domain in domains)
        if (domain.startsWith(typedDomain) && domain != typedDomain)
          '$local@$domain',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final completions = completionsFor(input, domains: domains);
    if (completions.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final spacing = context.spacing;
    return SizedBox(
      height: spacing.minTouchTarget + spacing.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.xs,
        ),
        itemCount: completions.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, index) {
          final address = completions[index];
          return Semantics(
            label: address,
            button: true,
            excludeSemantics: true,
            onTap: () => onSelected(address),
            child: ActionChip(
              label: Text(address.substring(address.indexOf('@'))),
              labelStyle: context.text.bodySmall,
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.border),
              shape: const StadiumBorder(),
              onPressed: () => onSelected(address),
            ),
          );
        },
      ),
    );
  }
}
