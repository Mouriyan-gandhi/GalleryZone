import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart' show DeliveryAddress;
import '../../../data/models/artwork.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/order.dart' show Address;
import '../../../data/remote/mappers/catalog_mappers.dart' show artworkStatusToApi;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../ownership/providers/ownership_providers.dart';
import '../../ownership/widgets/transfer_widgets.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/collection-board.tsx`. Owned = a delivered
/// order, a piece bought in person at a gallery, or one handed over by its
/// previous owner. Each tile opens one sheet folding certificate, provenance,
/// the paper-certificate request and the ways to pass the piece on together -
/// a collection is usually a handful of pieces, so a sub-navigation per
/// artwork would be more tapping than reading.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  static const path = '/account/collection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Collection')),
      body: collection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your collection",
          description: 'Something went wrong. Try again in a moment.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(collectionProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.frame,
                title: 'No owned artworks yet',
                description:
                    'Once an order is delivered, the artwork moves here with its '
                    'certificate, provenance, and ownership record.',
                action: OutlinedButton(
                  onPressed: () => context.push('/marketplace'),
                  child: const Text('Browse the marketplace'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(collectionProvider);
                  await ref.read(collectionProvider.future);
                },
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  // A square photo, then title, artist and what was paid.
                  gridDelegate: ArtworkGridDelegate(
                    textScale: ArtworkGridDelegate.textScaleOf(context),
                    imageRatio: 1,
                    contentHeight: 96,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _CollectionTile(item: items[index]),
                ),
              ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          builder: (context, controller) => _CollectionDetailSheet(item: item, scrollController: controller),
        ),
      ),
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
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ArtworkImageView(url: item.artwork.thumbnailUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.artwork.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  // What was paid; a piece received by transfer cost nothing here.
                  if (item.paidPrice > 0) ...[
                    const SizedBox(height: 4),
                    PriceTag(amount: item.paidPrice, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionDetailSheet extends ConsumerWidget {
  const _CollectionDetailSheet({required this.item, required this.scrollController});

  final CollectionItem item;
  final ScrollController scrollController;

  /// `pending_approval` -> `Pending Approval`, as the website words it.
  static String _statusLabel(ArtworkStatus status) => artworkStatusToApi(
    status,
  ).split('_').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artwork = item.artwork;
    final order = item.order;
    // A bought piece is "acquired" the day it arrived; one handed over by its
    // previous owner, the day of the hand-over.
    final acquired =
        item.acquiredAt ??
        order?.statusHistory
            .where((event) => event.status.name == 'delivered')
            .map((event) => event.changedAt)
            .lastOrNull;
    final transfers = ref.watch(artworkTransfersProvider(artwork.id)).value ?? const <OwnershipTransfer>[];
    final onDisplay = activeDisplayTransfer(transfers);
    final tagged = artwork.nfcTagId != null;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(artwork.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('by ${artwork.artistName}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(LucideIcons.fingerprint, size: 32, color: theme.colorScheme.tertiary),
              const SizedBox(height: 8),
              Text(
                artwork.coaCertificateNumber.isEmpty ? 'Certificate pending' : artwork.coaCertificateNumber,
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              _NfcPill(tagged: tagged),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: theme.colorScheme.outline),
        const SizedBox(height: 4),
        _row(context, 'Artist', artwork.artistName),
        _row(context, 'Medium', humanize(artwork.medium)),
        _row(
          context,
          'Certificate issued',
          artwork.coaIssueDate.isEmpty ? '—' : formatShortDate(artwork.coaIssueDate),
        ),
        _row(context, 'Acquired', acquired == null ? '—' : formatShortDate(acquired)),
        if (order == null && item.fromName.isNotEmpty) _row(context, 'Received from', item.fromName),
        const SizedBox(height: 8),
        Divider(color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text(
          'PROVENANCE',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        for (final event in artwork.statusHistory)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(_statusLabel(event.status), style: theme.textTheme.bodyMedium)),
                const SizedBox(width: 12),
                Text(formatShortDate(event.changedAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        // A loan of display rights is not a change of owner; the owner can
        // always take it back before the date.
        if (onDisplay != null) ...[
          const SizedBox(height: 16),
          _OnDisplayCard(transfer: onDisplay, artworkId: artwork.id),
        ],
        const SizedBox(height: 16),
        _PaperCertificate(artwork: artwork),
        const SizedBox(height: 16),
        Divider(color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Bought in person from an aggregator: there is no GalleryZone
            // order to open, so the provenance of the purchase is stated
            // instead of linking nowhere.
            if (order != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/account/orders/${order.id}');
                },
                icon: const Icon(LucideIcons.externalLink, size: 14),
                label: const Text('View order'),
              )
            else
              Chip(label: const Text('Bought in person'), side: BorderSide(color: theme.colorScheme.outline)),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/verify/${artwork.id}');
              },
              icon: const Icon(LucideIcons.scanLine, size: 14),
              label: const Text('Passport'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/account/resale');
              },
              icon: const Icon(LucideIcons.repeat2, size: 14),
              label: const Text('List for resale'),
            ),
            // Handing the piece on privately, without a sale through the
            // platform. The passport follows the piece either way.
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showTransferOwnershipSheet(
                  context,
                  ref,
                  artwork: artwork,
                  fromName: ref.read(customerProfileProvider).value?.name ?? 'The owner',
                );
              },
              icon: const Icon(LucideIcons.userRoundCheck, size: 14),
              label: const Text('Transfer rights'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether a physical tag is on the piece. The chip's own identifier is not
/// shown: that stays between the artist and GalleryZone.
class _NfcPill extends StatelessWidget {
  const _NfcPill({required this.tagged});

  final bool tagged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF34D399);
    final color = tagged ? green : theme.textTheme.bodySmall?.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tagged ? green.withValues(alpha: 0.1) : theme.colorScheme.secondary,
        border: Border.all(color: tagged ? green.withValues(alpha: 0.3) : theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tagged ? LucideIcons.scanLine : LucideIcons.badgeCheck, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            tagged ? 'NFC tagged' : 'Digital certificate only',
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _OnDisplayCard extends ConsumerWidget {
  const _OnDisplayCard({required this.transfer, required this.artworkId});

  final OwnershipTransfer transfer;
  final String artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.frame, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('On display with ${transfer.toName}', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Until ${formatLongDate(transfer.displayEndsAt!)}. Ownership is unchanged - display rights end on that '
            'date on their own.',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(ownershipRepositoryProvider).endDisplay(transfer.id);
                ref.invalidate(artworkTransfersProvider(artworkId));
                messenger.showSnackBar(const SnackBar(content: Text('Display ended')));
              } catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
              }
            },
            child: const Text('End display now'),
          ),
        ],
      ),
    );
  }
}

/// The buyer's side of MOU §12: the digital certificate always exists; this
/// asks the artist for the signed paper original, posted to the default
/// address.
class _PaperCertificate extends ConsumerStatefulWidget {
  const _PaperCertificate({required this.artwork});

  final Artwork artwork;

  @override
  ConsumerState<_PaperCertificate> createState() => _PaperCertificateState();
}

class _PaperCertificateState extends ConsumerState<_PaperCertificate> {
  bool _busy = false;
  String? _error;

  Future<void> _request(Address address) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(customerRepositoryProvider)
          .requestPhysicalCoa(
            artworkId: widget.artwork.id,
            delivery: DeliveryAddress(
              line1: address.line1,
              city: address.city,
              state: address.state,
              pincode: address.pincode,
            ),
          );
      ref.invalidate(physicalCoaRequestsProvider);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = ref.watch(physicalCoaRequestsProvider).value ?? const <PhysicalCoaRequest>[];
    final existing = requests.where((r) => r.artworkId == widget.artwork.id).firstOrNull;
    final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
    final address = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

    Widget status(IconData icon, String title, String detail) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.tertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(detail, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );

    if (existing?.status == PhysicalCoaStatus.dispatched) {
      final ref = existing!.courierRef;
      return status(
        LucideIcons.packageCheck,
        'Signed certificate posted',
        ref == null || ref.isEmpty ? 'On its way to you' : 'Tracking $ref',
      );
    }
    if (existing?.status == PhysicalCoaStatus.requested) {
      return status(
        LucideIcons.clock3,
        'Physical certificate requested',
        "The artist prints, signs and posts it — you'll see tracking here.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: address == null || _busy ? null : () => _request(address),
          icon: const Icon(LucideIcons.printer, size: 14),
          label: Text(_busy ? 'Requesting…' : 'Request signed paper certificate'),
        ),
        const SizedBox(height: 6),
        Text(
          address == null
              ? 'Add a delivery address to your account first.'
              : 'The artist signs the certificate for “${widget.artwork.title}” by hand and posts it to ${address.city}.',
          style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}
