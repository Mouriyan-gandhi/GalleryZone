import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `features/aggregator/wallet-overview.tsx`. Same shape as the
/// artist wallet — this is earned commission, so it has a withdrawal path
/// with the ₹1,000 floor — but the pending balance here only clears when a
/// settlement is processed, never on a timer.
class AggregatorWalletScreen extends ConsumerWidget {
  const AggregatorWalletScreen({super.key});

  static const path = '/aggregator/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(aggregatorWalletProvider).value;
    final transactions = ref.watch(aggregatorWalletTransactionsProvider).value;
    final profile = ref.watch(aggregatorProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalCard(
                  gold: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.wallet,
                              size: 16, color: theme.colorScheme.tertiary),
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
                      if (profile != null)
                        PortalDetailRow(
                          label: 'Payout account',
                          value: profile.bankAccountMasked,
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed:
                              wallet == null || wallet.balance < aggregatorMinimumWithdrawal
                                  ? null
                                  : () => _openWithdrawSheet(context, ref, wallet),
                          icon: const Icon(LucideIcons.banknote, size: 16),
                          label: const Text('Withdraw'),
                        ),
                      ),
                      if (wallet != null &&
                          wallet.balance < aggregatorMinimumWithdrawal) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Minimum withdrawal is '
                          '${formatInr(aggregatorMinimumWithdrawal)}. Commission '
                          'becomes available once its settlement is processed.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const ProvisionalCommissionNotice(),
                const SizedBox(height: 24),
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
                    description:
                        'Commission from a recorded sale, and withdrawals, show up here.',
                  )
                else
                  for (final transaction in transactions)
                    _TransactionRow(transaction: transaction),
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
                '${formatInr(aggregatorMinimumWithdrawal)}',
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
                  if (parsed < aggregatorMinimumWithdrawal) {
                    return 'Minimum withdrawal is ₹1,000';
                  }
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
      await ref.read(aggregatorRepositoryProvider).requestWithdrawal(amount);
      ref.invalidate(aggregatorWalletProvider);
      ref.invalidate(aggregatorWalletTransactionsProvider);
      ref.invalidate(aggregatorAnalyticsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatInr(amount)} sent to your bank account — typically 1–2 '
            'business days.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.amount >= 0;
    final pending = transaction.status == WalletTransactionStatus.pending;

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
                Text(
                  transaction.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  pending
                      ? 'Pending settlement'
                      : '${formatShortDate(transaction.date)} · '
                          '${transaction.status.name}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: pending ? theme.colorScheme.tertiary : null,
                  ),
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
