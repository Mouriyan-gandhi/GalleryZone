import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/mock/seed/artist_seed.dart';
import '../../../data/models/artwork.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/artist-analytics-view.tsx`. Revenue history
/// is a fixture (there is no ledger to derive it from); everything below it
/// is computed from the artist's own artworks and orders.
class ArtistAnalyticsScreen extends ConsumerWidget {
  const ArtistAnalyticsScreen({super.key});

  static const path = '/dashboard/analytics';

  static const _soldStatuses = {ArtworkStatus.sold, ArtworkStatus.settlementComplete};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworks = ref.watch(artistArtworksProvider).value ?? const [];
    final orders = ref.watch(artistOrdersProvider).value ?? const [];
    final series = artistRevenueSeries();

    final totalPayout = orders.fold<double>(0, (sum, entry) => sum + entry.artistPayout);
    final averageSale = orders.isEmpty ? 0.0 : totalPayout / orders.length;

    final byCategory = <String, double>{};
    for (final entry in artworks) {
      if (_soldStatuses.contains(entry.artwork.status)) {
        byCategory.update(
          entry.artwork.category,
          (value) => value + entry.artwork.customerPrice,
          ifAbsent: () => entry.artwork.customerPrice,
        );
      }
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            maxWidth: 820,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revenue', style: theme.textTheme.titleMedium),
                      Text('Last 6 months', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: theme.colorScheme.outline,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) => Text(
                                    '${(value / 1000).round()}k',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.round();
                                    if (index < 0 || index >= series.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(series[index].month,
                                          style: theme.textTheme.labelSmall),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: theme.colorScheme.tertiary,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                ),
                                spots: [
                                  for (var i = 0; i < series.length; i++)
                                    FlSpot(i.toDouble(), series[i].amount),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: WindowSize.of(context).isCompact ? 2 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _Stat(label: 'Sales', value: '${orders.length}'),
                    _Stat(label: 'Payouts', value: formatInr(totalPayout)),
                    _Stat(label: 'Average sale', value: formatInr(averageSale)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('By category', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  Text(
                    'Nothing sold yet — category performance appears after your '
                    'first sale.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  for (final entry in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PortalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(titleCase(entry.key), style: theme.textTheme.bodyMedium),
                                Text(formatInr(entry.value),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: entry.value / categories.first.value,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.outline,
                                valueColor:
                                    AlwaysStoppedAnimation(theme.colorScheme.tertiary),
                              ),
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
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
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
