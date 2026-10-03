import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/repositories/aggregator_repository.dart' show cashRemittanceDays;
import '../../artist/screens/artist_settlements_screen.dart' show settlementStatusLabel;
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/payee_details.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';
import '../widgets/list_tools.dart';
import 'aggregator_wallet_screen.dart';

/// Port of `features/aggregator/settlements-table.tsx`: what GalleryZone owes
/// the aggregator for each sale, and - above it, because it is an obligation
/// rather than an entitlement - the cash they took at the counter and still owe
/// GalleryZone.
class AggregatorSettlementsScreen extends ConsumerStatefulWidget {
  const AggregatorSettlementsScreen({super.key});

  static const path = '/aggregator/dashboard/settlements';

  @override
  ConsumerState<AggregatorSettlementsScreen> createState() => _AggregatorSettlementsScreenState();
}

class _AggregatorSettlementsScreenState extends ConsumerState<AggregatorSettlementsScreen> {
  final _search = TextEditingController();
  SettlementStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settlementsAsync = ref.watch(aggregatorSettlementsProvider);
    final salesAsync = ref.watch(aggregatorSalesProvider);

    if (settlementsAsync.value == null && salesAsync.value == null) {
      final error = settlementsAsync.error ?? salesAsync.error;
      return Scaffold(
        appBar: AppBar(title: const Text('Settlements')),
        body: error == null
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: LucideIcons.triangleAlert,
                title: "Couldn't load your settlements",
                description: authErrorMessage(error),
                action: OutlinedButton(
                  onPressed: () {
                    ref.invalidate(aggregatorSettlementsProvider);
                    ref.invalidate(aggregatorSalesProvider);
                  },
                  child: const Text('Try again'),
                ),
              ),
      );
    }

    final settlements = settlementsAsync.value ?? const <Settlement>[];
    final remote = ref.watch(remoteBackendProvider);

    // The offline demo has a step the real service does not: a sale with no
    // settlement record yet can be "simulated" through. Against the API every
    // sale already has its row here, so this is empty and never drawn.
    final settledSaleIds = settlements.map((s) => s.orderId).toSet();
    final awaiting = [
      for (final sale in salesAsync.value ?? const <AggregatorSale>[])
        if (!settledSaleIds.contains(sale.id)) sale,
    ];

    final needle = _search.text.trim().toLowerCase();
    final shown = [
      for (final settlement in settlements)
        if ((_status == null || settlement.status == _status) &&
            (needle.isEmpty || '${settlement.artworkTitle} ${settlement.orderId}'.toLowerCase().contains(needle)))
          settlement,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settlements')),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateAggregatorSaleFlow(ref);
          await ref.read(aggregatorSettlementsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The obligation goes above the entitlements. Mixing the two is how
                  // people end up netting off.
                  const _OwedToGalleryZone(),
                  const WalletMechanicsNotice(),
                  const SizedBox(height: 16),
                  if (awaiting.isNotEmpty && !remote) ...[
                    Text('Awaiting settlement', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    for (final sale in awaiting)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _AwaitingCard(sale: sale)),
                    const SizedBox(height: 16),
                  ],
                  Text('Commission settlements', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (settlements.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.landmark,
                      title: 'No settlements yet',
                      description: 'A commission breakdown appears here once a piece sells.',
                    )
                  else ...[
                    ListSearchField(
                      controller: _search,
                      hint: 'Search by artwork',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _status == null,
                          onSelected: (_) => setState(() => _status = null),
                        ),
                        for (final status in SettlementStatus.values)
                          ChoiceChip(
                            label: Text(settlementStatusLabel[status]!),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = _status == status ? null : status),
                          ),
                      ],
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
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: _SettlementCard(settlement: settlement)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sale with no settlement record yet - the offline demo only.
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
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    try {
      await ref.read(aggregatorRepositoryProvider).processSettlement(sale.id);
      invalidateAggregatorSaleFlowIn(container);
      messenger.showSnackBar(const SnackBar(content: Text('Settlement processed')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}

class _SettlementCard extends ConsumerWidget {
  const _SettlementCard({required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text('Sale ${settlement.orderId}', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SettlementStatusPill(status: settlement.status),
            ],
          ),
          const Divider(height: 20),
          PortalDetailRow(label: 'Your commission', value: formatInr(settlement.aggregatorCommission), gold: true),
          PortalDetailRow(label: 'Created', value: formatShortDate(settlement.createdAt)),
          PortalDetailRow(
            label: 'Processed',
            value: settlement.processedAt == null ? 'Not yet' : formatShortDate(settlement.processedAt!),
          ),
        ],
      ),
    );
  }
}

/// Cash the aggregator took at the counter belongs to GalleryZone, and the WHOLE
/// sale price is owed - not the sale less commission. Their commission is settled
/// separately, in the list below this card. Port of `RemittancesDueCard`.
class _OwedToGalleryZone extends ConsumerStatefulWidget {
  const _OwedToGalleryZone();

  @override
  ConsumerState<_OwedToGalleryZone> createState() => _OwedToGalleryZoneState();
}

class _OwedToGalleryZoneState extends ConsumerState<_OwedToGalleryZone> {
  /// Sales being paid in right now, so a second tap can't pay one twice.
  final _paying = <String>{};

  Future<void> _pay(AggregatorSale sale, RemitVia via) async {
    final theme = Theme.of(context);
    // Money moves (or is claimed to have moved) and neither can be taken back, so
    // it is asked about first. The website relies on a hover hint instead.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(via == RemitVia.wallet ? 'Pay from your wallet?' : 'Mark as transferred?'),
        content: Text(
          via == RemitVia.wallet
              ? '${formatInr(sale.soldPrice)} is taken from your free wallet balance and paid in to GalleryZone for '
                  "${sale.buyerName}'s purchase."
              : "You have transferred ${formatInr(sale.soldPrice)} to GalleryZone's bank account for "
                  "${sale.buyerName}'s purchase. GalleryZone takes this on your word.",
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not yet')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(via == RemitVia.wallet ? 'Pay from wallet' : 'Mark transferred'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    setState(() => _paying.add(sale.id));
    try {
      await ref.read(aggregatorRepositoryProvider).markRemitted(sale.id, via: via);
      invalidateAggregatorSaleFlowIn(container);
      messenger.showSnackBar(
        SnackBar(content: Text(via == RemitVia.wallet ? 'Paid from your wallet' : 'Marked as transferred')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _paying.remove(sale.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = ref.watch(aggregatorRemittancesDueProvider).value ?? const <AggregatorSale>[];
    if (due.isEmpty) return const SizedBox.shrink();

    final wallet = ref.watch(aggregatorWalletProvider).value;
    final free = wallet == null ? 0.0 : wallet.balance - wallet.lockedBalance;
    final total = due.fold(0.0, (sum, sale) => sum + sale.soldPrice);
    final now = DateTime.now().toUtc();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PortalCard(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Owed to GalleryZone', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        "Cash you collected on GalleryZone's behalf. Pay in the full amount "
                        'within $cashRemittanceDays days, either from your wallet (add the cash to it first in Earnings & '
                        "Wallet) or by transfer to GalleryZone's bank account. Your commission is settled "
                        'separately, below.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PriceTag(amount: total, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.tertiary)),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.go(AggregatorWalletScreen.path),
                child: const Text('Open Earnings & Wallet'),
              ),
            ),
            const SizedBox(height: 4),
            for (final sale in due) ...[
              _DueRow(
                sale: sale,
                now: now,
                short: math.max(0.0, sale.soldPrice - free),
                busy: _paying.contains(sale.id),
                onPay: (via) => _pay(sale, via),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            PayeeDetails(
              amount: total,
              note: 'GZ remittance ${due.length} sale${due.length > 1 ? 's' : ''}',
            ),
          ],
        ),
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({required this.sale, required this.now, required this.short, required this.busy, required this.onPay});

  final AggregatorSale sale;
  final DateTime now;

  /// How much of this sale the free wallet balance can't cover.
  final double short;
  final bool busy;
  final ValueChanged<RemitVia> onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueAt = sale.remitDueAt == null ? null : DateTime.tryParse(sale.remitDueAt!);
    final overdue = dueAt == null ? Duration.zero : now.difference(dueAt);
    final overdueDays = overdue.inDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Sold ${formatDay(sale.soldAt)}'
                      '${dueAt != null && overdue <= Duration.zero ? ' · due ${formatDay(dueAt.toIso8601String())}' : ''}',
                      style: theme.textTheme.labelSmall,
                    ),
                    if (overdue > Duration.zero)
                      Text(
                        overdueDays >= 1 ? 'Overdue by $overdueDays day${overdueDays > 1 ? 's' : ''}' : 'Overdue',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriceTag(amount: sale.soldPrice, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: busy || short > 0 ? null : () => onPay(RemitVia.wallet),
                child: const Text('Pay from wallet'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => onPay(RemitVia.bank),
                child: const Text('Mark transferred'),
              ),
            ],
          ),
          // The website says this in a hover hint; a phone has none.
          if (short > 0) ...[
            const SizedBox(height: 6),
            Text('Add ${formatInr(short)} to your wallet first to pay from it.', style: theme.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}
