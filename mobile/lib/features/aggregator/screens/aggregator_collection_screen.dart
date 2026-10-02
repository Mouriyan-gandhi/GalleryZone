import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';
import '../widgets/holding_dialogs.dart';
import 'aggregator_inventory_screen.dart';

/// Port of `app/aggregator/collection/page.tsx` + `collection-table.tsx` - the
/// web's "My Inventory". The web's seven-column table becomes the card its own
/// mobile layout uses: a phone has no room for a table, and tapping a card
/// opens the holding page that carries every column.
class AggregatorCollectionScreen extends ConsumerStatefulWidget {
  const AggregatorCollectionScreen({super.key});

  static const path = '/aggregator/collection';

  @override
  ConsumerState<AggregatorCollectionScreen> createState() => _AggregatorCollectionScreenState();
}

enum _StatusFilter {
  all('All'),
  reserved('Reserved'),
  sold('Sold');

  const _StatusFilter(this.label);
  final String label;

  bool matches(HoldingStatus status) => switch (this) {
        all => true,
        reserved => status == HoldingStatus.reserved,
        sold => status == HoldingStatus.soldPendingSettlement,
      };
}

class _AggregatorCollectionScreenState extends ConsumerState<AggregatorCollectionScreen> {
  _StatusFilter _filter = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collection = ref.watch(aggregatorCollectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My inventory')),
      body: collection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.galleryVerticalEnd,
          title: "Couldn't load your collection",
          description: 'Something went wrong loading your holdings.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorCollectionProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (all) {
          // A piece that has gone back to GalleryZone is no longer this
          // aggregator's to show, so it leaves the list entirely (client, 30 Sep 2026).
          final rows = [for (final view in all) if (view.holding.status != HoldingStatus.returned) view];
          if (rows.isEmpty) {
            return EmptyState(
              icon: LucideIcons.galleryVerticalEnd,
              title: 'No holdings yet',
              description: 'Reserve an artwork from Inventory to see it appear here.',
              action: FilledButton(
                onPressed: () => context.go(AggregatorBrowseScreen.path),
                child: const Text('Browse Inventory'),
              ),
            );
          }
          final shown = [for (final view in rows) if (_filter.matches(view.holding.status)) view];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(aggregatorCollectionProvider);
              await ref.read(aggregatorCollectionProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'The pieces you are displaying. Record a sale here, or return one you no longer want to hold.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final filter in _StatusFilter.values)
                            ChoiceChip(
                              label: Text('${filter.label}  ${rows.where((v) => filter.matches(v.holding.status)).length}'),
                              selected: _filter == filter,
                              onSelected: (_) => setState(() => _filter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (shown.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.galleryVerticalEnd,
                          title: 'No holdings with this status',
                          description: 'Try a different filter above.',
                        )
                      else
                        for (final view in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HoldingCard(view: view),
                          ),
                    ],
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

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.view});

  final AggregatorHoldingView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = view.holding;
    final reserved = holding.status == HoldingStatus.reserved;
    final asked = holding.extensionRequest?.status == ExtensionStatus.pending;

    return PortalCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            onTap: () => context.push('/aggregator/collection/${holding.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(width: 56, height: 56, child: ArtworkImageView(url: view.artwork.thumbnailUrl)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          view.artwork.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        HoldingStatusPill(status: holding.status),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PriceTag(amount: holding.displayPrice, style: theme.textTheme.bodyMedium),
                            if (reserved && asked)
                              Text(
                                'Extension requested',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        if (reserved) ...[
                          const SizedBox(height: 8),
                          ExpiryCountdown(expiresAt: holding.expiresAt),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: reserved
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: FilledButton(
                            onPressed: () => showRecordSale(context, view),
                            child: const Text('Record sale'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => showReturnHolding(context, view),
                            child: const Text('Return'),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text('Sale recorded', style: theme.textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}
