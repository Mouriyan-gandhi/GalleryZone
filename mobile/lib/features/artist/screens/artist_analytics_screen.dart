import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart' show SocialProofPlatform;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart' show EmptyState;
import '../../marketplace/widgets/social_glyphs.dart';
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
                        _ChartCard(
                          title: 'Revenue trend',
                          description: 'Your settled earnings, last 6 months.',
                          child: _RevenueChart(series: revenueSeries(transactionsAsync.value ?? const [])),
                        ),
                        const SizedBox(height: 12),
                        _ChartCard(
                          title: 'Revenue by category',
                          description: 'Your own settled sales, by category.',
                          child: _Bars(
                            emptyTitle: 'No category revenue yet',
                            emptyDescription: 'No category has recorded a settled sale.',
                            rows: [
                              for (final c in categoryPerformance(artworks))
                                (label: humanize(c.category), value: c.revenue, text: formatCompactInr(c.revenue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChartCard(
                          title: 'Artwork status',
                          description: 'Where your artworks currently sit, by count.',
                          child: _Bars(
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
    Widget stat(String label, String value) => Expanded(child: _Stat(label: label, value: value));
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
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleLarge),
          ),
        ],
      ),
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

/// The frame every chart on this page sits in: a title, one line on what is
/// plotted, and the plot.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.description, required this.child});

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          child,
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
      return const _Empty(title: 'No revenue yet', description: 'Settled sales will show up here.');
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

typedef _BarRow = ({String label, double value, String text});

/// Horizontal bars, every one the same colour and each labelled with its own
/// figure, so the number is there without hovering. The funnel fades down the
/// pipeline ([fade]): the stages are in order, and the intensity says so.
class _Bars extends StatelessWidget {
  const _Bars({required this.rows, required this.emptyTitle, required this.emptyDescription, this.fade = false});

  final List<_BarRow> rows;
  final String emptyTitle;
  final String emptyDescription;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = rows.fold<double>(0, (max, r) => r.value > max ? r.value : max);
    // A funnel with nothing in any stage has nothing to show.
    if (rows.isEmpty || top == 0) return _Empty(title: emptyTitle, description: emptyDescription);

    return Semantics(
      label: rows.map((r) => '${r.label} ${r.text}').join(', '),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(rows[i].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth * (rows[i].value / top);
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: width < 3 && rows[i].value > 0 ? 3 : width,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: fade ? (1 - i * 0.2).clamp(0.3, 1.0) : 0.9,
                              ),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppRadius.sm)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(rows[i].text, textAlign: TextAlign.right, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(LucideIcons.chartNoAxesColumn, size: 24, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(description, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
