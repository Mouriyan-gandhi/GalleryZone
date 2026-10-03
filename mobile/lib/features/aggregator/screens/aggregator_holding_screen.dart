import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/nfc.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../nfc/providers/nfc_providers.dart';
import '../../nfc/widgets/nfc_sheets.dart';
import '../../shell/display_clock.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';
import '../widgets/holding_dialogs.dart';
import 'aggregator_collection_screen.dart';
import 'aggregator_inventory_screen.dart';

/// Port of `holding-detail.tsx` - one holding's whole lifecycle in one place:
/// price breakdown, expiry, the passport while it is actively theirs, and what to
/// do when a period ends. Reserving lands here; so does a tap on a card in My
/// Inventory.
class AggregatorHoldingScreen extends ConsumerWidget {
  const AggregatorHoldingScreen({super.key, required this.holdingId});

  final String holdingId;

  /// Under [AggregatorCollectionScreen.path].
  static const subPath = ':holdingId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holding = ref.watch(aggregatorHoldingProvider(holdingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Holding')),
      body: holding.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.galleryVerticalEnd,
          title: "Couldn't load this holding",
          description: 'Something went wrong. Try again in a moment.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorHoldingProvider(holdingId)),
            child: const Text('Try again'),
          ),
        ),
        data: (view) => view == null
            ? EmptyState(
                icon: LucideIcons.galleryVerticalEnd,
                title: 'Holding not found',
                description: 'This reservation may have been removed, or the link is wrong.',
                action: TextButton(
                  onPressed: () => context.go(AggregatorCollectionScreen.path),
                  child: const Text('Back to My Inventory'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aggregatorHoldingProvider(holdingId));
                  await ref.read(aggregatorHoldingProvider(holdingId).future);
                },
                child: _HoldingBody(view: view),
              ),
      ),
    );
  }
}

class _HoldingBody extends ConsumerWidget {
  const _HoldingBody({required this.view});

  final AggregatorHoldingView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final holding = view.holding;
    final artwork = view.artwork;
    final reserved = holding.status == HoldingStatus.reserved;
    final returned = holding.status == HoldingStatus.returned;
    // The API takes a piece back itself once its window has passed, so this only
    // shows in the gap before that runs. Recording a sale is the one thing still
    // worth doing from here.
    final expired = reserved && !DateTime.parse(holding.expiresAt).isAfter(displayNow(ref));
    // One answer per window: GalleryZone's reply stands until the window moves.
    // The API also refuses a second request while one is waiting, and once the
    // piece is already held to the end of its listing.
    final request = holding.extensionRequest;
    final canAskToKeep = reserved &&
        !expired &&
        !holding.windowExtended &&
        request?.status != ExtensionStatus.pending &&
        !(request != null && request.previousExpiresAt == holding.expiresAt);
    // The lock-before-shipping rule seen from the gallery (NFC_IMPLEMENTATION.md
    // §4.7): the piece's tag state, never the chip's id. A phone without NFC is
    // told, not offered buttons it can't use.
    final stage = artwork.nfcStage;
    final hasNfc = ref.watch(nfcAvailableProvider).value ?? true;
    void refreshTag() {
      ref.invalidate(aggregatorHoldingProvider(holding.id));
      ref.invalidate(aggregatorCollectionProvider);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (expired) ...[
                PortalNotice(
                  icon: LucideIcons.clock,
                  destructive: true,
                  title: "This piece's 30-day window has ended.",
                  body: 'GalleryZone takes it back and offers it to another aggregator, and your advance returns '
                      'to your wallet. If it sold before then, record the sale now.',
                  action: Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () => showRecordSale(context, view),
                      child: const Text('Record sale'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (returned) ...[
                PortalNotice(
                  icon: LucideIcons.undo2,
                  title: 'Your period for this piece has ended.',
                  body: 'It has gone back to GalleryZone and is now available to another aggregator. Your advance '
                      'is back in your wallet.',
                  action: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go(AggregatorBrowseScreen.path),
                      child: const Text('Browse inventory to reserve something else'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!returned && stage != NfcStage.linkedLocked) ...[
                PortalNotice(
                  key: const Key('holding-nfc-banner'),
                  icon: LucideIcons.lock,
                  destructive: true,
                  title: "This piece's NFC tag is not locked",
                  body: stage == NfcStage.unlinked
                      ? 'No tag is linked to it yet. Link and lock one before you put it on display or ship it.'
                      : 'Lock it before you put it on display or ship it: it can’t be dispatched to a buyer until it is.',
                  action: hasNfc
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              key: const Key('holding-nfc-action'),
                              onPressed: () => showNfcSheet(
                                context,
                                artwork: artwork,
                                mode: stage == NfcStage.unlinked ? NfcMode.link : NfcMode.lock,
                                onChanged: refreshTag,
                              ),
                              icon: Icon(stage == NfcStage.unlinked ? LucideIcons.link2 : LucideIcons.lock, size: 14),
                              label: Text(stage == NfcStage.unlinked ? 'Link tag' : 'Lock tag'),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              PortalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(width: 80, height: 80, child: ArtworkImageView(url: artwork.thumbnailUrl)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(artwork.artistName, style: theme.textTheme.bodySmall),
                              const SizedBox(height: 8),
                              HoldingStatusPill(status: holding.status),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriceTag(amount: holding.displayPrice, style: theme.textTheme.titleMedium),
                      ],
                    ),
                    if (reserved) ...[
                      const Divider(height: 28),
                      const _Caption('Display window'),
                      ExpiryCountdown(expiresAt: holding.expiresAt),
                      const SizedBox(height: 6),
                      Text(
                        'Reserved ${formatShortDate(holding.assignedAt)} · expires ${formatShortDate(holding.expiresAt)}',
                        style: theme.textTheme.labelSmall,
                      ),
                      if (holding.windowExtended)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            // The client's own case: a stub of under thirty days is not
                            // worth shipping to anyone else, so whoever has the piece
                            // keeps it to the end of the artist's 180 days.
                            "Extended — too little of this piece's listing was left to place it elsewhere, so it "
                            'stays with you until the listing ends.',
                            style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                          ),
                        ),
                      if (request != null) ...[
                        const SizedBox(height: 8),
                        _ExtensionStatus(request: request, expiresAt: holding.expiresAt),
                      ],
                    ],
                    const Divider(height: 28),
                    _Caption('Rotation · month ${holding.cycleMonth} of $aggregatorCycleMonths'),
                    CycleStepper(currentMonth: holding.cycleMonth),
                    const Divider(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Stat(
                            label: 'Advance',
                            value: formatInr(holding.advanceAmount),
                            suffix: '(${holding.advancePercent}%)',
                          ),
                        ),
                        Expanded(child: _Stat(label: 'Delivery deposit', value: formatInr(holding.deliveryDeposit))),
                        Expanded(child: _Stat(label: 'Display price', value: formatInr(holding.displayPrice))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PortalDetailRow(
                      label: 'Assigned',
                      value: holding.assignmentSource == AssignmentSource.gzAssigned ? 'By GalleryZone' : 'You reserved it',
                    ),
                    if (reserved) ...[
                      const Divider(height: 28),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => showRecordSale(context, view),
                            child: const Text('Record sale'),
                          ),
                          OutlinedButton(
                            onPressed: () => showReturnHolding(context, view),
                            child: const Text('Return'),
                          ),
                          if (canAskToKeep)
                            OutlinedButton(
                              onPressed: () => showRequestExtension(context, view),
                              child: const Text('Ask to keep it longer'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // The note's rule: COA/NFC access follows the ACTIVE allocation. Once a
              // piece is returned it moves on to the next aggregator, so the passport
              // stops showing here - it isn't deleted, just no longer this
              // aggregator's to see.
              if (!returned)
                _PassportCard(view: view)
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldOff, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "This piece's COA/NFC passport is only visible while it's in your active inventory.",
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SuggestedArtworks(references: [artwork], title: 'Similar artworks'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        if (suffix != null) Text(suffix!, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Asking to keep a piece longer, and what GalleryZone answered. The answer
/// stands for the window it was asked about.
class _ExtensionStatus extends StatelessWidget {
  const _ExtensionStatus({required this.request, required this.expiresAt});

  final HoldingExtensionRequest request;
  final String expiresAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ends = formatShortDate(expiresAt);
    final (icon, title, color) = switch (request.status) {
      ExtensionStatus.pending => (LucideIcons.hourglass, 'Waiting for GalleryZone', theme.colorScheme.tertiary),
      ExtensionStatus.approved => (LucideIcons.circleCheckBig, 'GalleryZone agreed', const Color(0xFF34D399)),
      ExtensionStatus.declined => (LucideIcons.circleX, 'GalleryZone said no', theme.colorScheme.onSurfaceVariant),
    };
    final body = switch (request.status) {
      ExtensionStatus.pending => "You asked to keep this piece longer. If it isn't approved by $ends, it goes back "
          'on sale and your advance is released.',
      ExtensionStatus.approved => 'The window now runs to $ends.',
      ExtensionStatus.declined => 'The window ends on $ends. Then the piece goes back on sale and your advance is '
          'released.',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
                if (request.status == ExtensionStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Your assurance: “${request.assurance}”', style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
                  ),
                if (request.note != null && request.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('GalleryZone wrote: “${request.note}”', style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The certificate-styled passport summary (`artwork-passport-card.tsx`), with a
/// way into the full passport page.
class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.view});

  final AggregatorHoldingView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = view.artwork;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          StatusPill(label: 'Artwork Passport', color: theme.colorScheme.tertiary, icon: LucideIcons.shieldCheck),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(width: 120, height: 120, child: ArtworkImageView(url: artwork.thumbnailUrl)),
          ),
          const SizedBox(height: 14),
          Text(
            artwork.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('by ${artwork.artistName}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          Container(width: 64, height: 1, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'CERTIFICATE NO.',
                  value: artwork.coaCertificateNumber.isEmpty ? 'Pending approval' : artwork.coaCertificateNumber,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'ISSUED',
                  value: artwork.coaIssueDate.isEmpty ? '—' : formatLongDate(artwork.coaIssueDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'This digital passport confirms the piece above as an original, authenticated work registered with '
            'GalleryZone. It resolves the same NFC/QR tag physically attached to the artwork.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.push('/verify/${artwork.id}'),
            child: const Text('Open full passport'),
          ),
        ],
      ),
    );
  }
}
