import 'package:flutter/material.dart';

/// Production's brand mark (`gallery-web/public/brand/gz-logo.png`), with its
/// white studio background keyed out so it sits on any surface.
///
/// It is black-and-gold artwork, drawn for a light background — which is what
/// the app opens in. If a dark theme is ever switched on, this needs a
/// light-on-dark variant rather than a tint.
const brandMarkAsset = 'assets/brand/gz-logo.png';

/// The mark over the wordmark, used on the Auth screens and anywhere else the
/// app introduces itself.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          brandMarkAsset,
          height: size,
          errorBuilder: (context, error, stack) => Text(
            'GZ',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 6),
          Text(
            'GALLERYZONE',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 3.5,
            ),
          ),
        ],
      ],
    );
  }
}
