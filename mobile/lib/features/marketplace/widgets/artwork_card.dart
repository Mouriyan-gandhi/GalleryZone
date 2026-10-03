import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/artwork.dart';
import '../providers/marketplace_providers.dart';

/// Resolves the image paths the seed fixtures carry (web `public/` paths
/// like `/artworks/bird.png`) to bundled assets. The bundled copies are
/// JPEG re-encodes at 1200px — see the `assets:` note in pubspec.yaml — so
/// the extension is swapped here rather than rewriting every fixture.
/// Anything already absolute (http/https) loads over the network, which is
/// what a real backend's image URLs will be.
class ArtworkImageView extends StatelessWidget {
  const ArtworkImageView({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  final String url;
  final BoxFit fit;

  static String _assetFor(String url) {
    final withoutExtension = url.replaceAll(RegExp(r'\.(png|jpe?g|webp)$'), '');
    return 'assets/images$withoutExtension.jpg';
  }

  @override
  Widget build(BuildContext context) {
    // No photo yet reads as exactly that — never a shared stock picture, so
    // unrelated listings don't look like duplicates of each other.
    if (url.isEmpty) return const ImageComingSoon();
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const SizedBox.expand(),
    );
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stack) => placeholder,
      );
    }
    return Image.asset(
      _assetFor(url),
      fit: fit,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

/// The honest "no image yet" state for a piece with no uploaded photo.
class ImageComingSoon extends StatelessWidget {
  const ImageComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget logo(double size) => Opacity(
      opacity: 0.25,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Image.asset(
          'assets/brand/gz-logo.png',
          width: size,
          height: size,
          errorBuilder: (context, error, stack) => SizedBox(width: size, height: size),
        ),
      ),
    );

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A thumbnail in a list row is too small to carry the words; it keeps
          // just the faded mark, scaled to the box.
          final compact = constraints.maxHeight < 120 || constraints.maxWidth < 110;
          if (compact) {
            final size = (constraints.biggest.shortestSide.isFinite ? constraints.biggest.shortestSide : 40) * 0.5;
            return Center(child: logo(size));
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                logo(40),
                const SizedBox(height: 8),
                Text(
                  'Image coming soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Every ₹ amount renders through this — `tabular` figures keep prices
/// aligned down a grid column.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.amount, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      formatInr(amount),
      style: (style ?? theme.textTheme.titleMedium)?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Tier 0 renders nothing. Tiers 1-2 render the subtle "Verified" mark;
/// tier 3 renders the "Gold ✦ Verified" pill. Callers holding only
/// `Artwork.verifiedArtist` (a boolean lower bound) pass
/// [VerifiedBadge.minimumVerification] — never a synthesized all-true state.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    required this.verification,
    this.small = false,
  });

  static const minimumVerification = ArtistVerificationState(
    tier1SocialMedia: true,
    tier2ActivePlan: false,
    tier3FirstSale: false,
  );

  final ArtistVerificationState verification;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiers = verifiedTierCount(verification);
    if (tiers == 0) return const SizedBox.shrink();

    final textStyle =
        (small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(fontWeight: FontWeight.w500);

    if (tiers == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl4),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          'Gold ✦ Verified',
          style: textStyle?.copyWith(color: theme.colorScheme.tertiary),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.badgeCheck,
          size: small ? 12 : 14,
          color: theme.colorScheme.tertiary,
        ),
        const SizedBox(width: 4),
        Text('Verified', style: textStyle),
      ],
    );
  }
}

/// Grid/rail tile. Taps through to the artwork detail route; the heart and the
/// buy button are nested tap targets that must not trigger the card's own
/// navigation.
///
/// What it shows follows the website's card: GalleryZone's rank as a stamp
/// over the photo, the title, the artist, medium and year, size, the price —
/// with "Reserved" / "Sold" beside it when it is not on sale — and an
/// "Insured" tag only when the piece is. There is no certificate or passport
/// tag: the marketplace carries none (1 Oct 2026).
class ArtworkCard extends ConsumerWidget {
  const ArtworkCard({super.key, required this.artwork, this.width});

  final Artwork artwork;
  final double? width;

  // Only `reserved` and `sold` ever occur as the *current* status of a listed
  // piece; any other off-market status reads "Unavailable" instead of breaking.
  static const _statusLabels = <ArtworkStatus, String>{
    ArtworkStatus.reserved: 'Reserved',
    ArtworkStatus.sold: 'Sold',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isWishlisted = ref.watch(wishlistProvider).contains(artwork.id);
    final isAvailable = artwork.status == ArtworkStatus.marketplace;
    final status = isAvailable
        ? null
        : (_statusLabels[artwork.status] ?? 'Unavailable');
    final details = [
      if (artwork.medium.isNotEmpty) humanize(artwork.medium),
      if (artwork.yearCreated != null) '${artwork.yearCreated}',
    ].join(', ');
    final size = dimensionsLabel(artwork.dimensions);

    return SizedBox(
      width: width,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Stack(
          children: [
            InkWell(
              onTap: () => context.push('/marketplace/${artwork.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    // Unavailable pieces stay visible but visibly dimmed, like
                    // the website's faded, part-greyscale treatment.
                    child: Opacity(
                      opacity: isAvailable ? 1 : 0.65,
                      child: ArtworkImageView(url: artwork.thumbnailUrl),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                artwork.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            if (artwork.verifiedArtist) ...[
                              const SizedBox(width: 6),
                              const VerifiedBadge(
                                verification: VerifiedBadge.minimumVerification,
                                small: true,
                              ),
                            ],
                          ],
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        if (size.isNotEmpty)
                          Text(
                            size,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            PriceTag(amount: artwork.customerPrice),
                            if (status != null)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (artwork.insured) ...[
                          const SizedBox(height: 8),
                          // Clear of the buy button that sits in this corner.
                          const Padding(
                            padding: EdgeInsets.only(right: 40),
                            child: _Pill(label: 'Insured', gold: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (artwork.rarityType != null)
              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  child: RarityBadge(rarity: artwork.rarityType!, stamp: true),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () =>
                    ref.read(wishlistProvider.notifier).toggle(artwork.id),
                tooltip: isWishlisted
                    ? 'Remove from wishlist'
                    : 'Add to wishlist',
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isWishlisted
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.85,
                  ),
                ),
              ),
            ),
            // One tap from the grid to buying, as on the website - only while
            // the piece is actually on sale.
            if (isAvailable)
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton(
                  onPressed: () =>
                      context.push('/checkout?artworkId=${artwork.id}'),
                  tooltip: 'Buy ${artwork.title}',
                  icon: Icon(
                    LucideIcons.shoppingBag,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays [ArtworkCard]s out two across on a phone and wider on a tablet.
///
/// Each row is as tall as its cards need: the photo is a fixed 4:5 of the
/// card's width and the text under it a fixed height, so the height follows
/// the width instead of a ratio that suits one screen size and clips on
/// another. The text part grows with the person's text size setting.
class ArtworkGridDelegate extends SliverGridDelegate {
  const ArtworkGridDelegate({
    this.maxCrossAxisExtent = 240,
    this.spacing = 16,
    this.textScale = 1,
    this.imageRatio = 1.25,
    this.contentHeight = textHeight,
  });

  /// Reads the text size setting from [context].
  factory ArtworkGridDelegate.of(BuildContext context) =>
      ArtworkGridDelegate(textScale: textScaleOf(context));

  /// How much bigger than default the person has set their text.
  static double textScaleOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) / 14;

  final double maxCrossAxisExtent;
  final double spacing;
  final double textScale;

  /// Photo height as a multiple of the card's width (4:5 is 1.25; a square
  /// tile is 1).
  final double imageRatio;

  /// Room under the photo at the default text size; [textHeight] suits the
  /// marketplace card, a plainer tile passes less.
  final double contentHeight;

  /// Title, artist, medium and year, size, price and the "Insured" tag, with
  /// the card's padding and border — at the default text size.
  static const textHeight = 170.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final columns = math.max(
      1,
      (constraints.crossAxisExtent / (maxCrossAxisExtent + spacing)).ceil(),
    );
    final width =
        math.max(0.0, constraints.crossAxisExtent - spacing * (columns - 1)) /
        columns;
    final height = width * imageRatio + contentHeight * textScale;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: height + spacing,
      crossAxisStride: width + spacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(ArtworkGridDelegate oldDelegate) =>
      oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
      oldDelegate.spacing != spacing ||
      oldDelegate.textScale != textScale ||
      oldDelegate.imageRatio != imageRatio ||
      oldDelegate.contentHeight != contentHeight;
}

/// What a card looks like while its page is on the way.
class ArtworkCardSkeleton extends StatelessWidget {
  const ArtworkCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = theme.colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: block,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Semantics(
      label: 'Loading artwork',
      child: ExcludeSemantics(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ColoredBox(color: block),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(0.8, 14),
                    const SizedBox(height: 8),
                    bar(0.5, 12),
                    const SizedBox(height: 12),
                    bar(0.4, 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.gold = false});

  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = gold
        ? theme.colorScheme.tertiary
        : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(
          color: gold
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shared "nothing here" panel — port of `components/shared/empty-state.tsx`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        // Callers hand this the whole body of a screen, so start-aligned
        // content parks it under the app bar with the rest of the page
        // empty. Centering is a no-op where the height is unbounded.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.tertiary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// The rank mark shown over an artwork image: the word, not a bare letter —
/// "R" means nothing to someone seeing it for the first time.
///
/// Two looks, as on the website. The pill (default) is the translucent gold
/// outline used wherever a rank is named; the [stamp] is a solid, per-rank
/// colour for the marketplace card corner, where four ranks have to be told
/// apart at a glance over a busy photo.
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.stamp = false});

  final ArtworkRarity rarity;
  final bool stamp;

  /// The stamp's solid colour for each rank, with the text colour that reads
  /// on it. Red, green, gold, grey — distinct for colour-blind viewers too,
  /// since the letter is always printed on it.
  static (Color, Color) stampTone(BuildContext context, ArtworkRarity rank) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (rank) {
      ArtworkRarity.rare => (AppColors.destructive, Colors.white),
      ArtworkRarity.unique => (const Color(0xFF059669), Colors.white),
      ArtworkRarity.original => (
        dark ? AppColors.darkGoldDeep : AppColors.lightGoldDeep,
        Colors.white,
      ),
      ArtworkRarity.standard => (
        dark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
        dark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stamp) {
      final (background, foreground) = stampTone(context, rarity);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          artworkRarityCode[rarity]!,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${artworkRarityCode[rarity]!} ${artworkRarityLabel[rarity]!.toUpperCase()}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
