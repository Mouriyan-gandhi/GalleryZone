import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork_filters.dart';
import '../../marketing/screens/about_screen.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';

/// Port of `app/marketplace/page.tsx` + `marketplace-grid.tsx`. The web's
/// always-visible filter bar becomes a bottom sheet here — four selects and
/// two number inputs laid out inline is a desktop affordance, not a phone
/// one — but the filter model, defaults and reset semantics are identical.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialCategory, this.initialQuery});

  static const path = '/marketplace';
  static const defaultFilters = ArtworkFilters(sortBy: ArtworkSortBy.newest);

  final String? initialCategory;
  final String? initialQuery;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  late ArtworkFilters _filters = MarketplaceScreen.defaultFilters.copyWith(
    category: widget.initialCategory,
    query: widget.initialQuery,
  );
  late final TextEditingController _search =
      TextEditingController(text: widget.initialQuery ?? '');
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Same 300ms debounce the web search bar uses, so the repository's 600ms
  /// mock delay doesn't refire on every keystroke.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _filters = _filters.copyWith(query: value.isEmpty ? null : value));
    });
  }

  bool get _hasStructuredFilters =>
      _filters.category != null ||
      _filters.medium != null ||
      _filters.minPrice != null ||
      _filters.maxPrice != null ||
      (_filters.sortBy != null && _filters.sortBy != ArtworkSortBy.newest);

  Future<void> _openFilterSheet() async {
    final updated = await showModalBottomSheet<ArtworkFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterSheet(filters: _filters),
    );
    if (updated != null) setState(() => _filters = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artworks = ref.watch(artworksProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Marketplace'),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible: _hasStructuredFilters,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
          IconButton(
            onPressed: () => context.push(AboutScreen.path),
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(artworksProvider(_filters).future),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original, verified artwork from independent artists across '
                      'India. Every piece ships with a signed certificate of '
                      'authenticity.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search artworks, artists, mediums…',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  _onSearchChanged('');
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl4),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl4),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl4),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...artworks.when(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (error, stack) => [
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: LucideIcons.triangleAlert,
                    title: 'Something went wrong',
                    description:
                        "We couldn't load the marketplace right now. Please try "
                        'again in a moment.',
                  ),
                ),
              ],
              data: (results) {
                if (results.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: LucideIcons.searchX,
                        title: 'No artworks match your filters',
                        description:
                            'Try widening your price range or clearing a filter to '
                            'see more original work.',
                        action: OutlinedButton(
                          onPressed: () => setState(() {
                            _search.clear();
                            _filters = MarketplaceScreen.defaultFilters;
                          }),
                          child: const Text('Clear filters'),
                        ),
                      ),
                    ),
                  ];
                }
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '${results.length} ${results.length == 1 ? 'artwork' : 'artworks'}',
                        style: theme.textTheme.bodySmall,
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
                        // 4:5 image + the title/artist/price block under it.
                        childAspectRatio: 0.56,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ArtworkCard(artwork: results[index]),
                        childCount: results.length,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.filters});

  final ArtworkFilters filters;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ArtworkFilters _draft = widget.filters;
  late final TextEditingController _min =
      TextEditingController(text: widget.filters.minPrice?.toStringAsFixed(0) ?? '');
  late final TextEditingController _max =
      TextEditingController(text: widget.filters.maxPrice?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(
      _draft.copyWith(
        minPrice: _min.text.isEmpty ? null : double.tryParse(_min.text),
        maxPrice: _max.text.isEmpty ? null : double.tryParse(_max.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facets = ref.watch(artworkFacetsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            facets.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )),
              error: (error, stack) => const SizedBox.shrink(),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Dropdown<String>(
                    label: 'Category',
                    value: _draft.category,
                    allLabel: 'All categories',
                    items: {for (final c in data.categories) c: titleCase(c)},
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(category: value)),
                  ),
                  const SizedBox(height: 16),
                  _Dropdown<String>(
                    label: 'Medium',
                    value: _draft.medium,
                    allLabel: 'All mediums',
                    items: {for (final m in data.mediums) m: m},
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(medium: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Price range (₹)', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Min'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to'),
                ),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Dropdown<ArtworkSortBy>(
              label: 'Sort by',
              value: _draft.sortBy ?? ArtworkSortBy.newest,
              items: const {
                ArtworkSortBy.newest: 'Newest',
                ArtworkSortBy.priceAsc: 'Price: Low to High',
                ArtworkSortBy.priceDesc: 'Price: High to Low',
              },
              onChanged: (value) => setState(
                () => _draft = _draft.copyWith(sortBy: value ?? ArtworkSortBy.newest),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _min.clear();
                      _max.clear();
                      setState(() => _draft = MarketplaceScreen.defaultFilters
                          .copyWith(query: widget.filters.query));
                    },
                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _apply, child: const Text('Apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled dropdown. A null [value] means "no filter" — the web's `all`
/// sentinel exists only because its Select primitive needs a real string;
/// here null is representable, so the sentinel isn't needed.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.allLabel,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          items: [
            if (allLabel != null) DropdownMenuItem<T>(value: null, child: Text(allLabel!)),
            for (final entry in items.entries)
              DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
