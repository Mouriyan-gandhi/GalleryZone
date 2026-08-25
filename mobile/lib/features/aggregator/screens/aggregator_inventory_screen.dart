import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';

/// Port of `app/aggregator/inventory/page.tsx` — the web's "Browse
/// GalleryZone". Artworks eligible for aggregator display that nobody has
/// claimed yet; reserving one pays the advance and moves it to Inventory.
class AggregatorBrowseScreen extends ConsumerWidget {
  const AggregatorBrowseScreen({super.key});

  static const path = '/aggregator/inventory';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(aggregatorInventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse GalleryZone')),
      body: inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const EmptyState(
          icon: LucideIcons.triangleAlert,
          title: "Couldn't load inventory",
          description: 'Something went wrong. Try again in a moment.',
        ),
        data: (artworks) => artworks.isEmpty
            ? const EmptyState(
                icon: LucideIcons.packageSearch,
                title: 'No reservable artworks right now',
                description:
                    'Every aggregator-listed artwork is already claimed. '
                    'Check back as new work is listed.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(aggregatorInventoryProvider);
                  await ref.read(aggregatorInventoryProvider.future);
                },
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _ReserveReadiness()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.52,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ReservableCard(item: artworks[index]),
                          childCount: artworks.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ReservableCard extends ConsumerWidget {
  const _ReservableCard({required this.item});

  final ReservableArtwork item;

  Artwork get artwork => item.artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offer = item.offer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GestureDetector(
            // Opens the public marketplace detail page — the aggregator sees
            // exactly what a collector would before committing an advance.
            onTap: () => context.push('/marketplace/${artwork.id}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ArtworkImageView(url: artwork.thumbnailUrl),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artwork.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          artwork.artistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        PriceTag(amount: offer.offerPrice, style: theme.textTheme.bodyMedium),
        Text(
          'Your price · month ${offer.month} of $aggregatorCycleMonths',
          style: theme.textTheme.labelSmall,
        ),
        // Only worth showing once the two have parted company. In month one
        // they are the same number and the strike-through would read as a
        // discount that isn't there.
        if (offer.month > 1)
          Text(
            'was ${formatInr(basePriceOf(artistPriceFrom(offer.marketplacePrice)))}',
            style: theme.textTheme.labelSmall?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: () => _openReserveSheet(context, ref, item),
            child: const Text('Reserve'),
          ),
        ),
      ],
    );
  }
}

/// Confirmation before an advance is held. The preview shows the offer the
/// repository itself built, so what's on screen can't drift from what gets
/// written.
Future<void> _openReserveSheet(
  BuildContext context,
  WidgetRef ref,
  ReservableArtwork item,
) async {
  final artwork = item.artwork;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReserveSheet(item: item),
  );
  if (confirmed == null) return;

  try {
    // `confirmed == false` is the dev toggle: it asks the repository for the
    // documented 409 "lost the race" failure instead of a success.
    await ref
        .read(aggregatorRepositoryProvider)
        .reserve(artwork.id, simulateConflict: !confirmed);
    invalidateAggregatorSaleFlow(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${artwork.title}" is now in your inventory')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authErrorMessage(error))),
    );
  }
}

class _ReserveSheet extends StatefulWidget {
  const _ReserveSheet({required this.item});

  final ReservableArtwork item;

  @override
  State<_ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<_ReserveSheet> {
  bool _simulateConflict = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = widget.item.artwork;
    final offer = widget.item.offer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reserve this artwork', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Month ${offer.month} of $aggregatorCycleMonths. Confirming holds the '
            'advance and delivery from your wallet and opens a 30-day display '
            'window. ${offer.daysLeftInListing} days remain on this piece\'s listing.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          PortalCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: ArtworkImageView(url: artwork.thumbnailUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(artwork.artistName, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                PriceTag(amount: offer.offerPrice),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PortalCard(
            gold: true,
            child: Column(
              children: [
                _MoneyRow(
                  label: 'Advance (${(offer.advanceRate * 100).round()}%)',
                  // The basis changes with the month, so it is spelled out
                  // rather than assumed: month one is charged on the price the
                  // piece is displayed at, every later month on the artist's.
                  detail: offer.advanceBasis == AdvanceBasis.displayPrice
                      ? 'of the display price, ${formatInr(offer.advanceBase)}'
                      : "of the artist's price, ${formatInr(offer.advanceBase)}",
                  amount: offer.advance,
                ),
                const SizedBox(height: 8),
                _MoneyRow(
                  label: 'Delivery',
                  detail: 'Returned when the piece sells',
                  amount: offer.deliveryCharge,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _MoneyRow(
                  label: 'Held from your wallet',
                  detail: 'Not a payment — released on sale or return',
                  amount: offer.payable,
                  emphasized: true,
                ),
              ],
            ),
          ),
          if (!offer.canSetPrice) ...[
            const SizedBox(height: 10),
            PortalCard(
              child: Text(
                'GalleryZone sets the selling price for this piece. From month '
                'two the advance is lower, so the price is not the '
                "aggregator's to change.",
                style: theme.textTheme.labelMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _simulateConflict,
            onChanged: (value) => setState(() => _simulateConflict = value ?? false),
            title: Row(
              children: [
                Flexible(
                  child: Text('Simulate reservation conflict',
                      style: theme.textTheme.labelMedium),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text('DEV',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
                ),
              ],
            ),
            subtitle: Text(
              'Demos the 409 "lost the race" error another aggregator can trigger.',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(!_simulateConflict),
            child: const Text('Confirm reservation'),
          ),
        ],
      ),
    );
  }
}

/// One line of the reserve sheet's money card.
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.detail,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final String detail;
  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              Text(detail, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        Text(
          formatInr(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: emphasized ? theme.colorScheme.tertiary : null,
          ),
        ),
      ],
    );
  }
}

/// What has to be true before anything on this screen can be reserved, said
/// up front rather than as an error after the tap.
///
/// Two real gates, both enforced in the repository: a signed MOU (an unsigned
/// aggregator has no agreement covering custody) and enough free wallet
/// balance to hold the advance and delivery against.
class _ReserveReadiness extends ConsumerWidget {
  const _ReserveReadiness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(aggregatorProfileProvider).value;
    final wallet = ref.watch(aggregatorWalletProvider).value;
    final signed = profile?.mouAcceptance != null;
    final free = wallet == null ? 0.0 : wallet.balance - wallet.lockedBalance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reserving holds the advance and the delivery charge from your '
            'wallet, and opens a 30-day display window.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          if (!signed) ...[
            const SizedBox(height: 10),
            _Gate(
              icon: LucideIcons.fileSignature,
              message: 'Sign your Aggregator MOU before reserving artwork.',
              action: 'Read and sign',
              onPressed: () => context.push('/aggregator/dashboard/mou'),
            ),
          ],
          if (signed && free <= 0) ...[
            const SizedBox(height: 10),
            _Gate(
              icon: LucideIcons.wallet,
              message: 'Your wallet has nothing free to hold an advance '
                  'against. Add money to start reserving.',
              action: 'Add money',
              onPressed: () => context.push('/aggregator/wallet'),
            ),
          ] else if (signed) ...[
            const SizedBox(height: 6),
            Text(
              '${formatInr(free)} free in your wallet.',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.icon,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PortalCard(
      gold: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
