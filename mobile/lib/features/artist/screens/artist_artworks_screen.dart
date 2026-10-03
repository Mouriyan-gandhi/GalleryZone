import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/adaptive.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/artwork.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/widgets/artwork_card.dart';
import '../providers/artist_providers.dart';
import '../widgets/artist_widgets.dart';

/// Each tab is a bucket of statuses, not one status: a piece that is
/// "reserved" by an aggregator belongs under "With aggregator", and one that is
/// "delivered" or "completed" is still a sale. Every status the API can return
/// lands in exactly one bucket, so nothing is reachable only through "All".
enum ArtworkBucket { all, draft, pending, live, aggregator, sold, soldElsewhere, returned }

extension ArtworkBucketX on ArtworkBucket {
  String get label => switch (this) {
        ArtworkBucket.all => 'All',
        ArtworkBucket.draft => 'Draft',
        ArtworkBucket.pending => 'Pending',
        ArtworkBucket.live => 'Live',
        ArtworkBucket.aggregator => 'With aggregator',
        ArtworkBucket.sold => 'Sold',
        ArtworkBucket.soldElsewhere => 'Sold elsewhere',
        ArtworkBucket.returned => 'Returned',
      };

  /// Null for "All".
  Set<ArtworkStatus>? get statuses => switch (this) {
        ArtworkBucket.all => null,
        ArtworkBucket.draft => const {ArtworkStatus.draft},
        ArtworkBucket.pending => const {ArtworkStatus.pendingApproval},
        ArtworkBucket.live => const {ArtworkStatus.marketplace},
        ArtworkBucket.aggregator => const {ArtworkStatus.reserved, ArtworkStatus.withAggregator},
        ArtworkBucket.sold => const {
            ArtworkStatus.sold,
            ArtworkStatus.settlementComplete,
            ArtworkStatus.delivered,
            ArtworkStatus.completed,
          },
        ArtworkBucket.soldElsewhere => const {ArtworkStatus.soldExternally},
        ArtworkBucket.returned => const {ArtworkStatus.returned},
      };

  bool matches(ArtworkStatus status) => statuses?.contains(status) ?? true;
}

/// Port of `features/dashboard/artworks-board.tsx` — the management board,
/// the only screen in the app that shows drafts and in-review submissions,
/// and the only one that shows the artist's own asking price beside the
/// customer price. A search box narrows it further (the website's board has
/// none; a phone's list is longer to scroll).
class ArtistArtworksScreen extends ConsumerStatefulWidget {
  const ArtistArtworksScreen({super.key});

  static const path = '/dashboard/artworks';

  @override
  ConsumerState<ArtistArtworksScreen> createState() => _ArtistArtworksScreenState();
}

class _ArtistArtworksScreenState extends ConsumerState<ArtistArtworksScreen> {
  ArtworkBucket _bucket = ArtworkBucket.all;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artworks = ref.watch(artistArtworksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Artworks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/artworks/upload'),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('List new artwork'),
      ),
      body: artworks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your artworks couldn't be loaded just now.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(artistArtworksProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (list) => _Board(
          list: list,
          bucket: _bucket,
          onBucketChanged: (value) => setState(() => _bucket = value),
          searchController: _searchController,
          query: _query,
          onQueryChanged: (value) => setState(() => _query = value),
        ),
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({
    required this.list,
    required this.bucket,
    required this.onBucketChanged,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  final List<ArtistArtwork> list;
  final ArtworkBucket bucket;
  final ValueChanged<ArtworkBucket> onBucketChanged;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final needle = query.trim().toLowerCase();
    final filtered = [
      for (final entry in list)
        if (bucket.matches(entry.artwork.status) &&
            (needle.isEmpty || entry.artwork.title.toLowerCase().contains(needle)))
          entry,
    ];
    int countOf(ArtworkBucket b) => list.where((e) => b.matches(e.artwork.status)).length;

    return Column(
      children: [
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${list.length} ${list.length == 1 ? 'artwork' : 'artworks'}', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  "Manage submissions, track status, and see what's live.",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (list.isNotEmpty)
                  TextField(
                    controller: searchController,
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      hintText: 'Search your artworks…',
                      isDense: true,
                    ),
                  ),
                const SizedBox(height: 10),
                // Wrap, not a horizontal ScrollView — a second Scrollable in
                // the tree breaks tester.scrollUntilVisible's default lookup
                // (it expects exactly one), and wrapping reads fine at every
                // phone width anyway. Empty buckets stay visible so the artist
                // learns the vocabulary.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in ArtworkBucket.values)
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(option.label),
                            const SizedBox(width: 6),
                            Text(
                              '${countOf(option)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        selected: bucket == option,
                        onSelected: (_) => onBucketChanged(option),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _Empty(
                  hasAny: list.isNotEmpty,
                  bucket: bucket,
                  searching: needle.isNotEmpty,
                  total: list.length,
                  onShowAll: () {
                    searchController.clear();
                    onQueryChanged('');
                    onBucketChanged(ArtworkBucket.all);
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(artistArtworksProvider);
                    await ref.read(artistArtworksProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => ContentWidth(child: ArtistArtworkRow(entry: filtered[index])),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.hasAny,
    required this.bucket,
    required this.searching,
    required this.total,
    required this.onShowAll,
  });

  final bool hasAny;
  final ArtworkBucket bucket;
  final bool searching;
  final int total;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) {
      return const EmptyState(
        icon: LucideIcons.frame,
        title: "You haven't listed anything yet.",
        description: 'Add your paintings here to get them listed on the marketplace.',
      );
    }
    return EmptyState(
      icon: LucideIcons.searchX,
      title: searching ? 'No matching artworks' : 'Nothing under “${bucket.label}” right now.',
      description: searching ? 'Try a different filter or search term.' : 'Pieces move here as their status changes.',
      action: OutlinedButton(onPressed: onShowAll, child: Text('Show all $total')),
    );
  }
}

/// Shows both prices side by side. This is the type wall in action: the row
/// takes an [ArtistArtwork], the only shape carrying `artistPrice`, so a
/// customer-facing screen physically cannot render this widget.
class ArtistArtworkRow extends ConsumerWidget {
  const ArtistArtworkRow({super.key, required this.entry});

  final ArtistArtwork entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artwork = entry.artwork;
    final editState = artworkEditState(artwork);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 60,
                  height: 60,
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
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        humanize(artwork.medium),
                        if (artwork.yearCreated != null) '${artwork.yearCreated}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ArtworkStatusPill(status: artwork.status),
                        if (artwork.rarityType != null) RarityBadge(rarity: artwork.rarityType!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Your price', style: theme.textTheme.labelSmall),
                  Text(
                    formatInr(entry.artistPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Listed price', style: theme.textTheme.labelSmall),
                  Text(formatInr(artwork.customerPrice), style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Text(listingTypeLabel[artwork.listingType]!, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (editState.editable)
                _RowAction(
                  icon: LucideIcons.pencil,
                  label: artwork.status == ArtworkStatus.draft
                      ? 'Continue editing'
                      : 'Edit · ${editState.daysLeft} '
                            '${editState.daysLeft == 1 ? "day" : "days"} left',
                  onTap: () => context.push('/dashboard/artworks/${artwork.id}/edit'),
                )
              else
                _RowAction(
                  icon: LucideIcons.lock,
                  label: editState.reason == ArtworkEditReason.purchased
                      ? 'Locked — sold or claimed'
                      : 'Edit window closed',
                ),
              if (artwork.status == ArtworkStatus.draft)
                _RowAction(
                  icon: LucideIcons.send,
                  label: 'Send for review',
                  onTap: () => _sendForReview(context, ref, artwork),
                ),
              if (withdrawableStatuses.contains(artwork.status))
                _RowAction(
                  icon: LucideIcons.externalLink,
                  label: 'Sold on other platform',
                  destructive: true,
                  onTap: () => _confirmSoldElsewhere(context, ref, entry),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _sendForReview(BuildContext context, WidgetRef ref, Artwork artwork) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(artistRepositoryProvider).submitForReview(artwork.id);
    ref.invalidate(artistArtworksProvider);
    ref.invalidate(artistKpisProvider);
    ref.invalidate(artistActivityProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Sent for review — it goes live once approved')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

/// The withdrawal is irreversible and may cost the artist money, so the exact
/// amount is named in the dialog rather than described as "a fee". The fee is
/// raised for an admin to decide - it is not charged by this tap.
Future<void> _confirmSoldElsewhere(BuildContext context, WidgetRef ref, ArtistArtwork entry) async {
  final messenger = ScaffoldMessenger.of(context);
  final fee = (entry.artwork.customerPrice * externalSalePenaltyRate).roundToDouble();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mark as sold on another platform?'),
      content: Text(
        '"${entry.artwork.title}" will be removed from all GalleryZone sales channels immediately and cannot be '
        'relisted. A platform fee (up to 1% of its listed price — ${formatInr(fee)}) may be applicable at the '
        "admin's discretion.",
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Mark as sold elsewhere'),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false)) return;
  try {
    await ref.read(artistRepositoryProvider).markSoldElsewhere(entry.artwork.id);
    ref.invalidate(artistArtworksProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('"${entry.artwork.title}" is marked as sold elsewhere')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({required this.icon, required this.label, this.onTap, this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onTap == null
        ? theme.textTheme.labelSmall?.color
        : destructive
        ? AppColors.destructive
        : theme.colorScheme.tertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
