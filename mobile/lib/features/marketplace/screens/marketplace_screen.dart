import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/artwork_filters.dart';
import '../../../data/models/marketplace.dart';
import '../../marketing/screens/about_screen.dart';
import '../filter_options.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';
import 'artists_directory_screen.dart';
import 'marketplace_filter_sheet.dart';

/// Port of `app/marketplace/page.tsx` + `marketplace-grid.tsx`: the hero with
/// search and category pills, the results with their filters, sort and active
/// filter chips, and the rank guide under them.
///
/// Where the website has a filter sidebar and numbered pages, a phone has a
/// bottom sheet and a list that keeps loading as it is scrolled; the filter
/// model, defaults and reset semantics are the website's.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialCategory, this.initialQuery});

  static const path = '/marketplace';
  static const defaultFilters = defaultMarketplaceFilters;

  final String? initialCategory;
  final String? initialQuery;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

const _sortLabels = {
  ArtworkSortBy.newest: 'Newest',
  ArtworkSortBy.priceAsc: 'Price: Low to High',
  ArtworkSortBy.priceDesc: 'Price: High to Low',
};

/// Text on a gold fill: the same near-black in both themes, as on the website.
const _onGold = Color(0xFF171310);

/// How far from the end of the list the next page starts loading.
const _loadAheadExtent = 600.0;

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  late ArtworkFilters _filters = MarketplaceScreen.defaultFilters.copyWith(
    categories: widget.initialCategory == null ? const [] : [widget.initialCategory!],
    query: widget.initialQuery,
  );
  late final TextEditingController _search = TextEditingController(text: widget.initialQuery ?? '');
  final _catalogKey = GlobalKey();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _apply(ArtworkFilters next) {
    if (next == _filters) return;
    // A chip or "Clear all" can change the query from outside the box; keep the
    // box honest. Typing never arrives here with different text, so this never
    // overwrites what is being typed.
    final text = next.query ?? '';
    if (next.query != _filters.query && text != _search.text) _search.text = text;
    setState(() => _filters = next);
  }

  /// Same 300ms pause the website's search bar waits for, so a keystroke does
  /// not start a request.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _apply(_filters.copyWith(query: value.isEmpty ? null : value));
    });
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    _apply(_filters.copyWith(query: value.isEmpty ? null : value));
  }

  /// The pills act like tabs: one category at a time, or All. The filter sheet
  /// still allows several.
  void _selectCategory(String? category) {
    final alreadyOnly = _filters.categories.length == 1 && _filters.categories.first == category;
    _apply(_filters.copyWith(categories: category == null || alreadyOnly ? const [] : [category]));
  }

  /// A rank in the guide filters the catalogue to it and brings it into view.
  void _pickRank(ArtworkRarity rank) {
    _apply(_filters.copyWith(rarity: rank));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _catalogKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(marketplaceOverviewProvider);
    ref.invalidate(marketplaceFeedProvider(_filters));
    try {
      await ref.read(marketplaceFeedProvider(_filters).future);
    } catch (_) {
      // Pulling to refresh while offline leaves the list as it was.
    }
  }

  bool _loadMoreIfNearEnd(ScrollMetrics metrics) {
    if (metrics.axis == Axis.vertical && metrics.extentAfter < _loadAheadExtent) {
      ref.read(marketplaceFeedProvider(_filters).notifier).loadMore();
    }
    return false;
  }

  List<_ActiveChip> _activeChips(MarketplaceFacets facets) {
    final f = _filters;
    return [
      for (final value in f.categories)
        _ActiveChip(
          'category-$value',
          humanize(value),
          () => _apply(f.copyWith(categories: [...f.categories.where((c) => c != value)])),
        ),
      for (final value in f.mediums)
        _ActiveChip(
          'medium-$value',
          humanize(value),
          () => _apply(f.copyWith(mediums: [...f.mediums.where((m) => m != value)])),
        ),
      if (f.minPrice != null || f.maxPrice != null)
        _ActiveChip(
          'price',
          PriceBand(min: f.minPrice, max: f.maxPrice).label,
          () => _apply(f.copyWith(minPrice: null, maxPrice: null)),
        ),
      if (f.size != null)
        _ActiveChip('size', artworkSizeBandLabel[f.size]!, () => _apply(f.copyWith(size: null))),
      if (f.artistId != null)
        _ActiveChip(
          'artist',
          facets.artists.where((a) => a.id == f.artistId).firstOrNull?.name ?? 'Artist',
          () => _apply(f.copyWith(artistId: null)),
        ),
      if (f.location != null) _ActiveChip('location', f.location!, () => _apply(f.copyWith(location: null))),
      if (f.rarity != null) _ActiveChip('rarity', rankLabel(f.rarity!), () => _apply(f.copyWith(rarity: null))),
      if (f.query != null) _ActiveChip('query', '“${f.query}”', () => _apply(f.copyWith(query: null))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(marketplaceFeedProvider(_filters));
    final facets = ref.watch(artworkFacetsProvider);
    final facetData = facets.value ?? MarketplaceFacets.empty;
    final chips = _activeChips(facetData);
    final loaded = feed.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Marketplace'),
        actions: [
          IconButton(
            onPressed: () => context.push(ArtistsDirectoryScreen.path),
            tooltip: 'Artists',
            icon: const Icon(LucideIcons.users),
          ),
          IconButton(
            onPressed: () => context.push(AboutScreen.path),
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => n.depth == 0 && _loadMoreIfNearEnd(n.metrics),
          child: NotificationListener<ScrollMetricsNotification>(
            // A tall screen can show the whole first page without ever
            // scrolling; the layout change is what asks for the next one.
            onNotification: (n) => _loadMoreIfNearEnd(n.metrics),
            child: CustomScrollView(
              // Pulling down must work when the page is shorter than the screen.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchNow,
                    categories: facetData.categories,
                    selected: _filters.categories,
                    onSelectCategory: _selectCategory,
                  ),
                ),
                SliverToBoxAdapter(
                  key: _catalogKey,
                  child: _Toolbar(
                    total: loaded?.total,
                    chips: chips,
                    sortBy: _filters.sortBy ?? ArtworkSortBy.newest,
                    onSort: (sort) => _apply(_filters.copyWith(sortBy: sort)),
                    onClearAll: () => _apply(MarketplaceScreen.defaultFilters),
                    onOpenFilters: () => showMarketplaceFilterSheet(
                      context,
                      filters: _filters,
                      onChanged: _apply,
                    ),
                  ),
                ),
                ..._results(feed),
                if (facets.hasValue)
                  SliverToBoxAdapter(
                    child: _RankGuide(counts: facetData.rarityCounts, onPick: _pickRank),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _results(AsyncValue<MarketplaceFeed> feed) {
    final loaded = feed.value;
    if (loaded == null) {
      if (feed.hasError) {
        return [
          SliverToBoxAdapter(
            child: EmptyState(
              icon: LucideIcons.triangleAlert,
              title: "The marketplace didn't load",
              description: 'Check your connection and try again.',
              action: OutlinedButton(
                onPressed: () => ref.invalidate(marketplaceFeedProvider(_filters)),
                child: const Text('Try again'),
              ),
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverGrid(
            gridDelegate: ArtworkGridDelegate.of(context),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ArtworkCardSkeleton(),
              childCount: 8,
            ),
          ),
        ),
      ];
    }

    if (loaded.artworks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: LucideIcons.searchX,
            title: 'No artworks match these filters',
            description: 'Remove a filter or search with different words to see more work.',
            action: OutlinedButton(
              onPressed: () => _apply(MarketplaceScreen.defaultFilters),
              child: const Text('Clear all filters'),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: SliverGrid(
          gridDelegate: ArtworkGridDelegate.of(context),
          delegate: SliverChildBuilderDelegate(
            (context, index) => ArtworkCard(key: ValueKey(loaded.artworks[index].id), artwork: loaded.artworks[index]),
            childCount: loaded.artworks.length,
          ),
        ),
      ),
      if (loaded.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        )
      else if (loaded.loadMoreFailed)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const Text("Couldn't load more artworks."),
                TextButton(
                  onPressed: () => ref.read(marketplaceFeedProvider(_filters).notifier).loadMore(),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _ActiveChip {
  const _ActiveChip(this.key, this.label, this.onRemove);

  final String key;
  final String label;
  final VoidCallback onRemove;
}

/// The page's opening: what GalleryZone is, the search, and the category pills.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.categories,
    required this.selected,
    required this.onSelectCategory,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final List<String> categories;
  final List<String> selected;

  /// Null is "All".
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORIGINAL ART. REAL PEOPLE. MEANINGFUL STORIES.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover original art from independent artists',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Explore unique paintings, sculptures and more from talented artists across India and beyond.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 20),
                _SearchField(controller: controller, onChanged: onChanged, onSubmitted: onSubmitted),
              ],
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryPill(label: 'All', active: selected.isEmpty, onTap: () => onSelectCategory(null)),
                  for (final category in categories)
                    _CategoryPill(
                      label: humanize(category),
                      active: selected.contains(category),
                      onTap: () => onSelectCategory(category),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: color, width: width),
        );
    final ring = theme.colorScheme.primary.withValues(alpha: 0.5);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search artworks, artists, styles, mediums...',
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(LucideIcons.search, size: 20),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton.filled(
                  tooltip: 'Search',
                  onPressed: () => onSubmitted(controller.text),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: _onGold,
                    minimumSize: const Size(40, 40),
                  ),
                  icon: const Icon(LucideIcons.arrowRight, size: 20),
                ),
              ),
            ],
          ),
        ),
        border: border(ring),
        enabledBorder: border(ring),
        focusedBorder: border(theme.colorScheme.primary, 1.5),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: Material(
          color: active ? theme.colorScheme.primary : Colors.transparent,
          shape: StadiumBorder(side: BorderSide(color: active ? Colors.transparent : theme.colorScheme.outline)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: active ? _onGold : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The count, the filter chips that are on, and the Filters and Sort controls.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.total,
    required this.chips,
    required this.sortBy,
    required this.onSort,
    required this.onClearAll,
    required this.onOpenFilters,
  });

  final int? total;
  final List<_ActiveChip> chips;
  final ArtworkSortBy sortBy;
  final ValueChanged<ArtworkSortBy> onSort;
  final VoidCallback onClearAll;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ToolbarButton(
                  onTap: onOpenFilters,
                  semanticLabel: chips.isEmpty ? 'Filters' : 'Filters, ${chips.length} on',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.slidersHorizontal, size: 16),
                      const SizedBox(width: 8),
                      const Text('Filters'),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: Text(
                            '${chips.length}',
                            style: theme.textTheme.labelSmall?.copyWith(color: _onGold, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PopupMenuButton<ArtworkSortBy>(
                  tooltip: 'Sort artworks',
                  initialValue: sortBy,
                  onSelected: onSort,
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) => [
                    for (final entry in _sortLabels.entries)
                      PopupMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  child: _ToolbarButton(
                    semanticLabel: 'Sort artworks, ${_sortLabels[sortBy]}',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Sort:', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 6),
                        Text(_sortLabels[sortBy]!),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (count != null || chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (count != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '$count ${count == 1 ? 'artwork' : 'artworks'}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                for (final chip in chips)
                  InputChip(
                    key: ValueKey(chip.key),
                    label: Text(chip.label),
                    onDeleted: chip.onRemove,
                    deleteButtonTooltipMessage: 'Remove filter ${chip.label}',
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelMedium,
                    backgroundColor: theme.cardTheme.color,
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: const StadiumBorder(),
                  ),
                if (chips.isNotEmpty)
                  TextButton(
                    onPressed: onClearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.tertiary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.child, required this.semanticLabel, this.onTap});

  final Widget child;
  final String semanticLabel;

  /// Null where the parent (the sort menu) takes the tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Each rank's own colour: the tile, the card's tint and its edge. The same
/// four hues the cards stamp on a piece, a little brighter so they hold up on
/// a tinted card.
const _rankColor = {
  ArtworkRarity.rare: Color(0xFFE5484D),
  ArtworkRarity.unique: Color(0xFF12B886),
  ArtworkRarity.original: Color(0xFFE0A63E),
  ArtworkRarity.standard: Color(0xFF9AA4B2),
};

/// "Every painting has a rank" — what the four ranks mean and how many works
/// each holds; a rank with works is a shortcut to them.
class _RankGuide extends StatelessWidget {
  const _RankGuide({required this.counts, required this.onPick});

  final Map<ArtworkRarity, int> counts;
  final ValueChanged<ArtworkRarity> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RANKED BY GALLERYZONE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Every painting has a rank',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Artists do not pick it. GalleryZone reviews each work and gives it one of four ranks before it '
              'goes live. Choose one to see its works.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            for (final rank in ArtworkRarity.values) ...[
              _RankCard(rank: rank, count: counts[rank] ?? 0, onTap: () => onPick(rank)),
              if (rank != ArtworkRarity.values.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.count, required this.onTap});

  final ArtworkRarity rank;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _rankColor[rank]!;
    final radius = BorderRadius.circular(AppRadius.xl);
    return Semantics(
      button: count > 0,
      label: '${rankLabel(rank)}, ${count == 0 ? 'none yet' : '$count ${count == 1 ? 'work' : 'works'}'}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          // A rank with no works is still part of the guide, so it stays at
          // full strength; it just is not a link to an empty list.
          onTap: count > 0 ? onTap : null,
          borderRadius: radius,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Color.alphaBlend(color.withValues(alpha: 0.38), theme.colorScheme.outline)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: const Alignment(0.6, 0.4),
                colors: [color.withValues(alpha: 0.17), color.withValues(alpha: 0)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.48)!],
                    ),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Text(
                    artworkRarityCode[rank]!,
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            rankLabel(rank),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? color.withValues(alpha: 0.26)
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              count == 0 ? 'None yet' : '$count ${count == 1 ? 'work' : 'works'}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: count > 0
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        artworkRarityDescription[rank]!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View works',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.arrowRight, size: 14, color: theme.colorScheme.tertiary),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
