import 'package:demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Lets a message grow into place and cross-fade when it changes.
///
/// With reduced motion enabled the durations collapse to zero, so the message
/// simply appears.
class AnimatedMessage extends StatelessWidget {
  /// Creates the wrapper; a null [child] shows nothing.
  const AnimatedMessage({required this.child, super.key});

  /// The current message, or null for none. Give it a key that changes with
  /// the text so changes cross-fade.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final duration = context.motionDuration(context.motion.fast);
    // Reduced motion: no animation widgets at all (a zero-duration
    // AnimatedSize re-dirties its own layout, which asserts in debug builds).
    if (duration == Duration.zero) {
      return child ?? const SizedBox.shrink();
    }
    return AnimatedSize(
      duration: duration,
      curve: context.motion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: context.motion.curve,
        child: child ?? const SizedBox.shrink(key: ValueKey('no_message')),
      ),
    );
  }
}
