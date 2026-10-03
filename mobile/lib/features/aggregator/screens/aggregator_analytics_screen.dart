import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../artist/analytics.dart' show formatCompactInr;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../shell/chart_widgets.dart';
import '../providers/aggregator_providers.dart';

/// Port of `features/aggregator/analytics-view.tsx`: four headline figures from the
/// recorded sales, and which categories they came from.
class AggregatorAnalyticsScreen extends ConsumerWidget {
  const AggregatorAnalyticsScreen({super.key});

  static const path = '/aggregator/dashboard/analytics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(aggregatorAnalyticsProvider);
    final categoriesAsync = ref.watch(aggregatorCategoryPerformanceProvider);
    final summary = summaryAsync.value;

    if (summary == null && summaryAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your analytics",
          description: authErrorMessage(summaryAsync.error!),
          action: OutlinedButton(
            onPressed: () {
              ref.invalidate(aggregatorAnalyticsProvider);
              ref.invalidate(aggregatorCategoryPerformanceProvider);
            },
            child: const Text('Try again'),
          ),
        ),
      );
    }

    // A dash while the figure is still on its way, as the website shows.
    String figure(String Function(double) format, double? value) => value == null ? '—' : format(value);
    Widget stat(String label, String value) => Expanded(child: StatCard(label: label, value: value));

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorAnalyticsProvider);
          ref.invalidate(aggregatorCategoryPerformanceProvider);
          await ref.read(aggregatorAnalyticsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stat('Sales recorded', summary == null ? '—' : '${summary.salesCount}'),
                      const SizedBox(width: 12),
                      stat('Total revenue', figure(formatInr, summary?.totalRevenue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stat('Avg. sold price', figure(formatInr, summary?.averageSoldPrice)),
                      const SizedBox(width: 12),
                      stat('Avg. display markup', figure(formatInr, summary?.averageDisplayMarkup)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChartCard(
                    title: 'Top categories moved',
                    description: 'Revenue from your recorded sales, by artwork category.',
                    child: categoriesAsync.when(
                      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                      error: (error, stack) => ChartEmpty(
                        title: "Couldn't load your categories",
                        description: authErrorMessage(error),
                      ),
                      data: (categories) => BarList(
                        emptyTitle: 'No category revenue yet',
                        emptyDescription: 'Revenue appears here once you record a sale.',
                        rows: [
                          for (final category in [...categories]..sort((a, b) => b.revenue.compareTo(a.revenue)))
                            (
                              label: humanize(category.category),
                              value: category.revenue,
                              text: formatCompactInr(category.revenue),
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
