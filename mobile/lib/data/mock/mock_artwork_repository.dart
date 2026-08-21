import '../models/artist.dart';
import '../models/artwork.dart';
import '../models/artwork_filters.dart';
import '../repositories/artwork_repository.dart';
import '../storage/mock_db.dart';
import 'mock_utils.dart';
import 'seed/artist_seed.dart';
import 'seed/artists_seed.dart';
import 'seed/artworks_seed.dart';

const _artworksKey = 'artworks';

/// Seed for the `artworks` collection: the public fixtures plus the demo
/// artist's already-approved work — the same merge the web makes, so a piece
/// she sees as "live" in the portal is the same record a collector browses.
/// Her drafts and in-review submissions are deliberately absent: those live
/// in `pendingArtworks`.
///
/// Every reader of this collection must seed it through this function. A
/// second reader seeding it with `[]` would persist an empty marketplace for
/// whichever repository happened to touch it first.
List<Artwork> seedArtworksCollection() => [...seedArtworks(), ...seedArtistListedArtworks()];

class MockArtworkRepository implements ArtworkRepository {
  List<Artwork> _readAll() => MockDb.getCollection(
    _artworksKey,
    seedArtworksCollection,
    Artwork.fromJson,
    (a) => a.toJson(),
  );

  @override
  Future<List<Artwork>> list(ArtworkFilters filters) => mockDelay(() {
    var results = _readAll();

    if (filters.category != null) {
      results = results.where((a) => a.category == filters.category).toList();
    }
    if (filters.medium != null) {
      results = results.where((a) => a.medium == filters.medium).toList();
    }
    if (filters.minPrice != null) {
      results = results.where((a) => a.customerPrice >= filters.minPrice!).toList();
    }
    if (filters.maxPrice != null) {
      results = results.where((a) => a.customerPrice <= filters.maxPrice!).toList();
    }
    if (filters.query != null && filters.query!.trim().isNotEmpty) {
      final q = filters.query!.toLowerCase();
      results = results.where((a) => a.title.toLowerCase().contains(q) || a.artistName.toLowerCase().contains(q)).toList();
    }

    switch (filters.sortBy) {
      case ArtworkSortBy.priceAsc:
        results.sort((a, b) => a.customerPrice.compareTo(b.customerPrice));
      case ArtworkSortBy.priceDesc:
        results.sort((a, b) => b.customerPrice.compareTo(a.customerPrice));
      case ArtworkSortBy.newest:
      case null:
        // "Newest" proxy: the artwork's earliest status-history entry (its
        // draft/creation date) — Artwork has no standalone createdAt field
        // on the web model either, this is the same signal that would be
        // used there.
        results.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    }

    return results;
  });

  DateTime _createdAt(Artwork a) =>
      a.statusHistory.isEmpty ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(a.statusHistory.first.changedAt);

  @override
  Future<Artwork?> get(String id) => mockDelay(() {
    final all = _readAll();
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  });

  @override
  Future<List<Artwork>> listByArtist(String artistId) =>
      mockDelay(() => _readAll().where((a) => a.artistId == artistId).toList());

  @override
  Future<ArtistProfile?> getArtistProfile(String id) => mockDelay(() {
    final artists = seedArtists();
    for (final a in artists) {
      if (a.id == id) return a;
    }
    return null;
  });

  @override
  Future<List<ArtistProfile>> listArtists() => mockDelay(seedArtists);
}
