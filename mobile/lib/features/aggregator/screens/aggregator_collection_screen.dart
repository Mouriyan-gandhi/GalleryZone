import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/payee_details.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `app/aggregator/collection/page.tsx` — the web's "My Inventory".
/// The web's five-column table becomes a card per holding: a phone has no
/// room for a table, and every column here is a field, not a comparison.
class AggregatorCollectionScreen extends ConsumerWidget {
  const AggregatorCollectionScreen({super.key});

  static const path = '/aggregator/collection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(aggregatorCollectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My inventory')),
      body: collection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load your inventory",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (holdings) => holdings.isEmpty
            ? const EmptyState(
                icon: LucideIcons.galleryVerticalEnd,
                title: 'No holdings yet',
                description: 'Reserve an artwork from Browse to see it here.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aggregatorCollectionProvider);
                  await ref.read(aggregatorCollectionProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    ContentWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Manage display pricing and record sales for pieces you '
                            'have reserved.',
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          for (final view in holdings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HoldingCard(view: view),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HoldingCard extends ConsumerWidget {
  const _HoldingCard({required this.view});

  final AggregatorHoldingView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final holding = view.holding;
    final sold = holding.status == HoldingStatus.soldPendingSettlement;
    // MOU §6, and the cycle: only the first aggregator to display a work may
    // price it, and only once. From month two the price is GalleryZone's,
    // because the advance is cheaper instead.
    final canPrice = !sold &&
        canSetDisplayPrice(holding.cycleMonth) &&
        holding.displayPriceSetAt == null;

    return PortalCard(
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ArtworkImageView(url: view.artwork.thumbnailUrl),
                ),
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
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(view.artwork.artistName, style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    HoldingStatusPill(status: holding.status),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Display price is a button, not a row: it's the one figure on this
          // card the aggregator owns and edits.
          InkWell(
            onTap: canPrice ? () => _openPriceSheet(context, ref, view) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Display price', style: theme.textTheme.bodySmall),
                  ),
                  Text(
                    formatInr(holding.displayPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  if (canPrice) ...[
                    const SizedBox(width: 6),
                    Icon(LucideIcons.pencil, size: 12, color: theme.colorScheme.outline),
                  ],
                ],
              ),
            ),
          ),
          if (!sold && !canPrice)
            Text(
              holding.displayPriceSetAt != null
                  ? 'You have used your one price change (MOU §6).'
                  : 'GalleryZone sets the price from month two onwards.',
              style: theme.textTheme.labelSmall,
            ),
          PortalDetailRow(
            label: 'Advance held (${holding.advancePercent}%)',
            value: formatInr(holding.advanceAmount),
          ),
          PortalDetailRow(
            label: 'Delivery held',
            value: formatInr(holding.deliveryDeposit),
          ),
          PortalDetailRow(
            label: 'Cycle',
            value: 'Month ${holding.cycleMonth} of $aggregatorCycleMonths',
          ),
          PortalDetailRow(
            label: 'Assigned',
            value: holding.assignmentSource == AssignmentSource.gzAssigned
                ? 'By GalleryZone'
                : 'You reserved it',
          ),
          if (!sold) ...[
            const SizedBox(height: 8),
            ExpiryCountdown(expiresAt: holding.expiresAt),
            if (holding.windowExtended)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  // The client's own case: a stub of under thirty days is not
                  // worth shipping to anyone else, so whoever has the piece
                  // keeps it to the end of the artist's 180 days.
                  'Extended — too little of this piece\'s listing was left to '
                  'place it elsewhere, so it stays with you until the listing '
                  'ends.',
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                ),
              ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: sold
                ? OutlinedButton(onPressed: null, child: const Text('Sale recorded'))
                : FilledButton(
                    onPressed: () => _openRecordSaleSheet(context, ref, view),
                    child: const Text('Record sale'),
                  ),
          ),
          if (!sold) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: TextButton(
                onPressed: () => _confirmReturn(context, ref, view),
                child: const Text('Return unsold'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openPriceSheet(
  BuildContext context,
  WidgetRef ref,
  AggregatorHoldingView view,
) async {
  // The floor is what GalleryZone offered THIS aggregator, which from month
  // two sits below the marketplace price. Using the marketplace price here
  // would refuse a perfectly legal raise.
  final floor = view.holding.displayPrice;
  final controller =
      TextEditingController(text: view.holding.displayPrice.toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();

  final price = await showModalBottomSheet<double>(
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
            Text('Edit display price', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '"${view.artwork.title}" — you may raise the selling price above '
              'what GalleryZone offered you, never below it. MOU §6 gives you '
              'one opportunity, and raising the price raises the advance held '
              'from your wallet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Display price (₹)',
                helperText: "Floor: ${formatInr(floor)} (GalleryZone's price to you)",
              ),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter a price';
                if (parsed < floor) {
                  return 'Cannot be lower than the floor of ${formatInr(floor)}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(double.parse(controller.text.trim()));
              },
              child: const Text('Save price'),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
  if (price == null) return;

  try {
    await ref.read(aggregatorRepositoryProvider).updateDisplayPrice(view.holding.id, price);
    // Commission is derived from this figure, so the KPI, analytics and
    // settlement numbers all move with it.
    invalidateAggregatorSaleFlow(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Display price updated')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

/// The piece did not sell and goes back to GalleryZone.
///
/// Confirmed rather than done on tap, because the delivery leg is genuinely
/// spent here — the money-flow sheet settles it only on a sale — and that is
/// not something to discover afterwards.
Future<void> _confirmReturn(
  BuildContext context,
  WidgetRef ref,
  AggregatorHoldingView view,
) async {
  final holding = view.holding;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Return this piece unsold?'),
      content: Text(
        '"${view.artwork.title}" goes back to GalleryZone and can be placed with '
        'another aggregator.\n\n'
        'Your ${formatInr(holding.advanceAmount)} advance is released. The '
        '${formatInr(holding.deliveryDeposit)} delivery charge is not — that is '
        'settled only on a sale.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Return unsold'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final release =
        await ref.read(aggregatorRepositoryProvider).releaseHolding(holding.id);
    invalidateAggregatorSaleFlow(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${formatInr(release.refunded)} released · '
          '${formatInr(release.deliveryLost)} delivery charged',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

Future<void> _openRecordSaleSheet(
  BuildContext context,
  WidgetRef ref,
  AggregatorHoldingView view,
) async {
  final input = await showModalBottomSheet<RecordSaleInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _RecordSaleSheet(view: view),
  );
  if (input == null) return;

  try {
    await ref.read(aggregatorRepositoryProvider).recordSale(input);
    invalidateAggregatorSaleFlow(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${view.artwork.title}" is now pending settlement')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

/// Fields match `POST /aggregators/sale`'s payload one-for-one (SAD §3.5),
/// with the delivery address's four sub-fields flattened for the form and
/// re-nested on submit.
class _RecordSaleSheet extends StatefulWidget {
  const _RecordSaleSheet({required this.view});

  final AggregatorHoldingView view;

  @override
  State<_RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends State<_RecordSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _soldPrice =
      TextEditingController(text: widget.view.holding.displayPrice.toStringAsFixed(0));
  final _buyerName = TextEditingController();
  final _buyerEmail = TextEditingController();
  final _buyerPhone = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  DeliveryMode _mode = DeliveryMode.courier;
  PaymentRoute _route = PaymentRoute.directToGalleryZone;

  @override
  void dispose() {
    for (final controller in [
      _soldPrice,
      _buyerName,
      _buyerEmail,
      _buyerPhone,
      _line1,
      _city,
      _state,
      _pincode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      RecordSaleInput(
        artworkId: widget.view.artwork.id,
        soldPrice: double.parse(_soldPrice.text.trim()),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                '"${widget.view.artwork.title}" — the buyer and delivery details '
                'used to confirm this sale.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soldPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sold price (₹)'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Enter the sold price';
                  if (parsed <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Buyer name'),
                validator: (value) =>
                    (value ?? '').trim().length < 2 ? "Enter the buyer's name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Buyer email'),
                validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch((value ?? '').trim())
                    ? null
                    : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Buyer phone'),
                validator: (value) => (value ?? '').trim().length < 10
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1,
                decoration: const InputDecoration(labelText: 'Delivery address'),
                validator: (value) => _required(value, 'Enter the address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (value) => _required(value, 'Enter the city'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _state,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (value) => _required(value, 'Enter the state'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Pincode'),
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch((value ?? '').trim())
                        ? null
                        : 'Enter a valid 6-digit pincode',
              ),
              const SizedBox(height: 4),
              SegmentedButton<DeliveryMode>(
                segments: const [
                  ButtonSegment(value: DeliveryMode.courier, label: Text('Courier')),
                  ButtonSegment(
                      value: DeliveryMode.selfPickup, label: Text('Self pickup')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 20),
              // You collect on GalleryZone's behalf, never for yourself. Which
              // of the two routes the money took decides what you owe
              // afterwards, so it is recorded with the sale rather than sorted
              // out later.
              Text(
                'How did the buyer pay?',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RadioGroup<PaymentRoute>(
                groupValue: _route,
                onChanged: (value) => setState(() => _route = value!),
                child: Column(
                  children: [
                    for (final route in PaymentRoute.values)
                      RadioListTile<PaymentRoute>(
                        contentPadding: EdgeInsets.zero,
                        value: route,
                        title: Text(
                          paymentRouteLabel[route]!,
                          style: theme.textTheme.bodySmall,
                        ),
                        subtitle: Text(
                          route == PaymentRoute.directToGalleryZone
                              ? 'Transfer or UPI into the GalleryZone account.'
                              : 'You hold GalleryZone\'s money until you '
                                  'transfer the full sale price.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Shown for both routes: if the buyer is paying directly these
              // are the details they need, and if they are paying cash these
              // are the details the aggregator will remit to.
              PayeeDetails(
                amount: double.tryParse(_soldPrice.text.trim()) ??
                    widget.view.holding.displayPrice,
                note: '${widget.view.artwork.title} — ${widget.view.artwork.id}',
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Record sale')),
            ],
          ),
        ),
      ),
    );
  }
}
