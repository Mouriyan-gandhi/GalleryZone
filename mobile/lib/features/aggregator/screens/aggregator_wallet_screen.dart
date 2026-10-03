import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/payments/payment_gateway.dart' show PaymentDismissedException;
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `features/aggregator/wallet-overview.tsx`.
///
/// This wallet does something the artist's does not: it is the float reserving
/// artwork is HELD against. Money locked behind a live reservation is still the
/// aggregator's, but it is not theirs to spend or take out, so every figure here
/// distinguishes what is free from what is held.
class AggregatorWalletScreen extends ConsumerWidget {
  const AggregatorWalletScreen({super.key});

  static const path = '/aggregator/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(aggregatorWalletProvider);
    final transactionsAsync = ref.watch(aggregatorWalletTransactionsProvider);
    final wallet = walletAsync.value;
    // What can actually be spent. Money behind a live reservation is still
    // theirs; it just isn't available.
    final free = wallet == null ? 0.0 : wallet.balance - wallet.lockedBalance;

    if (wallet == null && walletAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Earnings & wallet')),
        body: EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your wallet",
          description: authErrorMessage(walletAsync.error!),
          action: OutlinedButton(
            onPressed: () {
              ref.invalidate(aggregatorWalletProvider);
              ref.invalidate(aggregatorWalletTransactionsProvider);
            },
            child: const Text('Try again'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & wallet')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregatorWalletProvider);
          ref.invalidate(aggregatorWalletTransactionsProvider);
          ref.invalidate(aggregatorProfileProvider);
          await ref.read(aggregatorWalletProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(
                    label: 'Free to use',
                    value: free,
                    hint: 'Available to reserve artwork',
                    icon: LucideIcons.wallet,
                    gold: true,
                  ),
                  const SizedBox(height: 10),
                  _SummaryCard(
                    label: 'Held against reservations',
                    value: wallet?.lockedBalance ?? 0,
                    hint: 'Advances and delivery on pieces you are displaying',
                    icon: LucideIcons.lock,
                  ),
                  const SizedBox(height: 10),
                  _SummaryCard(
                    label: 'Commission pending',
                    value: wallet?.pendingBalance ?? 0,
                    hint: 'Earned on sales, waiting to be settled',
                    icon: LucideIcons.clock3,
                  ),
                  const SizedBox(height: 12),
                  const WalletMechanicsNotice(),
                  const SizedBox(height: 16),
                  const _AddFundsCard(),
                  const SizedBox(height: 16),
                  _WithdrawCard(free: free),
                  const SizedBox(height: 24),
                  Text('Transaction history', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (transactionsAsync.value == null && transactionsAsync.hasError)
                    EmptyState(
                      icon: LucideIcons.triangleAlert,
                      title: "Couldn't load your transactions",
                      description: authErrorMessage(transactionsAsync.error!),
                      action: OutlinedButton(
                        onPressed: () => ref.invalidate(aggregatorWalletTransactionsProvider),
                        child: const Text('Try again'),
                      ),
                    )
                  else if (transactionsAsync.value == null)
                    const Center(
                      child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                    )
                  else if (transactionsAsync.requireValue.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.wallet,
                      title: 'No transactions yet',
                      description: 'Money added, held and returned, and commission from sales, show up here.',
                    )
                  else
                    for (final transaction in transactionsAsync.requireValue)
                      WalletTransactionRow(transaction: transaction),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, _) {
                      final profile = ref.watch(aggregatorProfileProvider).value;
                      if (profile == null) return const SizedBox.shrink();
                      return GstNumberCard(
                        value: profile.gstNumber,
                        description:
                            'Used on your commission settlements and invoices. Also editable from your profile.',
                        onSave: (gstNumber) async {
                          await ref
                              .read(aggregatorRepositoryProvider)
                              .updateProfile(profile.copyWith(gstNumber: gstNumber));
                          ref.invalidate(aggregatorProfileProvider);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    this.gold = false,
  });

  final String label;
  final double value;
  final String hint;
  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: gold,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Icon(icon, size: 16, color: gold ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          PriceTag(amount: value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(hint, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// The advance and delivery are held from this balance, so an empty wallet means
/// nothing can be reserved. Money comes in from the aggregator's own bank
/// account, card or UPI through Razorpay (client, 30 Sep 2026).
class _AddFundsCard extends ConsumerStatefulWidget {
  const _AddFundsCard();

  @override
  ConsumerState<_AddFundsCard> createState() => _AddFundsCardState();
}

class _AddFundsCardState extends ConsumerState<_AddFundsCard> {
  final _amount = TextEditingController();
  bool _pending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  bool get _outOfRange =>
      _amount.text.trim().isNotEmpty &&
      (_value != _value.roundToDouble() || _value < aggregatorTopupMin || _value > aggregatorTopupMax);

  bool get _canSubmit => _value >= aggregatorTopupMin && !_outOfRange && !_pending;

  Future<void> _submit() async {
    final amount = _value;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pending = true);
    try {
      await ref.read(aggregatorRepositoryProvider).addFunds(amount);
      // Topping up frees capacity to reserve, so the list re-evaluates too.
      container
        ..invalidate(aggregatorWalletProvider)
        ..invalidate(aggregatorWalletTransactionsProvider)
        ..invalidate(aggregatorInventoryProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Added to your wallet. ${formatInr(amount)} is ready to reserve with.')),
      );
      if (mounted) _amount.clear();
    } on PaymentDismissedException {
      messenger.showSnackBar(const SnackBar(content: Text('Payment cancelled — nothing was charged.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(LucideIcons.wallet, size: 16, color: theme.colorScheme.tertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add funds', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Pay from your bank account, card or UPI through Razorpay. Reserving artwork holds the '
                      "advance and delivery from this balance. The advance comes back if a piece doesn't sell; "
                      'the delivery deposit comes back when it does.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            enabled: !_pending,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              hintText: '25000',
              errorText: _outOfRange ? '₹1,000 to ₹5,00,000 in whole rupees, one payment at a time.' : null,
              helperText: _outOfRange ? null : '₹1,000 to ₹5,00,000 in whole rupees, one payment at a time.',
              helperMaxLines: 2,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(_pending ? 'Waiting for payment…' : 'Add to wallet'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aggregators are agents, not principals: the API has no withdrawal route, so
/// against the real service this says so and points at GalleryZone rather than
/// offering a form that can only be refused. The offline demo keeps a working one.
class _WithdrawCard extends ConsumerStatefulWidget {
  const _WithdrawCard({required this.free});

  final double free;

  @override
  ConsumerState<_WithdrawCard> createState() => _WithdrawCardState();
}

class _WithdrawCardState extends ConsumerState<_WithdrawCard> {
  final _amount = TextEditingController();
  bool _pending = false;
  double? _requested;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;
  bool get _belowMinimum => _amount.text.trim().isNotEmpty && _value < aggregatorMinimumWithdrawal;
  bool get _exceedsBalance => _value > widget.free;
  bool get _canSubmit => _value >= aggregatorMinimumWithdrawal && _value <= widget.free && !_pending;

  Future<void> _submit() async {
    final amount = _value;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pending = true);
    try {
      await ref.read(aggregatorRepositoryProvider).requestWithdrawal(amount);
      container
        ..invalidate(aggregatorWalletProvider)
        ..invalidate(aggregatorWalletTransactionsProvider);
      if (mounted) setState(() => _requested = amount);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remote = ref.watch(remoteBackendProvider);
    final profile = ref.watch(aggregatorProfileProvider).value;

    if (remote) {
      return PortalNotice(
        icon: LucideIcons.landmark,
        title: 'Withdraw funds',
        body: "Withdrawals from the wallet aren't open yet. Contact GalleryZone to have unused money returned to "
            'your bank account.',
        action: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.push('/aggregator/dashboard/support'),
            child: const Text('Contact GalleryZone'),
          ),
        ),
      );
    }

    final requested = _requested;
    if (requested != null) {
      final masked = profile?.bankAccountMasked ?? '';
      return PortalCard(
        gold: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.check, size: 20, color: theme.colorScheme.tertiary),
            const SizedBox(height: 8),
            Text('Withdrawal requested.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              '${formatInr(requested)} will be sent to your bank account ending '
              '${masked.length >= 4 ? masked.substring(masked.length - 4) : masked}. This typically takes 1–2 '
              'business days.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            TextButton(
              onPressed: () => setState(() {
                _requested = null;
                _amount.clear();
              }),
              child: const Text('Request another withdrawal'),
            ),
          ],
        ),
      );
    }

    return PortalCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Withdraw funds', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (profile != null)
            Row(
              children: [
                Icon(LucideIcons.building2, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.bankAccountMasked, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      Text(profile.ifsc, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            enabled: !_pending,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              hintText: '5000',
              errorText: _belowMinimum
                  ? 'Minimum withdrawal is ${formatInr(aggregatorMinimumWithdrawal)}'
                  : _exceedsBalance
                      ? 'Exceeds your available balance'
                      : null,
              helperText: 'Minimum ${formatInr(aggregatorMinimumWithdrawal)} · Available ${formatInr(widget.free)}',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(_pending ? 'Requesting…' : 'Request withdrawal'),
            ),
          ),
        ],
      ),
    );
  }
}
