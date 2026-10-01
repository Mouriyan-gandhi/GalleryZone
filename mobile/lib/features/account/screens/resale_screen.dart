import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/customer.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/resale-view.tsx`. Seller-side only: it lets a
/// collector put a piece they own back on the market and take the listing down
/// again. Buyer matching and the payout of a resale are not part of the app -
/// the website's "Simulate sale" stand-in for a buyer is a demo control and
/// deliberately has no counterpart here.
class ResaleScreen extends ConsumerWidget {
  const ResaleScreen({super.key});

  static const path = '/account/resale';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(collectionProvider);
    final listings = ref.watch(resaleListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resell artwork')),
      body: (collection.isLoading || listings.isLoading) && !collection.hasValue && !listings.hasValue
          ? const Center(child: CircularProgressIndicator())
          : (collection.hasError || listings.hasError) && !(collection.hasValue && listings.hasValue)
              ? EmptyState(
                  icon: LucideIcons.repeat2,
                  title: "Couldn't load your resale options",
                  description: 'Something went wrong. Try again in a moment.',
                  action: OutlinedButton(
                    onPressed: () {
                      ref.invalidate(collectionProvider);
                      ref.invalidate(resaleListingsProvider);
                    },
                    child: const Text('Try again'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(collectionProvider);
                    ref.invalidate(resaleListingsProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      ContentWidth(
                        child: Builder(
                          builder: (context) {
                            final items = collection.value ?? const <CollectionItem>[];
                            final all = listings.value ?? const <ResaleListing>[];
                            final active = {
                              for (final listing in all)
                                if (listing.status == ResaleListingStatus.active) listing.artworkId,
                            };
                            final eligible = [
                              for (final item in items)
                                if (!active.contains(item.artwork.id)) item,
                            ];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Eligible artworks', style: theme.textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  'Any artwork in your collection can be listed for resale.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                if (eligible.isEmpty)
                                  const EmptyState(
                                    icon: LucideIcons.repeat2,
                                    title: 'Nothing eligible right now',
                                    description:
                                        "Artworks become eligible for resale once they're "
                                        'delivered and part of your collection.',
                                  )
                                else
                                  for (final item in eligible)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _EligibleRow(item: item),
                                    ),
                                const SizedBox(height: 28),
                                Text('Your listings', style: theme.textTheme.titleLarge),
                                const SizedBox(height: 12),
                                if (all.isEmpty)
                                  const EmptyState(
                                    icon: LucideIcons.tag,
                                    title: 'No resale listings yet',
                                    description: 'Artworks you list for resale will appear here.',
                                  )
                                else
                                  for (final listing in all)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _ListingRow(
                                        listing: listing,
                                        // The listing names the piece by id only; the
                                        // collection is where its title and photo are.
                                        artwork: items
                                            .where((c) => c.artwork.id == listing.artworkId)
                                            .firstOrNull
                                            ?.artwork,
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _EligibleRow extends ConsumerWidget {
  const _EligibleRow({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 52,
              height: 52,
              child: ArtworkImageView(url: item.artwork.thumbnailUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.artwork.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  item.order != null
                      ? 'Acquired for ${formatInr(item.order!.amount)}'
                      : 'Received from ${item.fromName.isEmpty ? 'its previous owner' : item.fromName}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _openListingSheet(context, ref, item),
            icon: const Icon(LucideIcons.tag, size: 14),
            label: const Text('List for resale'),
          ),
        ],
      ),
    );
  }

  Future<void> _openListingSheet(BuildContext context, WidgetRef ref, CollectionItem item) async {
    final paid = item.order?.amount;
    final controller = TextEditingController(text: paid == null ? '' : paid.toStringAsFixed(0));
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
              Text('List "${item.artwork.title}"', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(labelText: 'Asking price (₹)'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a listing price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${paid == null ? '' : 'Originally acquired for ${formatInr(paid)}. '}'
                "Buyer inquiries and resale checkout aren't wired to a live marketplace yet.",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(context).pop(double.parse(controller.text.trim()));
                },
                child: const Text('List for resale'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (price == null) return;

    try {
      await ref
          .read(customerRepositoryProvider)
          .createResaleListing(artworkId: item.artwork.id, listedPrice: price);
      ref.invalidate(resaleListingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listed for resale')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }
}

class _ListingRow extends ConsumerWidget {
  const _ListingRow({required this.listing, required this.artwork});

  final ResaleListing listing;
  final Artwork? artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = listing.status == ResaleListingStatus.active;
    final piece = artwork;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 52,
              height: 52,
              child: piece == null
                  ? ColoredBox(color: theme.colorScheme.surfaceContainerHighest)
                  : ArtworkImageView(url: piece.thumbnailUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  piece?.title ?? 'Artwork',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                PriceTag(amount: listing.listedPrice, style: theme.textTheme.bodyMedium),
                Text('Listed ${formatShortDate(listing.listedAt)}', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(status: listing.status),
              if (isActive)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(customerRepositoryProvider).withdrawResaleListing(listing.id);
                      ref.invalidate(resaleListingsProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Listing withdrawn')),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authErrorMessage(error))),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Withdraw'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ResaleListingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = status == ResaleListingStatus.active;
    const green = Color(0xFF34D399);
    final color = active ? green : theme.textTheme.bodySmall?.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? green.withValues(alpha: 0.1) : theme.colorScheme.secondary,
        border: Border.all(color: active ? green.withValues(alpha: 0.3) : theme.colorScheme.outline),
      ),
      child: Text(
        titleCase(status.name),
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
