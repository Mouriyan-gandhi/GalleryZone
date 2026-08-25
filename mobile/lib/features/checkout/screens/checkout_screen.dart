import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_checkout_repository.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/order.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../account/providers/account_providers.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/price_breakdown.dart';
import '../providers/checkout_providers.dart';

/// Port of `app/checkout/page.tsx` + `features/checkout/*`. Three steps on
/// one route (address → review → confirm), same as the web's single-page
/// flow. **No payment step** — the web build has none either; adding one is
/// blocked on the still-open payment-gateway decision, and confirming here
/// places the order at the reviewed price, exactly as the web does.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.artworkId});

  static const path = '/checkout';

  final String? artworkId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _Step { address, review, payment, confirm }

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  _Step _step = _Step.address;
  Address? _address;
  Order? _placedOrder;
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final artworkId = widget.artworkId;
    if (artworkId == null || artworkId.isEmpty) return _nothingToCheckOut(context);

    final artwork = ref.watch(artworkProvider(artworkId));
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: artwork.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: 'Something went wrong',
          description: "We couldn't start checkout right now.",
        ),
        data: (data) => data == null ? _nothingToCheckOutBody(context) : _flow(data),
      ),
    );
  }

  Widget _nothingToCheckOut(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: _nothingToCheckOutBody(context),
  );

  Widget _nothingToCheckOutBody(BuildContext context) => EmptyState(
    icon: LucideIcons.shoppingBag,
    title: 'Nothing to check out.',
    description:
        "We couldn't find an artwork to buy. Head back to the marketplace "
        'and pick a piece to get started.',
    action: FilledButton(
      onPressed: () => context.go('/marketplace'),
      child: const Text('Browse the marketplace'),
    ),
  );

  Widget _flow(Artwork artwork) {
    return ContentWidth(
      maxWidth: 600,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _StepIndicator(
            current: _step,
            locked: _placedOrder != null,
            onTap: (step) {
              // Backward only, and never once the order is placed.
              if (_placedOrder != null || step.index > _step.index) return;
              setState(() => _step = step);
            },
          ),
          const SizedBox(height: 24),
          switch (_step) {
            _Step.address => _AddressStep(
              selectedId: _address?.id,
              onSelect: (address) => setState(() => _address = address),
              onContinue: _address == null ? null : () => setState(() => _step = _Step.review),
            ),
            _Step.review => _ReviewStep(
              artwork: artwork,
              address: _address!,
              onBack: () => setState(() => _step = _Step.address),
              onContinue: () => setState(() => _step = _Step.payment),
            ),
            _Step.payment => _PaymentStep(
              artwork: artwork,
              isPlacing: _isPlacing,
              onBack: () => setState(() => _step = _Step.review),
              onPay: (method, simulateFailure) =>
                  _placeOrder(artwork, method, simulateFailure),
            ),
            _Step.confirm => _ConfirmStep(
              artwork: artwork,
              address: _address!,
              placedOrder: _placedOrder,
              isPlacing: _isPlacing,
              onBack: () => setState(() => _step = _Step.payment),
            ),
          },
        ],
      ),
    );
  }

  Future<void> _placeOrder(
    Artwork artwork,
    PaymentMethod method,
    bool simulateFailure,
  ) async {
    setState(() => _isPlacing = true);
    try {
      final order = await ref
          .read(checkoutRepositoryProvider)
          .createOrder(
            artworkId: artwork.id,
            addressId: _address!.id,
            paymentMethod: method,
            simulateFailure: simulateFailure,
          );
      if (!mounted) return;
      setState(() {
        _placedOrder = order;
        _step = _Step.confirm;
      });
      // The buyer's own screens read these, and the artist's wallet just
      // gained a pending credit.
      ref.invalidate(ordersProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(collectionProvider);
      // The artwork just went to `sold`; drop the cached reads so the
      // marketplace grid and its detail page don't show it as available.
      ref.invalidate(artworkProvider);
      ref.invalidate(artworksProvider);
      ref.invalidate(artworksByArtistProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.locked, required this.onTap});

  final _Step current;
  final bool locked;
  final ValueChanged<_Step> onTap;

  static const _labels = {
    _Step.address: 'Address',
    _Step.review: 'Review',
    _Step.payment: 'Payment',
    _Step.confirm: 'Done',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final step in _Step.values) ...[
          InkWell(
            onTap: step.index > current.index || locked ? null : () => onTap(step),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.index < current.index || locked
                        ? theme.colorScheme.tertiary
                        : Colors.transparent,
                    border: Border.all(
                      color: step.index <= current.index
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: step.index < current.index || locked
                      ? Icon(LucideIcons.check, size: 13, color: theme.colorScheme.onTertiary)
                      : Text('${step.index + 1}', style: theme.textTheme.labelSmall),
                ),
                const SizedBox(width: 8),
                Text(
                  _labels[step]!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: step == current ? theme.colorScheme.onSurface : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (step != _Step.confirm)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: step.index < current.index
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outline,
              ),
            ),
        ],
      ],
    );
  }
}

/// Step 1 — pick a saved address, or add one inline. A newly added address
/// is selected immediately; the provider is invalidated so the list reflects
/// it rather than tracking a parallel session-only copy the way the web has
/// to.
class _AddressStep extends ConsumerStatefulWidget {
  const _AddressStep({required this.selectedId, required this.onSelect, required this.onContinue});

  final String? selectedId;
  final ValueChanged<Address> onSelect;
  final VoidCallback? onContinue;

  @override
  ConsumerState<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends ConsumerState<_AddressStep> {
  final _formKey = GlobalKey<FormState>();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  bool _isAdding = false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in [_line1, _line2, _city, _state, _pincode]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final created = await ref
          .read(customerRepositoryProvider)
          .addAddress(
            Address(
              id: '',
              line1: _line1.text.trim(),
              line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              pincode: _pincode.text.trim(),
              isDefault: false,
            ),
          );
      if (!mounted) return;
      widget.onSelect(created);
      ref.invalidate(addressesProvider);
      setState(() => _isAdding = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = ref.watch(addressesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delivery address', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        addresses.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const EmptyState(
            icon: LucideIcons.triangleAlert,
            title: 'Something went wrong',
            description: "We couldn't load your saved addresses.",
          ),
          data: (list) => Column(
            children: [
              for (final address in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AddressTile(
                    address: address,
                    selected: address.id == widget.selectedId,
                    onTap: () => widget.onSelect(address),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!_isAdding)
          OutlinedButton.icon(
            onPressed: () => setState(() => _isAdding = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add a new address'),
          )
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  _line1,
                  'Address line 1',
                  (v) => (v ?? '').trim().length < 3 ? 'Enter the address line' : null,
                ),
                _field(_line2, 'Address line 2 (optional)', null),
                _field(_city, 'City', (v) => (v ?? '').trim().length < 2 ? 'Enter the city' : null),
                _field(
                  _state,
                  'State',
                  (v) => (v ?? '').trim().length < 2 ? 'Enter the state' : null,
                ),
                _field(
                  _pincode,
                  'Pincode',
                  (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                      ? null
                      : 'Enter a valid 6-digit pincode',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => setState(() => _isAdding = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: Text(_isSaving ? 'Saving…' : 'Save address'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: widget.onContinue,
            child: const Text('Continue to review'),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    FormFieldValidator<String>? validator, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.selected, required this.onTap});

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? theme.colorScheme.tertiary : theme.colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? LucideIcons.circleCheckBig : LucideIcons.mapPin,
              size: 18,
              color: selected ? theme.colorScheme.tertiary : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.line1,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (address.line2 != null) Text(address.line2!, style: theme.textTheme.bodySmall),
                  Text(
                    '${address.city}, ${address.state} ${address.pincode}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (address.isDefault) Text('Default', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Step 2 — the price breakdown. This math mirrors
/// `MockCheckoutRepository.createOrder` exactly; the constants come from the
/// same file so the preview can never disagree with what gets charged.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.artwork,
    required this.address,
    required this.onBack,
    required this.onContinue,
  });

  final Artwork artwork;
  final Address address;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = checkoutTotal(artwork.customerPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review your order', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 76,
                height: 95,
                child: ArtworkImageView(url: artwork.thumbnailUrl),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(artwork.artistName, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(artwork.medium, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        PriceBreakdown(
          displayPrice: totals.displayPrice,
          gstIncluded: totals.gstIncluded,
          deliveryCharge: totals.deliveryCharge,
          convenienceFee: totals.convenienceFee,
          platformFee: checkoutPlatformFee,
        ),
        const SizedBox(height: 20),
        Text('Delivering to', style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          [
            address.line1,
            address.line2,
            '${address.city}, ${address.state} ${address.pincode}',
          ].whereType<String>().join('\n'),
          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onBack, child: const Text('Back')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: onContinue, child: const Text('Continue')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Step 3 — one action. No payment form in this build (same as the web);
/// confirming places the order at the reviewed price.
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.artwork,
    required this.address,
    required this.placedOrder,
    required this.isPlacing,
    required this.onBack,
  });

  final Artwork artwork;
  final Address address;
  final Order? placedOrder;
  final bool isPlacing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = placedOrder;

    if (order != null) {
      return Column(
        children: [
          Icon(LucideIcons.circleCheckBig, size: 40, color: theme.colorScheme.tertiary),
          const SizedBox(height: 16),
          Text('Order placed', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '"${artwork.title}" is on its way to ${address.city}. We\'ll keep you '
            'updated as it moves through packing and dispatch.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Total paid ', style: theme.textTheme.bodySmall),
              PriceTag(amount: order.total, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/account/orders/${order.id}'),
            child: const Text('Track this order'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/marketplace'),
            child: const Text('Continue browsing'),
          ),
        ],
      );
    }

    // Only reachable by tapping back into a finished step, which the
    // indicator locks once an order exists — so this is the "you haven't
    // paid yet" fallback rather than a step of its own.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nothing placed yet', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Go back to the payment step to complete this purchase.',
          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: isPlacing ? null : onBack, child: const Text('Back')),
      ],
    );
  }
}

/// The mock payment step.
///
/// **No gateway is contacted.** Which one to integrate is still an open
/// product decision (Razorpay is the standing recommendation), so this
/// collects a method and shows the flow a buyer expects, and the repository
/// treats "payment succeeded" as a given. The declined-payment toggle exists
/// because a demo that can only ever succeed hides the error path — and that
/// path is the one that matters when a real gateway lands here.
class _PaymentStep extends StatefulWidget {
  const _PaymentStep({
    required this.artwork,
    required this.isPlacing,
    required this.onBack,
    required this.onPay,
  });

  final Artwork artwork;
  final bool isPlacing;
  final VoidCallback onBack;
  final void Function(PaymentMethod method, bool simulateFailure) onPay;

  @override
  State<_PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<_PaymentStep> {
  PaymentMethod _method = PaymentMethod.upi;
  bool _simulateFailure = false;

  // Prefilled with obvious test values: this is a demo, and making someone
  // type a card number to see the next screen serves nobody.
  final _upi = TextEditingController(text: 'collector@okhdfc');
  final _card = TextEditingController(text: '4242 4242 4242 4242');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');
  String _bank = 'HDFC Bank';

  static const _banks = ['HDFC Bank', 'ICICI Bank', 'State Bank of India', 'Axis Bank'];

  @override
  void dispose() {
    for (final controller in [_upi, _card, _expiry, _cvv]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canPay => switch (_method) {
    PaymentMethod.upi => _upi.text.trim().isNotEmpty,
    PaymentMethod.card =>
      _card.text.trim().isNotEmpty && _expiry.text.trim().isNotEmpty && _cvv.text.trim().isNotEmpty,
    PaymentMethod.netbanking => true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = checkoutTotal(widget.artwork.customerPrice).total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Payment', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Amount due ', style: theme.textTheme.bodySmall),
            PriceTag(amount: total, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),
        RadioGroup<PaymentMethod>(
          groupValue: _method,
          onChanged: (value) => setState(() => _method = value!),
          child: Column(
            children: [
              for (final method in PaymentMethod.values)
                RadioListTile<PaymentMethod>(
                  contentPadding: EdgeInsets.zero,
                  value: method,
                  title: Text(paymentMethodLabel[method]!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        switch (_method) {
          PaymentMethod.upi => TextField(
            controller: _upi,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'name@bank',
            ),
          ),
          PaymentMethod.card => Column(
            children: [
              TextField(
                controller: _card,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Card number'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiry,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Expiry'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvv,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'CVV'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          PaymentMethod.netbanking => DropdownButtonFormField<String>(
            initialValue: _bank,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Bank'),
            items: [
              for (final bank in _banks) DropdownMenuItem(value: bank, child: Text(bank)),
            ],
            onChanged: (value) => setState(() => _bank = value!),
          ),
        },
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _simulateFailure,
          onChanged: (value) => setState(() => _simulateFailure = value),
          title: const Text('Simulate a declined payment'),
          subtitle: Text(
            'Shows the failure path instead of placing the order.',
            style: theme.textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.info, size: 14, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mock payment — no gateway is contacted and no money moves.',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isPlacing ? null : widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: widget.isPlacing || !_canPay
                    ? null
                    : () => widget.onPay(_method, _simulateFailure),
                child: Text(
                  widget.isPlacing ? 'Processing…' : 'Pay ${formatInr(total)}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
