import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
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
    final theme = Theme.of(context);
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          'Reserving pays the advance and holds the piece for 30 days.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                      ),
                    ),
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
                          (context, index) => _ReservableCard(artwork: artworks[index]),
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
  const _ReservableCard({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
        PriceTag(amount: artwork.customerPrice, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: () => _openReserveSheet(context, ref, artwork),
            child: const Text('Reserve'),
          ),
        ),
      ],
    );
  }
}

/// Confirmation before an advance is paid. The preview uses the exact
/// helpers `reserve()` itself calls, so what's shown here can't drift from
/// what gets written.
Future<void> _openReserveSheet(BuildContext context, WidgetRef ref, Artwork artwork) async {
  final percent = advancePercentFor(artwork.customerPrice);
  final amount = advanceAmountFor(artwork.customerPrice, percent);

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReserveSheet(
      artwork: artwork,
      advancePercent: percent,
      advanceAmount: amount,
    ),
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
  const _ReserveSheet({
    required this.artwork,
    required this.advancePercent,
    required this.advanceAmount,
  });

  final Artwork artwork;
  final int advancePercent;
  final double advanceAmount;

  @override
  State<_ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<_ReserveSheet> {
  bool _simulateConflict = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reserve this artwork', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Confirming pays the advance and holds this piece for a 30-day display '
            'window.',
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
                    child: ArtworkImageView(url: widget.artwork.thumbnailUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artwork.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(widget.artwork.artistName, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                PriceTag(amount: widget.artwork.customerPrice),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PortalCard(
            gold: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advance due today',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      Text(
                        '${widget.advancePercent}% of '
                        '${formatInr(widget.artwork.customerPrice)}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatInr(widget.advanceAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
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
