import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/artist_score.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/artist_network.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/repositories/artist_network_repository.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/artist/analytics.dart';
import 'package:gallery_zone/features/artist/providers/artist_network_providers.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/artist_analytics_screen.dart';
import 'package:gallery_zone/features/artist/widgets/rating_widgets.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/catalog_fixtures.dart';

ArtistProfileDetails _profile({
  String bio = '',
  String instagram = '',
  String website = '',
  String bank = '',
  String ifsc = '',
  String? pan,
  String? gstin,
  String line1 = '',
  String pincode = '',
  ReviewStatus aadhaar = ReviewStatus.approved,
}) =>
    ArtistProfileDetails(
      fullName: 'Ananya Rao',
      email: 'a@b.co',
      phone: '9000000000',
      bio: bio,
      instagram: instagram,
      website: website,
      bankAccountMasked: bank,
      ifsc: ifsc,
      aadhaarStatus: aadhaar,
      aadhaarMasked: '',
      pan: pan,
      gstin: gstin,
      pickupLine1: line1,
      pickupPincode: pincode,
    );

ArtistArtwork _art(String id, ArtworkStatus status, {String category = 'painting', double price = 50000}) =>
    ArtistArtwork(artwork: fixtureArtwork(id: id, status: status, category: category, price: price), artistPrice: 40000);

WalletTransaction _settle(String date, double amount, {WalletTransactionStatus status = WalletTransactionStatus.completed}) =>
    WalletTransaction(
      id: date,
      type: WalletTransactionType.settlement,
      label: 'sale',
      amount: amount,
      date: date,
      status: status,
    );

ArtistOrder _order(String id, OrderStatus status, double payout) => ArtistOrder(
      order: _orderOf(id, status),
      artistPayout: payout,
    );

Order _orderOf(String id, OrderStatus status) => Order(
      id: id,
      artworkId: 'aw-1',
      addressId: 'ad-1',
      amount: 50000,
      gstAmount: 2381,
      deliveryCharge: 0,
      status: status,
      createdAt: '2026-09-01T00:00:00.000Z',
      statusHistory: const [],
    );

class _Artist implements ArtistRepository {
  _Artist({this.artworks = const [], this.orders = const [], this.transactions = const [], ArtistProfileDetails? profile})
      : profile = profile ?? _profile(instagram: 'ananya.art');

  final List<ArtistArtwork> artworks;
  final List<ArtistOrder> orders;
  final List<WalletTransaction> transactions;
  ArtistProfileDetails profile;

  @override
  Future<List<ArtistArtwork>> listArtworks() async => artworks;

  @override
  Future<List<ArtistOrder>> listOrders() async => orders;

  @override
  Future<List<WalletTransaction>> listWalletTransactions() async => transactions;

  @override
  Future<ArtistProfileDetails> getProfile() async => profile;

  @override
  Future<ArtistProfileDetails> updateProfile(ArtistProfileDetails next) async => profile = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Network implements ArtistNetworkRepository {
  _Network([this.rating]);

  final ArtistRating? rating;

  @override
  Future<ArtistRating> getRating(String artistId) async =>
      rating ?? ArtistRating(artistId: artistId, average: 0, count: 0, breakdown: const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _show(WidgetTester tester, Widget screen, _Artist artist, {_Network? network}) async {
  tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artistRepositoryProvider.overrideWithValue(artist),
        artistNetworkRepositoryProvider.overrideWithValue(network ?? _Network()),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('the composite score', () {
    test('weights ratings most, then the profile, then how much has been posted', () {
      expect(ratingScoreWeights, (customerRating: 0.65, profileCompletion: 0.25, artworkCount: 0.1));
      expect(scoreArtist(customerRating: 10, profileCompletion: 10, artworkCount: 10), 10);
      expect(scoreArtist(customerRating: 0, profileCompletion: 0, artworkCount: 0), 0);
      // 8 x .65 + 5 x .25 + 3 x .1 = 5.2 + 1.25 + .3 = 6.75, to one decimal
      expect(scoreArtist(customerRating: 8, profileCompletion: 5, artworkCount: 3), 6.8);
    });

    test('artworks count linearly to ten, then stop', () {
      expect(artworkCountScore(0), 0);
      expect(artworkCountScore(4), 4);
      expect(artworkCountScore(10), 10);
      expect(artworkCountScore(37), 10);
      expect(artworkCountScore(-3), 0);
    });

    test('a profile scores the share of its fields that are filled in', () {
      expect(profileCompletionScore(_profile()), 0);
      expect(
        profileCompletionScore(
          _profile(
            bio: 'Paints',
            instagram: 'a',
            website: 'w.com',
            bank: '•••• 1234',
            ifsc: 'HDFC0001234',
            pan: 'ABCDE1234F',
            gstin: '22AAAAA0000A1Z5',
            line1: '14 Road',
            pincode: '411001',
          ),
        ),
        9,
        reason: 'nine of ten - the website checks Aadhaar against "verified", which the API never sends',
      );
      expect(profileCompletionScore(_profile(bio: '  ', instagram: 'a')), 1, reason: 'blank space is not a field');
    });
  });

  group('the numbers on the analytics page', () {
    test('revenue is the last six months of settled earnings, with the empty months at zero', () {
      final series = revenueSeries(
        [
          _settle('2026-10-02T09:00:00.000', 38000),
          _settle('2026-10-20T09:00:00.000', 2000),
          _settle('2026-08-15T09:00:00.000', 12000),
          _settle('2026-04-01T09:00:00.000', 99999, status: WalletTransactionStatus.pending),
          _settle('2025-12-01T09:00:00.000', 77777),
          const WalletTransaction(
            id: 'w',
            type: WalletTransactionType.withdrawal,
            label: 'out',
            amount: -5000,
            date: '2026-10-05T09:00:00.000',
            status: WalletTransactionStatus.completed,
          ),
          _settle('2026-10-06T09:00:00.000', -100),
        ],
        now: DateTime(2026, 10, 2),
      );
      expect(series.map((p) => p.month), ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']);
      expect(series.map((p) => p.amount), [0, 0, 0, 12000, 0, 40000]);
    });

    test('the window rolls over a year boundary', () {
      final series = revenueSeries([_settle('2026-01-10T09:00:00.000', 500)], now: DateTime(2026, 2, 3), months: 3);
      expect(series.map((p) => p.month), ['Dec', 'Jan', 'Feb']);
      expect(series.map((p) => p.amount), [0, 500, 0]);
    });

    test('categories are ranked by what they earned, and a category with no sale is left out', () {
      final rows = categoryPerformance([
        _art('1', ArtworkStatus.sold, category: 'painting', price: 50000),
        _art('2', ArtworkStatus.delivered, category: 'painting', price: 30000),
        _art('3', ArtworkStatus.settlementComplete, category: 'sculpture', price: 120000),
        _art('4', ArtworkStatus.marketplace, category: 'textile', price: 99999),
        _art('5', ArtworkStatus.draft, category: 'ceramics'),
      ]);
      expect(rows, [
        (category: 'sculpture', revenue: 120000.0, orders: 1),
        (category: 'painting', revenue: 80000.0, orders: 2),
      ]);
    });

    test('the pipeline files a returned piece nowhere rather than calling it live', () {
      final funnel = artworkFunnel([
        _art('1', ArtworkStatus.draft),
        _art('2', ArtworkStatus.draft),
        _art('3', ArtworkStatus.pendingApproval),
        _art('4', ArtworkStatus.marketplace),
        _art('5', ArtworkStatus.withAggregator),
        _art('6', ArtworkStatus.reserved),
        _art('7', ArtworkStatus.sold),
        _art('8', ArtworkStatus.completed),
        _art('9', ArtworkStatus.returned),
        _art('10', ArtworkStatus.soldExternally),
      ]);
      expect(funnel, [
        (stage: 'Draft', count: 2),
        (stage: 'Pending Approval', count: 1),
        (stage: 'Live', count: 3),
        (stage: 'Sold', count: 2),
      ]);
    });

    test('a sale is a paid order, and the revenue is what the artist took home', () {
      final summary = analyticsSummary(
        artworks: [_art('1', ArtworkStatus.sold), _art('2', ArtworkStatus.draft)],
        orders: [
          _order('a', OrderStatus.delivered, 38001),
          _order('b', OrderStatus.paid, 22000),
          _order('c', OrderStatus.pending, 99999),
          _order('d', OrderStatus.cancelled, 99999),
        ],
      );
      expect(summary, (artworks: 2, sales: 2, revenue: 60001.0, averageSale: 30001.0));
      expect(analyticsSummary(artworks: const [], orders: const []), (artworks: 0, sales: 0, revenue: 0.0, averageSale: 0.0));
    });

    test('figures shorten the way the website\'s charts shorten them', () {
      expect(formatCompactInr(0), '₹0');
      expect(formatCompactInr(950), '₹950');
      expect(formatCompactInr(1000), '₹1k');
      expect(formatCompactInr(45500), '₹45.5k');
      expect(formatCompactInr(120000), '₹1.2L');
      expect(formatCompactInr(250000), '₹2.5L');
      expect(formatCompactInr(30000000), '₹3Cr');
      expect(formatCompactInr(-45000), '-₹45k');
      expect(formatCompactCount(7), '7');
      expect(formatCompactCount(1500), '1.5k');
    });
  });

  group('the analytics page', () {
    testWidgets('shows the headline numbers, the handle, and one chart for each question', (tester) async {
      await _show(
        tester,
        const ArtistAnalyticsScreen(),
        _Artist(
          artworks: [
            _art('1', ArtworkStatus.sold, category: 'painting', price: 50000),
            _art('2', ArtworkStatus.marketplace),
            _art('3', ArtworkStatus.draft),
          ],
          orders: [_order('a', OrderStatus.delivered, 38000)],
          transactions: [_settle(DateTime.now().toIso8601String(), 38000)],
        ),
      );
      expect(find.text('TOTAL ARTWORKS'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('TOTAL SALES'), findsOneWidget);
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('₹38,000'), findsWidgets);
      expect(find.text('AVG. SALE PRICE'), findsOneWidget);

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('@ananya.art'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);

      expect(find.text('Revenue trend'), findsOneWidget);
      expect(find.text('Revenue by category'), findsOneWidget);
      expect(find.text('Painting'), findsOneWidget);
      expect(find.text('₹50k'), findsOneWidget);
      expect(find.text('Artwork status'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
    });

    testWidgets('with no sales it says so rather than drawing flat lines', (tester) async {
      await _show(tester, const ArtistAnalyticsScreen(), _Artist(artworks: [_art('1', ArtworkStatus.draft)]));
      expect(find.text('No revenue yet'), findsOneWidget);
      expect(find.text('Settled sales will show up here.'), findsOneWidget);
      expect(find.text('No category revenue yet'), findsOneWidget);
      expect(find.text('No artworks submitted yet'), findsNothing, reason: 'there is a draft in the pipeline');
    });

    testWidgets('the Instagram handle can be connected and updated from here, and it is the profile\'s handle', (tester) async {
      final artist = _Artist(profile: _profile());
      await _show(tester, const ArtistAnalyticsScreen(), artist);
      expect(find.text('Not connected'), findsOneWidget);

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Instagram handle'), '  ananya.art ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(artist.profile.instagram, 'ananya.art');
      expect(find.text('@ananya.art'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('an empty handle is not saved', (tester) async {
      final artist = _Artist(profile: _profile(instagram: 'old'));
      await _show(tester, const ArtistAnalyticsScreen(), artist);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Instagram handle'), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(artist.profile.instagram, 'old');
    });
  });

  group('the rating card', () {
    testWidgets('is the composite out of ten, built from the three factors', (tester) async {
      await _show(
        tester,
        const RatingCard(),
        _Artist(
          artworks: [for (var i = 0; i < 4; i++) _art('$i', ArtworkStatus.marketplace)],
          profile: _profile(bio: 'x', instagram: 'a', website: 'w', bank: 'b', ifsc: 'i'),
        ),
      );
      // profile 5/10 filled -> 5.0; four artworks -> 4.0; no ratings -> 0
      // 0 x .65 + 5 x .25 + 4 x .1 = 1.65 -> 1.7 (the website rounds half up)
      expect(find.text('1.7'), findsOneWidget);
      expect(find.text('out of 10'), findsOneWidget);
      expect(find.text('Customer rating'), findsOneWidget);
      expect(find.text('Profile completion'), findsOneWidget);
      expect(find.text('Artworks posted'), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.textContaining('Your first rating will show here.'), findsOneWidget);
    });

    testWidgets('counts a customer rating twice over, since it is out of five and the score is out of ten', (tester) async {
      await _show(
        tester,
        const RatingCard(),
        _Artist(artworks: const [], profile: _profile()),
        network: _Network(
          const ArtistRating(artistId: 'x', average: 4.5, count: 2, breakdown: {5: 1, 4: 1, 3: 0, 2: 0, 1: 0}),
        ),
      );
      // 9 x .65 = 5.85 -> 5.9
      expect(find.text('5.9'), findsOneWidget);
      expect(find.text('2 ratings'), findsOneWidget);
      expect(find.text('CUSTOMER RATING BREAKDOWN'), findsOneWidget);
      expect(find.textContaining('LATEST REVIEWS'), findsNothing, reason: 'came off the card at the client\'s request');
    });
  });
}
