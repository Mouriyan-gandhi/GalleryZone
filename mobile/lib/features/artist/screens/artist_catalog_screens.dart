import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/mock/seed/aggregator_seed.dart' show fixtureToday;
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/artist_repository.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/coa-nfc-board.tsx`. Every submitted artwork
/// gets a Certificate of Authenticity; physical pieces also carry an NFC/QR
/// tag that resolves to the same passport a collector scans.
class CoaNfcScreen extends ConsumerWidget {
  const CoaNfcScreen({super.key});

  static const path = '/dashboard/coa-nfc';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworks = ref.watch(artistArtworksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('COA & NFC')),
      body: artworks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your certificates",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.fingerprint,
                title: 'No certificates yet',
                description: 'Submit an artwork to generate its first certificate.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Every submitted artwork gets a Certificate of Authenticity; '
                          'physical pieces also get an NFC/QR tag linked to it.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        for (final entry in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PortalCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        child: SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: ArtworkImageView(
                                              url: entry.artwork.thumbnailUrl),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.artwork.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(fontWeight: FontWeight.w500),
                                            ),
                                            Text(entry.artwork.coaCertificateNumber,
                                                style: theme.textTheme.labelSmall),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  PortalDetailRow(
                                    label: 'Issued',
                                    value: formatLongDate(entry.artwork.coaIssueDate),
                                  ),
                                  PortalDetailRow(
                                    label: 'NFC tag',
                                    value: entry.artwork.nfcTagId ?? 'Not tagged',
                                    gold: entry.artwork.nfcTagId != null,
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          context.push('/verify/${entry.artwork.id}'),
                                      icon: const Icon(LucideIcons.scanLine, size: 14),
                                      label: const Text('Preview passport'),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    ),
                                  ),
                                ],
                              ),
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

/// Port of `features/dashboard/gallery-spaces-table.tsx` — pieces currently
/// placed with an aggregator for physical display, for up to 30 days.
class GallerySpacesScreen extends ConsumerWidget {
  const GallerySpacesScreen({super.key});

  static const path = '/dashboard/gallery-spaces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placements = ref.watch(artistGallerySpacesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery spaces')),
      body: placements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your gallery spaces",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.frame,
                title: 'Nothing placed right now',
                description:
                    'Pieces listed as "Marketplace + Galleries" can be reserved by a '
                    'verified gallery for physical display.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pieces currently placed with an aggregator for physical '
                          'display, for up to 30 days.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
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
    final expires = DateTime.parse(holding.expiresAt);
    // Fixture clock, not the wall clock — see [fixtureToday].
    final daysLeft = expires.difference(fixtureToday).inDays;

    return PortalCard(
      child: Column(
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
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    _HoldingPill(status: holding.status),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          PortalDetailRow(label: 'Display price', value: formatInr(holding.displayPrice)),
          PortalDetailRow(
            label: 'Advance paid (${holding.advancePercent}%)',
            value: formatInr(holding.advanceAmount),
          ),
          PortalDetailRow(
            label: 'Placed',
            value: holding.assignmentSource == AssignmentSource.gzAssigned
                ? 'By GalleryZone'
                : 'Gallery reserved it',
          ),
          PortalDetailRow(
            label: 'Expires',
            value: daysLeft >= 0
                ? '${formatShortDate(holding.expiresAt)} · $daysLeft days left'
                : '${formatShortDate(holding.expiresAt)} · expired',
            gold: daysLeft >= 0 && daysLeft <= 7,
          ),
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
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      HoldingStatus.reserved => ('With gallery', const Color(0xFF38BDF8)),
      HoldingStatus.soldPendingSettlement =>
        ('Sold, pending settlement', const Color(0xFF34D399)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Port of `features/dashboard/portfolio-board.tsx` — what buyers actually
/// see of this artist's work. Read-only, and distinct from My Artworks,
/// which also shows drafts and in-review pieces.
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
    final artworks = ref.watch(artistArtworksProvider).value ?? const [];
    final visible = [
      for (final entry in artworks)
        if (_publicStatuses.contains(entry.artwork.status)) entry.artwork,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: visible.isEmpty
          ? const EmptyState(
              icon: LucideIcons.images,
              title: 'Nothing published yet',
              description: 'Approved artworks appear here as buyers see them.',
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      '${visible.length} pieces visible to buyers',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.56,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ArtworkCard(artwork: visible[index]),
                      childCount: visible.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
