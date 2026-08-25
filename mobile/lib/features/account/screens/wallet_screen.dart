import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_customer_repository.dart'
    show minimumCustomerWithdrawal;
import '../../../data/models/customer.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../shell/portal_widgets.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/wallet-overview.tsx`.
///
/// This balance applies automatically at the next checkout — but it is the
/// collector's own money (refunds, and what they were paid when they resold a
/// piece), so it can also be taken out. A refund on a ₹1,36,500 painting that
/// can only be spent back on the same site is not a refund.
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
                        'Refunds, cancellations and resale proceeds credit here '
                        'automatically. Spend it at your next checkout, or take '
                        'it out to your bank.',
                        style: theme.textTheme.labelSmall?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      const _WithdrawButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _BankDetailsCard(),
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

/// Only enabled with somewhere to send the money and enough of it to send —
/// the same two rules the repository enforces, so the button never promises
/// something the call will refuse.
class _WithdrawButton extends ConsumerWidget {
  const _WithdrawButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletProvider).value;
    final profile = ref.watch(customerProfileProvider).value;
    final balance = wallet?.balance ?? 0;
    final ready = profile != null &&
        profile.hasBankDetails &&
        balance >= minimumCustomerWithdrawal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: ready ? () => _openWithdrawSheet(context, ref, balance) : null,
            icon: const Icon(LucideIcons.banknote, size: 16),
            label: const Text('Withdraw to bank'),
          ),
        ),
        if (!ready) ...[
          const SizedBox(height: 6),
          Text(
            profile != null && !profile.hasBankDetails
                ? 'Add your bank details below to withdraw.'
                : 'Minimum withdrawal is ${formatInr(minimumCustomerWithdrawal)}.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

Future<void> _openWithdrawSheet(
  BuildContext context,
  WidgetRef ref,
  double balance,
) async {
  final controller = TextEditingController(text: balance.toStringAsFixed(0));
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
            Text('Withdraw to bank',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Available ${formatInr(balance)} · minimum '
              '${formatInr(minimumCustomerWithdrawal)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter an amount';
                if (parsed < minimumCustomerWithdrawal) {
                  return 'Minimum is ${formatInr(minimumCustomerWithdrawal)}';
                }
                if (parsed > balance) return 'More than your balance';
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
    await ref.read(customerRepositoryProvider).requestWithdrawal(amount);
    ref.invalidate(walletProvider);
    ref.invalidate(walletTransactionsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${formatInr(amount)} on its way to your bank')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

/// Where a refund or resale payout goes. Optional until the collector wants
/// money out, which is why it sits under the balance rather than in the
/// profile form — this is the moment it matters.
class _BankDetailsCard extends ConsumerStatefulWidget {
  const _BankDetailsCard();

  @override
  ConsumerState<_BankDetailsCard> createState() => _BankDetailsCardState();
}

class _BankDetailsCardState extends ConsumerState<_BankDetailsCard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  bool _seeded = false;
  bool _saving = false;

  /// Four letters, a zero, then six alphanumerics — the RBI's format.
  static final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  @override
  void dispose() {
    for (final controller in [_name, _account, _ifsc]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(CustomerProfile profile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(customerRepositoryProvider).updateProfile(
            profile.copyWith(
              bankAccountName: _name.text.trim(),
              bankAccountNumber: _account.text.trim(),
              bankIfsc: _ifsc.text.trim().toUpperCase(),
            ),
          );
      ref.invalidate(customerProfileProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Bank details saved')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(customerProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();

    if (!_seeded) {
      _seeded = true;
      _name.text = profile.bankAccountName;
      _account.text = profile.bankAccountNumber;
      _ifsc.text = profile.bankIfsc;
    }

    return PortalCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bank details',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Where refunds and resale payouts are sent. Only needed if you '
              'want money out — purchases never touch this.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Account holder name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Account number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifsc,
              textCapitalization: TextCapitalization.characters,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final entered = (value ?? '').trim().toUpperCase();
                if (entered.isEmpty) return null;
                return _ifscPattern.hasMatch(entered)
                    ? null
                    : "That doesn't look like a valid IFSC";
              },
              decoration: const InputDecoration(
                labelText: 'IFSC',
                helperText: 'Eleven characters, e.g. HDFC0001234.',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : () => _save(profile),
              child: Text(_saving ? 'Saving…' : 'Save bank details'),
            ),
          ],
        ),
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
