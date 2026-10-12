import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Text input bound to a `reactive_forms` control that only uses theme tokens.
class AppTextField extends StatelessWidget {
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
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
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

  /// Optional trailing widget.
  final Widget? suffixIcon;

  /// Optional leading widget.
  final Widget? prefixIcon;

  /// Maximum visible lines (1 for single-line input).
  final int maxLines;

  /// Capitalization applied while typing.
  final TextCapitalization textCapitalization;

  /// Autofill hints for password managers.
  final Iterable<String>? autofillHints;

  /// Called when the user submits from the keyboard.
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: formControlName,
      validationMessages: validationMessages,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      style: context.text.body,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
