import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/collection-board.tsx`. Owned = a delivered
/// order. Each tile opens one sheet folding certificate, provenance link and
/// ownership date together — a collection is usually a handful of pieces,
/// so a sub-navigation per artwork would be more tapping than reading.
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
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your collection",
          description: 'Something went wrong. Try again in a moment.',
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
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.66,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _CollectionTile(item: items[index]),
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
        showDragHandle: true,
        builder: (context) => _CollectionDetailSheet(item: item),
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
              aspectRatio: 4 / 5,
              child: ArtworkImageView(url: item.artwork.thumbnailUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
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
                  Row(
                    children: [
                      Icon(LucideIcons.badgeCheck, size: 12, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Owned',
                          maxLines: 1,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
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

class _CollectionDetailSheet extends StatelessWidget {
  const _CollectionDetailSheet({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = item.artwork;
    final deliveredAt = item.order.statusHistory
        .where((event) => event.status.name == 'delivered')
        .map((event) => event.changedAt)
        .lastOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 160,
                  height: 200,
                  child: ArtworkImageView(url: artwork.thumbnailUrl),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(artwork.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('by ${artwork.artistName}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 18),
            _row(context, LucideIcons.fingerprint, 'Certificate', artwork.coaCertificateNumber),
            _row(context, LucideIcons.tag, 'Issued', formatLongDate(artwork.coaIssueDate)),
            if (artwork.nfcTagId != null)
              _row(context, LucideIcons.scanLine, 'NFC tag', artwork.nfcTagId!),
            if (deliveredAt != null)
              _row(context, LucideIcons.checkCheck, 'Owned since', formatLongDate(deliveredAt)),
            _row(context, LucideIcons.wallet, 'Paid', formatInr(item.order.total)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/verify/${artwork.id}');
                    },
                    icon: const Icon(LucideIcons.scanLine, size: 14),
                    label: const Text('Passport'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/account/resale');
                    },
                    icon: const Icon(LucideIcons.repeat2, size: 14),
                    label: const Text('Resell'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
