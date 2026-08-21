import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/account_providers.dart';

/// Port of `features/account/resale-view.tsx`. Seller-side only: this shows
/// that owned artwork can go back on the market, it is not a secondary
/// checkout. Buyer matching and ownership transfer aren't modelled.
class ResaleScreen extends ConsumerWidget {
  const ResaleScreen({super.key});

  static const path = '/account/resale';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collection = ref.watch(collectionProvider);
    final listings = ref.watch(resaleListingsProvider);
    final artworks = ref.watch(artworksByIdProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Resell artwork')),
      body: (collection.isLoading || listings.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentWidth(
                  child: Builder(
                    builder: (context) {
                      final active = {
                        for (final listing in listings.value ?? const <ResaleListing>[])
                          if (listing.status == ResaleListingStatus.active) listing.artworkId,
                      };
                      final eligible = [
                        for (final item in collection.value ?? const <CollectionItem>[])
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
                          if ((listings.value ?? const []).isEmpty)
                            const EmptyState(
                              icon: LucideIcons.tag,
                              title: 'No listings yet',
                              description:
                                  'List a piece above and it shows up here until you '
                                  'withdraw it.',
                            )
                          else
                            for (final listing in listings.value!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ListingRow(
                                  listing: listing,
                                  title: artworks[listing.artworkId]?.title ?? listing.artworkId,
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ],
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
                  'Bought for ${formatInr(item.order.amount)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _openListingSheet(context, ref, item),
            child: const Text('List'),
          ),
        ],
      ),
    );
  }

  Future<void> _openListingSheet(BuildContext context, WidgetRef ref, CollectionItem item) async {
    final controller = TextEditingController(text: item.order.amount.toStringAsFixed(0));
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
              Text('List "${item.artwork.title}"',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(labelText: 'Listing price (₹)'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a listing price';
                  return null;
                },
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
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(error))),
      );
    }
  }
}

class _ListingRow extends ConsumerWidget {
  const _ListingRow({required this.listing, required this.title});

  final ResaleListing listing;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = listing.status == ResaleListingStatus.active;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.tag, size: 16, color: theme.colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${formatInr(listing.listedPrice)} · ${listing.status.name} · '
                  'listed ${formatShortDate(listing.listedAt)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (isActive)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(customerRepositoryProvider).withdrawResaleListing(listing.id);
                  ref.invalidate(resaleListingsProvider);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authErrorMessage(error))),
                  );
                }
              },
              child: const Text('Withdraw'),
            ),
        ],
      ),
    );
  }
}
