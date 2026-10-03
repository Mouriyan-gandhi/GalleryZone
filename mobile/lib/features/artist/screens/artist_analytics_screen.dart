import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/artwork.dart' show SocialProofPlatform;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../marketplace/widgets/social_glyphs.dart';
import '../../shell/chart_widgets.dart';
import '../../shell/portal_widgets.dart';
import '../analytics.dart';
import '../providers/artist_providers.dart';

/// Port of `features/dashboard/artist-analytics-view.tsx`: how the artist's work
/// is doing - the headline numbers, where their Instagram handle stands, the
/// last six months of settled earnings, which categories sell, and where their
/// pieces sit in the pipeline.
class ArtistAnalyticsScreen extends ConsumerWidget {
  const ArtistAnalyticsScreen({super.key});

  static const path = '/dashboard/analytics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworksAsync = ref.watch(artistArtworksProvider);
    final ordersAsync = ref.watch(artistOrdersProvider);
    final transactionsAsync = ref.watch(artistWalletTransactionsProvider);
    final artworks = artworksAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: artworks == null
          ? artworksAsync.hasError
              ? EmptyState(
                  icon: LucideIcons.triangleAlert,
                  title: "Couldn't load your analytics",
                  description: authErrorMessage(artworksAsync.error!),
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(artistArtworksProvider),
                    child: const Text('Try again'),
                  ),
                )
              : const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(artistArtworksProvider);
                ref.invalidate(artistOrdersProvider);
                ref.invalidate(artistWalletTransactionsProvider);
                await ref.read(artistArtworksProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Summary(
                          summary: analyticsSummary(artworks: artworks, orders: ordersAsync.value ?? const []),
                        ),
                        const SizedBox(height: 12),
                        const _InstagramCard(),
                        const SizedBox(height: 12),
                        ChartCard(
                          title: 'Revenue trend',
                          description: 'Your settled earnings, last 6 months.',
                          child: _RevenueChart(series: revenueSeries(transactionsAsync.value ?? const [])),
                        ),
                        const SizedBox(height: 12),
                        ChartCard(
                          title: 'Revenue by category',
                          description: 'Your own settled sales, by category.',
                          child: BarList(
                            emptyTitle: 'No category revenue yet',
                            emptyDescription: 'No category has recorded a settled sale.',
                            rows: [
                              for (final c in categoryPerformance(artworks))
                                (label: humanize(c.category), value: c.revenue, text: formatCompactInr(c.revenue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ChartCard(
                          title: 'Artwork status',
                          description: 'Where your artworks currently sit, by count.',
                          child: BarList(
                            emptyTitle: 'No artworks submitted yet',
                            emptyDescription: 'Nothing has entered the lifecycle so far.',
                            fade: true,
                            rows: [
                              for (final stage in artworkFunnel(artworks))
                                (label: stage.stage, value: stage.count.toDouble(), text: formatCompactCount(stage.count.toDouble())),
                            ],
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

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(child: StatCard(label: label, value: value));
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stat('Total artworks', '${summary.artworks}'),
            const SizedBox(width: 12),
            stat('Total sales', '${summary.sales}'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stat('Total revenue', formatInr(summary.revenue)),
            const SizedBox(width: 12),
            stat('Avg. sale price', formatInr(summary.averageSale)),
          ],
        ),
      ],
    );
  }
}

/// The handle itself is collected once, on the Profile page (it is a required,
/// private field there). This card is where the artist sees and manages that
/// connection beside their other performance data, rather than analytics
/// quietly reading a field it doesn't own.
class _InstagramCard extends ConsumerStatefulWidget {
  const _InstagramCard();

  @override
  ConsumerState<_InstagramCard> createState() => _InstagramCardState();
}

class _InstagramCardState extends ConsumerState<_InstagramCard> {
  final _handle = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(artistProfileDetailsProvider).value;
    if (profile == null || _handle.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(artistRepositoryProvider).updateProfile(profile.copyWith(instagram: _handle.text.trim()));
      ref.invalidate(artistProfileDetailsProvider);
      if (!mounted) return;
      setState(() => _editing = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(artistProfileDetailsProvider).value;
    if (profile == null) return const SizedBox.shrink();
    final connected = profile.instagram.trim().isNotEmpty;

    if (!_editing) {
      return PortalCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: SocialGlyph(platform: SocialProofPlatform.instagram, size: 16, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instagram', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  Text(
                    connected ? '@${profile.instagram.replaceFirst(RegExp(r'^@'), '')}' : 'Not connected',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (connected) ...[
              const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              const Text('Connected', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () => setState(() {
                _handle.text = profile.instagram;
                _editing = true;
              }),
              child: Text(connected ? 'Update' : 'Connect'),
            ),
          ],
        ),
      );
    }

    return PortalCard(
      gold: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _handle,
            autofocus: true,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Instagram handle',
              hintText: 'yourhandle',
              helperText: 'This is the same handle saved on your Profile page.',
              errorText: _error,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: SocialGlyph(platform: SocialProofPlatform.instagram, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _editing = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Monthly settled earnings as an area under a line. Nothing is invented: a
/// month without a sale sits on the floor.
class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.series});

  final List<RevenuePoint> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = series.fold<double>(0, (sum, p) => sum + p.amount);
    if (total == 0) {
      return const ChartEmpty(title: 'No revenue yet', description: 'Settled sales will show up here.');
    }
    final top = series.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final gold = theme.colorScheme.tertiary;
    final label = theme.textTheme.labelSmall;

    return Semantics(
      label: 'Area chart of monthly revenue, last 6 months, totaling ${formatInr(total)}.',
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: top * 1.15,
            minX: 0,
            maxX: (series.length - 1).toDouble(),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outline, strokeWidth: 0.6),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min && value != 0) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(formatCompactInr(value), style: label),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= series.length || (value - i).abs() > 0.001) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, child: Text(series[i].month, style: label));
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${series[spot.x.round()].month}\n${formatInr(spot.y)}',
                      theme.textTheme.labelMedium!.copyWith(color: Colors.white),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].amount)],
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                color: gold,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: gold.withValues(alpha: 0.25)),
              ),
            ],
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}
