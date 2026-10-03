import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import 'portal_widgets.dart';

// The pieces of an analytics page that are the same in every portal: a headline
// number, the frame a chart sits in, horizontal bars, and the empty state of a
// chart with nothing to plot. The artist and aggregator Analytics pages both
// draw from here, as the website's two share its chart components.

/// A headline figure under a small-caps label.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});

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

/// The frame every chart sits in: a title, one line on what is plotted, and the plot.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.description, required this.child});

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

/// One bar: its name, its size, and the figure written beside it.
typedef BarRow = ({String label, double value, String text});

/// Horizontal bars, every one the same colour and each labelled with its own
/// figure, so the number is there without hovering. A funnel fades down its stages
/// ([fade]): they are in order, and the intensity says so.
class BarList extends StatelessWidget {
  const BarList({
    super.key,
    required this.rows,
    required this.emptyTitle,
    required this.emptyDescription,
    this.fade = false,
  });

  final List<BarRow> rows;
  final String emptyTitle;
  final String emptyDescription;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = rows.fold<double>(0, (max, r) => r.value > max ? r.value : max);
    // A chart with nothing in any bar has nothing to show.
    if (rows.isEmpty || top == 0) return ChartEmpty(title: emptyTitle, description: emptyDescription);

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

/// What a chart says when there is nothing to plot.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty({super.key, required this.title, required this.description});

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
