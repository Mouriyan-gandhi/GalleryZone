import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_artwork_repository.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/artwork_filters.dart';
import '../../../data/models/marketplace.dart';
import '../../../data/repositories/artwork_repository.dart';
import '../../../data/storage/mock_db.dart';
import '../filter_options.dart';

/// Only place the concrete implementation is named — a dio-backed
/// `RemoteArtworkRepository` overrides this and nothing else changes.
final artworkRepositoryProvider = Provider<ArtworkRepository>((ref) {
  return MockArtworkRepository();
});

/// Every page of the marketplace loaded so far for one set of filters: the
/// first page, plus whatever scrolling has pulled in since.
class MarketplaceFeed {
  const MarketplaceFeed({
    required this.artworks,
    required this.total,
    required this.page,
    required this.pageSize,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  factory MarketplaceFeed.first(MarketplacePage page) => MarketplaceFeed(
        artworks: page.artworks,
        total: page.total,
        page: page.page,
        pageSize: page.pageSize,
      );

  final List<Artwork> artworks;

  /// How many pieces match, across every page.
  final int total;

  /// The last page that has been loaded.
  final int page;
  final int pageSize;
  final bool loadingMore;

  /// The page after [page] was asked for and did not arrive; the list stays as
  /// it was and the grid offers a retry instead of looping.
  final bool loadMoreFailed;

  bool get hasMore => page * pageSize < total;

  MarketplaceFeed copyWith({bool? loadingMore, bool? loadMoreFailed}) => MarketplaceFeed(
        artworks: artworks,
        total: total,
        page: page,
        pageSize: pageSize,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  /// This feed with the next page on the end. A piece that moved onto a later
  /// page while the list was being scrolled (a newer listing pushes everything
  /// down one) is not shown twice, and an empty page ends the list rather than
  /// asking for the next one forever.
  MarketplaceFeed append(MarketplacePage next) {
    final seen = {for (final artwork in artworks) artwork.id};
    final added = [for (final artwork in next.artworks) if (seen.add(artwork.id)) artwork];
    return MarketplaceFeed(
      artworks: [...artworks, ...added],
      total: next.artworks.isEmpty ? artworks.length : next.total,
      page: next.page,
      pageSize: next.pageSize,
    );
  }
}

/// The marketplace listing for one set of filters, paged by scrolling.
///
/// `autoDispose` on purpose: SAD §9.2 forbids caching financial/stateful data
/// client-side, and an artwork's `status` (reserved / sold) is exactly that —
/// a stale grid showing a sold piece as available is the failure mode.
/// Nothing here is pinned in app-wide state.
class MarketplaceFeedNotifier extends AsyncNotifier<MarketplaceFeed> {
  MarketplaceFeedNotifier(this.filters);

  /// Always page 1: later pages are this notifier's own business.
  final ArtworkFilters filters;

  @override
  Future<MarketplaceFeed> build() async =>
      MarketplaceFeed.first(await ref.watch(artworkRepositoryProvider).list(filters));

  /// Appends the next page. Safe to call as often as the scroll position
  /// likes: it does nothing while a page is in flight or when there is no
  /// more, and a failed page is retried only by calling it again.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final loading = current.copyWith(loadingMore: true, loadMoreFailed: false);
    state = AsyncData(loading);
    try {
      final next = await ref.read(artworkRepositoryProvider).list(filters.copyWith(page: current.page + 1));
      // Refreshed or left while the page was in flight: this answer is stale.
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(current.append(next));
    } catch (_) {
      if (!ref.mounted || !identical(state.value, loading)) return;
      state = AsyncData(current.copyWith(loadMoreFailed: true));
    }
  }
}

final marketplaceFeedProvider = AsyncNotifierProvider.autoDispose
    .family<MarketplaceFeedNotifier, MarketplaceFeed, ArtworkFilters>(MarketplaceFeedNotifier.new);

final artworkProvider =
    FutureProvider.autoDispose.family<Artwork?, String>((ref, id) {
  return ref.watch(artworkRepositoryProvider).get(id);
});

final artworksByArtistProvider =
    FutureProvider.autoDispose.family<List<Artwork>, String>((ref, artistId) {
  return ref.watch(artworkRepositoryProvider).listByArtist(artistId);
});

final artistProfileProvider =
    FutureProvider.autoDispose.family<ArtistProfile?, String>((ref, id) {
  return ref.watch(artworkRepositoryProvider).getArtistProfile(id);
});

/// The unfiltered marketplace at the API's largest page. Its facets are the
/// filter choices that exist right now — across the whole live marketplace,
/// not the page in hand, so no option is a dead end and nothing is hard-coded —
/// and its pieces let the sheet count what each option would leave.
final marketplaceOverviewProvider = FutureProvider.autoDispose<MarketplacePage>((ref) {
  return ref
      .watch(artworkRepositoryProvider)
      .list(const ArtworkFilters(pageSize: marketplaceMaxPageSize));
});

final artworkFacetsProvider = FutureProvider.autoDispose<MarketplaceFacets>((ref) async {
  return (await ref.watch(marketplaceOverviewProvider.future)).facets;
});

/// Per-option counts for the filter sheet; null until they can be trusted
/// (see [FilterCounts.from]).
final filterCountsProvider = Provider.autoDispose<FilterCounts?>((ref) {
  final overview = ref.watch(marketplaceOverviewProvider).value;
  return overview == null ? null : FilterCounts.from(overview);
});

class WishlistNotifier extends Notifier<Set<String>> {
  static const _key = 'wishlist';

  @override
  Set<String> build() =>
      MockDb.getCollection<String>(_key, () => const [], (json) => json['id'] as String, (id) => {'id': id})
          .toSet();

  bool has(String artworkId) => state.contains(artworkId);

  void toggle(String artworkId) {
    final next = Set<String>.from(state);
    if (!next.remove(artworkId)) next.add(artworkId);
    MockDb.setCollection<String>(_key, next.toList(), (id) => {'id': id});
    state = next;
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, Set<String>>(WishlistNotifier.new);

/// Artists this device follows. Deliberately the same shape as
/// [WishlistNotifier] — a persisted set of ids with no API behind it yet —
/// so both swap to a query-backed hook the same way.
///
/// Client-only has a real consequence worth knowing: a follow is not visible
/// to the artist. Nothing in the artist portal shows a follower count,
/// because a number derived from one device's storage would be fiction.
class FollowsNotifier extends Notifier<Set<String>> {
  static const _key = 'follows';

  @override
  Set<String> build() => MockDb.getCollection<String>(
        _key,
        () => const [],
        (json) => json['id'] as String,
        (id) => {'id': id},
      ).toSet();

  bool has(String artistId) => state.contains(artistId);

  void toggle(String artistId) {
    final next = Set<String>.from(state);
    if (!next.remove(artistId)) next.add(artistId);
    MockDb.setCollection<String>(_key, next.toList(), (id) => {'id': id});
    state = next;
  }
}

final followsProvider =
    NotifierProvider<FollowsNotifier, Set<String>>(FollowsNotifier.new);

/// Every public artist, keyed by id — the join target for the Following list.
final artistsProvider = FutureProvider.autoDispose<List<ArtistProfile>>((ref) {
  return ref.watch(artworkRepositoryProvider).listArtists();
});
