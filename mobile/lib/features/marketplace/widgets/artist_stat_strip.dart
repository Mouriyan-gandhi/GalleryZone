import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist_network.dart';
import '../artist_stats.dart';

/// Works listed, works sold, price range and join date, then the rating and
/// the mediums they work in - port of the website's `artist-stat-strip.tsx`.
class ArtistStatStrip extends StatelessWidget {
  const ArtistStatStrip({super.key, required this.stats, this.rating});

  final ArtistPublicStats stats;

  /// Shown only once at least one collector has rated; never a made-up zero.
  final ArtistRating? rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = stats.priceLow;
    final high = stats.priceHigh;
    final range = low == null || high == null
        ? '—'
        : low == high
            ? formatInr(low)
            : '${formatInr(low)} – ${formatInr(high)}';
    final cells = [
      _Cell('Works listed', '${stats.artworksListed}'),
      _Cell('Works sold', '${stats.worksSold}'),
      _Cell('Price range', range, hint: low == null ? null : 'Listed price, GST included'),
      _Cell('On GalleryZone since', stats.joinedLabel),
    ];
    final reviews = rating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outline)),
            child: Column(
              children: [
                for (var row = 0; row < cells.length; row += 2) ...[
                  if (row > 0) Divider(height: 1, color: theme.colorScheme.outline),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatCell(cell: cells[row])),
                        VerticalDivider(width: 1, color: theme.colorScheme.outline),
                        Expanded(child: _StatCell(cell: cells[row + 1])),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (reviews != null && reviews.count > 0) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 6),
              Text(
                reviews.average.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'from ${reviews.count} ${reviews.count == 1 ? 'collector' : 'collectors'}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        if (stats.mediums.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final medium in stats.mediums.take(5))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(humanize(medium), style: theme.textTheme.labelMedium),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Cell {
  const _Cell(this.label, this.value, {this.hint});

  final String label;
  final String value;
  final String? hint;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.cell});

  final _Cell cell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cell.label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(
              cell.value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (cell.hint != null) Text(cell.hint!, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
