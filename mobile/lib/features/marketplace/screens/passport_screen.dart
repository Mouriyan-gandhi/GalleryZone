import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../ownership/widgets/transfer_widgets.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';

/// Port of `app/verify/[artworkId]` — the public page a physical NFC/QR tag
/// resolves to (mirrors `GET /nfc/{artwork_id}`). Deliberately ceremonial:
/// certificate card, then the append-only provenance record.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key, required this.artworkId});

  static const path = '/verify/:artworkId';

  final String artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.watch(artworkProvider(artworkId));

    return Scaffold(
      appBar: AppBar(title: const Text('Artwork Passport')),
      body: artwork.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: 'Something went wrong',
          description: "We couldn't load this passport right now.",
        ),
        data: (data) => data == null
            ? const EmptyState(
                icon: LucideIcons.searchX,
                title: 'No passport for this tag',
                description:
                    'This tag does not resolve to a registered artwork. If it came '
                    'off a physical piece, contact GalleryZone support.',
              )
            : _PassportBody(artwork: data),
      ),
    );
  }
}

class _PassportBody extends ConsumerWidget {
  const _PassportBody({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artist = ref.watch(artistProfileProvider(artwork.artistId)).value;
    final sorted = [...artwork.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final coverUrl = sorted.isEmpty ? artwork.thumbnailUrl : sorted.first.url;

    return ContentWidth(
      maxWidth: 620,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          TextButton.icon(
            onPressed: () => context.push('/marketplace/${artwork.id}'),
            icon: const Icon(LucideIcons.arrowLeft, size: 14),
            label: const Text('Back to listing'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 12),
          _PassportCard(artwork: artwork, coverUrl: coverUrl),
          if (artwork.nfcTagId != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.nfc, size: 14, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Physical tag ', style: theme.textTheme.labelSmall),
                Text(
                  artwork.nfcTagId!,
                  style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          _CustodyTrio(custody: resolveCustody(artwork)),
          const SizedBox(height: 32),
          OwnershipHistory(artworkId: artwork.id, artistName: artwork.artistName),
          const SizedBox(height: 36),
          ProvenanceTimeline(history: artwork.statusHistory),
          if (artist != null) ...[
            const SizedBox(height: 36),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Registered to ', style: theme.textTheme.labelSmall),
                  InkWell(
                    onTap: () => context.push('/artists/${artist.id}'),
                    child: Text(
                      artist.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(', a verified GalleryZone artist.', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ownership, custody and location are three independent facts about a
/// physical artwork — the passport shows all three rather than one collapsed
/// "owner". Port of the trio in `features/verify/artwork-passport-view.tsx`.
class _CustodyTrio extends StatelessWidget {
  const _CustodyTrio({required this.custody});

  final ArtworkCustody custody;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('Owner', custody.legalOwnerName ?? custodyPartyLabel[custody.legalOwner]!),
      ('Held by', custodyPartyLabel[custody.custodian]!),
      ('Location', custody.locationLabel),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, (label, value)) in cells.indexed) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _CustodyCell(label: label, value: value),
          ),
        ],
      ],
    );
  }
}

class _CustodyCell extends StatelessWidget {
  const _CustodyCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.artwork, required this.coverUrl});

  final Artwork artwork;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
        // The web's gold bloom, as a soft glow rather than a blurred layer.
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl4),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shieldCheck, size: 13, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  'ARTWORK PASSPORT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(width: 176, height: 176, child: ArtworkImageView(url: coverUrl)),
          ),
          const SizedBox(height: 24),
          Text(
            artwork.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('by ${artwork.artistName}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Container(height: 1, width: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'CERTIFICATE NO.',
                  value: artwork.coaCertificateNumber,
                  gold: true,
                ),
              ),
              Expanded(
                child: _Field(label: 'ISSUED', value: formatLongDate(artwork.coaIssueDate)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'This digital passport confirms the piece above as an original, '
            'authenticated work registered with GalleryZone. It resolves the same '
            'NFC/QR tag physically attached to the artwork.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: gold ? theme.colorScheme.tertiary : null,
          ),
        ),
      ],
    );
  }
}

/// `artwork.statusHistory` oldest-first — the append-only provenance record
/// behind the certificate, straight from `artwork_status_history`.
class ProvenanceTimeline extends StatelessWidget {
  const ProvenanceTimeline({super.key, required this.history});

  final List<ArtworkStatusEvent> history;

  static const _labels = <ArtworkStatus, String>{
    ArtworkStatus.draft: 'Listing created',
    ArtworkStatus.pendingApproval: 'Submitted for review',
    ArtworkStatus.marketplace: 'Listed on the marketplace',
    ArtworkStatus.reserved: 'Reserved by an aggregator',
    ArtworkStatus.preparingDispatch: 'Preparing for dispatch',
    ArtworkStatus.inTransit: 'In transit',
    ArtworkStatus.withAggregator: 'In aggregator display',
    ArtworkStatus.sold: 'Sold',
    ArtworkStatus.settlementComplete: 'Settlement complete',
    ArtworkStatus.delivered: 'Delivered',
    ArtworkStatus.completed: 'Sale completed',
    ArtworkStatus.returned: 'Returned',
  };

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ordered = [...history]
      ..sort((a, b) => DateTime.parse(a.changedAt).compareTo(DateTime.parse(b.changedAt)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Provenance', style: theme.textTheme.titleLarge),
        const SizedBox(height: 18),
        for (var i = 0; i < ordered.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardTheme.color,
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Icon(LucideIcons.check, size: 12, color: theme.colorScheme.tertiary),
                    ),
                    if (i != ordered.length - 1)
                      Expanded(child: Container(width: 1, color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == ordered.length - 1 ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labels[ordered[i].status] ?? ordered[i].status.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatShortDate(ordered[i].changedAt),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
