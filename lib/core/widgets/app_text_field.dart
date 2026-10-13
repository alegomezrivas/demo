import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Text input bound to a `reactive_forms` control that only uses theme tokens.
///
/// Besides the plain field it can show a clear button while typing, a check
/// mark when the control is valid, helper text and the disabled look of a
/// control that was disabled in the form.
class AppTextField extends StatefulWidget {
  /// Creates the field bound to [formControlName].
  const AppTextField({
    required this.formControlName,
    required this.label,
    this.validationMessages,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.helperText,
    this.showClearButton = false,
    this.showValidIndicator = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Name of the control in the surrounding `FormGroup`.
  final String formControlName;

  /// Floating label.
  final String label;

  /// Localized error messages keyed by validator error.
  final Map<String, ValidationMessageFunction>? validationMessages;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Action of the keyboard's enter key.
  final TextInputAction? textInputAction;

  /// Hides the typed text (passwords).
  final bool obscureText;

  /// Optional trailing widget; it takes precedence over the clear and valid
  /// indicators.
  final Widget? suffixIcon;

  /// Optional leading widget.
  final Widget? prefixIcon;

  /// Maximum visible lines (1 for single-line input).
  final int maxLines;

  /// Maximum number of characters; the counter is not shown.
  final int? maxLength;

  /// Capitalization applied while typing.
  final TextCapitalization textCapitalization;

  /// Autofill hints for password managers.
  final Iterable<String>? autofillHints;

  /// Focuses the field when it first appears.
  final bool autofocus;

  /// Focus node to control or observe the focus from outside.
  final FocusNode? focusNode;

  /// Restricts what can be typed or pasted.
  final List<TextInputFormatter>? inputFormatters;

  /// Short explanation shown under the field.
  final String? helperText;

  /// Shows a clear (X) button while the focused field has text.
  final bool showClearButton;

  /// Shows a check mark when the control holds a value and is valid.
  final bool showValidIndicator;

  /// Called with the new text on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard.
  final VoidCallback? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // The status stream also fires on every value change, so this rebuilds
    // for typing, validation results and enable/disable alike.
    return ReactiveStatusListenableBuilder(
      formControlName: widget.formControlName,
      builder: (context, control, _) {
        return ReactiveTextField<String>(
          formControlName: widget.formControlName,
          validationMessages: widget.validationMessages,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          style: context.text.body,
          onChanged: widget.onChanged == null
              ? null
              : (control) => widget.onChanged?.call(control.value ?? ''),
          onSubmitted: widget.onSubmitted == null
              ? null
              : (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helperText,
            helperMaxLines: 3,
            counterText: '',
            prefixIcon: widget.prefixIcon,
            suffixIcon: _suffix(context, control as FormControl<String>),
          ),
        );
      },
    );
  }

  Widget? _suffix(BuildContext context, FormControl<String> control) {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    final hasValue = (control.value ?? '').isNotEmpty;
    final l10n = AppLocalizations.of(context);

    if (widget.showValidIndicator &&
        hasValue &&
        control.valid &&
        !control.pending) {
      return Icon(
        Icons.check_circle_outline,
        color: context.colors.success,
        semanticLabel: l10n.fieldValidIndicator,
      );
    }
    if (widget.showClearButton &&
        hasValue &&
        control.enabled &&
        _focusNode.hasFocus) {
      return IconButton(
        tooltip: l10n.commonClear,
        icon: const Icon(Icons.close),
        onPressed: () {
          control.value = '';
          _focusNode.requestFocus();
        },
      );
    }
    return null;
  }
}
