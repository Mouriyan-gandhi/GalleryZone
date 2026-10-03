import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/artwork_filters.dart';
import '../filter_options.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/artwork_card.dart';

/// The marketplace filters as a bottom sheet — the website's filter sidebar
/// moved to where a thumb can reach it.
///
/// [onChanged] hears every tick as it happens, so the results behind the sheet
/// update live exactly as they do beside the website's sidebar; the sheet
/// closes on "Show results" or a swipe down, and there is nothing to apply.
Future<void> showMarketplaceFilterSheet(
  BuildContext context, {
  required ArtworkFilters filters,
  required ValueChanged<ArtworkFilters> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _FilterSheet(filters: filters, onChanged: onChanged),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.filters, required this.onChanged});

  final ArtworkFilters filters;
  final ValueChanged<ArtworkFilters> onChanged;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ArtworkFilters _draft = widget.filters;

  void _update(ArtworkFilters next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  List<String> _toggled(List<String> values, String value) =>
      values.contains(value) ? [...values.where((v) => v != value)] : [...values, value];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facets = ref.watch(artworkFacetsProvider);
    final counts = ref.watch(filterCountsProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filters', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close filters',
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Expanded(
            child: facets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("The filter options didn't load.", style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(marketplaceOverviewProvider),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final priceOptions = [
                  for (var i = 0; i < priceBands.length; i++)
                    if (counts == null || counts.price[i] != 0) (band: priceBands[i], count: counts?.price[i]),
                ];
                final sizeOptions = [
                  for (final size in ArtworkSizeBand.values)
                    if (counts == null || (counts.size[size] ?? 0) > 0) size,
                ];
                final ranks = [
                  for (final rank in ArtworkRarity.values)
                    if ((data.rarityCounts[rank] ?? 0) > 0) rank,
                ];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (data.categories.isNotEmpty)
                      _Group(
                        key: const ValueKey('category'),
                        title: 'Category',
                        expanded: true,
                        children: [
                          for (final category in data.categories)
                            _Option(
                              label: humanize(category),
                              count: counts?.category[category],
                              checked: _draft.categories.contains(category),
                              onToggle: () => _update(
                                _draft.copyWith(categories: _toggled(_draft.categories, category)),
                              ),
                            ),
                        ],
                      ),
                    if (data.mediums.isNotEmpty)
                      _Group(
                        key: const ValueKey('medium'),
                        title: 'Medium',
                        expanded: true,
                        children: [
                          for (final medium in data.mediums)
                            _Option(
                              label: humanize(medium),
                              count: counts?.medium[medium],
                              checked: _draft.mediums.contains(medium),
                              onToggle: () => _update(
                                _draft.copyWith(mediums: _toggled(_draft.mediums, medium)),
                              ),
                            ),
                        ],
                      ),
                    if (priceOptions.isNotEmpty)
                      _Group(
                        key: const ValueKey('price'),
                        title: 'Price',
                        expanded: true,
                        children: [
                          for (final option in priceOptions)
                            Builder(
                              builder: (context) {
                                final checked = option.band.matches(_draft.minPrice, _draft.maxPrice);
                                return _Option(
                                  label: option.band.label,
                                  count: option.count,
                                  checked: checked,
                                  onToggle: () => _update(
                                    checked
                                        ? _draft.copyWith(minPrice: null, maxPrice: null)
                                        : _draft.copyWith(minPrice: option.band.min, maxPrice: option.band.max),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    if (sizeOptions.isNotEmpty)
                      _Group(
                        key: const ValueKey('size'),
                        title: 'Size',
                        children: [
                          for (final size in sizeOptions)
                            _Option(
                              label: artworkSizeBandLabel[size]!,
                              count: counts?.size[size],
                              checked: _draft.size == size,
                              onToggle: () => _update(_draft.copyWith(size: _draft.size == size ? null : size)),
                            ),
                        ],
                      ),
                    if (data.artists.isNotEmpty)
                      _Group(
                        key: const ValueKey('artist'),
                        title: 'Artist',
                        children: [
                          for (final artist in data.artists)
                            _Option(
                              label: artist.name,
                              count: counts?.artist[artist.id],
                              checked: _draft.artistId == artist.id,
                              onToggle: () => _update(
                                _draft.copyWith(artistId: _draft.artistId == artist.id ? null : artist.id),
                              ),
                            ),
                        ],
                      ),
                    if (data.locations.isNotEmpty)
                      _Group(
                        key: const ValueKey('location'),
                        title: 'Location',
                        children: [
                          for (final location in data.locations)
                            _Option(
                              label: location,
                              count: counts?.location[location],
                              checked: _draft.location == location,
                              onToggle: () => _update(
                                _draft.copyWith(location: _draft.location == location ? null : location),
                              ),
                            ),
                        ],
                      ),
                    if (ranks.isNotEmpty)
                      _Group(
                        key: const ValueKey('rank'),
                        title: 'Rank',
                        children: [
                          for (final rank in ranks)
                            _Option(
                              label: rankLabel(rank),
                              count: data.rarityCounts[rank],
                              checked: _draft.rarity == rank,
                              leading: _RankDot(rank: rank),
                              onToggle: () => _update(_draft.copyWith(rarity: _draft.rarity == rank ? null : rank)),
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _update(defaultMarketplaceFilters.copyWith(query: _draft.query)),
                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Show results'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One collapsible group of options — the website's accordion item.
class _Group extends StatelessWidget {
  const _Group({super.key, required this.title, required this.children, this.expanded = false});

  final String title;
  final List<Widget> children;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outline))),
      child: Theme(
        // ExpansionTile draws its own hairlines; the group already has one.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          children: children,
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.checked,
    required this.onToggle,
    this.count,
    this.leading,
  });

  final String label;
  final bool checked;
  final VoidCallback onToggle;
  final int? count;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: checked,
      onChanged: (_) => onToggle(),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (count != null) Text('($count)', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// The rank's letter in its own stamp colour.
class _RankDot extends StatelessWidget {
  const _RankDot({required this.rank});

  final ArtworkRarity rank;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = RarityBadge.stampTone(context, rank);
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        artworkRarityCode[rank]!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
