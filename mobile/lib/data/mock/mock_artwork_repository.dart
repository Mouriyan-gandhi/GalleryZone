import '../models/artist.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/artwork_filters.dart';
import '../models/marketplace.dart';
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

/// One gate for every public listing surface (marketplace grid, artist page
/// rails). Aggregator-only pieces are sold through partner premises and
/// never appear in the online store; a piece the artist sold elsewhere
/// leaves every channel at once. Direct lookups by id ([MockArtworkRepository.get])
/// deliberately skip this — a passport/COA link must still resolve after the
/// piece is gone.
bool isPubliclyListed(Artwork artwork) =>
    isMarketplaceListed(artwork.listingType) && artwork.status != ArtworkStatus.soldExternally;

// --- Review queue ------------------------------------------------------------

const _pendingArtworksKey = 'pendingArtworks';
const _reviewQueueKey = 'reviewQueue';
const _activityKey = 'artistActivity';

/// How long a submitted artwork sits in review before this build approves it.
///
/// There is no admin portal in the mobile app and no backend behind it, so
/// nothing else would ever move a submission out of the review queue — an
/// artist would watch a piece sit at "In review" forever. Long enough to see
/// the review state on screen, short enough to sit through in a demo.
const demoReviewDelay = Duration(seconds: 15);

/// Ids waiting on that delay, with the moment each becomes approvable.
///
/// A queue rather than a timestamp read off the artwork: the seeded fixtures
/// include a piece that has been "in review" since long before the app
/// started, and it must stay that way. Only a submission made in this app
/// enters the queue.
void enqueueForReview(String artworkId) {
  final due = DateTime.now().add(demoReviewDelay).toIso8601String();
  MockDb.setCollection(_reviewQueueKey, [
    {'id': artworkId, 'dueAt': due},
    ..._readReviewQueue().where((entry) => entry['id'] != artworkId),
  ], _identityJson);
}

List<Map<String, dynamic>> _readReviewQueue() => MockDb.getCollection(
  _reviewQueueKey,
  () => const <Map<String, dynamic>>[],
  (json) => json,
  _identityJson,
);

Map<String, dynamic> _identityJson(Map<String, dynamic> value) => value;

/// Promotes every queued submission whose delay has elapsed: out of
/// `pendingArtworks`, into the live `artworks` collection at `marketplace`.
///
/// Called by every reader of either collection, because approval has no
/// other trigger in this build. Cheap when the queue is empty, which is the
/// normal case. Drafts never move — they were never submitted.
/// [now] is injectable so a test doesn't have to sit through
/// [demoReviewDelay] in real time.
void promoteApprovedSubmissions({DateTime? now}) {
  final queue = _readReviewQueue();
  if (queue.isEmpty) return;

  now ??= DateTime.now();
  final due = queue
      .where((entry) => DateTime.parse(entry['dueAt'] as String).isBefore(now!))
      .map((entry) => entry['id'] as String)
      .toSet();
  if (due.isEmpty) return;

  final pending = MockDb.getCollection(
    _pendingArtworksKey,
    seedPendingArtworks,
    Artwork.fromJson,
    (a) => a.toJson(),
  );
  final ready = pending
      .where((a) => due.contains(a.id) && a.status == ArtworkStatus.pendingApproval)
      .toList();

  final changedAt = now.toIso8601String();
  final approved = [
    for (final artwork in ready)
      artwork.copyWith(
        status: ArtworkStatus.marketplace,
        statusHistory: [
          ...artwork.statusHistory,
          ArtworkStatusEvent(status: ArtworkStatus.marketplace, changedAt: changedAt),
        ],
      ),
  ];
  final approvedIds = approved.map((a) => a.id).toSet();

  if (approved.isNotEmpty) {
    MockDb.setCollection(
      _pendingArtworksKey,
      pending.where((a) => !approvedIds.contains(a.id)).toList(),
      (a) => a.toJson(),
    );
    final live = MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
    MockDb.setCollection(_artworksKey, [...approved, ...live], (a) => a.toJson());

    final activity = MockDb.getCollection(
      _activityKey,
      seedArtistActivity,
      ActivityEntry.fromJson,
      (e) => e.toJson(),
    );
    MockDb.setCollection(_activityKey, [
      for (final artwork in approved)
        ActivityEntry(
          id: 'act-${DateTime.now().microsecondsSinceEpoch}-${artwork.id}',
          kind: ActivityKind.artworkApproved,
          title: '"${artwork.title}" was approved',
          detail: 'Now live on the marketplace',
          time: 'Just now',
        ),
      ...activity,
    ], (e) => e.toJson());
  }

  // Drop every due entry, including any whose artwork has since been
  // withdrawn — otherwise the queue grows forever retrying a dead id.
  MockDb.setCollection(
    _reviewQueueKey,
    queue.where((entry) => !due.contains(entry['id'] as String)).toList(),
    _identityJson,
  );
}

class MockArtworkRepository implements ArtworkRepository {
  List<Artwork> _readAll() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
  }

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) => mockDelay(() {
    final live = _readAll().where(isPubliclyListed).toList();
    var results = [...live];

    if (filters.categories.isNotEmpty) {
      results = results.where((a) => filters.categories.contains(a.category)).toList();
    }
    if (filters.mediums.isNotEmpty) {
      results = results.where((a) => filters.mediums.contains(a.medium)).toList();
    }
    if (filters.rarity != null) {
      results = results.where((a) => a.rarityType == filters.rarity).toList();
    }
    if (filters.artistId != null) {
      results = results.where((a) => a.artistId == filters.artistId).toList();
    }
    if (filters.size != null) {
      results = results.where((a) => a.sizeBand == filters.size).toList();
    }
    if (filters.minPrice != null) {
      results = results.where((a) => a.customerPrice >= filters.minPrice!).toList();
    }
    if (filters.maxPrice != null) {
      results = results.where((a) => a.customerPrice <= filters.maxPrice!).toList();
    }
    if (filters.query != null && filters.query!.trim().isNotEmpty) {
      final q = filters.query!.toLowerCase();
      results = results
          .where((a) => a.title.toLowerCase().contains(q) || a.artistName.toLowerCase().contains(q))
          .toList();
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

    final start = (filters.page - 1) * marketplacePageSize;
    final page = results.skip(start).take(marketplacePageSize).toList();
    return MarketplacePage(
      artworks: page,
      total: results.length,
      page: filters.page,
      pageSize: marketplacePageSize,
      facets: _facetsOf(live),
    );
  });

  /// Every publicly listed piece, newest first, unpaged. The marketplace
  /// screen pages (like the real API); fixtures and tests that mean "all of
  /// it" ask for this instead.
  Future<List<Artwork>> listAllLive() => mockDelay(() {
    final live = _readAll().where(isPubliclyListed).toList();
    live.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    return live;
  });

  /// The filter choices across the whole live marketplace, not just the page.
  MarketplaceFacets _facetsOf(List<Artwork> live) {
    final prices = live.map((a) => a.customerPrice).toList()..sort();
    final artists = <String, String>{for (final a in live) a.artistId: a.artistName};
    return MarketplaceFacets(
      categories: (live.map((a) => a.category).toSet().toList()..sort()),
      mediums: (live.map((a) => a.medium).toSet().toList()..sort()),
      artists: [for (final e in artists.entries) FacetArtist(id: e.key, name: e.value)],
      rarityCounts: {
        for (final rank in ArtworkRarity.values)
          if (live.any((a) => a.rarityType == rank))
            rank: live.where((a) => a.rarityType == rank).length,
      },
      priceMin: prices.isEmpty ? null : prices.first,
      priceMax: prices.isEmpty ? null : prices.last,
    );
  }

  DateTime _createdAt(Artwork a) => a.statusHistory.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(a.statusHistory.first.changedAt);

  @override
  Future<Artwork?> get(String id) => mockDelay(() {
    final all = _readAll();
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  });

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) => mockDelay(() {
    final wanted = ids.toSet();
    return _readAll().where((a) => wanted.contains(a.id)).toList();
  });

  @override
  Future<List<Artwork>> listByArtist(String artistId) => mockDelay(
    () => _readAll().where((a) => a.artistId == artistId && isPubliclyListed(a)).toList(),
  );

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

  @override
  Future<List<ArtistCard>> listArtistCards() => mockDelay(() {
    final live = _readAll().where(isPubliclyListed).toList();
    return [
      for (final profile in seedArtists())
        if (live.any((a) => a.artistId == profile.id))
          ArtistCard(
            profile: profile,
            artworkCount: live.where((a) => a.artistId == profile.id).length,
            coverImageUrl: live.firstWhere((a) => a.artistId == profile.id).thumbnailUrl,
          ),
    ];
  });
}
