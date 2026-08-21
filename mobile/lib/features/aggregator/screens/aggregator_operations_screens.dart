import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Sale rows need their artwork's title and floor price, and the holding's
/// display price for the commission. Joining once here beats three lookups
/// per row in three different screens.
class _SaleRow {
  const _SaleRow({required this.sale, this.artwork, this.holding});

  final AggregatorSale sale;
  final Artwork? artwork;
  final AggregatorHolding? holding;

  String get title => artwork?.title ?? sale.artworkId;

  double get commission => artwork == null || holding == null
      ? 0
      : aggregatorCommissionFor(
          displayPrice: holding!.displayPrice,
          customerPrice: artwork!.customerPrice,
        );
}

/// Sales joined to their artwork and holding. Reads the same two providers
/// the rest of the portal does, so a sale recorded a second ago is here.
final _saleRowsProvider = FutureProvider.autoDispose<List<_SaleRow>>((ref) async {
  final sales = await ref.watch(aggregatorSalesProvider.future);
  final collection = await ref.watch(aggregatorCollectionProvider.future);
  final byHoldingId = {for (final view in collection) view.holding.id: view};
  return [
    for (final sale in sales)
      _SaleRow(
        sale: sale,
        artwork: byHoldingId[sale.holdingId]?.artwork,
        holding: byHoldingId[sale.holdingId]?.holding,
      ),
  ];
});

/// Port of `features/aggregator/sales-table.tsx`.
class AggregatorOrdersScreen extends ConsumerWidget {
  const AggregatorOrdersScreen({super.key});

  static const path = '/aggregator/dashboard/orders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(_saleRowsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders & sales')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your sales",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.shoppingBag,
                title: 'No sales yet',
                description: 'Record a sale from My Inventory to see it here.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ProvisionalCommissionNotice(),
                        const SizedBox(height: 12),
                        for (final row in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SaleCard(row: row),
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

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.row});

  final _SaleRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sale = row.sale;

    return PortalCard(
      child: Column(
        children: [
          Row(
            children: [
              if (row.artwork != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: ArtworkImageView(url: row.artwork!.thumbnailUrl),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text('${sale.buyerName} · ${formatShortDate(sale.soldAt)}',
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              ShipmentStatusPill(status: sale.shipmentStatus),
            ],
          ),
          const Divider(height: 20),
          PortalDetailRow(label: 'Sold price', value: formatInr(sale.soldPrice)),
          PortalDetailRow(
            label: 'Commission (provisional)',
            value: formatInr(row.commission),
            gold: true,
          ),
          PortalDetailRow(label: 'Buyer email', value: sale.buyerEmail),
          PortalDetailRow(label: 'Buyer phone', value: sale.buyerPhone),
          PortalDetailRow(
            label: 'Delivery',
            value: sale.deliveryMode == DeliveryMode.courier
                ? sale.courierRef ?? 'Courier'
                : 'Self pickup',
          ),
          PortalDetailRow(
            label: 'Address',
            value: '${sale.deliveryAddress.line1}, ${sale.deliveryAddress.city}, '
                '${sale.deliveryAddress.state} ${sale.deliveryAddress.pincode}',
          ),
        ],
      ),
    );
  }
}

/// Port of `features/aggregator/customers-table.tsx`.
class AggregatorCustomersScreen extends ConsumerWidget {
  const AggregatorCustomersScreen({super.key});

  static const path = '/aggregator/dashboard/customers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customers = ref.watch(aggregatorCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your customers",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: LucideIcons.users,
                title: 'No customers yet',
                description: 'Buyers from your recorded sales show up here.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionIntro(
                          text: 'Rolled up from your recorded sales, one row per buyer.',
                        ),
                        for (final customer in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PortalCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customer.buyerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        '${customer.orderCount} '
                                        'order${customer.orderCount == 1 ? '' : 's'}',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  PortalDetailRow(
                                      label: 'Email', value: customer.buyerEmail),
                                  PortalDetailRow(
                                      label: 'Phone', value: customer.buyerPhone),
                                  PortalDetailRow(
                                    label: 'Total spend',
                                    value: formatInr(customer.totalSpend),
                                    gold: true,
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

/// Port of `features/aggregator/shipping-table.tsx` — inbound pieces on
/// their way to the premises, and outbound deliveries to buyers.
class AggregatorShippingScreen extends ConsumerWidget {
  const AggregatorShippingScreen({super.key});

  static const path = '/aggregator/dashboard/shipping';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(aggregatorCollectionProvider).value ?? const [];
    final sales = ref.watch(aggregatorSalesProvider).value;
    final inbound = collection
        .where((view) => view.holding.status == HoldingStatus.reserved)
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping & logistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Inbound', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                // Illustrative, and said so on screen: the data model has no
                // "in transit to the aggregator" state distinct from a
                // holding being reserved (SAD §2.7), so this surfaces
                // reserved holdings rather than inventing a tracking state
                // machine that nothing writes to.
                const SectionIntro(
                  text: 'Pieces assigned to you or reserved by you, en route to your '
                      'premises. Transit tracking is not modelled yet — this reflects '
                      'your current reservations.',
                ),
                if (inbound.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.packageSearch,
                    title: 'Nothing inbound',
                    description: 'Reserve an artwork from Browse to see it here.',
                  )
                else
                  for (final view in inbound)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PortalCard(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: ArtworkImageView(url: view.artwork.thumbnailUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                view.artwork.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const StatusPill(
                              label: 'Due for pickup',
                              color: Color(0xFF38BDF8),
                              icon: LucideIcons.truck,
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Text('Outbound', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                const SectionIntro(text: 'Post-sale shipments to buyers.'),
                if (sales == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (sales.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.packageCheck,
                    title: 'No outbound shipments yet',
                    description: 'Recorded sales appear here for dispatch tracking.',
                  )
                else
                  for (final sale in sales)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ShipmentCard(sale: sale),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  const _ShipmentCard({required this.sale});

  final AggregatorSale sale;

  static const _nextAction = <ShipmentStatus, String?>{
    ShipmentStatus.preparing: 'Mark dispatched',
    ShipmentStatus.dispatched: 'Mark delivered',
    ShipmentStatus.delivered: null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final action = _nextAction[sale.shipmentStatus];

    return PortalCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      sale.deliveryMode == DeliveryMode.courier
                          ? sale.courierRef ?? 'Courier'
                          : 'Self pickup',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              ShipmentStatusPill(status: sale.shipmentStatus),
            ],
          ),
          const SizedBox(height: 6),
          PortalDetailRow(
            label: 'Deliver to',
            value: '${sale.deliveryAddress.line1}, ${sale.deliveryAddress.city} '
                '${sale.deliveryAddress.pincode}',
          ),
          if (sale.dispatchedAt != null)
            PortalDetailRow(
                label: 'Dispatched', value: formatShortDate(sale.dispatchedAt!)),
          if (sale.deliveredAt != null)
            PortalDetailRow(
                label: 'Delivered', value: formatShortDate(sale.deliveredAt!)),
          if (action != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: () => _advance(context, ref),
                child: Text(action),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    try {
      final updated =
          await ref.read(aggregatorRepositoryProvider).advanceShipment(sale.id);
      ref.invalidate(aggregatorSalesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shipment marked ${updated.shipmentStatus.name}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}
