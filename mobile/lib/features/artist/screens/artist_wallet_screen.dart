import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/mock/mock_artist_repository.dart' show minimumWithdrawal;
import '../../../data/models/customer.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../../data/mock/mock_artist_repository.dart'
    show simulateDeliveryAndRelease;
import '../../shell/portal_widgets.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/wallet-overview.tsx`. Unlike the collector's
/// wallet, this balance is earnings — so it has a withdrawal path, with the
/// ₹1,000 floor the service enforces.
class ArtistWalletScreen extends ConsumerWidget {
  const ArtistWalletScreen({super.key});

  static const path = '/dashboard/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(artistWalletProvider).value;
    final transactions = ref.watch(artistWalletTransactionsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProvisionalPayoutNotice(),
                const SizedBox(height: 12),
                PortalCard(
                  gold: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.wallet, size: 16, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text('Available balance', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PriceTag(
                        amount: wallet?.balance ?? 0,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      PortalDetailRow(
                        label: 'Pending settlement',
                        value: formatInr(wallet?.pendingBalance ?? 0),
                      ),
                      PortalDetailRow(
                        label: 'Locked',
                        value: formatInr(wallet?.lockedBalance ?? 0),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        // The timing rule, where the number it explains is.
                        'A sale is paid $artistPayoutDaysAfterDelivery days after the '
                        'piece is DELIVERED, not when it sells. Until then it '
                        'sits in pending.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: wallet == null || wallet.balance < minimumWithdrawal
                              ? null
                              : () => _openWithdrawSheet(context, ref, wallet),
                          icon: const Icon(LucideIcons.banknote, size: 16),
                          label: const Text('Withdraw'),
                        ),
                      ),
                      if (wallet != null && wallet.balance < minimumWithdrawal) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Minimum withdrawal is ${formatInr(minimumWithdrawal)}.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _PendingSettlements(),
                const SizedBox(height: 8),
                Text('Transaction history', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (transactions == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (transactions.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.wallet,
                    title: 'No transactions yet',
                    description: 'Settlements and withdrawals will show up here.',
                  )
                else
                  for (final transaction in transactions)
                    _TransactionRow(transaction: transaction),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final profile = ref.watch(artistProfileDetailsProvider).value;
                    if (profile == null) return const SizedBox.shrink();
                    return GstNumberCard(
                      value: profile.gstin ?? '',
                      description:
                          'Used on your settlement statements and invoices. Also '
                          'editable from your profile.',
                      onSave: (gstin) async {
                        await ref
                            .read(artistRepositoryProvider)
                            .updateProfile(profile.copyWith(gstin: gstin));
                        ref.invalidate(artistProfileDetailsProvider);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWithdrawSheet(
    BuildContext context,
    WidgetRef ref,
    WalletSummary wallet,
  ) async {
    final controller = TextEditingController(text: wallet.balance.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Withdraw to bank', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Available ${formatInr(wallet.balance)} · minimum '
                '${formatInr(minimumWithdrawal)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Enter an amount';
                  if (parsed < minimumWithdrawal) return 'Minimum withdrawal is ₹1,000';
                  if (parsed > wallet.balance) return 'Exceeds your available balance';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(double.parse(controller.text.trim()));
                },
                child: const Text('Request withdrawal'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (amount == null) return;

    try {
      await ref.read(artistRepositoryProvider).requestWithdrawal(amount);
      ref.invalidate(artistWalletProvider);
      ref.invalidate(artistWalletTransactionsProvider);
      ref.invalidate(artistKpisProvider);
      ref.invalidate(artistActivityProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${formatInr(amount)} sent to your bank account')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }
}

/// What is waiting on the 7-day clock, and when each piece of it lands.
///
/// The "mark delivered" button is a demo shortcut, and says so: there is no
/// courier here, so nothing would ever mark a delivery long enough ago for
/// the seven days to have elapsed, and the release could never be seen.
class _PendingSettlements extends ConsumerWidget {
  const _PendingSettlements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settlements = ref.watch(artistSettlementsProvider).value ?? const [];
    final pending = [
      for (final settlement in settlements)
        if (settlement.status == SettlementStatus.pending) settlement,
    ];
    if (pending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('On the way', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final settlement in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PortalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          settlement.artworkTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      PriceTag(
                        amount: settlement.artistAmount,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settlement.releaseAfter == null
                        ? 'Waiting on delivery. The '
                            '$artistPayoutDaysAfterDelivery-day clock starts when the '
                            'piece arrives.'
                        : 'Available from '
                            '${formatLongDate(settlement.releaseAfter!)}.',
                    style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                  ),
                  if (settlement.releaseAfter == null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => _simulate(context, ref, settlement.id),
                        child: const Text('Simulate delivery (demo)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _simulate(BuildContext context, WidgetRef ref, String settlementId) {
    // Backdates the delivery far enough that the seven days have already run,
    // then releases — otherwise this button would appear to do nothing.
    simulateDeliveryAndRelease(settlementId);
    ref.invalidate(artistWalletProvider);
    ref.invalidate(artistWalletTransactionsProvider);
    ref.invalidate(artistSettlementsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivered and released to your balance')),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.amount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              isCredit ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
              size: 14,
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium),
                Text(
                  '${formatShortDate(transaction.date)} · ${transaction.status.name}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriceTag(amount: transaction.amount, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
