import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/mock/seed/aggregator_seed.dart';
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

/// Port of `features/aggregator/analytics-view.tsx`. Every tile and the
/// category chart are derived from live sales; only the sell-through trend
/// is demonstration data, and it says so.
class AggregatorAnalyticsScreen extends ConsumerWidget {
  const AggregatorAnalyticsScreen({super.key});

  static const path = '/aggregator/dashboard/analytics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(aggregatorAnalyticsProvider).value;
    final categories = ref.watch(aggregatorCategoryPerformanceProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: WindowSize.of(context).isCompact ? 2 : 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.9,
                        children: [
                          _Stat(label: 'Sales recorded', value: '${summary.salesCount}'),
                          _Stat(
                              label: 'Total revenue',
                              value: formatInr(summary.totalRevenue)),
                          _Stat(
                              label: 'Avg. sold price',
                              value: formatInr(summary.averageSoldPrice)),
                          _Stat(
                              label: 'Avg. markup',
                              value: formatInr(summary.averageDisplayMarkup)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Sell-through rate', style: theme.textTheme.titleLarge),
                      Text(
                        'Demonstration trend — illustrative, not derived from your '
                        'sales.',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 12),
                      const _SellThroughChart(),
                      const SizedBox(height: 24),
                      Text('Top categories moved', style: theme.textTheme.titleLarge),
                      Text('Revenue from your recorded sales, by category.',
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: 12),
                      if (categories.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.chartColumn,
                          title: 'Nothing sold yet',
                          description:
                              'Record a sale and its category shows up in this '
                              'breakdown.',
                        )
                      else
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CategoryRow(
                              category: category,
                              maxRevenue: categories
                                  .map((c) => c.revenue)
                                  .reduce((a, b) => a > b ? a : b),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellThroughChart extends StatelessWidget {
  const _SellThroughChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = aggregatorSellThroughSeries;

    return PortalCard(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: theme.colorScheme.outline, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  // One tick per point. Without this fl_chart picks its own
                  // sub-integer interval and draws each month twice.
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) return const SizedBox();
                    return Text(points[index].month, style: theme.textTheme.labelSmall);
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].rate),
                ],
                isCurved: true,
                barWidth: 2,
                color: theme.colorScheme.tertiary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.maxRevenue});

  final CategoryPerformance category;
  final double maxRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titleCase(category.category), style: theme.textTheme.bodyMedium),
              ),
              Text(
                formatInr(category.revenue),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: maxRevenue <= 0 ? 0 : category.revenue / maxRevenue,
            minHeight: 5,
            backgroundColor: theme.colorScheme.outline,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.tertiary),
          ),
          const SizedBox(height: 4),
          Text('${category.orders} sold', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
