import 'package:flutter/material.dart';
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
  const ArtworkImageView({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  static String _assetFor(String url) {
    final withoutExtension = url.replaceAll(RegExp(r'\.(png|jpe?g|webp)$'), '');
    return 'assets/images$withoutExtension.jpg';
  }

  @override
  Widget build(BuildContext context) {
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
  const VerifiedBadge({super.key, required this.verification, this.small = false});

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

    final textStyle = (small ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
        ?.copyWith(fontWeight: FontWeight.w500);

    if (tiers == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl4),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
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
        Icon(LucideIcons.badgeCheck, size: small ? 12 : 14, color: theme.colorScheme.tertiary),
        const SizedBox(width: 4),
        Text('Verified', style: textStyle),
      ],
    );
  }
}

/// Grid/rail tile. Taps through to the artwork detail route; the heart is a
/// nested tap target that must not trigger the card's own navigation.
class ArtworkCard extends ConsumerWidget {
  const ArtworkCard({super.key, required this.artwork, this.width});

  final Artwork artwork;
  final double? width;

  // Only `reserved` and `sold` ever occur as a *current* status on a
  // marketplace fixture; every other value appears solely in statusHistory.
  // The fallback keeps this honest if that changes.
  static const _statusBadges = <ArtworkStatus, (String, IconData)>{
    ArtworkStatus.reserved: ('Reserved', LucideIcons.bookmarkCheck),
    ArtworkStatus.sold: ('Sold', LucideIcons.circleCheckBig),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isWishlisted = ref.watch(wishlistProvider).contains(artwork.id);
    final isAvailable = artwork.status == ArtworkStatus.marketplace;
    final badge = isAvailable ? null : (_statusBadges[artwork.status] ?? ('Unavailable', LucideIcons.lock));

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => context.push('/marketplace/${artwork.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Unavailable pieces stay visible but visibly dimmed,
                    // same treatment as the web's grayscale + opacity.
                    Opacity(
                      opacity: isAvailable ? 1 : 0.6,
                      child: ArtworkImageView(url: artwork.thumbnailUrl),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _Pill(icon: badge.$2, label: badge.$1),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        onPressed: () => ref.read(wishlistProvider.notifier).toggle(artwork.id),
                        tooltip: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                        icon: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurface,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (artwork.insured)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: _Pill(
                          icon: LucideIcons.shieldCheck,
                          label: 'Insured',
                          gold: true,
                        ),
                      ),
                  ],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 6),
                    PriceTag(amount: artwork.customerPrice),
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
  const _Pill({required this.icon, required this.label, this.gold = false});

  final IconData icon;
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = gold ? theme.colorScheme.tertiary : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(
          color: gold
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
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
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.tertiary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
