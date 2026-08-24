import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/mock/seed/aggregator_seed.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../shell/portal_menu.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `app/aggregator/dashboard/page.tsx` — KPI cards, the commission
/// explainer, a recent-activity rail, and the entry points the web keeps in
/// its sidebar.
class AggregatorDashboardScreen extends ConsumerWidget {
  const AggregatorDashboardScreen({super.key});

  static const path = '/aggregator/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(aggregatorDashboardProvider).value;
    final holdings = ref.watch(aggregatorCollectionProvider).value ?? const [];
    final unread = (ref.watch(aggregatorMessagesProvider).value ?? const [])
        .where((message) => message.unread)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [PortalAvatarButton(name: currentAggregatorName, badgeCount: unread)],
      ),
      endDrawer: PortalMenuDrawer(
        name: currentAggregatorName,
        roleLabel: 'Aggregator',
        groups: aggregatorMenu,
        homeRoute: AggregatorDashboardScreen.path,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorDashboardProvider);
          ref.invalidate(aggregatorCollectionProvider);
          await ref.read(aggregatorDashboardProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(currentAggregatorName, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Reservations, sales and commission at a glance.',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 20),
                  if (summary == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: WindowSize.of(context).isCompact ? 1 : 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: WindowSize.of(context).isCompact ? 3.4 : 1.7,
                      children: [
                        _Kpi(
                          icon: LucideIcons.bookmarkCheck,
                          label: 'Active reservations',
                          value: '${summary.activeReservations}',
                        ),
                        _Kpi(
                          icon: LucideIcons.indianRupee,
                          label: 'Commission earned',
                          value: formatInr(summary.commissionEarned),
                          gold: true,
                        ),
                        _Kpi(
                          icon: LucideIcons.banknote,
                          label: 'Pending settlements',
                          value: '${summary.pendingSettlements}',
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const _CommissionExplainer(),
                  const SizedBox(height: 10),
                  const ProvisionalCommissionNotice(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent activity', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/aggregator/inventory'),
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (holdings.isEmpty)
                    Text(
                      'No activity yet. Reserve an artwork from Browse to get started.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final view in _mostRecent(holdings))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActivityRow(view: view),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Newest five holdings by assignment date. Unlike the web — which reads
  /// this rail straight off the frozen fixture — this reads the live
  /// collection, so a reservation made in-session shows up here too.
  static List<AggregatorHoldingView> _mostRecent(List<AggregatorHoldingView> holdings) {
    final sorted = [...holdings]
      ..sort((a, b) => b.holding.assignedAt.compareTo(a.holding.assignedAt));
    return sorted.take(5).toList();
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    this.gold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(icon, size: 15, color: theme.colorScheme.tertiary),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: gold ? theme.colorScheme.tertiary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Port of `commission-explainer.tsx`. The worked figures are the Onboarding
/// Guide's own example, not invented numbers.
class _CommissionExplainer extends StatelessWidget {
  const _CommissionExplainer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.percent, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('You earn 20% of the 30% markup',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'On every aggregator-assisted sale, GalleryZone adds a 30% markup on top '
            "of the artist's price. You keep a 20% share of that markup as "
            'commission, on top of your advance.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _Figure(label: 'Listed price', amount: 30000),
              const Icon(Icons.arrow_right_alt, size: 16),
              const _Figure(label: 'Platform markup', amount: 9000),
              const Icon(Icons.arrow_right_alt, size: 16),
              const _Figure(label: 'Your share', amount: 1800, gold: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, this.gold = false});

  final String label;
  final double amount;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatInr(amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: gold ? theme.colorScheme.tertiary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.view});

  final AggregatorHoldingView view;

  /// Days between the fixture anchor and this holding's assignment. Real
  /// wall-clock time would drift the seeded spread — see [fixtureToday].
  static String _relative(String iso) {
    final days = fixtureToday.difference(DateTime.parse(iso)).inHours ~/ 24;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = view.holding;
    final sold = holding.status == HoldingStatus.soldPendingSettlement;
    final title = view.artwork.title;

    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            sold ? LucideIcons.banknote : LucideIcons.bookmarkCheck,
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sold ? 'Sale recorded: "$title"' : 'Reserved: "$title"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Display price ${formatInr(holding.displayPrice)} · '
                  '${holding.advancePercent}% advance',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_relative(holding.assignedAt), style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
