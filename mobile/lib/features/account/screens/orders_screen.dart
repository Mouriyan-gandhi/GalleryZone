import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';
import '../widgets/order_widgets.dart';

/// Port of `app/account/orders/page.tsx` + `order-list.tsx`.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const path = '/account/orders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final artworks = ref.watch(artworksByIdProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.packageSearch,
          title: "Couldn't load your orders",
          description:
              'Something went wrong loading your order history. Pull to refresh '
              'and try again.',
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: LucideIcons.packageSearch,
                title: 'No orders yet',
                description:
                    'Everything you buy on GalleryZone will show up here, with '
                    'full status tracking.',
                action: OutlinedButton(
                  onPressed: () => context.push('/marketplace'),
                  child: const Text('Browse the marketplace'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(ordersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ContentWidth(
                    child: OrderRow(
                      order: list[index],
                      artwork: artworks[list[index].artworkId],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Port of `app/account/orders/[orderId]/page.tsx` — the item, its status
/// timeline, the price breakdown, and where it's going.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  static const path = '/account/orders/:orderId';

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final order = ref.watch(orderProvider(orderId));
    final artworks = ref.watch(artworksByIdProvider).value ?? const {};
    final addresses = ref.watch(addressesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.packageSearch,
          title: "Couldn't load this order",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (data) {
          if (data == null) {
            return const EmptyState(
              icon: LucideIcons.packageSearch,
              title: 'Order not found',
              description: 'This order is no longer in your history.',
            );
          }
          final artwork = artworks[data.artworkId];
          final address = addresses.where((a) => a.id == data.addressId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artwork != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: SizedBox(
                              width: 88,
                              height: 110,
                              child: ArtworkImageView(url: artwork.thumbnailUrl),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork?.title ?? 'Artwork no longer available',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (artwork != null) ...[
                                const SizedBox(height: 4),
                                Text(artwork.artistName, style: theme.textTheme.bodySmall),
                              ],
                              const SizedBox(height: 8),
                              OrderStatusChip(status: data.status),
                              const SizedBox(height: 8),
                              Text(
                                'Placed ${formatLongDate(data.createdAt)}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (artwork != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => context.push('/marketplace/${artwork.id}'),
                            icon: const Icon(LucideIcons.externalLink, size: 14),
                            label: const Text('View listing'),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/verify/${artwork.id}'),
                            icon: const Icon(LucideIcons.scanLine, size: 14),
                            label: const Text('Passport'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    OrderStatusTimeline(history: data.statusHistory),
                    const SizedBox(height: 28),
                    OrderPriceBreakdown(order: data),
                    if (address != null) ...[
                      const SizedBox(height: 28),
                      Text('Delivery address', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        [
                          address.line1,
                          address.line2,
                          '${address.city}, ${address.state} ${address.pincode}',
                        ].whereType<String>().join('\n'),
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
