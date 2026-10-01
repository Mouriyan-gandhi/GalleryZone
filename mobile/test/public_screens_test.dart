import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/marketplace.dart';
import 'package:gallery_zone/data/repositories/artwork_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/marketplace/artist_stats.dart';
import 'package:gallery_zone/features/marketplace/providers/marketplace_providers.dart';
import 'package:gallery_zone/features/marketplace/screens/artist_profile_screen.dart';
import 'package:gallery_zone/features/marketplace/screens/artists_directory_screen.dart';
import 'package:gallery_zone/features/marketplace/screens/artwork_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artwork _artwork({
  String id = 'aw-1',
  String medium = 'oil-on-canvas',
  double price = 48000,
  ArtworkStatus status = ArtworkStatus.marketplace,
  String thumbnail = '',
}) {
  return Artwork(
    id: id,
    title: 'Monsoon, Madurai',
    artistId: 'ar-1',
    artistName: 'Ananya Rao',
    verifiedArtist: true,
    category: 'mixed-media',
    medium: medium,
    customerPrice: price,
    thumbnailUrl: thumbnail,
    insured: true,
    status: status,
    listingType: ListingType.marketplaceOnly,
    description: 'A study in rain light.',
    dimensions: '24 x 36 in',
    yearCreated: 2021,
    images: const [],
    socialProofLinks: const [],
    statusHistory: const [],
    rarityType: ArtworkRarity.rare,
  );
}

ArtistProfile _artist({
  String id = 'ar-1',
  String headline = 'Coastal light in oils',
  String location = 'Pune, Maharashtra',
  String bio = '<p>Ananya paints the coast.</p>',
}) {
  return ArtistProfile(
    id: id,
    name: 'Ananya Rao',
    bio: bio,
    profileImageUrl: '',
    verification: const ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: false,
      tier3FirstSale: false,
    ),
    socialLinks: const [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://instagram.com/ananya'),
      SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://youtube.com/@ananya'),
    ],
    headline: headline,
    location: location,
    joinedAt: '2026-03-04T09:00:00.000Z',
  );
}

class _Catalog implements ArtworkRepository {
  _Catalog({this.artworks = const [], this.artists = const [], this.failArtists = false});

  final List<Artwork> artworks;
  final List<ArtistProfile> artists;
  bool failArtists;

  @override
  Future<MarketplacePage> list(ArtworkFilters filters) async => MarketplacePage(
        artworks: artworks,
        total: artworks.length,
        page: 1,
        pageSize: filters.pageSize,
      );

  @override
  Future<Artwork?> get(String id) async => artworks.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Artwork>> getMany(Iterable<String> ids) async => [
        for (final a in artworks) if (ids.contains(a.id)) a,
      ];

  @override
  Future<List<ArtistCard>> listArtistCards() async => const [];

  @override
  Future<List<Artwork>> listByArtist(String artistId) async =>
      [for (final a in artworks) if (a.artistId == artistId) a];

  @override
  Future<ArtistProfile?> getArtistProfile(String id) async => artists.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<ArtistProfile>> listArtists() async {
    if (failArtists) {
      failArtists = false;
      throw Exception('offline');
    }
    return artists;
  }
}

Widget _app(_Catalog catalog, Widget home) => ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artworkRepositoryProvider.overrideWithValue(catalog),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
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

  group('an artist\'s public numbers', () {
    test('are derived from what is listed, most-used medium first', () {
      final stats = ArtistPublicStats.of(_artist(), [
        _artwork(id: 'a', medium: 'oil-on-canvas', price: 30000),
        _artwork(id: 'b', medium: 'watercolour', price: 12000),
        _artwork(id: 'c', medium: 'oil-on-canvas', price: 90000),
      ]);
      expect(stats.artworksListed, 3);
      expect(stats.mediums, ['oil-on-canvas', 'watercolour']);
      expect(stats.priceLow, 12000);
      expect(stats.priceHigh, 90000);
      expect(stats.worksSold, 0, reason: 'the public API cannot tell; the website shows 0 too');
      expect(stats.joinedLabel, 'March 2026');
    });

    test('say so plainly when there is nothing to count', () {
      final stats = ArtistPublicStats.of(_artist().copyWith(joinedAt: ''), const []);
      expect(stats.priceLow, isNull);
      expect(stats.mediums, isEmpty);
      expect(stats.joinedLabel, '—');
    });
  });

  group('the artists directory', () {
    testWidgets('lists each artist with their headline, or a plain excerpt of the bio', (tester) async {
      _phone(tester);
      final catalog = _Catalog(artists: [
        _artist(),
        _artist(id: 'ar-2', headline: '', bio: '<p>Hand-built <b>ceramics</b> from Khurja.</p>'),
      ]);
      await tester.pumpWidget(_app(catalog, const ArtistsDirectoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Our Artists'), findsOneWidget);
      expect(find.text('Coastal light in oils'), findsOneWidget);
      expect(find.text('Hand-built ceramics from Khurja.'), findsOneWidget);
      expect(find.text('A'), findsWidgets, reason: 'no portrait yet shows an initial, not a stock face');
    });

    testWidgets('an empty directory explains when artists appear', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(_Catalog(), const ArtistsDirectoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('No artists listed yet'), findsOneWidget);
    });

    testWidgets('a failed load can be tried again', (tester) async {
      _phone(tester);
      final catalog = _Catalog(artists: [_artist()], failArtists: true);
      await tester.pumpWidget(_app(catalog, const ArtistsDirectoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load artists"), findsOneWidget);

      await tester.ensureVisible(find.text('Try again'));
      await tester.pump();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Coastal light in oils'), findsOneWidget);
    });
  });

  group('an artist\'s profile', () {
    testWidgets('opens with what they make and where, then the numbers - and never their Instagram', (tester) async {
      _phone(tester);
      final catalog = _Catalog(artists: [_artist()], artworks: [_artwork()]);
      await tester.pumpWidget(_app(catalog, const ArtistProfileScreen(artistId: 'ar-1')));
      await tester.pumpAndSettle();

      expect(find.text('Coastal light in oils'), findsOneWidget);
      expect(find.text('Pune, Maharashtra'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Instagram'), findsNothing, reason: 'collected for verification, never shown publicly');

      await tester.scrollUntilVisible(find.text('Works listed'), 300);
      await tester.pumpAndSettle(); // the rating read has its own mock delay
      expect(find.text('Works listed'), findsOneWidget);
      expect(find.text('₹48,000'), findsWidgets);
      expect(find.text('Listed price, GST included'), findsOneWidget);
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('Oil on canvas'), findsWidgets, reason: 'mediums are written as words, not slugs');
    });
  });

  group('the artwork page', () {
    testWidgets('puts buying beside the price and carries no certificate', (tester) async {
      _phone(tester);
      final catalog = _Catalog(artworks: [_artwork()], artists: [_artist()]);
      await tester.pumpWidget(_app(catalog, const ArtworkDetailScreen(artworkId: 'aw-1')));
      await tester.pumpAndSettle();

      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('incl. GST'), findsOneWidget);
      expect(find.text('Insured'), findsOneWidget);
      await tester.scrollUntilVisible(find.text("View this artwork's digital passport"), 300);
      expect(find.textContaining('Certificate'), findsNothing);
      expect(find.textContaining('Authenticity'), findsNothing);
      // Spec rows read as words, with the proper multiplication sign.
      expect(find.text('Mixed media'), findsOneWidget);
      expect(find.text('Oil on canvas'), findsOneWidget);
      expect(find.text('24 × 36 in'), findsOneWidget);
      expect(find.text('Image coming soon'), findsOneWidget);
    });

    testWidgets('a reserved piece cannot be bought', (tester) async {
      _phone(tester);
      final catalog = _Catalog(artworks: [_artwork(status: ArtworkStatus.reserved)], artists: [_artist()]);
      await tester.pumpWidget(_app(catalog, const ArtworkDetailScreen(artworkId: 'aw-1')));
      await tester.pumpAndSettle();

      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Buy Now'), findsNothing);
    });
  });
}
