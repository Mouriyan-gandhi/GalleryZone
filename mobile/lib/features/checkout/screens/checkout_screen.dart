import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/payments/payment_gateway.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/auth.dart';
import '../../../data/models/order.dart';
import '../../auth/providers/auth_providers.dart';
import '../../account/providers/account_providers.dart';
import '../../marketplace/providers/marketplace_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/payee_details.dart';
import '../../shell/price_breakdown.dart';
import '../providers/checkout_providers.dart';

/// Port of `app/checkout/page.tsx` + `features/checkout/*`: address, review,
/// confirm - on one route, as on the website.
///
/// Prices are the server's: the review and the Pay button show the quote the
/// API gives for this piece, so what is shown is what the order is built from.
/// Paying opens Razorpay's sheet; closing it leaves the order pending and the
/// buyer here, with nothing charged.
///
/// The offline demo build (no API) keeps its pretend payment sheet as an extra
/// step between review and confirm, so the whole journey can still be shown
/// without a network; it never appears with the real backend.
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

  /// The piece as it was when checkout opened. Buying it flips it to `sold`
  /// and the catalogue is re-read; the receipt must not turn into "nothing to
  /// check out" the moment that happens.
  Artwork? _artwork;

  List<_Step> get _steps => ref.read(remoteBackendProvider)
      ? const [_Step.address, _Step.review, _Step.confirm]
      : _Step.values;

  void _goTo(_Step step) {
    // Backward only, and never once the order is placed.
    if (_placedOrder != null) return;
    if (_steps.indexOf(step) > _steps.indexOf(_step)) return;
    setState(() => _step = step);
  }

  void _next() {
    final steps = _steps;
    setState(() => _step = steps[steps.indexOf(_step) + 1]);
  }

  @override
  Widget build(BuildContext context) {
    final artworkId = widget.artworkId;
    if (artworkId == null || artworkId.isEmpty) return _nothingToCheckOut(context);

    // Orders are placed from a collector account (the API refuses anyone
    // else); without this a signed-in artist would reach a payment that fails.
    final role = ref.watch(sessionProvider);
    if (ref.watch(remoteBackendProvider) && role != null && role != Role.customer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: _CollectorOnly(artworkId: artworkId),
      );
    }

    final artwork = ref.watch(artworkProvider(artworkId));
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: artwork.when(
        loading: () => _artwork != null
            ? _flow(_artwork!)
            : const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _artwork != null
            ? _flow(_artwork!)
            : EmptyState(
                icon: LucideIcons.triangleAlert,
                title: 'Something went wrong',
                description: "We couldn't start checkout right now.",
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(artworkProvider(artworkId)),
                  child: const Text('Try again'),
                ),
              ),
        data: (data) {
          _artwork ??= data;
          final piece = _artwork;
          // A piece that is not on the marketplace any more cannot be bought.
          if (piece == null || (piece.status != ArtworkStatus.marketplace && _placedOrder == null)) {
            return _nothingToCheckOutBody(context);
          }
          return _flow(piece);
        },
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
    final remote = ref.watch(remoteBackendProvider);
    return ContentWidth(
      maxWidth: 600,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _StepIndicator(
            steps: _steps,
            current: _step,
            locked: _placedOrder != null,
            confirmLabel: remote ? 'Confirm' : 'Done',
            onTap: _goTo,
          ),
          const SizedBox(height: 24),
          switch (_step) {
            _Step.address => _AddressStep(
              selectedId: _address?.id,
              onSelect: (address) => setState(() => _address = address),
              onContinue: _address == null ? null : _next,
            ),
            _Step.review => _ReviewStep(
              artwork: artwork,
              address: _address!,
              onBack: () => _goTo(_Step.address),
              onContinue: _next,
            ),
            _Step.payment => _DemoPaymentStep(
              artwork: artwork,
              isPlacing: _isPlacing,
              onBack: () => _goTo(_Step.review),
              onPay: (method, simulateFailure) => _placeOrder(artwork, method, simulateFailure),
            ),
            _Step.confirm => _ConfirmStep(
              artwork: artwork,
              address: _address!,
              placedOrder: _placedOrder,
              isPlacing: _isPlacing,
              remote: remote,
              onBack: () => _goTo(remote ? _Step.review : _Step.payment),
              onPay: () => _placeOrder(artwork, PaymentMethod.upi, false),
            ),
          },
        ],
      ),
    );
  }

  Future<void> _placeOrder(Artwork artwork, PaymentMethod method, bool simulateFailure) async {
    setState(() => _isPlacing = true);
    final messenger = ScaffoldMessenger.of(context);
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
      ref.invalidate(marketplaceFeedProvider);
      ref.invalidate(marketplaceOverviewProvider);
      ref.invalidate(artworksByArtistProvider);
    } on PaymentDismissedException {
      // Closing the sheet is not an error: nothing was charged.
      messenger.showSnackBar(const SnackBar(content: Text('Payment cancelled — nothing was charged.')));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}

/// Someone signed in as an artist or an aggregator reaching "Buy now".
class _CollectorOnly extends ConsumerWidget {
  const _CollectorOnly({required this.artworkId});

  final String artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.userRound, size: 32, color: theme.colorScheme.tertiary),
              const SizedBox(height: 16),
              Text(
                'Buying needs a collector account',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'The certificate and ownership record are issued to the collector who places the order.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final next = Uri.encodeComponent('/checkout?artworkId=${Uri.encodeComponent(artworkId)}');
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go('/login?next=$next');
                },
                child: const Text('Sign in as a collector'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go('/register?role=customer'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.current,
    required this.locked,
    required this.confirmLabel,
    required this.onTap,
  });

  final List<_Step> steps;
  final _Step current;
  final bool locked;
  final String confirmLabel;
  final ValueChanged<_Step> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = {
      _Step.address: 'Address',
      _Step.review: 'Review',
      _Step.payment: 'Payment',
      _Step.confirm: confirmLabel,
    };
    final currentIndex = steps.indexOf(current);
    // Four labelled steps do not fit a narrow phone; like the website's own
    // indicator below its breakpoint, the other steps keep just their number.
    final showAllLabels = MediaQuery.sizeOf(context).width >= 440;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: i > currentIndex || locked ? null : () => onTap(steps[i]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < currentIndex || locked ? theme.colorScheme.tertiary : Colors.transparent,
                    border: Border.all(
                      color: i <= currentIndex ? theme.colorScheme.tertiary : theme.colorScheme.outline,
                    ),
                  ),
                  child: i < currentIndex || locked
                      ? Icon(LucideIcons.check, size: 13, color: theme.colorScheme.onTertiary)
                      : Text('${i + 1}', style: theme.textTheme.labelSmall),
                ),
                if (showAllLabels || steps[i] == current) ...[
                  const SizedBox(width: 8),
                  Text(
                    labels[steps[i]]!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: steps[i] == current ? theme.colorScheme.onSurface : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: i < currentIndex ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outline,
              ),
            ),
        ],
      ],
    );
  }
}

/// Step 1 - pick a saved address, or add one inline. A newly added address
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
  bool _makeDefault = false;
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
    final messenger = ScaffoldMessenger.of(context);
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
              isDefault: _makeDefault,
            ),
          );
      if (!mounted) return;
      widget.onSelect(created);
      ref.invalidate(addressesProvider);
      setState(() {
        _isAdding = false;
        _makeDefault = false;
      });
      for (final controller in [_line1, _line2, _city, _state, _pincode]) {
        controller.clear();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
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
        Text('Where should we deliver this?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Choose a saved address, or add a new one for this order.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        addresses.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
          ),
          error: (error, stack) => EmptyState(
            icon: LucideIcons.triangleAlert,
            title: 'Something went wrong',
            description: "We couldn't load your saved addresses.",
            action: OutlinedButton(
              onPressed: () => ref.invalidate(addressesProvider),
              child: const Text('Try again'),
            ),
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _isAdding = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add a new address'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: theme.colorScheme.tertiary),
            ),
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
                  maxLength: 6,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _makeDefault,
                  onChanged: _isSaving ? null : (value) => setState(() => _makeDefault = value == true),
                  title: const Text('Set as default address'),
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
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLength: maxLength,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(labelText: label, counterText: ''),
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
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.cardTheme.color,
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
      ),
    );
  }
}

/// Step 2 - a read-only summary before the buyer commits. The totals are the
/// server's quote for this piece, so this preview cannot drift from what Pay
/// then charges.
class _ReviewStep extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quote = ref.watch(checkoutQuoteProvider(artwork.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review your order', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Confirm the artwork, delivery address, and total before placing your order.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(width: 76, height: 95, child: ArtworkImageView(url: artwork.thumbnailUrl)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      humanize(artwork.category),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.tertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(artwork.artistName, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 14, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Text('DELIVERING TO', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  address.line2 == null ? address.line1 : '${address.line1}, ${address.line2}',
                  '${address.city}, ${address.state} ${address.pincode}',
                ].join('\n'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        quote.when(
          data: (q) => PriceBreakdown(
            displayPrice: q.displayPrice,
            gstIncluded: q.gstIncluded,
            gstRate: q.gstRate,
            deliveryCharge: q.deliveryCharge,
            convenienceFee: q.convenienceFee,
            convenienceGst: q.convenienceGst,
          ),
          loading: () => _QuoteNote(text: 'Working out your total…'),
          error: (error, stack) => _QuoteNote(
            text: "We couldn't price this order just now. Please try again in a moment.",
            onRetry: () => ref.invalidate(checkoutQuoteProvider(artwork.id)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onBack, child: const Text('Back')),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: quote.hasValue ? onContinue : null,
                child: const Text('Continue to confirm'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuoteNote extends StatelessWidget {
  const _QuoteNote({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.bodySmall),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Step 3 - one action. Paying opens the gateway's sheet; once it reports a
/// payment the order is read back and shown as placed.
class _ConfirmStep extends ConsumerWidget {
  const _ConfirmStep({
    required this.artwork,
    required this.address,
    required this.placedOrder,
    required this.isPlacing,
    required this.remote,
    required this.onBack,
    required this.onPay,
  });

  final Artwork artwork;
  final Address address;
  final Order? placedOrder;
  final bool isPlacing;
  final bool remote;
  final VoidCallback onBack;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final order = placedOrder;

    if (order != null) {
      final payment = order.payment;
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
          if (payment != null && payment.paymentId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${payment.paymentId}${payment.simulated ? ' · simulated payment' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/account/orders/${order.id}'),
            child: const Text('View order'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/marketplace'),
            child: const Text('Continue browsing'),
          ),
        ],
      );
    }

    // The offline build reaches this step only through its pretend payment
    // sheet, so there is nothing to confirm until that has run.
    if (!remote) {
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

    final quote = ref.watch(checkoutQuoteProvider(artwork.id));
    final total = quote.value?.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ready to place your order', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'You\'re buying "${artwork.title}", delivered to ${address.line1}, ${address.city}. Paying opens the '
          'secure Razorpay checkout — UPI, cards and net banking.',
          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: isPlacing ? null : onBack, child: const Text('Back')),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: isPlacing || total == null ? null : onPay,
                child: isPlacing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Waiting for payment…'),
                        ],
                      )
                    : Text(total == null ? 'Working out your total…' : 'Pay ${formatInr(total)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Payment always reaches GalleryZone, including when the buyer is
        // standing in a partner gallery - the aggregator collects on our behalf
        // and never for themselves.
        PayeeDetails(
          amount: total ?? artwork.customerPrice,
          note: 'GZ ${artwork.title.length > 24 ? artwork.title.substring(0, 24) : artwork.title}',
        ),
      ],
    );
  }
}

/// The pretend payment sheet of the offline demo build.
///
/// **No gateway is contacted.** It collects a method and shows the flow a buyer
/// expects, and the mock repository treats "payment succeeded" as a given. The
/// declined-payment toggle exists because a demo that can only ever succeed
/// hides the error path. With the real backend this step does not exist: Pay
/// opens Razorpay instead.
class _DemoPaymentStep extends ConsumerStatefulWidget {
  const _DemoPaymentStep({
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
  ConsumerState<_DemoPaymentStep> createState() => _DemoPaymentStepState();
}

class _DemoPaymentStepState extends ConsumerState<_DemoPaymentStep> {
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
    final quote = ref.watch(checkoutQuoteProvider(widget.artwork.id));
    final total = quote.value?.total ?? widget.artwork.customerPrice;

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
        PayeeDetails(
          amount: total,
          note: '${widget.artwork.title} — ${widget.artwork.id}',
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
            decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'name@bank'),
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
                'Demo payment — no gateway is contacted and no money moves.',
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
                onPressed: widget.isPlacing || !_canPay ? null : () => widget.onPay(_method, _simulateFailure),
                child: Text(widget.isPlacing ? 'Processing…' : 'Pay ${formatInr(total)}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
