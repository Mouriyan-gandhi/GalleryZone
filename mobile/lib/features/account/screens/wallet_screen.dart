import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/wallet-overview.tsx`. Deliberately simpler than
/// the artist/aggregator wallets: **no withdrawal form**. This balance is
/// refund/store credit that applies at the next checkout, not earnings a
/// collector cashes out.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static const path = '/account/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletProvider).value;
    final transactions = ref.watch(walletTransactionsProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.wallet, size: 16, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text('Store credit', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PriceTag(
                        amount: wallet?.balance ?? 0,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Refunds and cancellations credit here automatically, and '
                        'apply at your next checkout.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
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
                    description: 'Refunds and store credit adjustments will show up here.',
                  )
                else
                  for (final transaction in transactions)
                    _TransactionRow(transaction: transaction),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final profile = ref.watch(customerProfileProvider).value;
                    if (profile == null) return const SizedBox.shrink();
                    return GstNumberCard(
                      value: profile.gstin ?? '',
                      description:
                          'Add it if you need GST invoices for your purchases — '
                          'for a business or an office collection, say.',
                      onSave: (gstin) async {
                        await ref
                            .read(customerRepositoryProvider)
                            .updateProfile(profile.copyWith(gstin: gstin));
                        ref.invalidate(customerProfileProvider);
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
                Text(
                  transaction.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
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
