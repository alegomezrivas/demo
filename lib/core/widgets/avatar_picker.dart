import 'dart:typed_data';

import 'package:demo/core/theme/app_theme.dart';
import 'package:demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Round profile picture: a placeholder, or the chosen image with an edit
/// button underneath.
///
/// It is purely presentational. Picking, cropping and uploading are done by
/// the caller through [onTap] and [onEdit].
class AvatarPicker extends StatelessWidget {
  /// Creates the picker.
  const AvatarPicker({
    this.imageBytes,
    this.diameter,
    this.onTap,
    this.onEdit,
    super.key,
  });

  /// Encoded image (JPEG, PNG...) to show, or null for the placeholder.
  final Uint8List? imageBytes;

  /// Diameter; defaults to the form avatar size token.
  final double? diameter;

  /// Called when the picture is tapped (open the source sheet).
  final VoidCallback? onTap;

  /// Called by the edit button, shown only when there is an image.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final size = diameter ?? spacing.avatarMd;
    final hasImage = imageBytes != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: onTap != null,
          image: true,
          label: hasImage
              ? l10n.avatarSemanticsFilled
              : l10n.avatarSemanticsEmpty,
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            onTap: onTap,
            child: _Avatar(size: size, imageBytes: imageBytes),
          ),
        ),
        if (hasImage && onEdit != null) ...[
          SizedBox(height: spacing.md),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.crop),
            label: Text(l10n.commonEdit),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, required this.imageBytes});

  final double size;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = Icon(
      Icons.person,
      size: size / 2,
      color: colors.textSecondary,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceMuted,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageBytes == null
          ? placeholder
          : Image.memory(
              imageBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
