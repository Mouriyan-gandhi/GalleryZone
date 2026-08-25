import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/payee_details.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `features/aggregator/settlements-table.tsx`. This is the one
/// settlements screen in the app where `aggregatorCommission` is the figure
/// that matters — the artist's equivalent leads with `artistAmount`.
///
/// Sales awaiting settlement are listed alongside processed ones, because
/// "simulate settlement" is the action that moves pending commission into
/// the withdrawable balance and nothing else in the app triggers it.
class AggregatorSettlementsScreen extends ConsumerWidget {
  const AggregatorSettlementsScreen({super.key});

  static const path = '/aggregator/dashboard/settlements';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settlements = ref.watch(aggregatorSettlementsProvider).value ?? const [];
    final sales = ref.watch(aggregatorSalesProvider).value;
    final settledSaleIds = settlements.map((s) => s.orderId).toSet();
    final awaiting =
        (sales ?? const []).where((s) => !settledSaleIds.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: sales == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The obligation goes above the entitlements. Mixing
                      // the two is how people end up netting off.
                      const _OwedToGalleryZone(),
                      const WalletMechanicsNotice(),
                      const SizedBox(height: 16),
                      if (awaiting.isNotEmpty) ...[
                        Text('Awaiting settlement', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        for (final sale in awaiting)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AwaitingCard(sale: sale),
                          ),
                        const SizedBox(height: 16),
                      ],
                      Text('Processed', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (settlements.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.landmark,
                          title: 'No settlements yet',
                          description:
                              'A commission breakdown appears here once a sale is '
                              'settled.',
                        )
                      else
                        for (final settlement in settlements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SettlementCard(settlement: settlement),
                          ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AwaitingCard extends ConsumerWidget {
  const _AwaitingCard({required this.sale});

  final AggregatorSale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sale ${sale.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SettlementStatusPill(status: SettlementStatus.pending),
            ],
          ),
          PortalDetailRow(label: 'Buyer', value: sale.buyerName),
          PortalDetailRow(label: 'Sold', value: formatShortDate(sale.soldAt)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () => _process(context, ref),
              child: const Text('Simulate settlement'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _process(BuildContext context, WidgetRef ref) async {
    try {
      final settlement =
          await ref.read(aggregatorRepositoryProvider).processSettlement(sale.id);
      invalidateAggregatorSaleFlow(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatInr(settlement.aggregatorCommission)} moved to your available '
            'balance',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      settlement.artworkTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text('Sale ${settlement.orderId}',
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              SettlementStatusPill(status: settlement.status),
            ],
          ),
          const Divider(height: 20),
          PortalDetailRow(
            label: 'Your commission',
            value: formatInr(settlement.aggregatorCommission),
            gold: true,
          ),
          PortalDetailRow(
            label: 'Processed',
            value: settlement.processedAt == null
                ? 'Not yet'
                : formatShortDate(settlement.processedAt!),
          ),
        ],
      ),
    );
  }
}

/// Cash the aggregator took at the counter belongs to GalleryZone, and the
/// WHOLE sale price is owed — not the sale less commission. Their commission
/// is settled separately, in the table below this card.
class _OwedToGalleryZone extends ConsumerWidget {
  const _OwedToGalleryZone();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final due = ref.watch(aggregatorRemittancesDueProvider).value ?? const [];
    if (due.isEmpty) return const SizedBox.shrink();

    final total = due.fold(0.0, (sum, sale) => sum + sale.soldPrice);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PortalCard(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owed to GalleryZone',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Cash you collected on GalleryZone's behalf. Transfer "
                        'the full amount — your commission is settled '
                        'separately, below.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PriceTag(amount: total, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            for (final sale in due)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.buyerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Sold ${formatShortDate(sale.soldAt)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    PriceTag(amount: sale.soldPrice, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _markRemitted(context, ref, sale),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Transferred'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            PayeeDetails(
              amount: total,
              note: 'GZ remittance — ${due.length} sale'
                  '${due.length > 1 ? 's' : ''}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRemitted(
    BuildContext context,
    WidgetRef ref,
    AggregatorSale sale,
  ) async {
    try {
      await ref.read(aggregatorRepositoryProvider).markRemitted(sale.id);
      invalidateAggregatorSaleFlow(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as transferred')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}
