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
import '../../marketplace/screens/passport_screen.dart'
    show ProvenanceTimeline;
import '../../marketplace/widgets/artwork_card.dart';
import '../../auth/providers/auth_providers.dart';
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
                        const _PhysicalCoaQueue(),
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
                                  // Three separate facts, never collapsed into
                                  // one "owner" — the certificate is where an
                                  // artist checks who holds the piece today.
                                  PortalDetailRow(
                                    label: 'Legal owner',
                                    value: custodyPartyLabel[
                                        resolveCustody(entry.artwork).legalOwner]!,
                                  ),
                                  PortalDetailRow(
                                    label: 'Physical custodian',
                                    value: custodyPartyLabel[
                                        resolveCustody(entry.artwork).custodian]!,
                                  ),
                                  PortalDetailRow(
                                    label: 'Location',
                                    value: resolveCustody(entry.artwork).locationLabel,
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            context.push('/verify/${entry.artwork.id}'),
                                        icon: const Icon(LucideIcons.scanLine, size: 14),
                                        label: const Text('Preview passport'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // History answers a different question
                                      // from the certificate — where the piece
                                      // has been, not whether it is genuine —
                                      // so it gets its own way in.
                                      TextButton.icon(
                                        onPressed: () => showModalBottomSheet<void>(
                                          context: context,
                                          builder: (sheetContext) => Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              20,
                                              20,
                                              32,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.artwork.title,
                                                  style: Theme.of(sheetContext)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                const SizedBox(height: 12),
                                                ProvenanceTimeline(
                                                  history: entry
                                                      .artwork
                                                      .statusHistory,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(LucideIcons.history, size: 14),
                                        label: const Text('History'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
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

/// Paper-certificate requests from collectors (MOU §12).
///
/// The certificate itself is not generated here — there is no PDF pipeline in
/// this build. The artist prints and signs their own, and this records that it
/// went out, which is the part the collector needs to see.
class _PhysicalCoaQueue extends ConsumerWidget {
  const _PhysicalCoaQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requests = ref.watch(artistPhysicalCoaProvider).value ?? const [];
    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paper certificate requests', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final request in requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PortalCard(
              gold: request.status == PhysicalCoaStatus.requested,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.artworkTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  PortalDetailRow(label: 'Certificate', value: request.coaCertificateNumber),
                  PortalDetailRow(label: 'Requested by', value: request.requestedByName),
                  PortalDetailRow(label: 'Post to', value: request.deliveryAddress),
                  if (request.status == PhysicalCoaStatus.dispatched)
                    PortalDetailRow(
                      label: 'Dispatched',
                      value: '${formatLongDate(request.dispatchedAt!)} · '
                          '${request.courierRef}',
                      gold: true,
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showDispatchSheet(context, ref, request.id),
                        icon: const Icon(LucideIcons.package, size: 14),
                        label: const Text('Mark dispatched'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

Future<void> _showDispatchSheet(BuildContext context, WidgetRef ref, String requestId) {
  final courier = TextEditingController();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dispatch certificate', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: courier,
            decoration: const InputDecoration(
              labelText: 'Courier reference',
              helperText: 'Whatever the collector can track it with.',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref
                    .read(artistRepositoryProvider)
                    .dispatchPhysicalCoa(requestId, courier.text);
                ref.invalidate(artistPhysicalCoaProvider);
                ref.invalidate(artistActivityProvider);
                navigator.pop();
              } catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
              }
            },
            child: const Text('Mark dispatched'),
          ),
        ],
      ),
    ),
  );
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
      appBar: AppBar(title: const Text('Aggregator Display')),
      body: placements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your aggregator placements",
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
      HoldingStatus.reserved => ('With aggregator', const Color(0xFF38BDF8)),
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
                      (context, index) =>
                          ArtworkCard(artwork: visible[index], showRarity: true),
                      childCount: visible.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
