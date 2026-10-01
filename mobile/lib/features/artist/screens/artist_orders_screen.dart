import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../account/widgets/order_widgets.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/orders-table.tsx` — orders for this artist's
/// pieces, each showing what she actually receives rather than what the
/// buyer paid. The "Sales" tab of [ArtistSalesScreen] — no Scaffold/AppBar
/// of its own, since it never appears outside that tabbed screen.
///
/// Searchable by artwork or order id and filterable by status, like the
/// website's table.
class ArtistOrdersTab extends ConsumerStatefulWidget {
  const ArtistOrdersTab({super.key});

  @override
  ConsumerState<ArtistOrdersTab> createState() => _ArtistOrdersTabState();
}

class _ArtistOrdersTabState extends ConsumerState<ArtistOrdersTab> {
  String _query = '';
  OrderStatus? _status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(artistOrdersProvider);

    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        icon: LucideIcons.packageSearch,
        title: "Couldn't load your orders",
        description: 'Something went wrong. Try again in a moment.',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(artistOrdersProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.shoppingBag,
            title: 'No orders yet',
            description: 'Sold pieces and their fulfillment status will show up here.',
          );
        }
        final needle = _query.trim().toLowerCase();
        final shown = [
          for (final entry in list)
            if ((_status == null || entry.order.status == _status) &&
                (needle.isEmpty ||
                    '${entry.order.id} ${entry.order.artwork?.title ?? ''}'.toLowerCase().contains(needle)))
              entry,
        ];

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(artistOrdersProvider);
            await ref.read(artistOrdersProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by artwork or order id',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _StatusChip(label: 'All', selected: _status == null, onTap: () => setState(() => _status = null)),
                          for (final status in OrderStatus.values)
                            _StatusChip(
                              label: OrderStatusStyle.of(status).label,
                              selected: _status == status,
                              onTap: () => setState(() => _status = _status == status ? null : status),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      const EmptyState(
                        icon: LucideIcons.searchX,
                        title: 'No orders match',
                        description: 'Try a different search or status.',
                      )
                    else
                      for (final entry in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PortalCard(
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: entry.order.artwork == null
                                            ? ColoredBox(color: theme.colorScheme.surfaceContainerHighest)
                                            : ArtworkImageView(url: entry.order.artwork!.thumbnailUrl),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.order.artwork?.title ?? entry.order.artworkId,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Order ${entry.order.id}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          Text(
                                            'Placed ${formatShortDate(entry.order.createdAt)}',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    OrderStatusChip(status: entry.order.status),
                                  ],
                                ),
                                const Divider(height: 20),
                                PortalDetailRow(label: 'Buyer paid', value: formatInr(entry.order.total)),
                                PortalDetailRow(label: 'Your payout', value: formatInr(entry.artistPayout), gold: true),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
