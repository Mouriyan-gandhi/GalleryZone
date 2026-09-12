import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../account/providers/account_providers.dart';
import '../../account/widgets/order_widgets.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/orders-table.tsx` — orders for this artist's
/// pieces, each showing what she actually receives rather than what the
/// buyer paid. The "Sales" tab of [ArtistSalesScreen] — no Scaffold/AppBar
/// of its own, since it never appears outside that tabbed screen.
class ArtistOrdersTab extends ConsumerWidget {
  const ArtistOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orders = ref.watch(artistOrdersProvider);
    final artworks = ref.watch(artworksByIdProvider).value ?? const {};

    return orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.packageSearch,
          title: "Couldn't load your orders",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.packageSearch,
                title: 'No orders yet',
                description:
                    'When a collector buys one of your pieces, the order and your '
                    'payout show up here.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(artistOrdersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = list[index];
                    final artwork = artworks[entry.order.artworkId];
                    return ContentWidth(
                      child: PortalCard(
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (artwork != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: ArtworkImageView(url: artwork.thumbnailUrl),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artwork?.title ?? entry.order.artworkId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Placed ${formatShortDate(entry.order.createdAt)}',
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                                OrderStatusChip(status: entry.order.status),
                              ],
                            ),
                            const Divider(height: 20),
                            PortalDetailRow(
                              label: 'Buyer paid',
                              value: formatInr(entry.order.total),
                            ),
                            PortalDetailRow(
                              label: 'Your payout',
                              value: formatInr(entry.artistPayout),
                              gold: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
