import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/pricing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/aggregator.dart';
import '../../../data/models/artist_portal.dart';
import '../../../data/repositories/aggregator_repository.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../../shell/portal_widgets.dart';
import '../providers/aggregator_providers.dart';
import '../reserve_requirements.dart';
import '../widgets/aggregator_widgets.dart';

/// Port of `app/aggregator/inventory/page.tsx` + `reservable-inventory-grid.tsx` -
/// the web's "Browse GalleryZone". Artworks eligible for aggregator display that
/// nobody has claimed yet; reserving one pays the advance and moves it to
/// Inventory.
///
/// The web's search box, category chips and sort menu are decorative there (they
/// filter and sort nothing); here they work.
class AggregatorBrowseScreen extends ConsumerStatefulWidget {
  const AggregatorBrowseScreen({super.key});

  static const path = '/aggregator/inventory';

  @override
  ConsumerState<AggregatorBrowseScreen> createState() => _AggregatorBrowseScreenState();
}

enum _Sort {
  newest('Newest'),
  priceAsc('Price: Low to High'),
  priceDesc('Price: High to Low');

  const _Sort(this.label);
  final String label;
}

class _AggregatorBrowseScreenState extends ConsumerState<AggregatorBrowseScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;
  _Sort _sort = _Sort.newest;
  bool _grid = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ReservableArtwork> _visible(List<ReservableArtwork> all) {
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final item in all)
        if ((_category == null || item.artwork.category == _category) &&
            (query.isEmpty ||
                [
                  item.artwork.title,
                  item.artwork.artistName,
                  item.artwork.medium,
                  item.artwork.category,
                  item.artwork.paintingStyle ?? '',
                ].any((field) => field.toLowerCase().contains(query))))
          item,
    ];
    switch (_sort) {
      case _Sort.newest:
        break; // the service's own order
      case _Sort.priceAsc:
        shown.sort((a, b) => a.offer.offerPrice.compareTo(b.offer.offerPrice));
      case _Sort.priceDesc:
        shown.sort((a, b) => b.offer.offerPrice.compareTo(a.offer.offerPrice));
    }
    return shown;
  }

  void _reserve(ReservableArtwork item) {
    final requirements = ref.read(reserveRequirementsProvider);
    if (requirements.blockedReason != null) {
      showReserveBlockedDialog(context, requirements);
      return;
    }
    context.push('/aggregator/inventory/${item.artwork.id}/reserve');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventory = ref.watch(aggregatorInventoryProvider);
    // What this aggregator holds or has sold is what "suggested for you" is
    // measured against. A returned piece wasn't theirs to show, so it doesn't count.
    final held = [
      for (final view in ref.watch(aggregatorCollectionProvider).value ?? const <AggregatorHoldingView>[])
        if (view.holding.status != HoldingStatus.returned) view.artwork,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Browse GalleryZone')),
      body: inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: LucideIcons.packageSearch,
          title: "Couldn't load inventory",
          description: 'Something went wrong loading reservable artworks.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(aggregatorInventoryProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.packageSearch,
              title: 'No reservable artworks right now',
              description:
                  'Every marketplace-and-aggregator artwork is already claimed. Check back soon as new work is listed.',
            );
          }
          final categories = ({for (final item in all) item.artwork.category}..remove('')).toList()..sort();
          final visible = _visible(all);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(aggregatorInventoryProvider);
              await ref.read(aggregatorInventoryProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ContentColumn(
                      children: [
                        Text(
                          'Browse artworks available for aggregator display. Reserving pays '
                          'the advance and moves a piece into your Collection.',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        // The API refuses a reservation without a signed MOU and an
                        // approved GST number. Say so here rather than letting someone
                        // pick a piece and hit the wall on the reserve screen.
                        const ReserveRequirementsNotice(),
                        if (held.isNotEmpty) ...[
                          SuggestedArtworks(references: held, title: 'Suggested for you', limit: 6),
                          const SizedBox(height: 20),
                        ],
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search artworks, artists, or styles...',
                            prefixIcon: const Icon(LucideIcons.search, size: 16),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(LucideIcons.x, size: 16),
                                    onPressed: () {
                                      _search.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                        if (categories.length > 1) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final category in [null, ...categories])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(category ?? 'All'),
                                      selected: _category == category,
                                      onSelected: (_) => setState(() => _category = category),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _ResultsBar(
                          count: visible.length,
                          sort: _sort,
                          grid: _grid,
                          onSort: (value) => setState(() => _sort = value ?? _sort),
                          onToggleView: () => setState(() => _grid = !_grid),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: LucideIcons.packageSearch,
                      title: 'Nothing matches',
                      description: 'Try a different search or category.',
                    ),
                  )
                else if (_grid)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 420,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ReservableCard(item: visible[index], onReserve: () => _reserve(visible[index])),
                        childCount: visible.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ContentColumn(
                        children: [_ReservableRow(item: visible[index], onReserve: () => _reserve(visible[index]))],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "N artworks available", the sort menu and the grid/list switch - one line on a
/// wide window, two on a phone (the count, then the controls), as the web does.
class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.count,
    required this.sort,
    required this.grid,
    required this.onSort,
    required this.onToggleView,
  });

  final int count;
  final _Sort sort;
  final bool grid;
  final ValueChanged<_Sort?> onSort;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(
      '$count artwork${count == 1 ? '' : 's'} available',
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );
    final menu = DropdownButtonHideUnderline(
      child: DropdownButton<_Sort>(
        value: sort,
        isExpanded: true,
        isDense: true,
        style: theme.textTheme.labelLarge,
        items: [
          for (final option in _Sort.values)
            DropdownMenuItem(
              value: option,
              child: Text('Sort: ${option.label}', overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onSort,
      ),
    );
    final toggle = IconButton(
      tooltip: grid ? 'List view' : 'Grid view',
      visualDensity: VisualDensity.compact,
      icon: Icon(grid ? LucideIcons.list : LucideIcons.layoutGrid, size: 18),
      onPressed: onToggleView,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final controls = Row(
          children: [
            if (wide) SizedBox(width: 220, child: menu) else Expanded(child: menu),
            const SizedBox(width: 4),
            toggle,
          ],
        );
        return wide
            ? Row(children: [Expanded(child: label), controls])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [label, const SizedBox(height: 4), controls]);
      },
    );
  }
}

/// A centred, width-capped column - the header and list rows share it so text
/// and rows stay readable on a tablet while the grid fills the window.
class _ContentColumn extends StatelessWidget {
  const _ContentColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

/// Month 1 is the aggregator's to price; after that GalleryZone's ladder steps
/// the price down. Said the same way on the card and the list row.
String monthLine(AggregatorOffer offer) {
  final month = 'Month ${offer.month} of $aggregatorCycleMonths';
  if (offer.canSetPrice) return '$month · you set the price';
  return offer.monthlyReduction > 0 ? '$month · ${formatInr(offer.monthlyReduction)} off month 1' : month;
}

String _priceNote(AggregatorOffer offer) =>
    offer.canSetPrice ? "GalleryZone's price, incl. GST. You can set a higher one." : 'Fixed this month, incl. GST';

/// Initial in a gold disc, then the artist's name and the verified mark.
class _ArtistLine extends StatelessWidget {
  const _ArtistLine({required this.item});

  final ReservableArtwork item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = item.artwork;
    return Row(
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Text(
            artwork.artistName.isEmpty ? '' : artwork.artistName.characters.first.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            artwork.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ),
        if (artwork.verifiedArtist) ...[
          const SizedBox(width: 4),
          const VerifiedBadge(verification: VerifiedBadge.minimumVerification, small: true),
        ],
      ],
    );
  }
}

/// "Insured" over the corner of a piece's image.
class _InsuredBadge extends StatelessWidget {
  const _InsuredBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.xl4),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 11, color: theme.colorScheme.tertiary),
          const SizedBox(width: 4),
          Text(
            'Insured',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.tertiary),
          ),
        ],
      ),
    );
  }
}

/// Where this month sits in the five, and what it means for the price.
class _CycleBox extends StatelessWidget {
  const _CycleBox({required this.offer});

  final AggregatorOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          CycleStepper(currentMonth: offer.month, small: true),
          const SizedBox(height: 6),
          Text(
            monthLine(offer),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ReservableCard extends StatelessWidget {
  const _ReservableCard({required this.item, required this.onReserve});

  final ReservableArtwork item;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = item.artwork;
    final offer = item.offer;
    // Opens the public marketplace page - the aggregator sees exactly what a
    // collector would before committing an advance.
    void open() => context.push('/marketplace/${artwork.id}');

    return PortalCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: open,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ArtworkImageView(url: artwork.thumbnailUrl),
                  ),
                  if (artwork.insured) const Positioned(left: 6, bottom: 6, child: _InsuredBadge()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: open,
            child: Text(
              artwork.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
            ),
          ),
          const SizedBox(height: 4),
          _ArtistLine(item: item),
          const SizedBox(height: 6),
          PriceTag(amount: offer.offerPrice, style: theme.textTheme.titleMedium),
          Text(
            _priceNote(offer),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 8),
          _CycleBox(offer: offer),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: FilledButton(onPressed: onReserve, child: const Text('Reserve Artwork')),
          ),
        ],
      ),
    );
  }
}

class _ReservableRow extends StatelessWidget {
  const _ReservableRow({required this.item, required this.onReserve});

  final ReservableArtwork item;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = item.artwork;
    final offer = item.offer;
    void open() => context.push('/marketplace/${artwork.id}');

    return PortalCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: open,
            child: SizedBox(
              width: 96,
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ArtworkImageView(url: artwork.thumbnailUrl),
                  ),
                  if (artwork.insured) const Positioned(left: 4, bottom: 4, child: _InsuredBadge()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: open,
                  child: Text(
                    artwork.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                  ),
                ),
                const SizedBox(height: 4),
                _ArtistLine(item: item),
                if (artwork.medium.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      artwork.medium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                const SizedBox(height: 6),
                PriceTag(amount: offer.offerPrice, style: theme.textTheme.titleSmall),
                Text(_priceNote(offer), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.5)),
                const SizedBox(height: 8),
                _CycleBox(offer: offer),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: FilledButton(onPressed: onReserve, child: const Text('Reserve')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
