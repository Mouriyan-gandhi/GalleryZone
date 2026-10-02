import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/models/auth.dart';
import '../../shell/display_clock.dart';
import '../../shell/portal_menu.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';
import 'aggregator_inventory_screen.dart';

/// Port of `app/aggregator/dashboard/page.tsx` — KPI cards, the commission
/// explainer, the sales-conversion card and a recent-activity rail.
class AggregatorDashboardScreen extends ConsumerWidget {
  const AggregatorDashboardScreen({super.key});

  static const path = '/aggregator/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(aggregatorDashboardProvider);
    final unread = (ref.watch(aggregatorMessagesProvider).value ?? const [])
        .where((message) => message.unread)
        .length;
    final menu = portalMenuFor(Role.aggregator);
    final name = ref.watch(portalDisplayNameProvider);
    final compact = WindowSize.of(context).isCompact;

    // The cards are always drawn - a dash where the figure would be if it failed -
    // as on the website, so a slow or failed load never empties the page.
    final figures = summary.value;
    final failed = summary.hasError && figures == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [PortalAvatarButton(name: name, badgeCount: unread)],
      ),
      // The shell carries this same drawer for its Profile tab; the copy here is what
      // the avatar above can reach, since this Scaffold sits inside the shell's.
      endDrawer: PortalMenuDrawer(
        name: name,
        roleLabel: menu.roleLabel,
        groups: menu.groups,
        homeRoute: menu.homeRoute,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorDashboardProvider);
          ref.invalidate(aggregatorCollectionProvider);
          try {
            await ref.read(aggregatorDashboardProvider.future);
          } catch (_) {
            // The cards show the failure themselves, with a way to try again.
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Reservations, sales and commission at a glance.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: compact ? 1 : 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: compact ? 3.4 : 1.7,
                    children: [
                      _Kpi(
                        icon: LucideIcons.bookmarkCheck,
                        label: 'Active reservations',
                        value: figures == null ? null : '${figures.activeReservations}',
                        failed: failed,
                      ),
                      _Kpi(
                        icon: LucideIcons.indianRupee,
                        label: 'Commission earned',
                        value: figures == null ? null : formatInr(figures.commissionEarned),
                        failed: failed,
                        gold: true,
                      ),
                      _Kpi(
                        icon: LucideIcons.banknote,
                        label: 'Pending settlements',
                        value: figures == null ? null : '${figures.pendingSettlements}',
                        failed: failed,
                      ),
                    ],
                  ),
                  if (failed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => ref.invalidate(aggregatorDashboardProvider),
                        child: const Text("Couldn't load your figures. Try again"),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _CommissionExplainer(),
                  const SizedBox(height: 12),
                  _SalesConversion(rate: figures?.conversionRate, loading: figures == null && !failed),
                  const SizedBox(height: 10),
                  const WalletMechanicsNotice(),
                  const SizedBox(height: 24),
                  const _RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.failed,
    this.gold = false,
  });

  final IconData icon;
  final String label;

  /// Null while loading, and when it failed ([failed] says which).
  final String? value;
  final bool failed;
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
          if (value == null && !failed)
            const SizedBox(height: 22, width: 22, child: Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: value == null ? theme.colorScheme.onSurfaceVariant : (gold ? theme.colorScheme.tertiary : null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Port of `commission-explainer.tsx`. Worked off a round ₹1,00,000 artist price
/// so the split reads cleanly: a 30% markup is ₹30,000, and the aggregator's 20%
/// of that markup is ₹6,000.
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
              Expanded(child: Text('You earn 20% of the 30% markup', style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "On every aggregator-assisted sale, GalleryZone adds a 30% markup on top of the artist's price. "
            'You keep a 20% share of that markup as commission, on top of your advance.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Figure(label: 'Listed price', amount: 100000),
              Icon(Icons.arrow_right_alt, size: 16),
              _Figure(label: 'Platform markup', amount: 30000),
              Icon(Icons.arrow_right_alt, size: 16),
              _Figure(label: 'Your share', amount: 6000, gold: true),
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
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
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

/// Port of `sales-conversion-card.tsx`. Sold over (sold + returned): a piece still
/// on display hasn't had its outcome yet, so it isn't counted.
class _SalesConversion extends StatelessWidget {
  const _SalesConversion({required this.rate, required this.loading});

  final int? rate;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.trendingUp, size: 16, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales conversion', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      "Of the reservations you've concluded, the share that ended in a sale rather than a return.",
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const SizedBox(height: 22, width: 22, child: Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Text(
              rate == null ? '—' : '$rate%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: rate == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.tertiary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The newest five reservations, sales and returns, read off the live holdings - no
/// stored feed.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  /// "Today", "Yesterday", "3 days ago" - counted to the day, as the website does.
  static String relative(String iso, DateTime now) {
    final days = (now.difference(DateTime.parse(iso)).inMinutes / (24 * 60)).round();
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(aggregatorCollectionProvider);
    final now = displayNow(ref);
    final recent = ([...(collection.value ?? const <AggregatorHoldingView>[])]
          ..sort((a, b) => b.holding.assignedAt.compareTo(a.holding.assignedAt)))
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recent activity', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (collection.hasError && collection.value == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref.invalidate(aggregatorCollectionProvider),
              child: const Text("Couldn't load your activity. Try again"),
            ),
          )
        else if (collection.value == null)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (recent.isEmpty) ...[
          Text('No activity yet. Reserve an artwork from Inventory to get started.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => context.go(AggregatorBrowseScreen.path),
              child: const Text('Browse Inventory'),
            ),
          ),
        ] else
          for (final view in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityRow(view: view, when: relative(view.holding.assignedAt, now)),
            ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.view, required this.when});

  final AggregatorHoldingView view;
  final String when;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = view.holding;
    final title = view.artwork.title;
    // The website files a returned piece under "Reserved"; it has gone back.
    final (icon, headline) = switch (holding.status) {
      HoldingStatus.soldPendingSettlement => (LucideIcons.banknote, 'Sale recorded: "$title"'),
      HoldingStatus.returned => (LucideIcons.undo2, 'Returned: "$title"'),
      HoldingStatus.reserved => (LucideIcons.bookmarkCheck, 'Reserved: "$title"'),
    };

    return PortalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Display price ${formatInr(holding.displayPrice)} · ${holding.advancePercent}% advance',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(when, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
