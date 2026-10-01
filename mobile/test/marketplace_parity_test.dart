import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/marketplace.dart';
import 'package:gallery_zone/data/repositories/artwork_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/marketplace/filter_options.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:gallery_zone/features/marketplace/screens/marketplace_screen.dart';
import 'package:gallery_zone/features/marketplace/widgets/artwork_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artwork _artwork(
  int n, {
  String category = 'painting',
  ArtworkRarity? rank = ArtworkRarity.original,
  ArtworkStatus status = ArtworkStatus.marketplace,
  double price = 48000,
  bool insured = true,
  String medium = 'oil-on-canvas',
  ArtworkSizeBand? size = ArtworkSizeBand.medium,
}) {
  return Artwork(
    id: 'aw-$n',
    title: 'Piece $n',
    artistId: 'ar-${n % 2}',
    artistName: 'Ananya Rao',
    verifiedArtist: true,
    category: category,
    medium: medium,
    customerPrice: price,
    thumbnailUrl: '',
    insured: insured,
    status: status,
    listingType: ListingType.marketplaceOnly,
    description: 'A study in rain light.',
    dimensions: '24 x 36 in',
    yearCreated: 2021,
    images: const [],
    socialProofLinks: const [],
    statusHistory: const [],
    rarityType: rank,
    sizeBand: size,
    artistLocation: 'Pune',
  );
}

const _facets = MarketplaceFacets(
  categories: ['painting', 'sculpture'],
  mediums: ['oil-on-canvas'],
  locations: ['Pune'],
  artists: [FacetArtist(id: 'ar-0', name: 'Ananya Rao')],
  rarityCounts: {ArtworkRarity.original: 3, ArtworkRarity.rare: 1},
);

/// Serves pages the way the API does and records what it was asked.
class _Catalog implements ArtworkRepository {
  _Catalog(this.artworks);

  final List<Artwork> artworks;
  final facets = _facets;
  final calls = <ArtworkFilters>[];

  /// Pages that fail the next time they are asked for.
  final failPages = <int>{};
  var failFirstPageOnce = false;

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) async {
    calls.add(filters);
    if (failFirstPageOnce && filters.page == 1 && filters.pageSize == marketplacePageSize) {
      failFirstPageOnce = false;
      throw Exception('offline');
    }
    if (failPages.remove(filters.page)) throw Exception('offline');
    var matching = artworks;
    if (filters.categories.isNotEmpty) {
      matching = [for (final a in matching) if (filters.categories.contains(a.category)) a];
    }
    final start = (filters.page - 1) * filters.pageSize;
    return MarketplacePage(
      artworks: matching.skip(start).take(filters.pageSize).toList(),
      total: matching.length,
      page: filters.page,
      pageSize: filters.pageSize,
      facets: facets,
    );
  }

  @override
  Future<Artwork?> get(String id) async => artworks.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) async => [
        for (final a in artworks) if (ids.contains(a.id)) a,
      ];

  @override
  Future<List<ArtistCard>> listArtistCards() async => const [];

  @override
  Future<List<Artwork>> listByArtist(String artistId) async => const [];

  @override
  Future<ArtistProfile?> getArtistProfile(String id) async => null;

  @override
  Future<List<ArtistProfile>> listArtists() async => const [];
}

Widget _app(_Catalog catalog, {Widget? home}) => ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [artworkRepositoryProvider.overrideWithValue(catalog)],
      child: MaterialApp(theme: AppTheme.light, home: home ?? const MarketplaceScreen()),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('filter options', () {
    test('a price band reads the way the website words it', () {
      expect(const PriceBand(max: 10000).label, 'Under ₹10,000');
      expect(const PriceBand(min: 10000, max: 25000).label, '₹10,000 – ₹25,000');
      expect(const PriceBand(min: 100000).label, 'Above ₹1,00,000');
    });

    test('a price sits in the band that starts at it, not the one that ends at it', () {
      expect(priceBands[0].contains(9999), isTrue);
      expect(priceBands[0].contains(10000), isFalse);
      expect(priceBands[1].contains(10000), isTrue);
      expect(priceBands.last.contains(5000000), isTrue);
    });

    test('options are counted from the overview while the whole marketplace fits on it', () {
      final counts = FilterCounts.from(
        MarketplacePage(
          artworks: [
            _artwork(1, price: 9000),
            _artwork(2, category: 'sculpture', price: 12000, size: ArtworkSizeBand.large),
            _artwork(3, price: 12000),
          ],
          total: 3,
          page: 1,
          pageSize: 60,
        ),
      )!;
      expect(counts.category, {'painting': 2, 'sculpture': 1});
      expect(counts.size, {ArtworkSizeBand.medium: 2, ArtworkSizeBand.large: 1});
      expect(counts.artist, {'ar-1': 2, 'ar-0': 1});
      expect(counts.location, {'Pune': 3});
      expect(counts.price, [1, 2, 0, 0, 0]);
    });

    test('counts would be wrong, not just incomplete, once the marketplace outgrows the page', () {
      final counts = FilterCounts.from(
        MarketplacePage(artworks: [_artwork(1)], total: 61, page: 1, pageSize: 60),
      );
      expect(counts, isNull);
    });
  });

  group('the feed', () {
    test('scrolling appends the next page, then stops when there is no more', () async {
      final catalog = _Catalog([for (var i = 0; i < 45; i++) _artwork(i)]);
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [artworkRepositoryProvider.overrideWithValue(catalog)],
      );
      addTearDown(container.dispose);
      const filters = ArtworkFilters();
      final subscription = container.listen(marketplaceFeedProvider(filters), (_, _) {});
      addTearDown(subscription.close);
      final notifier = container.read(marketplaceFeedProvider(filters).notifier);

      var feed = await container.read(marketplaceFeedProvider(filters).future);
      expect(feed.artworks, hasLength(20));
      expect(feed.total, 45);
      expect(feed.hasMore, isTrue);

      await notifier.loadMore();
      feed = container.read(marketplaceFeedProvider(filters)).requireValue;
      expect(feed.artworks, hasLength(40));
      expect(catalog.calls.last.page, 2);

      await notifier.loadMore();
      feed = container.read(marketplaceFeedProvider(filters)).requireValue;
      expect(feed.artworks, hasLength(45));
      expect(feed.hasMore, isFalse);

      await notifier.loadMore();
      expect(catalog.calls, hasLength(3), reason: 'nothing left to ask for');
    });

    test('a page that fails leaves the list alone and can be asked for again', () async {
      final catalog = _Catalog([for (var i = 0; i < 30; i++) _artwork(i)])..failPages.add(2);
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [artworkRepositoryProvider.overrideWithValue(catalog)],
      );
      addTearDown(container.dispose);
      const filters = ArtworkFilters();
      final subscription = container.listen(marketplaceFeedProvider(filters), (_, _) {});
      addTearDown(subscription.close);
      await container.read(marketplaceFeedProvider(filters).future);
      final notifier = container.read(marketplaceFeedProvider(filters).notifier);

      await notifier.loadMore();
      var feed = container.read(marketplaceFeedProvider(filters)).requireValue;
      expect(feed.artworks, hasLength(20));
      expect(feed.loadMoreFailed, isTrue);
      expect(feed.loadingMore, isFalse);

      await notifier.loadMore();
      feed = container.read(marketplaceFeedProvider(filters)).requireValue;
      expect(feed.artworks, hasLength(30));
      expect(feed.loadMoreFailed, isFalse);
    });

    test('a piece pushed onto the next page by a new listing is not shown twice', () {
      final first = MarketplaceFeed.first(
        MarketplacePage(artworks: [_artwork(1), _artwork(2)], total: 4, page: 1, pageSize: 2),
      );
      final next = first.append(
        MarketplacePage(artworks: [_artwork(2), _artwork(3)], total: 4, page: 2, pageSize: 2),
      );
      expect([for (final a in next.artworks) a.id], ['aw-1', 'aw-2', 'aw-3']);
    });

    test('an empty page ends the list instead of asking for the next forever', () {
      final first = MarketplaceFeed.first(
        MarketplacePage(artworks: [_artwork(1)], total: 99, page: 1, pageSize: 1),
      );
      final next = first.append(const MarketplacePage(artworks: [], total: 99, page: 2, pageSize: 1));
      expect(next.hasMore, isFalse);
    });
  });

  group('the card', () {
    Future<void> pumpCard(WidgetTester tester, Artwork artwork) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(child: ArtworkCard(artwork: artwork, width: 200)),
            ),
          ),
        ),
      );
    }

    testWidgets('shows rank, medium and year, size, price, and Insured - and a way to buy', (tester) async {
      await pumpCard(tester, _artwork(1));
      expect(find.text('O'), findsOneWidget, reason: 'the rank stamp');
      expect(find.text('Oil on canvas, 2021'), findsOneWidget);
      expect(find.text('24 × 36 in'), findsOneWidget);
      expect(find.text('₹48,000'), findsOneWidget);
      expect(find.text('Insured'), findsOneWidget);
      expect(find.byTooltip('Buy Piece 1'), findsOneWidget);
      expect(find.text('Image coming soon'), findsOneWidget, reason: 'no photo is not a stock photo');
    });

    testWidgets('a reserved piece says so beside the price and cannot be bought', (tester) async {
      await pumpCard(tester, _artwork(1, status: ArtworkStatus.reserved, insured: false));
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Insured'), findsNothing);
      expect(find.byTooltip('Buy Piece 1'), findsNothing);
    });

    testWidgets('an unranked piece carries no stamp; any other off-market status reads Unavailable', (tester) async {
      await pumpCard(tester, _artwork(1, rank: null, status: ArtworkStatus.withAggregator));
      expect(find.text('Unavailable'), findsOneWidget);
      for (final letter in ['R', 'U', 'O', 'S']) {
        expect(find.text(letter), findsNothing);
      }
    });

    test('the grid gives a card the height its text needs, wider screens included', () {
      const phone = ArtworkGridDelegate();
      final layout = phone.getLayout(
        SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: 800,
          crossAxisExtent: 358,
          crossAxisDirection: AxisDirection.right,
          viewportMainAxisExtent: 800,
          remainingCacheExtent: 800,
          cacheOrigin: 0,
        ),
      ) as SliverGridRegularTileLayout;
      expect(layout.crossAxisCount, 2);
      expect(layout.childCrossAxisExtent, 171);
      expect(layout.childMainAxisExtent, 171 * 1.25 + ArtworkGridDelegate.textHeight);
      expect(const ArtworkGridDelegate(textScale: 1.5).shouldRelayout(phone), isTrue);
    });
  });

  group('the marketplace screen', () {
    testWidgets('opens on the hero, the count and the first page, with the rank guide below', (tester) async {
      _phone(tester);
      final catalog = _Catalog([for (var i = 0; i < 6; i++) _artwork(i)]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      expect(find.text('Discover original art from independent artists'), findsOneWidget);
      expect(find.text('6 artworks'), findsOneWidget);
      expect(find.text('Piece 0'), findsOneWidget);
      expect(find.textContaining('certificate'), findsNothing, reason: 'the marketplace carries no certificate');

      await tester.scrollUntilVisible(find.text('Every painting has a rank'), 600, scrollable: find.byType(Scrollable).first);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('None yet'), findsWidgets, reason: 'a rank with no works is still part of the guide');
    });

    testWidgets('a category pill filters, and tapping it again clears it', (tester) async {
      _phone(tester);
      final catalog = _Catalog([
        _artwork(1),
        _artwork(2, category: 'sculpture'),
      ]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Sculpture').first);
      await tester.pumpAndSettle();
      expect(catalog.calls.last.categories, ['sculpture']);
      expect(find.text('1 artwork'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Sculpture'), findsOneWidget, reason: 'an active filter chip');

      await tester.tap(find.widgetWithText(InkWell, 'Sculpture').first);
      await tester.pumpAndSettle();
      expect(catalog.calls.last.categories, isEmpty);
    });

    testWidgets('the filter sheet ticks options live, and reset puts the marketplace back', (tester) async {
      _phone(tester);
      final catalog = _Catalog([
        _artwork(1),
        _artwork(2, category: 'sculpture'),
        _artwork(3, rank: ArtworkRarity.rare),
      ]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Rank'), findsOneWidget);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Painting'));
      await tester.pumpAndSettle();
      expect(catalog.calls.last.categories, ['painting']);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Sculpture'));
      await tester.pumpAndSettle();
      expect(catalog.calls.last.categories, ['painting', 'sculpture'], reason: 'category is multi-select');

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(catalog.calls.last.categories, isEmpty);

      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();
      expect(find.text('Show results'), findsNothing, reason: 'the sheet closes');
    });

    testWidgets('sorting from the toolbar re-asks the server', (tester) async {
      _phone(tester);
      final catalog = _Catalog([_artwork(1), _artwork(2)]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High to Low').last);
      await tester.pumpAndSettle();
      expect(catalog.calls.last.sortBy, ArtworkSortBy.priceDesc);
    });

    testWidgets('scrolling to the end loads the next page', (tester) async {
      _phone(tester);
      final catalog = _Catalog([for (var i = 0; i < 45; i++) _artwork(i)]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();
      expect(catalog.calls.where((c) => c.page == 2), isEmpty);

      await tester.fling(find.byType(CustomScrollView), const Offset(0, -4000), 4000);
      await tester.pumpAndSettle();
      expect(catalog.calls.where((c) => c.page == 2), isNotEmpty);
    });

    testWidgets('a failed load says so and a tap tries again', (tester) async {
      _phone(tester);
      final catalog = _Catalog([_artwork(1)])..failFirstPageOnce = true;
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      expect(find.text("The marketplace didn't load"), findsOneWidget);
      await tester.ensureVisible(find.text('Try again'));
      await tester.pump();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text("The marketplace didn't load"), findsNothing);
      expect(find.text('Piece 1'), findsOneWidget);
    });

    testWidgets('with nothing to show, one tap clears every filter', (tester) async {
      _phone(tester);
      final catalog = _Catalog([_artwork(1)]);
      await tester.pumpWidget(_app(catalog, home: const MarketplaceScreen(initialCategory: 'sculpture')));
      await tester.pumpAndSettle();

      expect(find.text('No artworks match these filters'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear all filters'));
      await tester.pump();
      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();
      expect(find.text('Piece 1'), findsOneWidget);
    });

    testWidgets('picking a rank in the guide filters to it', (tester) async {
      _phone(tester);
      final catalog = _Catalog([_artwork(1), _artwork(2, rank: ArtworkRarity.rare)]);
      await tester.pumpWidget(_app(catalog));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Every painting has a rank'), 600, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.widgetWithText(InkWell, 'Original').last);
      await tester.pump();
      await tester.tap(find.widgetWithText(InkWell, 'Original').last);
      await tester.pumpAndSettle();
      expect(catalog.calls.last.rarity, ArtworkRarity.original);
    });
  });
}
