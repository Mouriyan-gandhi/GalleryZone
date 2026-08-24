import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
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
                      const ProvisionalCommissionNotice(),
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
