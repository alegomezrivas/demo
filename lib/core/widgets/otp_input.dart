import 'dart:async';

import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// One-time code input drawn as separate boxes.
///
/// A single invisible text field receives the typing, so the system keyboard,
/// one-time-code autofill (`AutofillHints.oneTimeCode`) and pasting all work;
/// the boxes only mirror its text. A long press pastes the digits found in
/// the clipboard.
class OtpInput extends StatefulWidget {
  /// Creates the input bound to [formControlName].
  const OtpInput({
    required this.formControlName,
    this.length = 6,
    this.autofocus = true,
    this.hasError = false,
    this.errorText,
    this.onCompleted,
    this.focusNode,
    super.key,
  });

  /// Name of the control in the surrounding `FormGroup`.
  final String formControlName;

  /// Number of digits.
  final int length;

  /// Focuses the input when it first appears.
  final bool autofocus;

  /// Draws the boxes in the error color.
  final bool hasError;

  /// Message shown under the boxes.
  final String? errorText;

  /// Called once all [length] digits are present.
  final ValueChanged<String>? onCompleted;

  /// Focus node to control or observe the focus from outside.
  final FocusNode? focusNode;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
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

  void _notifyIfComplete(String value) {
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  Future<void> _pasteFromClipboard(AbstractControl<String> control) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final code = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    control.value = code;
    _notifyIfComplete(code);
  }

  void _requestFocus() {
    _focusNode.requestFocus();
    // Focus alone does not bring the keyboard back after it was dismissed.
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return ReactiveValueListenableBuilder<String>(
      formControlName: widget.formControlName,
      builder: (context, control, _) {
        final text = control.value ?? '';
        final active = _focusNode.hasFocus
            ? (text.length < widget.length ? text.length : widget.length - 1)
            : -1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              textField: true,
              label: l10n.otpSemanticsLabel(text.length, widget.length),
              onTap: _requestFocus,
              child: SizedBox(
                height: spacing.otpBoxHeight,
                child: Stack(
                  children: [
                    ExcludeSemantics(child: _boxes(text, active)),
                    // The real input: invisible and not hit-testable, so the
                    // layer below owns every gesture (tap and long press).
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(opacity: 0, child: _hiddenField()),
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _requestFocus,
                        onLongPress: () => _pasteFromClipboard(control),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.errorText != null) ...[
              SizedBox(height: spacing.sm),
              Text(
                widget.errorText!,
                style: context.text.bodySmall.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _boxes(String text, int active) {
    final gap = SizedBox(width: context.spacing.sm);
    return Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) gap,
          Expanded(
            child: _CodeBox(
              digit: i < text.length ? text[i] : '',
              isActive: i == active,
              hasError: widget.hasError,
            ),
          ),
        ],
      ],
    );
  }

  Widget _hiddenField() {
    return ReactiveTextField<String>(
      formControlName: widget.formControlName,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      enableSuggestions: false,
      autocorrect: false,
      enableInteractiveSelection: false,
      showCursor: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.length),
      ],
      onChanged: (c) => _notifyIfComplete(c.value ?? ''),
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: '',
        isDense: true,
        filled: false,
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final borderColor = hasError
        ? colors.error
        : isActive
        ? colors.primary
        : colors.border;
    return AnimatedContainer(
      duration: context.motionDuration(context.motion.fast),
      curve: context.motion.curve,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: spacing.borderRadiusMd,
        border: Border.all(
          color: borderColor,
          width: isActive || hasError
              ? spacing.borderThick
              : spacing.borderThin,
        ),
      ),
      child: Text(digit, style: context.text.headline),
    );
  }
}
