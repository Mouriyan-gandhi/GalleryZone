import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_artist_repository.dart'
    show minimumWithdrawal, simulateDeliveryAndRelease;
import '../../../data/models/artist_portal.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Port of `features/dashboard/wallet-overview.tsx`. Unlike the collector's
/// wallet, this balance is earnings - so it has a withdrawal path, with the
/// ₹1,000 floor the API enforces. The "Overview" tab of [ArtistSalesScreen] -
/// no Scaffold/AppBar of its own, since it never appears outside that tabbed
/// screen.
class ArtistWalletTab extends ConsumerWidget {
  const ArtistWalletTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(artistWalletProvider);
    final transactionsAsync = ref.watch(artistWalletTransactionsProvider);
    final wallet = walletAsync.value;

    if (wallet == null && walletAsync.hasError) {
      return EmptyState(
        icon: LucideIcons.triangleAlert,
        title: "Couldn't load your wallet",
        description: authErrorMessage(walletAsync.error!),
        action: OutlinedButton(
          onPressed: () {
            ref.invalidate(artistWalletProvider);
            ref.invalidate(artistWalletTransactionsProvider);
          },
          child: const Text('Try again'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(artistWalletProvider);
        ref.invalidate(artistWalletTransactionsProvider);
        ref.invalidate(artistSettlementsProvider);
        await ref.read(artistWalletProvider.future);
      },
      child: ListView(
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
                          Icon(
                            LucideIcons.wallet,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available balance',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PriceTag(
                        amount: wallet?.balance ?? 0,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      PortalDetailRow(
                        label: 'Awaiting delivery',
                        value: formatInr(wallet?.pendingBalance ?? 0),
                      ),
                      PortalDetailRow(
                        label: 'Locked',
                        value: formatInr(wallet?.lockedBalance ?? 0),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed:
                              wallet == null ||
                                  wallet.balance < minimumWithdrawal
                              ? null
                              : () =>
                                    _openWithdrawSheet(context, wallet.balance),
                          icon: const Icon(LucideIcons.banknote, size: 16),
                          label: const Text('Withdraw'),
                        ),
                      ),
                      if (wallet != null &&
                          wallet.balance < minimumWithdrawal) ...[
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
                Text('Transaction history', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (transactionsAsync.value == null &&
                    transactionsAsync.hasError)
                  EmptyState(
                    icon: LucideIcons.triangleAlert,
                    title: "Couldn't load your transactions",
                    description: authErrorMessage(transactionsAsync.error!),
                    action: OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(artistWalletTransactionsProvider),
                      child: const Text('Try again'),
                    ),
                  )
                else if (transactionsAsync.value == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (transactionsAsync.requireValue.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.wallet,
                    title: 'No transactions yet',
                    description:
                        'Settlements and withdrawals will show up here.',
                  )
                else
                  for (final transaction in transactionsAsync.requireValue)
                    WalletTransactionRow(transaction: transaction),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final profile = ref
                        .watch(artistProfileDetailsProvider)
                        .value;
                    if (profile == null) return const SizedBox.shrink();
                    return GstNumberCard(
                      value: profile.gstin ?? '',
                      description: 'Used on your settlement statements and invoices. Also editable from your profile.',
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

  Future<void> _openWithdrawSheet(BuildContext context, double balance) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _WithdrawSheet(balance: balance),
    );
  }
}

/// The withdrawal request. It is a request, not a transfer: GalleryZone pays it
/// out by hand to the account on file, so the sheet says what was asked for and
/// when to expect it, rather than claiming the money has moved.
class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.balance});

  final double balance;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _amount = TextEditingController();
  bool _busy = false;
  double? _requested;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;
  bool get _belowMinimum =>
      _amount.text.trim().isNotEmpty && _value < minimumWithdrawal;
  bool get _exceedsBalance => _value > widget.balance;
  bool get _canSubmit =>
      _value >= minimumWithdrawal && _value <= widget.balance;

  Future<void> _submit() async {
    if (!_canSubmit || _busy) return;
    final amount = _value;
    final container = ProviderScope.containerOf(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(artistRepositoryProvider).requestWithdrawal(amount);
      container
        ..invalidate(artistWalletProvider)
        ..invalidate(artistWalletTransactionsProvider)
        ..invalidate(artistKpisProvider)
        ..invalidate(artistActivityProvider);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _requested = amount;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(artistProfileDetailsProvider).value;
    final masked = profile?.bankAccountMasked ?? '';
    final last4 = masked.length >= 4 ? masked.substring(masked.length - 4) : '';
    final requested = _requested;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: requested != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 20,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Withdrawal requested.',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatInr(requested)} will be sent to your bank account'
                    '${last4.isEmpty ? '' : ' ending $last4'}. This typically takes 1–2 business days.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Withdraw funds', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  PortalCard(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Icon(
                            LucideIcons.building2,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                masked.isEmpty
                                    ? 'No payout account on file'
                                    : masked,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if ((profile?.ifsc ?? '').isNotEmpty)
                                Text(
                                  profile!.ifsc,
                                  style: theme.textTheme.labelSmall,
                                ),
                            ],
                          ),
                        ),
                        if (masked.isEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/dashboard/profile');
                            },
                            child: const Text('Add one'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: '5000',
                      errorText: _belowMinimum
                          ? 'Minimum withdrawal is ₹1,000'
                          : _exceedsBalance
                          ? 'Exceeds your available balance'
                          : null,
                      helperText:
                          'Minimum ₹1,000 · Available ${formatInr(widget.balance)}',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _canSubmit && !_busy ? _submit : null,
                    child: Text(_busy ? 'Requesting…' : 'Request withdrawal'),
                  ),
                ],
              ),
      ),
    );
  }
}

/// What is waiting on the 7-day clock, and when each piece of it lands. Money
/// from a sale is not yours to withdraw the moment it sells: it clears seven
/// days after the artwork reaches the buyer, so this card answers "where is my
/// money" before the artist has to ask.
///
/// The "mark delivered" button is a demo shortcut for the offline build only -
/// there is no courier there, so nothing would ever mark a delivery long enough
/// ago for the seven days to have elapsed. Against the real service a delivery
/// is recorded by the operations team and the button is not offered.
class _PendingSettlements extends ConsumerWidget {
  const _PendingSettlements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remote = ref.watch(remoteBackendProvider);
    final settlements = ref.watch(artistSettlementsProvider).value ?? const [];
    final pending = [
      for (final settlement in settlements)
        if (settlement.status == SettlementStatus.pending) settlement,
    ];
    if (pending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('On the way to you', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Sales clear $artistPayoutDaysAfterDelivery days after the artwork is delivered to the buyer.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
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
                          ? 'Waiting for the artwork to be delivered'
                          : 'Delivered — clears ${formatDay(settlement.releaseAfter!)}',
                      style: theme.textTheme.labelSmall?.copyWith(height: 1.45),
                    ),
                    if (!remote && settlement.releaseAfter == null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () =>
                              _simulate(context, ref, settlement.id),
                          child: const Text('Simulate delivery (demo)'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _simulate(BuildContext context, WidgetRef ref, String settlementId) {
    // Backdates the delivery far enough that the seven days have already run,
    // then releases - otherwise this button would appear to do nothing.
    simulateDeliveryAndRelease(settlementId);
    ref.invalidate(artistWalletProvider);
    ref.invalidate(artistWalletTransactionsProvider);
    ref.invalidate(artistSettlementsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivered and released to your balance')),
    );
  }
}

