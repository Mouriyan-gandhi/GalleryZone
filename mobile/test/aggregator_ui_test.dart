import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gallery_zone/core/format.dart';
import 'package:gallery_zone/core/pricing.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart' show WalletSummary;
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';
import 'package:gallery_zone/features/auth/providers/auth_providers.dart';
import 'package:gallery_zone/features/aggregator/providers/aggregator_providers.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_collection_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_holding_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_inventory_screen.dart';
import 'package:gallery_zone/features/aggregator/screens/aggregator_reserve_screen.dart';
import 'package:gallery_zone/features/aggregator/widgets/aggregator_widgets.dart';

import 'support/catalog_fixtures.dart';

// --- Fixtures --------------------------------------------------------------------

AggregatorProfile _profile({ReviewStatus gst = ReviewStatus.approved, bool mou = true}) => AggregatorProfile(
      companyName: 'Verandah Art House',
      contactPerson: 'Meher Chatterjee',
      avatar: '',
      gstNumber: '29ABCDE1234F1Z5',
      phone: '+91 98450 12345',
      addressLine1: '14 Church Street',
      bankAccountMasked: '',
      ifsc: '',
      securityDepositStatus: 'active',
      gstStatus: gst,
      mouAcceptance: mou
          ? const MouAcceptance(version: '2026.2', acceptedAt: '2026-09-01T00:00:00.000Z', signatureName: 'Meher Chatterjee')
          : null,
    );

/// GalleryZone's month-1 terms for a 1,00,000 artist price.
AggregatorOffer _offer1() => const AggregatorOffer(
      artworkId: 'aw-1',
      month: 1,
      offerPrice: 136500,
      marketplacePrice: 136500,
      advance: 6500,
      advanceRate: 0.05,
      advanceBase: 130000,
      advanceBasis: AdvanceBasis.sellingPrice,
      canSetPrice: true,
      daysLeftInListing: 180,
      deliveryCharge: 2500,
      payable: 9000,
      sellingPrice: 130000,
      standardPrice: 136500,
      monthlyReduction: 0,
      priceWarnFrom: 260000,
    );

/// Month 3: GalleryZone's price, 3% of the artist price, nothing to set.
AggregatorOffer _offer3(String artworkId) => AggregatorOffer(
      artworkId: artworkId,
      month: 3,
      offerPrice: 132300,
      marketplacePrice: 136500,
      advance: 3000,
      advanceRate: 0.03,
      advanceBase: 100000,
      advanceBasis: AdvanceBasis.artistPrice,
      canSetPrice: false,
      daysLeftInListing: 120,
      deliveryCharge: 2500,
      payable: 5500,
      sellingPrice: 126000,
      standardPrice: 136500,
      monthlyReduction: 4200,
    );

ReservableArtwork _piece(String id, String title, {String category = 'painting', double price = 136500, AggregatorOffer? offer}) =>
    ReservableArtwork(
      artwork: fixtureArtwork(id: id, title: title, category: category, price: price),
      offer: offer ?? _offer1().copyWithId(id),
    );

extension on AggregatorOffer {
  AggregatorOffer copyWithId(String id) => AggregatorOffer(
        artworkId: id,
        month: month,
        offerPrice: offerPrice,
        marketplacePrice: marketplacePrice,
        advance: advance,
        advanceRate: advanceRate,
        advanceBase: advanceBase,
        advanceBasis: advanceBasis,
        canSetPrice: canSetPrice,
        daysLeftInListing: this.daysLeftInListing,
        deliveryCharge: deliveryCharge,
        payable: payable,
        sellingPrice: sellingPrice,
        standardPrice: standardPrice,
        monthlyReduction: monthlyReduction,
        priceWarnFrom: priceWarnFrom,
      );
}

AggregatorHolding _holding(
  String id, {
  String artworkId = 'aw-h1',
  HoldingStatus status = HoldingStatus.reserved,
  int month = 1,
  Duration? expiresIn,
  HoldingExtensionRequest? request,
  bool windowExtended = false,
  double price = 136500,
}) =>
    AggregatorHolding(
      id: id,
      artworkId: artworkId,
      advancePercent: month <= 2 ? 5 : 3,
      advanceAmount: 6500,
      displayPrice: price,
      assignedAt: '2026-09-15T00:00:00.000Z',
      expiresAt: DateTime.now().toUtc().add(expiresIn ?? const Duration(days: 20)).toIso8601String(),
      status: status,
      assignmentSource: AssignmentSource.selfReserved,
      deliveryDeposit: 2500,
      cycleMonth: month,
      extensionRequest: request,
      windowExtended: windowExtended,
    );

AggregatorHoldingView _view(AggregatorHolding holding, {String title = 'Held piece', String category = 'sculpture'}) =>
    AggregatorHoldingView(
      holding: holding,
      artwork: fixtureArtwork(id: holding.artworkId, title: title, category: category, price: 900000),
    );

AggregatorSale _saleOf(RecordSaleInput input) => AggregatorSale(
      id: 's1',
      holdingId: 'h1',
      artworkId: input.artworkId,
      soldPrice: input.soldPrice,
      buyerName: input.buyerName,
      buyerEmail: input.buyerEmail,
      buyerPhone: input.buyerPhone,
      deliveryAddress: input.deliveryAddress,
      deliveryMode: input.deliveryMode,
      soldAt: '2026-10-02T00:00:00.000Z',
      shipmentStatus: ShipmentStatus.preparing,
    );

/// An in-memory aggregator service that records what the screens ask of it.
class _Agg implements AggregatorRepository {
  _Agg({
    List<ReservableArtwork>? reservable,
    List<AggregatorHoldingView>? holdings,
    AggregatorProfile? profile,
    this.free = 50000,
  })  : reservable = reservable ?? [_piece('aw-1', 'Monsoon, Madurai')],
        holdings = holdings ?? [],
        profile = profile ?? _profile();

  List<ReservableArtwork> reservable;
  List<AggregatorHoldingView> holdings;
  AggregatorProfile profile;
  double free;

  final reserved = <({String id, double? price, bool conflict})>[];
  final sales = <RecordSaleInput>[];
  final returned = <String>[];
  final extensions = <({String id, String text})>[];
  Object? failReserveWith;
  Object? failSaleWith;
  Object? failReturnWith;

  @override
  Future<List<ReservableArtwork>> listReservableInventory() async => List.of(reservable);

  @override
  Future<AggregatorProfile> getProfile() async => profile;

  @override
  Future<WalletSummary> getWallet() async => WalletSummary(balance: free + 1000, pendingBalance: 0, lockedBalance: 1000);

  @override
  Future<List<AggregatorHoldingView>> listCollection() async => List.of(holdings);

  @override
  Future<AggregatorHoldingView?> getHolding(String holdingId) async =>
      holdings.where((v) => v.holding.id == holdingId).firstOrNull;

  @override
  Future<AggregatorHolding> reserve(String artworkId, {double? sellingPrice, bool simulateConflict = false}) async {
    reserved.add((id: artworkId, price: sellingPrice, conflict: simulateConflict));
    if (failReserveWith != null) throw failReserveWith!;
    final item = reservable.firstWhere((r) => r.artwork.id == artworkId);
    reservable = [for (final r in reservable) if (r.artwork.id != artworkId) r];
    final holding = _holding('h-new', artworkId: artworkId, price: withGst(sellingPrice ?? item.offer.sellingPrice));
    holdings = [...holdings, AggregatorHoldingView(holding: holding, artwork: item.artwork)];
    return holding;
  }

  @override
  Future<HoldingRelease> releaseHolding(String holdingId) async {
    if (failReturnWith != null) throw failReturnWith!;
    returned.add(holdingId);
    holdings = [
      for (final v in holdings)
        if (v.holding.id == holdingId)
          AggregatorHoldingView(holding: v.holding.copyWith(status: HoldingStatus.returned), artwork: v.artwork)
        else
          v,
    ];
    return const HoldingRelease(refunded: 6500, deliveryLost: 2500);
  }

  @override
  Future<AggregatorSale> recordSale(RecordSaleInput input) async {
    if (failSaleWith != null) throw failSaleWith!;
    sales.add(input);
    holdings = [
      for (final v in holdings)
        if (v.artwork.id == input.artworkId)
          AggregatorHoldingView(holding: v.holding.copyWith(status: HoldingStatus.soldPendingSettlement), artwork: v.artwork)
        else
          v,
    ];
    return _saleOf(input);
  }

  @override
  Future<AggregatorHolding> requestExtension(String holdingId, String assurance) async {
    extensions.add((id: holdingId, text: assurance));
    final view = holdings.firstWhere((v) => v.holding.id == holdingId);
    final updated = view.holding.copyWith(
      extensionRequest: HoldingExtensionRequest(
        status: ExtensionStatus.pending,
        assurance: assurance,
        requestedAt: '2026-10-02T00:00:00.000Z',
        previousExpiresAt: view.holding.expiresAt,
      ),
    );
    holdings = [for (final v in holdings) v.holding.id == holdingId ? AggregatorHoldingView(holding: updated, artwork: v.artwork) : v];
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Harness -----------------------------------------------------------------------

Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

Future<void> _show(
  WidgetTester tester,
  _Agg agg, {
  String at = AggregatorBrowseScreen.path,
  bool remote = true,
  Size size = const Size(390, 2600),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(
        path: AggregatorBrowseScreen.path,
        builder: (context, state) => const AggregatorBrowseScreen(),
        routes: [
          GoRoute(
            path: AggregatorReserveScreen.subPath,
            builder: (context, state) => AggregatorReserveScreen(artworkId: state.pathParameters['artworkId']!),
          ),
        ],
      ),
      GoRoute(
        path: AggregatorCollectionScreen.path,
        builder: (context, state) => const AggregatorCollectionScreen(),
        routes: [
          GoRoute(
            path: AggregatorHoldingScreen.subPath,
            builder: (context, state) => AggregatorHoldingScreen(holdingId: state.pathParameters['holdingId']!),
          ),
        ],
      ),
      GoRoute(path: '/aggregator/wallet', builder: (context, state) => _stub('WALLET PAGE')),
      GoRoute(path: '/aggregator/dashboard/profile', builder: (context, state) => _stub('PROFILE PAGE')),
      GoRoute(path: '/aggregator/dashboard/mou', builder: (context, state) => _stub('MOU PAGE')),
      GoRoute(path: '/aggregator/dashboard/settlements', builder: (context, state) => _stub('SETTLEMENTS PAGE')),
      GoRoute(path: '/marketplace/:id', builder: (context, state) => _stub('MARKETPLACE PAGE')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        aggregatorRepositoryProvider.overrideWithValue(agg),
        remoteBackendProvider.overrideWithValue(remote),
        initialRoleProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _priceField() => find.byType(TextField).last;

void main() {
  group('browsing', () {
    testWidgets("each piece shows GalleryZone's price and where it stands in the cycle", (tester) async {
      await _show(
        tester,
        _Agg(
          reservable: [
            _piece('aw-1', 'Monsoon, Madurai'),
            _piece('aw-3', 'Late Light', category: 'sculpture', offer: _offer3('aw-3')),
          ],
        ),
      );
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('₹1,36,500'), findsOneWidget);
      expect(find.text("GalleryZone's price, incl. GST. You can set a higher one."), findsOneWidget);
      expect(find.text('Month 1 of 5 · you set the price'), findsOneWidget);
      expect(find.text('2 artworks available'), findsOneWidget);

      expect(find.text('Late Light'), findsOneWidget);
      expect(find.text('₹1,32,300'), findsOneWidget);
      expect(find.text('Fixed this month, incl. GST'), findsOneWidget);
      expect(find.text('Month 3 of 5 · ₹4,200 off month 1'), findsOneWidget);
      expect(find.byType(CycleStepper), findsNWidgets(2));
    });

    testWidgets('search narrows the list, and a category chip does too', (tester) async {
      await _show(
        tester,
        _Agg(
          reservable: [
            _piece('aw-1', 'Monsoon, Madurai'),
            _piece('aw-2', 'Bronze Dancer', category: 'sculpture'),
          ],
        ),
      );
      await tester.enterText(find.byType(TextField).first, 'bronze');
      await tester.pumpAndSettle();
      expect(find.text('Bronze Dancer'), findsOneWidget);
      expect(find.text('Monsoon, Madurai'), findsNothing);
      expect(find.text('1 artwork available'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'painting'));
      await tester.pumpAndSettle();
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.text('Bronze Dancer'), findsNothing);
    });

    testWidgets('sorting by price reorders the list', (tester) async {
      await _show(
        tester,
        _Agg(
          reservable: [
            _piece('aw-1', 'Dear One', offer: _offer1().copyWithId('aw-1')),
            _piece('aw-3', 'Cheap One', offer: _offer3('aw-3')),
          ],
        ),
      );
      // Two to a row in the grid: reading order is top-to-bottom, then left-to-right.
      bool before(String a, String b) {
        final one = tester.getTopLeft(find.text(a));
        final two = tester.getTopLeft(find.text(b));
        return one.dy < two.dy || (one.dy == two.dy && one.dx < two.dx);
      }

      expect(before('Dear One', 'Cheap One'), isTrue, reason: "the service's own order to begin with");

      await tester.tap(find.text('Sort: Newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort: Price: Low to High').last);
      await tester.pumpAndSettle();
      expect(before('Cheap One', 'Dear One'), isTrue);
    });

    testWidgets('Reserve opens the reserve page when nothing stands in the way', (tester) async {
      await _show(tester, _Agg());
      await _tap(tester, find.text('Reserve Artwork'));
      expect(find.text('Confirm reservation'), findsOneWidget);
      expect(find.text('Your selling price, before GST (₹)'), findsOneWidget);
    });

    testWidgets('an unsigned MOU is said up front, and Reserve explains instead of going on', (tester) async {
      await _show(tester, _Agg(profile: _profile(mou: false)));
      expect(find.text('Sign your Aggregator MOU to reserve artwork.'), findsOneWidget);

      await _tap(tester, find.text('Reserve Artwork'));
      expect(find.text("You can't reserve this yet"), findsOneWidget);
      expect(find.text('Confirm reservation'), findsNothing);

      await _tap(tester, find.text('Close'));
      expect(find.text("You can't reserve this yet"), findsNothing);
    });

    testWidgets('a GST number under review says wait; a rejected one says fix it', (tester) async {
      await _show(tester, _Agg(profile: _profile(gst: ReviewStatus.submitted)));
      expect(find.text('Your GST number is being reviewed.'), findsOneWidget);
      expect(find.text('Go to My Profile'), findsNothing, reason: 'nothing to do but wait');

      await _show(tester, _Agg(profile: _profile(gst: ReviewStatus.rejected)));
      expect(find.text("Your GST number wasn't approved."), findsOneWidget);
      expect(find.text('Go to My Profile'), findsOneWidget);

      await _show(tester, _Agg(profile: _profile(gst: ReviewStatus.notSubmitted)));
      expect(find.text('Add your GST number to reserve artwork.'), findsOneWidget);
      await _tap(tester, find.text('Go to My Profile'));
      expect(find.text('PROFILE PAGE'), findsOneWidget);
    });

    testWidgets('both blockers at once are both listed in the dialog', (tester) async {
      await _show(tester, _Agg(profile: _profile(mou: false, gst: ReviewStatus.notSubmitted)));
      await _tap(tester, find.text('Reserve Artwork'));
      expect(find.text('Sign your Aggregator MOU to reserve artwork.'), findsNWidgets(2), reason: 'notice and dialog');
      expect(find.text('Add your GST number to reserve artwork.'), findsNWidgets(2));
    });

    testWidgets('with nothing to reserve it says so, and a failed load can be retried', (tester) async {
      await _show(tester, _Agg(reservable: []));
      expect(find.text('No reservable artworks right now'), findsOneWidget);
    });

    testWidgets("pieces like what you already hold are suggested", (tester) async {
      await _show(
        tester,
        _Agg(
          reservable: [
            _piece('aw-1', 'Bronze Two', category: 'sculpture', price: 900000),
            _piece('aw-2', 'Watercolour', category: 'paper', price: 5000),
          ],
          holdings: [_view(_holding('h1'), title: 'Bronze One', category: 'sculpture')],
        ),
      );
      expect(find.text('SUGGESTED FOR YOU'), findsOneWidget);
      // Once in the suggestions and once in the list.
      expect(find.text('Bronze Two'), findsNWidgets(2));
      expect(find.text('Watercolour'), findsOneWidget);
    });
  });

  group('reserving', () {
    testWidgets('month 1: the price starts at GalleryZone\'s and the money follows what is typed', (tester) async {
      await _show(tester, _Agg(), at: '/aggregator/inventory/aw-1/reserve');
      expect(find.text('Monsoon, Madurai'), findsOneWidget);
      expect(find.widgetWithText(TextField, '130000'), findsOneWidget);
      // 5% of 1,30,000, plus delivery.
      expect(find.text('₹6,500'), findsWidgets);
      expect(find.text('₹9,000'), findsOneWidget, reason: 'held from the wallet');
      expect(find.text('₹1,36,500'), findsWidgets, reason: 'what customers see');

      await tester.enterText(_priceField(), '150000');
      await tester.pumpAndSettle();
      // 5% of the price they set - and, as it happens, the GST on it as well.
      expect(find.text('₹7,500'), findsNWidgets(2));
      expect(find.text('₹1,57,500'), findsWidgets, reason: 'what customers see');
      // Where it goes: of the 50,000 markup over the artist's 1,00,000, 20% is theirs
      // and the rest GalleryZone's.
      expect(find.text('GalleryZone (80% of the markup)'), findsOneWidget);
      expect(find.text('₹40,000'), findsOneWidget);
      expect(find.text('Your commission if it sells here (20%)'), findsOneWidget);
      // 10,000 twice: that commission, and the 7,500 advance plus 2,500 delivery held.
      expect(find.text('₹10,000'), findsNWidgets(2));
    });

    testWidgets('a price below GalleryZone\'s, or in paise, is refused where it is typed', (tester) async {
      await _show(tester, _Agg(), at: '/aggregator/inventory/aw-1/reserve');

      await tester.enterText(_priceField(), '129999');
      await tester.pumpAndSettle();
      expect(find.text("It can't be lower than GalleryZone's price, ₹1,30,000."), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm reservation')).onPressed, isNull);
      // The figures hold at GalleryZone's price meanwhile rather than showing a nonsense advance.
      expect(find.text('₹9,000'), findsOneWidget);

      await tester.enterText(_priceField(), '140000.5');
      await tester.pumpAndSettle();
      expect(find.text('Enter a price in whole rupees.'), findsOneWidget);

      await tester.enterText(_priceField(), '');
      await tester.pumpAndSettle();
      expect(find.text('Enter a price in whole rupees.'), findsOneWidget);
    });

    testWidgets('double GalleryZone\'s price is allowed, with a word that GalleryZone will be told', (tester) async {
      await _show(tester, _Agg(), at: '/aggregator/inventory/aw-1/reserve');
      await tester.enterText(_priceField(), '259999');
      await tester.pumpAndSettle();
      expect(find.textContaining("at least double GalleryZone's price"), findsNothing);

      await tester.enterText(_priceField(), '260000');
      await tester.pumpAndSettle();
      expect(find.textContaining("at least double GalleryZone's price"), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm reservation')).onPressed, isNotNull);
    });

    testWidgets('confirming sends the price they set and lands on the new holding', (tester) async {
      final agg = _Agg();
      await _show(tester, agg, at: '/aggregator/inventory/aw-1/reserve');
      await tester.enterText(_priceField(), '150000');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Confirm reservation'));

      expect(agg.reserved.single.id, 'aw-1');
      expect(agg.reserved.single.price, 150000);
      expect(find.text('Holding'), findsOneWidget, reason: 'the holding page');
      expect(find.text('Monsoon, Madurai'), findsWidgets);
      expect(find.textContaining('is now in My Inventory'), findsOneWidget);
    });

    testWidgets('keeping GalleryZone\'s price sends that price', (tester) async {
      final agg = _Agg();
      await _show(tester, agg, at: '/aggregator/inventory/aw-1/reserve');
      await _tap(tester, find.text('Confirm reservation'));
      expect(agg.reserved.single.price, 130000);
    });

    testWidgets('from month 2 the price is GalleryZone\'s - there is nothing to type, and nothing is sent', (tester) async {
      final agg = _Agg(reservable: [_piece('aw-3', 'Late Light', offer: _offer3('aw-3'))]);
      await _show(tester, agg, at: '/aggregator/inventory/aw-3/reserve');
      expect(find.text('Your selling price, before GST (₹)'), findsNothing);
      expect(find.text('Price this month, before GST'), findsOneWidget);
      expect(find.text('Set by GalleryZone. Only the first aggregator sets a price.'), findsOneWidget);
      expect(find.text("Why this month's price is lower".toUpperCase()), findsOneWidget);
      expect(find.text('−₹4,200'), findsOneWidget);
      expect(find.text('Advance (3%)'), findsOneWidget);
      expect(find.text("of the artist price, ₹1,00,000"), findsOneWidget);
      expect(find.text('₹5,500'), findsOneWidget);

      await _tap(tester, find.text('Confirm reservation'));
      expect(agg.reserved.single.price, isNull);
    });

    testWidgets('a shortfall is named, Confirm waits, and the wallet is one tap away', (tester) async {
      await _show(tester, _Agg(free: 1000), at: '/aggregator/inventory/aw-1/reserve');
      expect(find.text('₹8,000 short'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm reservation')).onPressed, isNull);

      await _tap(tester, find.text('Go to wallet'));
      expect(find.text('WALLET PAGE'), findsOneWidget);
    });

    testWidgets('an open requirement keeps Confirm closed too', (tester) async {
      await _show(tester, _Agg(profile: _profile(gst: ReviewStatus.submitted)), at: '/aggregator/inventory/aw-1/reserve');
      expect(find.text('Your GST number is being reviewed.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm reservation')).onPressed, isNull);
    });

    testWidgets('a piece that has gone says so', (tester) async {
      await _show(tester, _Agg(), at: '/aggregator/inventory/nope/reserve');
      expect(find.text("This piece isn't reservable"), findsOneWidget);
      await _tap(tester, find.text('Back to inventory'));
      expect(find.text('Browse GalleryZone'), findsOneWidget);
    });

    testWidgets('losing the race keeps the page, says why, and re-reads the list', (tester) async {
      final agg = _Agg()..failReserveWith = Exception('Artwork no longer available');
      await _show(tester, agg, at: '/aggregator/inventory/aw-1/reserve');
      await _tap(tester, find.text('Confirm reservation'));
      expect(find.text('Artwork no longer available'), findsOneWidget);
      expect(agg.reserved, hasLength(1));
    });

    testWidgets('the offline demo can stage the lost race; the real service cannot', (tester) async {
      final agg = _Agg();
      await _show(tester, agg, at: '/aggregator/inventory/aw-1/reserve', remote: false);
      expect(find.textContaining('Simulate reservation conflict'), findsOneWidget);
      await _tap(tester, find.byType(CheckboxListTile));
      await _tap(tester, find.text('Confirm reservation'));
      expect(agg.reserved.single.conflict, isTrue);

      await _show(tester, _Agg(), at: '/aggregator/inventory/aw-1/reserve');
      expect(find.textContaining('Simulate reservation conflict'), findsNothing);
    });

    testWidgets('similar pieces still open for reservation are offered', (tester) async {
      await _show(
        tester,
        _Agg(reservable: [_piece('aw-1', 'Monsoon, Madurai'), _piece('aw-2', 'Sister Piece')]),
        at: '/aggregator/inventory/aw-1/reserve',
      );
      expect(find.text('SIMILAR PIECES YOU COULD RESERVE'), findsOneWidget);
      expect(find.text('Sister Piece'), findsOneWidget);
    });
  });

  group('my inventory', () {
    final reserved = _view(_holding('h1', artworkId: 'aw-h1'), title: 'Reserved One');
    final sold = _view(_holding('h2', artworkId: 'aw-h2', status: HoldingStatus.soldPendingSettlement), title: 'Sold One');
    final back = _view(_holding('h3', artworkId: 'aw-h3', status: HoldingStatus.returned), title: 'Gone One');

    testWidgets('returned pieces leave the list, and the filters count what is left', (tester) async {
      await _show(tester, _Agg(holdings: [reserved, sold, back]), at: AggregatorCollectionScreen.path);
      expect(find.text('Reserved One'), findsOneWidget);
      expect(find.text('Sold One'), findsOneWidget);
      expect(find.text('Gone One'), findsNothing);
      expect(find.text('All  2'), findsOneWidget);
      expect(find.text('Reserved  1'), findsOneWidget);
      expect(find.text('Sold  1'), findsOneWidget);

      await tester.tap(find.text('Sold  1'));
      await tester.pumpAndSettle();
      expect(find.text('Reserved One'), findsNothing);
      expect(find.text('Sold One'), findsOneWidget);
      expect(find.text('Sale recorded'), findsOneWidget);
    });

    testWidgets('a status with nothing in it says so', (tester) async {
      await _show(tester, _Agg(holdings: [reserved]), at: AggregatorCollectionScreen.path);
      await tester.tap(find.text('Sold  0'));
      await tester.pumpAndSettle();
      expect(find.text('No holdings with this status'), findsOneWidget);
    });

    testWidgets('no holdings at all points back to Browse', (tester) async {
      await _show(tester, _Agg(), at: AggregatorCollectionScreen.path);
      expect(find.text('No holdings yet'), findsOneWidget);
      await _tap(tester, find.text('Browse Inventory'));
      expect(find.text('Browse GalleryZone'), findsOneWidget);
    });

    testWidgets('a card opens the holding, and says when an extension has been asked for', (tester) async {
      final asked = _view(
        _holding(
          'h4',
          artworkId: 'aw-h4',
          request: const HoldingExtensionRequest(
            status: ExtensionStatus.pending,
            assurance: 'A collector is confirming this week.',
            requestedAt: '2026-10-01T00:00:00.000Z',
          ),
        ),
        title: 'Asked One',
      );
      await _show(tester, _Agg(holdings: [asked]), at: AggregatorCollectionScreen.path);
      expect(find.text('Extension requested'), findsOneWidget);
      await _tap(tester, find.text('Asked One'));
      expect(find.text('Holding'), findsOneWidget);
      expect(find.text('Waiting for GalleryZone'), findsOneWidget);
    });

    testWidgets('returning a piece shows what comes back and what does not, then does it', (tester) async {
      final agg = _Agg(holdings: [reserved]);
      await _show(tester, agg, at: AggregatorCollectionScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Return'));

      expect(find.text('Return this piece to GalleryZone'), findsOneWidget);
      expect(find.text('Released back to your wallet'), findsOneWidget);
      expect(find.text('Only refunded on a sale — forfeited on an unsold return'), findsOneWidget);
      expect(find.text('−₹2,500'), findsOneWidget);

      await _tap(tester, find.text('Return to GalleryZone'));
      expect(agg.returned, ['h1']);
      expect(find.textContaining('₹6,500 advance released.'), findsOneWidget);
      expect(find.text('Reserved One'), findsNothing, reason: 'it left the list');
    });

    testWidgets('keeping it changes nothing', (tester) async {
      final agg = _Agg(holdings: [reserved]);
      await _show(tester, agg, at: AggregatorCollectionScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Return'));
      await _tap(tester, find.text('Keep it'));
      expect(agg.returned, isEmpty);
      expect(find.text('Return this piece to GalleryZone'), findsNothing);
    });

    testWidgets('a refused return stays open with the reason', (tester) async {
      final agg = _Agg(holdings: [reserved])..failReturnWith = Exception('This piece has already sold and cannot be returned');
      await _show(tester, agg, at: AggregatorCollectionScreen.path);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Return'));
      await _tap(tester, find.text('Return to GalleryZone'));
      expect(find.text('This piece has already sold and cannot be returned'), findsOneWidget);
      expect(find.text('Return this piece to GalleryZone'), findsOneWidget);
    });
  });

  group('recording a sale', () {
    final reserved = _view(_holding('h1', artworkId: 'aw-h1', price: 157500), title: 'Reserved One');

    Future<void> openSheet(WidgetTester tester, _Agg agg) async {
      await _show(tester, agg, at: AggregatorCollectionScreen.path);
      await _tap(tester, find.widgetWithText(FilledButton, 'Record sale'));
    }

    Future<void> fill(WidgetTester tester, {String email = 'anita@example.com'}) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Buyer name'), 'Anita Sen');
      await tester.enterText(find.widgetWithText(TextFormField, 'Buyer phone'), '9845012345');
      await tester.enterText(find.widgetWithText(TextFormField, 'Buyer email'), email);
      await tester.enterText(find.widgetWithText(TextFormField, 'Delivery address'), '14 Church Street');
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Bengaluru');
      await tester.enterText(find.widgetWithText(TextFormField, 'State'), 'Karnataka');
      await tester.enterText(find.widgetWithText(TextFormField, 'Pincode'), '560001');
      await tester.pumpAndSettle();
    }

    Finder submit() => find.widgetWithText(FilledButton, 'Record sale').last;

    testWidgets('the price is the holding\'s own and cannot be changed; the working is shown', (tester) async {
      await openSheet(tester, _Agg(holdings: [reserved]));
      expect(find.text('Month 1 of 5 display price'), findsOneWidget);
      expect(find.text('Advance (5%) + delivery'), findsOneWidget);
      expect(find.text('₹9,000'), findsOneWidget);
      expect(find.text('Set off against this sale, not credited separately'), findsOneWidget);
      expect(find.text('157500'), findsOneWidget, reason: 'read-only sold price');
      expect(find.widgetWithText(TextFormField, 'Sold price (₹)'), findsNothing);
    });

    testWidgets('nothing is sent until the buyer and delivery details are valid', (tester) async {
      final agg = _Agg(holdings: [reserved]);
      await openSheet(tester, agg);
      await _tap(tester, submit());
      expect(find.text("Enter the buyer's name"), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter the address'), findsOneWidget);
      expect(find.text('Enter the city'), findsOneWidget);
      expect(find.text('Enter the state'), findsOneWidget);
      expect(find.text('Enter a valid 6-digit pincode'), findsOneWidget);
      expect(agg.sales, isEmpty);
    });

    testWidgets('the sale goes to the API at the holding\'s price and the buyer is told where it is held', (tester) async {
      final agg = _Agg(holdings: [reserved]);
      await openSheet(tester, agg);
      await fill(tester);
      await tester.ensureVisible(find.text('Cash, collected by you'));
      await tester.pump();
      await tester.tap(find.text('Cash, collected by you'));
      await tester.pumpAndSettle();
      expect(find.text('You will owe GalleryZone the full sale amount. Your commission is settled separately.'), findsOneWidget);

      await _tap(tester, submit());
      final input = agg.sales.single;
      expect(input.artworkId, 'aw-h1');
      expect(input.soldPrice, 157500);
      expect(input.buyerEmail, 'anita@example.com');
      expect(input.paymentRoute, PaymentRoute.cashAtPremises);
      expect(input.deliveryMode, DeliveryMode.courier);
      expect(input.deliveryAddress.pincode, '560001');

      expect(find.textContaining('is now pending settlement'), findsOneWidget);
      expect(find.textContaining('held against anita@example.com'), findsOneWidget);
      await _tap(tester, find.text('Settlements'));
      expect(find.text('SETTLEMENTS PAGE'), findsOneWidget);
    });

    testWidgets('a refused sale keeps what was typed and says why', (tester) async {
      final agg = _Agg(holdings: [reserved])..failSaleWith = Exception('The sale must be at the holding\'s own price');
      await openSheet(tester, agg);
      await fill(tester);
      await _tap(tester, submit());
      expect(find.text("The sale must be at the holding's own price"), findsOneWidget);
      expect(find.text('Anita Sen'), findsOneWidget, reason: 'the form is still there');
      expect(agg.sales, isEmpty);
    });

    testWidgets('paying GalleryZone directly needs nothing from the aggregator', (tester) async {
      await openSheet(tester, _Agg(holdings: [reserved]));
      expect(find.text('Nothing to transfer — the money reached GalleryZone directly.'), findsOneWidget);
    });
  });

  group('the holding page', () {
    testWidgets('lays the lifecycle out: window, rotation, the three figures, what can be done', (tester) async {
      final agg = _Agg(holdings: [_view(_holding('h1', month: 3), title: 'Held piece')]);
      await _show(tester, agg, at: '/aggregator/collection/h1');
      expect(find.text('Held piece'), findsWidgets);
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('DISPLAY WINDOW'), findsOneWidget);
      expect(find.text('ROTATION · MONTH 3 OF 5'), findsOneWidget);
      expect(find.text('Advance'), findsOneWidget);
      expect(find.text('(3%)'), findsOneWidget);
      expect(find.text('Delivery deposit'), findsOneWidget);
      expect(find.text('Display price'), findsOneWidget);
      expect(find.byType(CycleStepper), findsOneWidget);
      expect(find.text('Record sale'), findsOneWidget);
      expect(find.text('Return'), findsOneWidget);
      expect(find.text('Ask to keep it longer'), findsOneWidget);
      // The passport, while it is theirs.
      expect(find.text('Artwork Passport'), findsOneWidget);
      expect(find.text('GZ-COA-2026-0001'), findsOneWidget);
    });

    testWidgets('asking to keep a piece longer needs a real reason, and is then sent', (tester) async {
      final agg = _Agg(holdings: [_view(_holding('h1'))]);
      await _show(tester, agg, at: '/aggregator/collection/h1');
      await _tap(tester, find.text('Ask to keep it longer'));

      Finder send() => find.widgetWithText(FilledButton, 'Send request');
      expect(tester.widget<FilledButton>(send()).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'too short');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(send()).onPressed, isNull, reason: 'nine characters');

      await tester.enterText(find.byType(TextField).last, '  A collector is confirming this week.  ');
      await tester.pumpAndSettle();
      await _tap(tester, send());
      expect(agg.extensions.single, (id: 'h1', text: 'A collector is confirming this week.'));
      expect(find.textContaining("If it isn't approved before the window ends"), findsWidgets);

      // GalleryZone's answer is awaited: the question cannot be asked twice.
      expect(find.text('Waiting for GalleryZone'), findsOneWidget);
      expect(find.text('Ask to keep it longer'), findsNothing);
      expect(find.textContaining('Your assurance: “A collector is confirming this week.”'), findsOneWidget);
    });

    testWidgets("GalleryZone's answer stands for its window: a no is not asked again", (tester) async {
      final holding = _holding('h1');
      final declined = holding.copyWith(
        extensionRequest: HoldingExtensionRequest(
          status: ExtensionStatus.declined,
          assurance: 'Please',
          requestedAt: '2026-10-01T00:00:00.000Z',
          note: 'Too slow so far.',
          previousExpiresAt: holding.expiresAt,
        ),
      );
      await _show(tester, _Agg(holdings: [_view(declined)]), at: '/aggregator/collection/h1');
      expect(find.text('GalleryZone said no'), findsOneWidget);
      expect(find.textContaining('GalleryZone wrote: “Too slow so far.”'), findsOneWidget);
      expect(find.text('Ask to keep it longer'), findsNothing);
    });

    testWidgets('a new window opens the question again', (tester) async {
      final holding = _holding('h1');
      final extended = holding.copyWith(
        extensionRequest: const HoldingExtensionRequest(
          status: ExtensionStatus.approved,
          assurance: 'Please',
          requestedAt: '2026-10-01T00:00:00.000Z',
          previousExpiresAt: '2026-09-01T00:00:00.000Z',
        ),
      );
      await _show(tester, _Agg(holdings: [_view(extended)]), at: '/aggregator/collection/h1');
      expect(find.text('GalleryZone agreed'), findsOneWidget);
      expect(find.text('Ask to keep it longer'), findsOneWidget);
    });

    testWidgets('a piece already held to the end of its listing cannot ask for more', (tester) async {
      await _show(tester, _Agg(holdings: [_view(_holding('h1', windowExtended: true))]), at: '/aggregator/collection/h1');
      expect(find.text('Ask to keep it longer'), findsNothing);
      expect(find.textContaining('stays with you until the listing ends'), findsOneWidget);
    });

    testWidgets('once the window has passed only a sale can still be recorded', (tester) async {
      final lapsed = _view(_holding('h1', expiresIn: const Duration(days: -1)));
      await _show(tester, _Agg(holdings: [lapsed]), at: '/aggregator/collection/h1');
      expect(find.text("This piece's 30-day window has ended."), findsOneWidget);
      expect(find.text('Ask to keep it longer'), findsNothing);
      expect(find.text('Record sale'), findsWidgets);
    });

    testWidgets('a returned piece says so, and hides the passport that is no longer theirs', (tester) async {
      final back = _view(_holding('h1', status: HoldingStatus.returned));
      await _show(tester, _Agg(holdings: [back]), at: '/aggregator/collection/h1');
      expect(find.text('Your period for this piece has ended.'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Record sale'), findsNothing);
      expect(find.text('Artwork Passport'), findsNothing);
      expect(find.textContaining("only visible while it's in your active inventory"), findsOneWidget);
    });

    testWidgets('a holding that is not theirs is not found', (tester) async {
      await _show(tester, _Agg(), at: '/aggregator/collection/nope');
      expect(find.text('Holding not found'), findsOneWidget);
      await _tap(tester, find.text('Back to My Inventory'));
      expect(find.text('No holdings yet'), findsOneWidget);
    });

    testWidgets('a piece without a certificate yet says it is pending', (tester) async {
      final holding = _holding('h1');
      final view = AggregatorHoldingView(
        holding: holding,
        artwork: fixtureArtwork(id: holding.artworkId, title: 'Fresh', coaNumber: '', coaIssued: ''),
      );
      await _show(tester, _Agg(holdings: [view]), at: '/aggregator/collection/h1');
      expect(find.text('Pending approval'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });
  });

  test('the offer prices a month-1 reservation the way the rules say', () {
    // The fixtures above are the sheet's own numbers; if the rules move, so must they.
    final advance = aggregatorAdvanceForMonth(month: 1, sellingPrice: 130000, artistPrice: 100000);
    expect(advance.advance, _offer1().advance);
    expect(advance.payable, _offer1().payable);
    final later = aggregatorAdvanceForMonth(month: 3, sellingPrice: 126000, artistPrice: 100000);
    expect(later.advance, _offer3('x').advance);
    expect(withGst(130000), _offer1().offerPrice);
    expect(withGst(126000), _offer3('x').offerPrice);
    expect(formatInr(136500), '₹1,36,500');
  });
}
