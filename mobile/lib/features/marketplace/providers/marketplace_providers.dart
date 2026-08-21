import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_artwork_repository.dart';
import '../../../data/models/artist.dart';
import '../../../data/models/artwork.dart';
import '../../../data/models/artwork_filters.dart';
import '../../../data/repositories/artwork_repository.dart';
import '../../../data/storage/mock_db.dart';

/// Only place the concrete implementation is named — a dio-backed
/// `RemoteArtworkRepository` overrides this and nothing else changes.
final artworkRepositoryProvider = Provider<ArtworkRepository>((ref) {
  return MockArtworkRepository();
});

/// All four reads are `autoDispose` on purpose: SAD §9.2 forbids caching
/// financial/stateful data client-side, and an artwork's `status` (reserved
/// / sold) is exactly that — a stale grid showing a sold piece as available
/// is the failure mode. Nothing here is pinned in app-wide state.
final artworksProvider =
    FutureProvider.autoDispose.family<List<Artwork>, ArtworkFilters>((ref, filters) {
  return ref.watch(artworkRepositoryProvider).list(filters);
});

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

/// The distinct `category` / `medium` values the filter sheet offers. The
/// web derives these from the fixture module directly; here they come off
/// whatever the repository currently returns, so an artwork added later
/// (Phase 5's upload flow) shows up as a filter option without a code
/// change.
final artworkFacetsProvider =
    FutureProvider.autoDispose<({List<String> categories, List<String> mediums})>((ref) async {
  final all = await ref.watch(artworkRepositoryProvider).list(const ArtworkFilters());
  final categories = all.map((a) => a.category).toSet().toList()..sort();
  final mediums = all.map((a) => a.medium).toSet().toList()..sort();
  return (categories: categories, mediums: mediums);
});

/// Client-only wishlist, same scoped exception the web makes (SAD §5.5:
/// server data never lives in client state — but there is no /wishlist API
/// yet). Persisted under the same `gz-wishlist` key the web's zustand store
/// uses, and deliberately shaped like the query-backed hook that replaces
/// it later, so the swap is mechanical.
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
