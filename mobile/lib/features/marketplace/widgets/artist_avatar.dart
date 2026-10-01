import 'package:flutter/material.dart';

import 'artwork_card.dart';

/// An artist's round portrait, or their initial while they have none - never a
/// stock face, and never the "Image coming soon" panel squeezed into a circle.
class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({super.key, required this.name, required this.imageUrl, this.size = 80});

  final String name;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: imageUrl.isEmpty
          ? Center(
              child: Text(
                initial,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: size * 0.4,
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ArtworkImageView(url: imageUrl),
    );
  }
}
