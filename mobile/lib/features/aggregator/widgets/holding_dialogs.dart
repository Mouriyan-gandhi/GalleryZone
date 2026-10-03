import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/payee_details.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';

// The three things an aggregator does to a piece they hold - record its sale,
// send it back, ask to keep it longer - shared by the inventory list and the
// holding page, as the web's dialogs are. Each runs its own request, stays open
// with the reason when it fails, and closes with a result on success; the
// `show…` functions then refresh everything the change touches and say so.
//
// The container, messenger and router are taken before the first await: the
// screen that opened a sheet may be gone by the time the request returns.

/// Records a sale of [view]'s piece. Port of `record-sale-dialog.tsx`.
Future<void> showRecordSale(BuildContext context, AggregatorHoldingView view) async {
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final email = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _RecordSaleSheet(view: view),
  );
  if (email == null) return;

  invalidateAggregatorSaleFlowIn(container);
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 7),
      content: Text(
        'Sale recorded. "${view.artwork.title}" is now pending settlement. The buyer\'s purchase is held '
        'against $email — it appears in their collection when they sign up with that address.',
      ),
      action: SnackBarAction(
        label: 'Settlements',
        onPressed: () => router.push('/aggregator/dashboard/settlements'),
      ),
    ),
  );
}

/// Sends [view]'s piece back to GalleryZone. Port of `return-holding-dialog.tsx`.
Future<void> showReturnHolding(BuildContext context, AggregatorHoldingView view) async {
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final release = await showDialog<HoldingRelease>(
    context: context,
    builder: (context) => _ReturnDialog(view: view),
  );
  if (release == null) return;

  invalidateAggregatorSaleFlowIn(container);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        'Returned to GalleryZone. ${formatInr(release.refunded)} advance released.'
        '${release.deliveryLost > 0 ? ' ${formatInr(release.deliveryLost)} delivery was charged.' : ''}',
      ),
    ),
  );
}

/// Asks GalleryZone to let the aggregator keep a piece past its window. Port of
/// `request-extension-dialog.tsx`.
Future<void> showRequestExtension(BuildContext context, AggregatorHoldingView view) async {
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  final sent = await showDialog<bool>(
    context: context,
    builder: (context) => _ExtensionDialog(view: view),
  );
  if (sent != true) return;

  invalidateAggregatorSaleFlowIn(container);
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        "Request sent to GalleryZone. If it isn't approved before the window ends, the piece goes back on "
        'sale and your advance is released.',
      ),
    ),
  );
}

/// A failed request, said where the person is still looking.
class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return PortalNotice(icon: LucideIcons.circleAlert, destructive: true, body: message);
  }
}

class _PieceRow extends StatelessWidget {
  const _PieceRow({required this.view});

  final AggregatorHoldingView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(width: 52, height: 52, child: ArtworkImageView(url: view.artwork.thumbnailUrl)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                view.artwork.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                view.artwork.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PriceTag(amount: view.holding.displayPrice, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// --- Return ---------------------------------------------------------------------------

class _ReturnDialog extends ConsumerStatefulWidget {
  const _ReturnDialog({required this.view});

  final AggregatorHoldingView view;

  @override
  ConsumerState<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends ConsumerState<_ReturnDialog> {
  bool _pending = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final release = await ref.read(aggregatorRepositoryProvider).releaseHolding(widget.view.holding.id);
      if (mounted) Navigator.of(context).pop(release);
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = authErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = widget.view.holding;
    final deliveryLost = holding.deliveryDeposit;

    return PopScope(
      canPop: !_pending,
      child: AlertDialog(
        title: const Text('Return this piece to GalleryZone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'It stops showing in your inventory and becomes reservable by another aggregator, at '
                "next month's price.",
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              PortalCard(child: _PieceRow(view: widget.view)),
              const SizedBox(height: 10),
              PortalCard(
                child: Column(
                  children: [
                    _MoneyLine(
                      label: 'Advance (${holding.advancePercent}%)',
                      hint: 'Released back to your wallet',
                      value: formatInr(holding.advanceAmount),
                    ),
                    const Divider(height: 18),
                    _MoneyLine(
                      label: 'Delivery deposit',
                      hint: deliveryLost > 0
                          ? 'Only refunded on a sale — forfeited on an unsold return'
                          : 'Nothing was held for delivery',
                      value: '${deliveryLost > 0 ? '−' : ''}${formatInr(deliveryLost)}',
                      destructive: deliveryLost > 0,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 10), _InlineError(_error!)],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _pending ? null : () => Navigator.of(context).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton.icon(
            style: deliveryLost > 0
                ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError)
                : null,
            onPressed: _pending ? null : _confirm,
            icon: const Icon(LucideIcons.undo2, size: 14),
            label: Text(_pending ? 'Returning…' : 'Return to GalleryZone'),
          ),
        ],
      ),
    );
  }
}

/// A label with a line of explanation, and its figure.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    this.hint,
    this.destructive = false,
  });

  final String label;
  final String value;
  final String? hint;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              if (hint != null) Text(hint!, style: theme.textTheme.labelSmall?.copyWith(height: 1.35)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: destructive ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}

// --- Ask to keep it longer ------------------------------------------------------------

/// The same floor the API enforces (`requestHoldingExtensionInputSchema`).
const _minAssurance = 10;

class _ExtensionDialog extends ConsumerStatefulWidget {
  const _ExtensionDialog({required this.view});

  final AggregatorHoldingView view;

  @override
  ConsumerState<_ExtensionDialog> createState() => _ExtensionDialogState();
}

class _ExtensionDialogState extends ConsumerState<_ExtensionDialog> {
  final _assurance = TextEditingController();
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _assurance.dispose();
    super.dispose();
  }

  bool get _tooShort => _assurance.text.trim().length < _minAssurance;

  Future<void> _send() async {
    if (_tooShort) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await ref
          .read(aggregatorRepositoryProvider)
          .requestExtension(widget.view.holding.id, _assurance.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = authErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_pending,
      child: AlertDialog(
        title: const Text('Ask to keep this piece longer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '"${widget.view.artwork.title}" moves on to another aggregator when its 30 days end. '
                'GalleryZone decides each request, and only agrees when you can say why it will sell.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _assurance,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                enabled: !_pending,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Your assurance that it will sell',
                  hintText: 'e.g. A collector has viewed it twice and is confirming this week.',
                  helperText: 'A sentence or two. GalleryZone reads this before answering.',
                  helperMaxLines: 2,
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 10), _InlineError(_error!)],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _pending ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _tooShort || _pending ? null : _send,
            child: Text(_pending ? 'Sending…' : 'Send request'),
          ),
        ],
      ),
    );
  }
}

// --- Record a sale --------------------------------------------------------------------

/// Fields match `POST /v1/aggregator/holdings/:id/sale`'s payload one-for-one,
/// with the delivery address's four sub-fields flattened for the form and
/// re-nested on submit.
class _RecordSaleSheet extends ConsumerStatefulWidget {
  const _RecordSaleSheet({required this.view});

  final AggregatorHoldingView view;

  @override
  ConsumerState<_RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends ConsumerState<_RecordSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _buyerName = TextEditingController();
  final _buyerEmail = TextEditingController();
  final _buyerPhone = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  DeliveryMode _mode = DeliveryMode.courier;
  PaymentRoute _route = PaymentRoute.directToGalleryZone;
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_buyerName, _buyerEmail, _buyerPhone, _line1, _city, _state, _pincode]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _atLeast(String? value, int length, String message) =>
      (value ?? '').trim().length < length ? message : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final holding = widget.view.holding;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await ref.read(aggregatorRepositoryProvider).recordSale(
            RecordSaleInput(
              artworkId: widget.view.artwork.id,
              // Always the holding's own price, set once when it was reserved: every
              // ledger posting for the sale settles on it, so any other figure would
              // only make the sale record and the money disagree.
              soldPrice: holding.displayPrice,
              buyerName: _buyerName.text,
              buyerEmail: _buyerEmail.text,
              buyerPhone: _buyerPhone.text,
              deliveryAddress: DeliveryAddress(
                line1: _line1.text.trim(),
                city: _city.text.trim(),
                state: _state.text.trim(),
                pincode: _pincode.text.trim(),
              ),
              deliveryMode: _mode,
              paymentRoute: _route,
            ),
          );
      if (mounted) Navigator.of(context).pop(_buyerEmail.text.trim());
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = authErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holding = widget.view.holding;

    return PopScope(
      canPop: !_pending,
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Record sale', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '"${widget.view.artwork.title}" — the buyer and delivery details used to confirm this sale.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                PortalCard(
                  gold: true,
                  child: Column(
                    children: [
                      _MoneyLine(
                        label: 'Month ${holding.cycleMonth} of $aggregatorCycleMonths display price',
                        value: formatInr(holding.displayPrice),
                      ),
                      const Divider(height: 18),
                      _MoneyLine(
                        label: 'Advance (${holding.advancePercent}%) + delivery',
                        hint: 'Set off against this sale, not credited separately',
                        value: formatInr(holding.advanceAmount + holding.deliveryDeposit),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your ${(aggregatorCommissionRate * 100).round()}% commission on the markup settles '
                          'separately once delivery is confirmed.',
                          style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Not editable: see _submit.
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sold price (₹)',
                    helperText: "This piece's selling price, including GST. It was set when you reserved the piece.",
                    helperMaxLines: 2,
                  ),
                  child: Text(holding.displayPrice.toStringAsFixed(0), style: theme.textTheme.bodyLarge),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buyerName,
                  enabled: !_pending,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Buyer name'),
                  validator: (value) => _atLeast(value, 2, "Enter the buyer's name"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buyerPhone,
                  enabled: !_pending,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Buyer phone'),
                  validator: (value) => _atLeast(value, 10, 'Enter a valid phone number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buyerEmail,
                  enabled: !_pending,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Buyer email'),
                  validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
                      ? null
                      : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _line1,
                  enabled: !_pending,
                  decoration: const InputDecoration(labelText: 'Delivery address'),
                  validator: (value) => _atLeast(value, 3, 'Enter the address'),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        enabled: !_pending,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (value) => _atLeast(value, 2, 'Enter the city'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _state,
                        enabled: !_pending,
                        decoration: const InputDecoration(labelText: 'State'),
                        validator: (value) => _atLeast(value, 2, 'Enter the state'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pincode,
                  enabled: !_pending,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  validator: (value) =>
                      RegExp(r'^\d{6}$').hasMatch((value ?? '').trim()) ? null : 'Enter a valid 6-digit pincode',
                ),
                const SizedBox(height: 4),
                Text('Delivery mode', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                SegmentedButton<DeliveryMode>(
                  segments: const [
                    ButtonSegment(value: DeliveryMode.courier, label: Text('Courier')),
                    ButtonSegment(value: DeliveryMode.selfPickup, label: Text('Self pickup')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _pending ? null : (selection) => setState(() => _mode = selection.first),
                ),
                const SizedBox(height: 20),
                // You collect on GalleryZone's behalf, never for yourself. Which of the
                // two routes the money took decides what you owe afterwards, so it is
                // recorded with the sale rather than sorted out later.
                Text('How did the buyer pay?', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                RadioGroup<PaymentRoute>(
                  groupValue: _route,
                  onChanged: (value) {
                    if (!_pending) setState(() => _route = value!);
                  },
                  child: Column(
                    children: [
                      RadioListTile<PaymentRoute>(
                        contentPadding: EdgeInsets.zero,
                        value: PaymentRoute.directToGalleryZone,
                        title: Text('Paid GalleryZone directly (transfer or UPI)', style: theme.textTheme.bodySmall),
                      ),
                      RadioListTile<PaymentRoute>(
                        contentPadding: EdgeInsets.zero,
                        value: PaymentRoute.cashAtPremises,
                        title: Text('Cash, collected by you', style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
                // Cash is GalleryZone's money in the aggregator's till. Say so at the
                // moment they choose it, not at settlement.
                Text(
                  _route == PaymentRoute.cashAtPremises
                      ? 'You will owe GalleryZone the full sale amount. Your commission is settled separately.'
                      : 'Nothing to transfer — the money reached GalleryZone directly.',
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                // Shown for both routes: if the buyer is paying directly these are the
                // details they need, and if they are paying cash these are the details
                // the aggregator will remit to.
                PayeeDetails(
                  amount: holding.displayPrice,
                  note: '${widget.view.artwork.title} — ${widget.view.artwork.id}',
                ),
                if (_error != null) ...[const SizedBox(height: 12), _InlineError(_error!)],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pending ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _pending ? null : _submit,
                        child: Text(_pending ? 'Recording…' : 'Record sale'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
