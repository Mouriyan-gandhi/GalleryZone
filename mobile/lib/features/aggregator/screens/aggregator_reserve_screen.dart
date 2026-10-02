import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../reserve_requirements.dart';
import '../widgets/aggregator_widgets.dart';
import 'aggregator_inventory_screen.dart';

/// Port of `reserve-artwork-page.tsx`. Reserving is a real commitment - it holds
/// money from the wallet for thirty days - so it gets its own screen and back
/// button rather than a sheet to mis-tap through. Confirming lands on the new
/// holding's page, which is the "what happens next".
///
/// Month 1 is the one month the aggregator sets the price (client, 30 Sep 2026:
/// "the aggregator can set the price only while reserving in month 1"). They may
/// go as high as they like, never below GalleryZone's own price, and it can't be
/// changed once reserved. Every later month the price is GalleryZone's.
class AggregatorReserveScreen extends ConsumerStatefulWidget {
  const AggregatorReserveScreen({super.key, required this.artworkId});

  final String artworkId;

  /// Under [AggregatorBrowseScreen.path].
  static const subPath = ':artworkId/reserve';

  @override
  ConsumerState<AggregatorReserveScreen> createState() => _AggregatorReserveScreenState();
}

class _AggregatorReserveScreenState extends ConsumerState<AggregatorReserveScreen> {
  /// Once the reservation is made the piece leaves the reservable list; keep
  /// drawing what was reserved while the page slides away, not "isn't reservable".
  ReservableArtwork? _reserved;

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(aggregatorInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reserve artwork')),
      body: inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.packageSearch,
          title: "Couldn't load this piece",
          description: 'Something went wrong. Try again in a moment.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorInventoryProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (all) {
          final item = _reserved ?? all.where((entry) => entry.artwork.id == widget.artworkId).firstOrNull;
          if (item == null) {
            return EmptyState(
              icon: LucideIcons.packageSearch,
              title: "This piece isn't reservable",
              description: 'It may have just been taken by another aggregator, or its listing period has ended.',
              action: TextButton(
                onPressed: () => context.go(AggregatorBrowseScreen.path),
                child: const Text('Back to inventory'),
              ),
            );
          }
          return _ReserveForm(item: item, onReserved: () => setState(() => _reserved = item));
        },
      ),
    );
  }
}

/// `+(rate * 100).toFixed(2)` - 5, or 12.5.
String _percentLabel(double fraction) {
  final value = double.parse((fraction * 100).toStringAsFixed(2));
  return value == value.roundToDouble() ? value.round().toString() : value.toString();
}

class _ReserveForm extends ConsumerStatefulWidget {
  const _ReserveForm({required this.item, required this.onReserved});

  final ReservableArtwork item;
  final VoidCallback onReserved;

  @override
  ConsumerState<_ReserveForm> createState() => _ReserveFormState();
}

class _ReserveFormState extends ConsumerState<_ReserveForm> {
  late final _price = TextEditingController(text: widget.item.offer.sellingPrice.toStringAsFixed(0));
  bool _reserving = false;

  /// Mock only: asks the offline repository for the documented 409 "lost the race".
  bool _simulateConflict = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _confirm(double price) async {
    final offer = widget.item.offer;
    final title = widget.item.artwork.title;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _reserving = true);
    try {
      final holding = await ref
          .read(aggregatorRepositoryProvider)
          .reserve(widget.item.artwork.id, sellingPrice: offer.canSetPrice ? price : null, simulateConflict: _simulateConflict);
      if (!mounted) return;
      widget.onReserved();
      invalidateAggregatorSaleFlow(ref);
      messenger.showSnackBar(SnackBar(content: Text('Artwork reserved — "$title" is now in My Inventory.')));
      // Leave this page off the Browse tab's stack, then land on the holding.
      router
        ..pop()
        ..go('/aggregator/collection/${holding.id}');
    } catch (error) {
      // A failed reserve is nearly always the list disagreeing with the store -
      // the piece has gone, or someone took it. Refetching is what stops the
      // next tap failing identically.
      ref.invalidate(aggregatorInventoryProvider);
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      if (mounted) setState(() => _reserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = widget.item.artwork;
    final offer = widget.item.offer;
    final wallet = ref.watch(aggregatorWalletProvider).value;
    final requirements = ref.watch(reserveRequirementsProvider);
    final remote = ref.watch(remoteBackendProvider);

    final typed = double.tryParse(_price.text.trim());
    final chosen = offer.canSetPrice ? (typed ?? double.nan) : offer.sellingPrice;
    final priceError = !offer.canSetPrice
        ? null
        : (!chosen.isFinite || chosen != chosen.roundToDouble() || chosen <= 0)
            ? 'Enter a price in whole rupees.'
            : chosen < offer.sellingPrice
                ? "It can't be lower than GalleryZone's price, ${formatInr(offer.sellingPrice)}."
                : null;
    // The numbers below follow what is typed, but never a price the API would refuse.
    final price = priceError != null ? offer.sellingPrice : chosen;

    // MOU §8: the aggregator's commission is 20% of (selling price - the artist's
    // price), before GST, whoever set the price. The artist's price is worked back
    // from GalleryZone's month-1 price.
    final artistPrice =
        (offer.standardPrice / (1 + offer.gstRate) / (1 + platformMarkup)).round().toDouble();
    final terms = aggregatorTermsAt(sellingPrice: price, artistPrice: artistPrice, gstRate: offer.gstRate);
    final commissionPercent = (aggregatorCommissionRate * 100).round();

    // Month 1's advance follows the price they choose; after that it is fixed.
    final advance = offer.canSetPrice ? (price * offer.advanceRate).round().toDouble() : offer.advance;
    final advanceBase = offer.canSetPrice ? price : offer.advanceBase;
    final payable = advance + offer.deliveryCharge;
    final free = wallet == null ? 0.0 : wallet.balance - wallet.lockedBalance;
    final shortfall = math.max(0.0, payable - free);
    final priceWarning = offer.priceWarnFrom != null && price >= offer.priceWarnFrom!;
    final canConfirm = !_reserving && shortfall <= 0 && priceError == null && requirements.blockedReason == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ReserveRequirementsNotice(),
              PortalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(width: 64, height: 64, child: ArtworkImageView(url: artwork.thumbnailUrl)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artwork.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                artwork.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriceTag(amount: terms.displayPrice, style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CycleStepper(currentMonth: offer.month),
                    const SizedBox(height: 8),
                    Text(
                      'Month ${offer.month} of $aggregatorCycleMonths. Confirming holds the advance from your '
                      'wallet and moves this piece into My Inventory for 30 days. After that it moves on to the '
                      'next aggregator and your advance is back in your wallet on day 31, unless you ask '
                      'GalleryZone to let you keep it and they agree.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    if (offer.canSetPrice)
                      _Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your selling price, before GST (₹)', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _price,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                errorText: priceError,
                                helperText: priceError == null
                                    ? "GalleryZone's price is ${formatInr(offer.sellingPrice)}. Set it higher if "
                                        "you like, not lower. You set it once: it can't be changed after you reserve."
                                    : null,
                                helperMaxLines: 4,
                              ),
                            ),
                            if (priceWarning && priceError == null) ...[
                              const SizedBox(height: 10),
                              PortalNotice(
                                icon: LucideIcons.triangleAlert,
                                gold: true,
                                body: "That's at least double GalleryZone's price. You can still reserve it, and "
                                    'GalleryZone will be told about the price.',
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      _Panel(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Price this month, before GST', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('Set by GalleryZone. Only the first aggregator sets a price.', style: theme.textTheme.labelSmall),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(formatInr(offer.sellingPrice), style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Caption('Where this price goes'),
                          _Line("Artist's price", formatInr(artistPrice)),
                          _Line('GalleryZone (${100 - commissionPercent}% of the markup)', formatInr(terms.galleryZoneShare)),
                          _Line('Your commission if it sells here ($commissionPercent%)', formatInr(terms.commission)),
                          _Line('GST (${_percentLabel(offer.gstRate)}%)', formatInr(terms.gst)),
                          const Divider(height: 16),
                          _Line('What customers see', formatInr(terms.displayPrice), strong: true),
                          if (offer.canSetPrice) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Every extra rupee you charge splits $commissionPercent% to you and ${100 - commissionPercent}% "
                              "to GalleryZone. The artist's price never changes.",
                              style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (offer.monthlyReduction > 0) ...[
                      const SizedBox(height: 12),
                      _Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Caption("Why this month's price is lower"),
                            _Line('Month 1 price', formatInr(offer.standardPrice), strike: true),
                            _Line('Month ${offer.month} reduction', '−${formatInr(offer.monthlyReduction)}'),
                            const Divider(height: 16),
                            _Line('Your price today', formatInr(offer.offerPrice), strong: true),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    PortalCard(
                      gold: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Line(
                            'Advance (${(offer.advanceRate * 100).round()}%)',
                            formatInr(advance),
                            hint: 'of ${offer.advanceBasis == AdvanceBasis.sellingPrice ? 'your price before GST' : 'the artist price'}, '
                                '${formatInr(advanceBase)}',
                          ),
                          const SizedBox(height: 6),
                          _Line(
                            'Delivery',
                            formatInr(offer.deliveryCharge),
                            hint: 'Returned when the piece sells, not if it comes back',
                          ),
                          const Divider(height: 18),
                          _Line(
                            'Held from your wallet',
                            formatInr(payable),
                            hint: '${formatInr(math.max(0.0, free))} free right now',
                            strong: true,
                            gold: true,
                          ),
                        ],
                      ),
                    ),
                    if (shortfall > 0) ...[
                      const SizedBox(height: 12),
                      PortalNotice(
                        icon: LucideIcons.wallet,
                        title: '${formatInr(shortfall)} short',
                        body: 'Top up your wallet to reserve this piece. Money is held, not spent: it comes back '
                            'when the piece sells.',
                        action: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.go('/aggregator/wallet'),
                            child: const Text('Go to wallet'),
                          ),
                        ),
                      ),
                    ],
                    // Only the offline mock can lose a race on demand.
                    if (!remote) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _simulateConflict,
                        onChanged: (value) => setState(() => _simulateConflict = value ?? false),
                        title: Text('Simulate reservation conflict (DEV)', style: theme.textTheme.labelMedium),
                        subtitle: Text(
                          'Demos the 409 "lost the race" error another aggregator can trigger.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reserving ? null : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: canConfirm ? () => _confirm(price) : null,
                            child: Text(_reserving ? 'Reserving…' : 'Confirm reservation'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SuggestedArtworks(references: [artwork], title: 'Similar pieces you could reserve'),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bordered block inside the reserve card.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: child,
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// One label/value line, with an optional second line of explanation.
class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.hint, this.strong = false, this.gold = false, this.strike = false});

  final String label;
  final String value;
  final String? hint;
  final bool strong;
  final bool gold;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: strong ? FontWeight.w600 : null,
                    color: strong ? theme.colorScheme.onSurface : null,
                  ),
                ),
                if (hint != null) Text(hint!, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
              color: gold ? theme.colorScheme.tertiary : (strike ? theme.colorScheme.onSurfaceVariant : null),
              decoration: strike ? TextDecoration.lineThrough : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
