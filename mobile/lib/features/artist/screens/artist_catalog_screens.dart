import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../aggregator/widgets/aggregator_widgets.dart' show ExpiryCountdown;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/artist_providers.dart';

/// Port of `features/dashboard/gallery-spaces-table.tsx` - where this artist's
/// work is physically on display right now.
class GallerySpacesScreen extends ConsumerWidget {
  const GallerySpacesScreen({super.key});

  static const path = '/dashboard/gallery-spaces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placements = ref.watch(artistGallerySpacesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aggregator Display')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(artistGallerySpacesProvider);
          await ref.read(artistGallerySpacesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Where your work is physically on display right now.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  // Your artwork is with GalleryZone for a six-month listing period -
                  // not a fixed month-per-location schedule. Locations can change
                  // within that period; this page always shows the current one.
                  PortalNotice(
                    gold: true,
                    icon: LucideIcons.calendarRange,
                    body:
                        'You send your artwork for a six-month listing period. Within it, GalleryZone places the '
                        "piece with an aggregator for display and may move it to another one if it hasn't sold — you "
                        "don't commit to a location for a fixed month. Whatever the current placement is, it shows "
                        'here.',
                  ),
                  const SizedBox(height: 16),
                  placements.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => EmptyState(
                      icon: LucideIcons.galleryVerticalEnd,
                      title: "Couldn't load your aggregator display",
                      description: authErrorMessage(error),
                      action: OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(artistGallerySpacesProvider),
                        child: const Text('Try again'),
                      ),
                    ),
                    data: (list) => list.isEmpty
                        ? const EmptyState(
                            icon: LucideIcons.galleryVerticalEnd,
                            title: 'No pieces with an aggregator yet',
                            description: 'Artworks listed on the aggregator channel show up here once an aggregator reserves one.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final placement in list)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _PlacementCard(placement: placement),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.placement});

  final GallerySpacePlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = placement.holding;
    final sold = holding.status == HoldingStatus.soldPendingSettlement;

    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ArtworkImageView(url: placement.artwork.thumbnailUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placement.artwork.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _HoldingPill(status: holding.status),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PortalDetailRow(
            label: 'Display price',
            value: formatInr(holding.displayPrice),
          ),
          PortalDetailRow(label: 'Current location', value: 'Partner gallery'),
          if (!sold) ...[
            const SizedBox(height: 6),
            Text('At this location until', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            ExpiryCountdown(expiresAt: holding.expiresAt),
          ],
        ],
      ),
    );
  }
}

class _HoldingPill extends StatelessWidget {
  const _HoldingPill({required this.status});

  final HoldingStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      HoldingStatus.reserved => (
        'With aggregator',
        LucideIcons.bookmarkCheck,
        const Color(0xFF38BDF8),
      ),
      HoldingStatus.soldPendingSettlement => (
        'Sold, pending settlement',
        LucideIcons.circleCheckBig,
        const Color(0xFF34D399),
      ),
      HoldingStatus.returned => (
        'Returned',
        LucideIcons.undo2,
        const Color(0xFF94A3B8),
      ),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

/// Port of `features/dashboard/portfolio-board.tsx` - what buyers effectively
/// see of this artist's work. Read-only, and distinct from My Artworks, which
/// also shows drafts and in-review pieces.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  static const path = '/dashboard/portfolio';

  static const _publicStatuses = {
    ArtworkStatus.marketplace,
    ArtworkStatus.withAggregator,
    ArtworkStatus.sold,
    ArtworkStatus.settlementComplete,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworksAsync = ref.watch(artistArtworksProvider);
    final artworks = artworksAsync.value;
    final visible = [
      for (final entry in artworks ?? const <ArtistArtwork>[])
        if (_publicStatuses.contains(entry.artwork.status)) entry.artwork,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: artworks == null
          ? artworksAsync.hasError
                ? EmptyState(
                    icon: LucideIcons.triangleAlert,
                    title: "Couldn't load your portfolio",
                    description: authErrorMessage(artworksAsync.error!),
                    action: OutlinedButton(
                      onPressed: () => ref.invalidate(artistArtworksProvider),
                      child: const Text('Try again'),
                    ),
                  )
                : const Center(child: CircularProgressIndicator())
          : visible.isEmpty
          ? const EmptyState(
              icon: LucideIcons.images,
              title: 'Nothing published yet',
              description:
                  'Nothing published yet — approved artworks will appear here.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(artistArtworksProvider);
                await ref.read(artistArtworksProvider.future);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${visible.length} ${visible.length == 1 ? 'piece' : 'pieces'} visible to buyers',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A preview of how your published work looks across GalleryZone.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 270,
                          ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) =>
                          _PortfolioCard(artwork: visible[index]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// One published piece as buyers meet it: the photo, its rank, the title and
/// what it is made of. No price and no buy button - this is the artist's own
/// preview, not a shop window - but a tap opens the real page.
class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = artwork.rarityType;
    return PortalCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push('/marketplace/${artwork.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ArtworkImageView(url: artwork.thumbnailUrl),
                      if (rank != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: RarityBadge(rarity: rank, stamp: true),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${humanize(artwork.medium)}${artwork.yearCreated == null ? '' : ' · ${artwork.yearCreated}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
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
