import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/format.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/marketplace.dart';
import 'package:gallery_zone/data/repositories/artwork_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:gallery_zone/features/marketplace/screens/marketplace_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artwork _artwork({
  String id = 'aw-1',
  String title = 'Monsoon, Madurai',
  double price = 48000,
  ArtworkStatus status = ArtworkStatus.marketplace,
}) {
  return Artwork(
    id: id,
    title: title,
    artistId: 'ar-1',
    artistName: 'Ananya Rao',
    verifiedArtist: true,
    category: 'painting',
    medium: 'Oil on canvas',
    customerPrice: price,
    thumbnailUrl: '/artworks/bird.png',
    insured: true,
    status: status,
    listingType: ListingType.marketplaceOnly,
    description: 'A study in rain light.',
    images: const [],
    coaCertificateNumber: 'GZ-COA-0001',
    coaIssueDate: '2025-03-04',
    socialProofLinks: const [],
    statusHistory: const [],
  );
}

/// Returns whatever it is given, and records the filters it was called with
/// so the screen's filter plumbing can be asserted on.
class _FakeArtworkRepository implements ArtworkRepository {
  _FakeArtworkRepository(this.artworks);

  final List<Artwork> artworks;
  final calls = <ArtworkFilters>[];

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) async {
    calls.add(filters);
    return MarketplacePage(
      artworks: artworks,
      total: artworks.length,
      page: filters.page,
      pageSize: marketplacePageSize,
    );
  }

  @override
  Future<Artwork?> get(String id) async =>
      artworks.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) async =>
      artworks.where((a) => ids.contains(a.id)).toList();

  @override
  Future<List<ArtistCard>> listArtistCards() async => const [];

  @override
  Future<List<Artwork>> listByArtist(String artistId) async =>
      artworks.where((a) => a.artistId == artistId).toList();

  @override
  Future<ArtistProfile?> getArtistProfile(String id) async => null;

  @override
  Future<List<ArtistProfile>> listArtists() async => const [];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('formatting matches the web', () {
    test('INR uses lakh grouping and no paise', () {
      expect(formatInr(48000), '₹48,000');
      expect(formatInr(150000), '₹1,50,000');
    });

    test('dates', () {
      expect(formatLongDate('2025-03-04'), '4 March 2025');
      expect(formatShortDate('2025-03-04'), '4 Mar 2025');
    });

    test('titleCase', () {
      expect(titleCase('mixed media'), 'Mixed Media');
    });
  });

  group('ArtworkFilters', () {
    test('copyWith clears a field when passed null, keeps it when omitted', () {
      const filters = ArtworkFilters(location: 'Pune', sortBy: ArtworkSortBy.newest);
      expect(filters.copyWith(query: 'rain').location, 'Pune');
      expect(filters.copyWith(location: null).location, isNull);
      expect(filters.copyWith(location: null).sortBy, ArtworkSortBy.newest);
    });

    test('category and medium are multi-select; clearing is an empty list', () {
      const filters = ArtworkFilters(categories: ['painting', 'sculpture'], mediums: ['oil']);
      expect(filters.copyWith(query: 'rain').categories, ['painting', 'sculpture']);
      expect(filters.copyWith(categories: const []).categories, isEmpty);
      expect(filters.activeCount, 3);
      expect(const ArtworkFilters(sortBy: ArtworkSortBy.priceAsc).isNarrowed, isFalse);
    });

    test('any change to what is asked for starts again from page 1', () {
      const filters = ArtworkFilters(page: 3);
      expect(filters.copyWith(page: 4).page, 4);
      expect(filters.copyWith(query: 'rain').page, 1);
    });

    test('value equality — the family key would refetch on every rebuild without it', () {
      expect(
        const ArtworkFilters(categories: ['painting']),
        const ArtworkFilters(categories: ['painting']),
      );
      expect(
        const ArtworkFilters(categories: ['painting']),
        isNot(const ArtworkFilters(categories: ['sculpture'])),
      );
      expect(const ArtworkFilters(page: 2), isNot(const ArtworkFilters()));
    });
  });

  test('wishlist toggles and persists under the web\'s gz-wishlist key', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final wishlist = container.read(wishlistProvider.notifier);
    expect(container.read(wishlistProvider), isEmpty);

    wishlist.toggle('aw-1');
    expect(container.read(wishlistProvider), {'aw-1'});

    wishlist.toggle('aw-1');
    expect(container.read(wishlistProvider), isEmpty);

    // Survives a fresh container — it went through MockDb, not just memory.
    wishlist.toggle('aw-2');
    final reread = ProviderContainer();
    addTearDown(reread.dispose);
    expect(reread.read(wishlistProvider), {'aw-2'});
  });

  testWidgets('marketplace renders a card per artwork and its result count',
      (tester) async {
    final repository = _FakeArtworkRepository([
      _artwork(),
      _artwork(id: 'aw-2', title: 'Backwater Light', price: 92000),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [artworkRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.dark, home: const MarketplaceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 artworks'), findsOneWidget);
    expect(find.text('Monsoon, Madurai'), findsOneWidget);
    expect(find.text('₹92,000'), findsOneWidget);
    // The initial fetch uses the default filters, not an empty object.
    expect(repository.calls.first.sortBy, ArtworkSortBy.newest);
  });

  testWidgets('empty results offer a way back out', (tester) async {
    final repository = _FakeArtworkRepository([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [artworkRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.dark, home: const MarketplaceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No artworks match these filters'), findsOneWidget);
    expect(find.text('Clear all filters'), findsOneWidget);
  });
}
