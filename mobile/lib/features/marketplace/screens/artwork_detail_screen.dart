import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/launch.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/artwork.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';
import '../widgets/social_glyphs.dart';

/// Port of `app/marketplace/[artworkId]/page.tsx` — gallery, info panel and
/// the "more from this artist" rail, stacked instead of the web's two-column
/// split. The artist's *real* verification state is looked up (not
/// synthesized from `artwork.verifiedArtist`) so the Gold ✦ tier can show
/// where it applies.
class ArtworkDetailScreen extends ConsumerWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});

  static const path = '/marketplace/:artworkId';

  final String artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.watch(artworkProvider(artworkId));

    return Scaffold(
      appBar: AppBar(title: const Text('Artwork')),
      body: artwork.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: 'Something went wrong',
          description: "We couldn't load this artwork right now.",
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: LucideIcons.searchX,
              title: 'Artwork not found',
              description: 'This listing may have been removed.',
            );
          }
          return _ArtworkDetailBody(artwork: data);
        },
      ),
    );
  }
}

class _ArtworkDetailBody extends ConsumerWidget {
  const _ArtworkDetailBody({required this.artwork});

  final Artwork artwork;

  static const _noVerification = ArtistVerificationState(
    tier1SocialMedia: false,
    tier2ActivePlan: false,
    tier3FirstSale: false,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artist = ref.watch(artistProfileProvider(artwork.artistId)).value;
    final siblings = ref.watch(artworksByArtistProvider(artwork.artistId)).value ?? [];
    final related = siblings.where((a) => a.id != artwork.id).take(4).toList();
    final isWishlisted = ref.watch(wishlistProvider).contains(artwork.id);
    final isAvailable = artwork.status == ArtworkStatus.marketplace;

    // One stacked column, capped: gallery + description + spec rows stretched
    // across a desktop window is unreadable, and a second wide-only layout
    // would be a whole duplicate screen to keep in sync.
    return ContentWidth(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Gallery(images: artwork.images, fallbackUrl: artwork.thumbnailUrl),
          const SizedBox(height: 24),
          Text(
            artwork.category.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.tertiary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artwork.title,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: InkWell(
                  onTap: () => context.push('/artists/${artwork.artistId}'),
                  child: Text(
                    artwork.artistName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              VerifiedBadge(verification: artist?.verification ?? _noVerification, small: true),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceTag(amount: artwork.customerPrice, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text('incl. GST', style: theme.textTheme.labelSmall),
                ],
              ),
              const Spacer(),
              if (artwork.insured) const _InsuranceChip(),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          _SpecGrid(artwork: artwork),
          const Divider(),
          const SizedBox(height: 16),
          Text(artwork.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          const SizedBox(height: 24),
          _AuthenticityCard(artwork: artwork),
          if (artwork.socialProofLinks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Process & provenance', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final link in artwork.socialProofLinks)
                  ActionChip(
                    avatar: SocialGlyph(platform: link.platform, size: 14),
                    label: Text(SocialGlyph.label(link.platform)),
                    onPressed: () => openExternal(context, link.url),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: isAvailable
                        ? () => context.push('/checkout?artworkId=${artwork.id}')
                        : null,
                    child: Text(_buyLabel(artwork.status)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(wishlistProvider.notifier).toggle(artwork.id),
                  icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, size: 18),
                  label: Text(isWishlisted ? 'Wishlisted' : 'Wishlist'),
                ),
              ),
            ],
          ),
          if (artwork.verifiedArtist) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(LucideIcons.badgeCheck, size: 14, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text('Sold by a verified GalleryZone artist.', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
          if (related.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('More from ${artwork.artistName}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) => ArtworkCard(artwork: related[index], width: 200),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _buyLabel(ArtworkStatus status) => switch (status) {
    ArtworkStatus.marketplace => 'Buy Now',
    ArtworkStatus.reserved => 'Reserved',
    ArtworkStatus.sold => 'Sold',
    _ => 'No longer available',
  };
}

/// Hero image + thumbnail strip, with tap-to-expand into a full-screen
/// viewer (the web's zoom dialog).
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.fallbackUrl});

  final List<ArtworkImage> images;
  final String fallbackUrl;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...widget.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final activeUrl = sorted.isEmpty ? widget.fallbackUrl : sorted[_activeIndex].url;

    return Column(
      children: [
        GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: ArtworkImageView(url: activeUrl, fit: BoxFit.contain),
                  ),
                  SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkImageView(url: activeUrl),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.xl4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.expand, size: 12),
                          const SizedBox(width: 6),
                          Text('View full size', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (sorted.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => setState(() => _activeIndex = index),
                child: Container(
                  width: 68,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: index == _activeIndex
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline,
                      width: index == _activeIndex ? 2 : 1,
                    ),
                  ),
                  child: ArtworkImageView(url: sorted[index].thumbnailUrl),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context) {
    final specs = {
      'Category': titleCase(artwork.category),
      'Medium': artwork.medium,
      'Dimensions': artwork.dimensions ?? 'Not specified',
      'Year': artwork.yearCreated?.toString() ?? 'Not specified',
    };
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          for (final entry in specs.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(entry.key, style: theme.textTheme.bodySmall)),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InsuranceChip extends StatelessWidget {
  const _InsuranceChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(LucideIcons.shieldCheck, size: 14, color: theme.colorScheme.tertiary),
      label: const Text('Insured'),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insured in transit'),
          content: const Text(
            'Transit insurance is recommended for artworks valued above ₹20,000, '
            'in partnership with HDFC ERGO. This piece qualifies and ships fully '
            'covered.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
          ],
        ),
      ),
    );
  }
}

class _AuthenticityCard extends StatelessWidget {
  const _AuthenticityCard({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Authenticity',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Row(label: 'Certificate number', value: artwork.coaCertificateNumber),
          const SizedBox(height: 6),
          _Row(label: 'Issued', value: formatLongDate(artwork.coaIssueDate)),
          const SizedBox(height: 12),
          Text(
            'Hand-signed by the artist and shipped with full chain-of-custody '
            'documentation confirming its origin.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.push('/verify/${artwork.id}'),
            icon: const Icon(LucideIcons.scrollText, size: 14),
            label: const Text("View this artwork's digital passport"),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
