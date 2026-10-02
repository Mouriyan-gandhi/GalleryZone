import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artist_portal.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/artist_providers.dart';

/// Port of `app/dashboard/settlements/page.tsx` - one record per sale, showing
/// exactly how the money split. Thin Scaffold wrapper around
/// [ArtistSettlementsTab], which is also embedded directly as the "Payouts" tab
/// of `ArtistSalesScreen` - one body, two entry points (the More menu's own
/// Settlements row, and the Sales screen), so they can't drift apart.
class ArtistSettlementsScreen extends StatelessWidget {
  const ArtistSettlementsScreen({super.key});

  static const path = '/dashboard/settlements';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: const ArtistSettlementsTab(),
    );
  }
}

/// How a settlement's status reads, and in what colour. The website's own
/// words (`adminStatusLabel`): Pending, Processed, Failed.
const settlementStatusLabel = {
  SettlementStatus.pending: 'Pending',
  SettlementStatus.processed: 'Processed',
  SettlementStatus.failed: 'Failed',
};

Color _statusColor(BuildContext context, SettlementStatus status) =>
    switch (status) {
      SettlementStatus.pending => Theme.of(context).colorScheme.tertiary,
      SettlementStatus.processed => const Color(0xFF34D399),
      SettlementStatus.failed => AppColors.destructive,
    };

/// What the sale added up to: the artist's payout, the aggregator's commission
/// and the platform's fee. Port of `settlementTotal`.
double settlementTotal(Settlement settlement) =>
    settlement.artistAmount +
    settlement.aggregatorCommission +
    settlement.platformRevenue;

/// A share of the total as a whole percentage, 0 when there is no total.
int settlementShare(double value, double total) =>
    total > 0 ? (value / total * 100).round() : 0;

/// Port of `features/dashboard/settlements-table.tsx`: searchable by artwork or
/// order, filterable by status, with each sale opening into its split. No
/// Scaffold/AppBar of its own, so it can sit inside either
/// [ArtistSettlementsScreen] or a tab of the Sales screen.
class ArtistSettlementsTab extends ConsumerStatefulWidget {
  const ArtistSettlementsTab({super.key});

  @override
  ConsumerState<ArtistSettlementsTab> createState() =>
      _ArtistSettlementsTabState();
}

class _ArtistSettlementsTabState extends ConsumerState<ArtistSettlementsTab> {
  String _query = '';
  SettlementStatus? _status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settlements = ref.watch(artistSettlementsProvider);

    return settlements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        icon: LucideIcons.triangleAlert,
        title: "Couldn't load your settlements",
        description: authErrorMessage(error),
        action: OutlinedButton(
          onPressed: () => ref.invalidate(artistSettlementsProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.receipt,
            title: 'No settlements yet',
            description: 'A payout breakdown appears here once a piece sells.',
          );
        }
        final needle = _query.trim().toLowerCase();
        final shown = [
          for (final settlement in list)
            if ((_status == null || settlement.status == _status) &&
                (needle.isEmpty ||
                    '${settlement.artworkTitle} ${settlement.orderId}'
                        .toLowerCase()
                        .contains(needle)))
              settlement,
        ];

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(artistSettlementsProvider);
            await ref.read(artistSettlementsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search by artwork',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Chip(
                            label: 'All',
                            selected: _status == null,
                            onTap: () => setState(() => _status = null),
                          ),
                          for (final status in SettlementStatus.values)
                            _Chip(
                              label: settlementStatusLabel[status]!,
                              selected: _status == status,
                              onTap: () => setState(
                                () =>
                                    _status = _status == status ? null : status,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shown.isEmpty)
                      const EmptyState(
                        icon: LucideIcons.searchX,
                        title: 'No settlements match',
                        description: 'Try a different search or status.',
                      )
                    else
                      for (final settlement in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PortalCard(
                            padding: EdgeInsets.zero,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                onTap: () => _openDetail(context, settlement),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  settlement.artworkTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Text(
                                                  'Order ${settlement.orderId}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusPill(
                                            label:
                                                settlementStatusLabel[settlement
                                                    .status]!,
                                            color: _statusColor(
                                              context,
                                              settlement.status,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 18),
                                      PortalDetailRow(
                                        label: 'Your payout',
                                        value: formatInr(
                                          settlement.artistAmount,
                                        ),
                                        gold: true,
                                      ),
                                      PortalDetailRow(
                                        label: 'Platform fee',
                                        value: formatInr(
                                          settlement.platformRevenue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, Settlement settlement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SettlementDetail(settlement: settlement),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Port of `SettlementDetailDialog`: the split of one sale, as amounts and as
/// shares of the whole.
class _SettlementDetail extends StatelessWidget {
  const _SettlementDetail({required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = settlementTotal(settlement);

    Widget split(String label, double value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  TextSpan(
                    text: '  ${settlementShare(value, total)}%',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(formatInr(value), style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(settlement.artworkTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Status', style: theme.textTheme.bodyMedium),
                  ),
                  StatusPill(
                    label: settlementStatusLabel[settlement.status]!,
                    color: _statusColor(context, settlement.status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            split('Your payout', settlement.artistAmount),
            split('Aggregator commission', settlement.aggregatorCommission),
            split('Platform fee', settlement.platformRevenue),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(formatInr(total), style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PortalDetailRow(label: 'Order', value: settlement.orderId),
            PortalDetailRow(
              label: 'Processed',
              value: settlement.processedAt == null
                  ? 'Not yet'
                  : formatShortDate(settlement.processedAt!),
            ),
          ],
        ),
      ),
    );
  }
}
