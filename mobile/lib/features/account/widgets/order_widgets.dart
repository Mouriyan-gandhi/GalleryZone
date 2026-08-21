import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/order.dart';
import '../../marketplace/widgets/artwork_card.dart';

/// Status label, glyph and colour for every `OrderStatus`, ported from
/// `order-list.tsx`'s `STATUS_CONFIG`. The traffic-light hues are the one
/// deliberate exception to the gold-only palette — order state is
/// information the collector reads at a glance, not brand surface.
class OrderStatusStyle {
  const OrderStatusStyle(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static const _sky = Color(0xFF38BDF8);
  static const _amber = Color(0xFFFBBF24);
  static const _emerald = Color(0xFF34D399);

  static OrderStatusStyle of(OrderStatus status) => switch (status) {
        OrderStatus.pending => const OrderStatusStyle('Pending', LucideIcons.clock3, Color(0xFF9C9686)),
        OrderStatus.paid => const OrderStatusStyle('Paid', LucideIcons.wallet, _sky),
        OrderStatus.confirmed => const OrderStatusStyle('Confirmed', LucideIcons.circleCheckBig, _sky),
        OrderStatus.packed => const OrderStatusStyle('Packed', LucideIcons.packageCheck, _amber),
        OrderStatus.transit => const OrderStatusStyle('In transit', LucideIcons.truck, _amber),
        OrderStatus.delivered => const OrderStatusStyle('Delivered', LucideIcons.checkCheck, _emerald),
        OrderStatus.cancelled => const OrderStatusStyle('Cancelled', LucideIcons.circleX, AppColors.destructive),
      };

  /// The timeline's wording differs from the chip's — "Order placed" reads
  /// as an event, "Pending" as a state.
  static String timelineLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Order placed',
        OrderStatus.paid => 'Payment received',
        OrderStatus.confirmed => 'Order confirmed',
        OrderStatus.packed => 'Packed for dispatch',
        OrderStatus.transit => 'In transit',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Order cancelled',
      };
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = OrderStatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(color: style.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.color),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: style.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the order list — thumbnail, artwork, placed-on date, status,
/// total. Tapping opens the order detail.
class OrderRow extends StatelessWidget {
  const OrderRow({super.key, required this.order, required this.artwork});

  final Order order;
  final Artwork? artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/account/orders/${order.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: artwork == null
                    ? ColoredBox(color: theme.colorScheme.surfaceContainerHighest)
                    : ArtworkImageView(url: artwork!.thumbnailUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork?.title ?? 'Artwork no longer available',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (artwork != null)
                    Text(
                      artwork!.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 2),
                  Text('Placed ${formatShortDate(order.createdAt)}',
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OrderStatusChip(status: order.status),
                const SizedBox(height: 8),
                PriceTag(amount: order.total, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Same vertical timeline as the artwork passport's provenance record,
/// with an order-shaped source and label set.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.history});

  final List<OrderStatusEvent> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ordered = [...history]
      ..sort((a, b) => DateTime.parse(a.changedAt).compareTo(DateTime.parse(b.changedAt)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order status', style: theme.textTheme.titleLarge),
        const SizedBox(height: 18),
        for (var i = 0; i < ordered.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final isCancelled = ordered[i].status == OrderStatus.cancelled;
                        final tint = isCancelled
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary;
                        return Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardTheme.color,
                            border: Border.all(color: tint.withValues(alpha: 0.4)),
                          ),
                          child: Icon(
                            isCancelled ? LucideIcons.circleX : LucideIcons.check,
                            size: 12,
                            color: isCancelled ? theme.colorScheme.error : theme.colorScheme.tertiary,
                          ),
                        );
                      },
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
                          OrderStatusStyle.timelineLabel(ordered[i].status),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(formatShortDate(ordered[i].changedAt),
                            style: theme.textTheme.labelSmall),
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

/// Displays the amounts already sitting on the order record. It never
/// recomputes GST/delivery — that math's single source of truth is
/// `mock_checkout_repository.dart`, applied once when the order is placed.
class OrderPriceBreakdown extends StatelessWidget {
  const OrderPriceBreakdown({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price breakdown', style: theme.textTheme.titleLarge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              _row(context, 'Artwork price', order.amount),
              _row(context, 'GST', order.gstAmount),
              _row(context, 'Delivery', order.deliveryCharge),
              const Divider(height: 20),
              _row(context, 'Total paid', order.total, emphasized: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, double amount, {bool emphasized = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasized
                ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                : theme.textTheme.bodySmall,
          ),
          PriceTag(
            amount: amount,
            style: emphasized ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
