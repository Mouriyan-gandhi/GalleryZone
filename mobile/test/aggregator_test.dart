import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/format.dart';
import 'package:gallery_zone/core/pricing.dart';
import 'package:gallery_zone/data/mock/mock_aggregator_repository.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/mock/seed/aggregator_seed.dart';
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:gallery_zone/features/aggregator/aggregator_mou_data.dart' show aggregatorMouVersion;
import 'package:shared_preferences/shared_preferences.dart';

const _address = DeliveryAddress(
  line1: '14 Church Street',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
);

RecordSaleInput _sale(
  String artworkId, {
  double soldPrice = 50000,
  String email = 'buyer@example.com',
  PaymentRoute route = PaymentRoute.directToGalleryZone,
}) =>
    RecordSaleInput(
      artworkId: artworkId,
      soldPrice: soldPrice,
      buyerName: 'Anita Sen',
      buyerEmail: email,
      buyerPhone: '9845012345',
      deliveryAddress: _address,
      deliveryMode: DeliveryMode.courier,
      paymentRoute: route,
    );

void main() {
  late MockAggregatorRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    repository = MockAggregatorRepository();
    // Reserving is gated on a signed MOU and a funded wallet — both are real
    // rules, so every test that reserves has to satisfy them first.
    await repository.acceptMou(signatureName: currentAggregatorContact, version: aggregatorMouVersion);
    await repository.addFunds(500000);
  });

  test('every seeded holding points at a real, aggregator-eligible artwork', () {
    // The web fails this at module load with a throw; Dart has no equivalent,
    // so the two fixtures are kept in sync here instead.
    final byId = {for (final artwork in seedArtworksCollection()) artwork.id: artwork};
    for (final holding in seedHoldingsCollection()) {
      final artwork = byId[holding.artworkId];
      expect(artwork, isNotNull, reason: '${holding.artworkId} is not in artworks_seed');
      expect(
        artwork!.listingType,
        ListingType.marketplaceAndAggregator,
        reason: '${holding.artworkId} is not eligible for aggregator display',
      );
    }
  });

  test('the artist and aggregator portals see the same holdings collection', () async {
    // The artist repo reads `holdings` first here. If it seeded only its own
    // holding, the aggregator's collection would come back one row long.
    final placements = await MockArtistRepository().listGallerySpaces();
    expect(placements, hasLength(1), reason: "only aw-4 is this artist's");

    final collection = await repository.listCollection();
    expect(collection.length, greaterThan(1));
    expect(collection.map((v) => v.holding.id), contains('hold-1'));
    expect(collection.map((v) => v.holding.id), contains('hold-devika-1'));
  });

  test('reservable inventory excludes anything already held', () async {
    final reservable = await repository.listReservableInventory();
    final claimed = seedHoldingsCollection().map((h) => h.artworkId).toSet();

    expect(reservable, isNotEmpty);
    for (final item in reservable) {
      final artwork = item.artwork;
      expect(claimed.contains(artwork.id), isFalse);
      expect(artwork.status, ArtworkStatus.marketplace);
      // Aggregator-eligible, not specifically marketplaceAndAggregator: an
      // aggregator-only piece is reservable here precisely because it never
      // appears in the online grid. Asserting the literal passed only while
      // no unclaimed aggregator-only fixture existed.
      expect(isAggregatorListed(artwork.listingType), isTrue);
      // Nothing has been placed yet, so every piece is on month one.
      expect(item.offer.month, 1);
      expect(item.offer.canSetPrice, isTrue);
      expect(item.offer.daysLeftInListing, aggregatorListingDays);
    }
  });

  test('reserving opens at the offer price and cannot happen twice', () async {
    final item = (await repository.listReservableInventory()).first;
    final artwork = item.artwork;
    final holding = await repository.reserve(artwork.id);

    // Month one: the offer price is GalleryZone's own price, so it matches
    // what the marketplace shows. From month two it drops below it.
    expect(holding.displayPrice, item.offer.offerPrice);
    expect(holding.cycleMonth, 1);
    expect(holding.status, HoldingStatus.reserved);
    expect(holding.assignmentSource, AssignmentSource.selfReserved);
    expect(holding.advancePercent, 5);
    // Client, 30 Sep 2026: 5% of the price before GST (6,500 on 1,30,000), not
    // of the figure a customer pays.
    expect(holding.advanceAmount, (item.offer.sellingPrice * 0.05).round());
    expect(holding.advanceAmount, item.offer.advance);
    expect(holding.deliveryDeposit, deliveryCharge);
    expect(
      DateTime.parse(holding.expiresAt).difference(DateTime.parse(holding.assignedAt)),
      holdingWindow,
    );

    // Gone from the browse grid, present in the collection.
    final reservable = await repository.listReservableInventory();
    expect(reservable.map((a) => a.artwork.id), isNot(contains(artwork.id)));
    expect(
      (await repository.listCollection()).map((v) => v.artwork.id),
      contains(artwork.id),
    );

    await expectLater(repository.reserve(artwork.id), throwsA(isA<Exception>()));
  });

  test('an aggregator whose GST number is not approved cannot reserve, whatever the MOU says', () async {
    final item = (await repository.listReservableInventory()).first;
    final profile = await repository.getProfile();
    expect(profile.gstStatus, ReviewStatus.approved, reason: 'the demo aggregator starts approved');

    // GalleryZone's verdict is not the client's to set, so the states are reached the
    // way they are for real: a new number is under review, none is not started, and a
    // rejection is the admin's - written here straight into the store.
    Future<void> expectRefused(String why) => expectLater(
          repository.reserve(item.artwork.id),
          throwsA(isA<Exception>().having((e) => '$e', 'message', contains('GST number'))),
          reason: why,
        );

    await repository.updateProfile(profile.copyWith(gstNumber: '27ABCDE1234F1Z7'));
    await expectRefused('under review');

    await repository.updateProfile(profile.copyWith(gstNumber: ''));
    await expectRefused('not started');

    MockDb.setCollection(
      'aggregatorProfile',
      [(await repository.getProfile()).copyWith(gstStatus: ReviewStatus.rejected)],
      (p) => p.toJson(),
    );
    await expectRefused('rejected');
    expect((await repository.getWallet()).lockedBalance, 0, reason: 'a refusal holds nothing');

    MockDb.setCollection(
      'aggregatorProfile',
      [(await repository.getProfile()).copyWith(gstStatus: ReviewStatus.approved)],
      (p) => p.toJson(),
    );
    expect((await repository.reserve(item.artwork.id)).status, HoldingStatus.reserved);
  });

  test('a holding can still be read after it has gone back, but not a stranger\'s', () async {
    final item = (await repository.listReservableInventory()).first;
    final holding = await repository.reserve(item.artwork.id);
    await repository.releaseHolding(holding.id);

    expect((await repository.listCollection()).map((v) => v.holding.id), isNot(contains(holding.id)));
    final view = await repository.getHolding(holding.id);
    expect(view?.holding.status, HoldingStatus.returned);
    expect(view?.artwork.id, item.artwork.id);
    expect(await repository.getHolding('nope'), isNull);
  });

  test('the advance and delivery are LOCKED from the wallet, not charged',
      () async {
    final item = (await repository.listReservableInventory()).first;
    final before = await repository.getWallet();

    await repository.reserve(item.artwork.id);

    final after = await repository.getWallet();
    expect(after.balance, before.balance, reason: 'no money left the wallet');
    expect(after.lockedBalance, before.lockedBalance + item.offer.payable);
  });

  test('an unsigned aggregator cannot take possession of anyone\'s artwork',
      () async {
    // A fresh store: no MOU, no funds.
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    final fresh = MockAggregatorRepository();
    final item = (await fresh.listReservableInventory()).first;

    await expectLater(fresh.reserve(item.artwork.id), throwsA(isA<Exception>()));

    // Signed but broke: still refused, now for the money.
    await fresh.acceptMou(signatureName: currentAggregatorContact, version: aggregatorMouVersion);
    await expectLater(fresh.reserve(item.artwork.id), throwsA(isA<Exception>()));

    await fresh.addFunds(item.offer.payable);
    final holding = await fresh.reserve(item.artwork.id);
    expect(holding.status, HoldingStatus.reserved);
  });

  test('a piece nobody buys moves to the next aggregator, cheaper', () async {
    final first = (await repository.listReservableInventory()).first;
    final artworkId = first.artwork.id;
    final holding = await repository.reserve(artworkId);

    // It goes back unsold. The advance is released; the delivery leg is not —
    // the sheet settles that only on a sale.
    final release = await repository.releaseHolding(holding.id);
    expect(release.refunded, holding.advanceAmount);
    expect(release.deliveryLost, deliveryCharge);

    final wallet = await repository.getWallet();
    expect(wallet.lockedBalance, 0);
    expect(wallet.balance, 500000 - deliveryCharge);

    // Out of the collection, back in the grid — at month two's price, and now
    // priced by GalleryZone rather than by the aggregator.
    expect(
      (await repository.listCollection()).map((v) => v.artwork.id),
      isNot(contains(artworkId)),
    );
    final second = (await repository.listReservableInventory())
        .firstWhere((i) => i.artwork.id == artworkId);
    expect(second.offer.month, 2);
    expect(second.offer.offerPrice, lessThan(first.offer.offerPrice));
    expect(second.offer.canSetPrice, isFalse);

    // Month two is charged on the artist's price, not the display price.
    expect(second.offer.advanceBasis, AdvanceBasis.artistPrice);
    // 5% of the artist's price in month two; 3% from month three.
    expect(second.offer.advanceRate, 0.05);
    expect(second.offer.advance, (artistPriceOf(first.artwork) * 0.05).round());
  });

  test('only the first aggregator of a cycle may price the piece', () async {
    final first = (await repository.listReservableInventory()).first;
    final holding = await repository.reserve(first.artwork.id);
    await repository.releaseHolding(holding.id);

    // Month two takes GalleryZone's price; a figure sent anyway is not honoured.
    final offer = (await repository.listReservableInventory())
        .firstWhere((i) => i.artwork.id == first.artwork.id)
        .offer;
    expect(offer.canSetPrice, isFalse);
    final second =
        await repository.reserve(first.artwork.id, sellingPrice: offer.sellingPrice + 50000);
    expect(second.cycleMonth, 2);
    expect(second.displayPrice, offer.offerPrice);
    expect(second.displayPriceSetAt, isNull);
  });

  test('the price is chosen once, as the piece is reserved, and held to the floor', () async {
    final item = (await repository.listReservableInventory()).first;
    final floor = item.offer.sellingPrice;

    // Never below GalleryZone's own price, and only in whole rupees - refused by
    // the repository, not just the form.
    await expectLater(
      repository.reserve(item.artwork.id, sellingPrice: floor - 1),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      repository.reserve(item.artwork.id, sellingPrice: floor + 0.5),
      throwsA(isA<Exception>()),
    );
    expect(
      (await repository.listCollection()).map((v) => v.artwork.id),
      isNot(contains(item.artwork.id)),
      reason: 'a refused price reserves nothing',
    );

    final before = await repository.getWallet();
    final holding = await repository.reserve(item.artwork.id, sellingPrice: floor + 20000);
    expect(holding.displayPrice, withGst(floor + 20000));
    expect(holding.displayPriceSetAt, isNotNull);
    expect(holding.appreciated, isTrue);
    expect(holding.priceWarning, isFalse);
    // 5% of what they priced it at, before GST - not of the floor.
    expect(holding.advanceAmount, ((floor + 20000) * 0.05).round());
    expect(
      (await repository.getWallet()).lockedBalance,
      before.lockedBalance + holding.advanceAmount + holding.deliveryDeposit,
    );
  });

  test('GalleryZone is warned, not blocked, once the price reaches double its own', () async {
    final item = (await repository.listReservableInventory()).first;
    expect(item.offer.priceWarnFrom, item.offer.sellingPrice * 2);
    final holding =
        await repository.reserve(item.artwork.id, sellingPrice: item.offer.sellingPrice * 2);
    expect(holding.priceWarning, isTrue);
  });

  test('after a month-1 price above the offer, the next aggregator is back at full price', () async {
    final item = (await repository.listReservableInventory()).first;
    final holding =
        await repository.reserve(item.artwork.id, sellingPrice: item.offer.sellingPrice + 20000);
    await repository.releaseHolding(holding.id);

    final next = (await repository.listReservableInventory())
        .firstWhere((i) => i.artwork.id == item.artwork.id)
        .offer;
    expect(next.month, 2);
    expect(next.sellingPrice, item.offer.sellingPrice, reason: 'the monthly drops start a month later');
    expect(next.advanceRate, 0.05);
    expect(next.advanceBasis, AdvanceBasis.artistPrice);
  });

  test('a sale credits pending commission, and settling makes it withdrawable',
      () async {
    // Priced above GalleryZone's own as it was reserved - the only time it can be.
    final item = (await repository.listReservableInventory()).first;
    final holding =
        await repository.reserve(item.artwork.id, sellingPrice: item.offer.sellingPrice + 10000);
    // MOU §8: 20% of the markup over the ARTIST's price, both before GST —
    // not over GalleryZone's price to the aggregator, which is what the old
    // formula compared against and paid far too little for.
    final expected = aggregatorCommissionFor(
      displayPrice: holding.displayPrice,
      artistPrice: artistPriceOf(item.artwork),
    );
    expect(
      expected,
      (0.2 * (exGst(holding.displayPrice) - artistPriceOf(item.artwork))).round(),
    );

    final sale = await repository.recordSale(_sale(item.artwork.id));
    expect(sale.shipmentStatus, ShipmentStatus.preparing);
    expect(sale.courierRef, isNotNull);

    // Pending, not available: the money isn't withdrawable until settled.
    // The balance is the top-up this test's setUp put in, untouched — the
    // advance was locked from it, never taken.
    var wallet = await repository.getWallet();
    expect(wallet.pendingBalance, expected);
    expect(wallet.balance, 500000);
    expect(wallet.lockedBalance, 0, reason: 'the sale released the hold');
    // Pending commission is not part of what can be withdrawn: asking for the
    // whole balance plus it is refused.
    await expectLater(
      repository.requestWithdrawal(wallet.balance + expected),
      throwsA(isA<Exception>()),
    );

    final settlement = await repository.processSettlement(sale.id);
    expect(settlement.aggregatorCommission, expected);
    expect(settlement.status, SettlementStatus.processed);

    wallet = await repository.getWallet();
    expect(wallet.pendingBalance, 0);
    expect(wallet.balance, 500000 + expected);

    // One sale, one commission line — the pending row became the settlement
    // row rather than a second appearing beside it. The other rows are the
    // top-up, the reserve hold, and the advance being set off on the sale.
    final transactions = await repository.listWalletTransactions();
    final settlements = transactions
        .where((t) => t.type == WalletTransactionType.settlement)
        .toList();
    expect(settlements, hasLength(1));
    expect(settlements.single.status, WalletTransactionStatus.completed);

    await expectLater(
      repository.processSettlement(sale.id),
      throwsA(isA<Exception>()),
    );
  });

  test('a sold holding stays in the collection and refuses a second sale', () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    await repository.recordSale(_sale(view.artwork.id));

    final after = (await repository.listCollection())
        .firstWhere((v) => v.holding.id == view.holding.id);
    expect(after.holding.status, HoldingStatus.soldPendingSettlement);

    await expectLater(
      repository.recordSale(_sale(view.artwork.id)),
      throwsA(isA<Exception>()),
    );
  });

  test('reserving never mutates the shared artworks collection', () async {
    final artwork = (await repository.listReservableInventory()).first.artwork;
    await repository.reserve(artwork.id);
    await repository.recordSale(_sale(artwork.id));

    // The marketplace and artist portal share this collection; an
    // aggregator-only state written into it would leak into both.
    final marketplace = await MockArtworkRepository().get(artwork.id);
    expect(marketplace?.status, ArtworkStatus.marketplace);
  });

  test('customers roll up by email across repeat purchases', () async {
    final reserved = (await repository.listCollection())
        .where((v) => v.holding.status == HoldingStatus.reserved)
        .take(2)
        .toList();

    await repository.recordSale(_sale(reserved[0].artwork.id, soldPrice: 20000));
    await repository.recordSale(_sale(reserved[1].artwork.id, soldPrice: 30000));

    final customers = await repository.listCustomers();
    expect(customers, hasLength(1));
    expect(customers.single.orderCount, 2);
    expect(customers.single.totalSpend, 50000);
  });


  group('cash sales: GalleryZone\'s money in the aggregator\'s till', () {
    const cash = PaymentRoute.cashAtPremises;

    Future<AggregatorHoldingView> reservedSeed() async =>
        (await repository.listCollection()).firstWhere((v) => v.holding.status == HoldingStatus.reserved);

    test('a cash sale is due two days after it is made; one paid straight to GalleryZone is never due', () async {
      final views = (await repository.listCollection())
          .where((v) => v.holding.status == HoldingStatus.reserved)
          .take(2)
          .toList();
      final owed = await repository.recordSale(_sale(views[0].artwork.id, route: cash));
      final direct = await repository.recordSale(_sale(views[1].artwork.id));

      expect(cashRemittanceDays, 2);
      expect(direct.remitDueAt, isNull);
      expect(
        DateTime.parse(owed.remitDueAt!).difference(DateTime.parse(owed.soldAt)),
        const Duration(days: cashRemittanceDays),
      );
      expect((await repository.listRemittancesDue()).map((sale) => sale.id), [owed.id]);
    });

    test('paying from the wallet takes the free balance and writes it in the ledger', () async {
      final view = await reservedSeed();
      final sale = await repository.recordSale(_sale(view.artwork.id, soldPrice: 40000, route: cash));
      final before = await repository.getWallet();

      final paid = await repository.markRemitted(sale.id);

      expect(paid.remittedVia, RemitVia.wallet);
      expect(paid.remittedAt, isNotNull);
      expect((await repository.getWallet()).balance, before.balance - 40000);
      final newest = (await repository.listWalletTransactions()).first;
      expect(newest.label, 'Cash sale paid to GalleryZone · ${view.artwork.title}');
      expect(newest.amount, -40000);
      expect(await repository.listRemittancesDue(), isEmpty);
    });

    test('it cannot overdraw: money held for reservations is not free, and the shortfall is named', () async {
      // Two reservations set money aside; selling one releases only its own.
      final pieces = (await repository.listReservableInventory()).take(2).toList();
      final first = await repository.reserve(pieces[0].artwork.id);
      final second = await repository.reserve(pieces[1].artwork.id);
      final stillHeld = second.advanceAmount + second.deliveryDeposit;
      final free = 500000 - stillHeld;

      // Within the balance, but not within what is free.
      final price = 500000 - stillHeld / 2;
      final sale = await repository.recordSale(_sale(first.artworkId, soldPrice: price, route: cash));
      expect((await repository.getWallet()).balance, 500000);

      await expectLater(
        repository.markRemitted(sale.id),
        throwsA(
          predicate(
            (e) => '$e'.contains('Your wallet has ${formatInr(free)} free') &&
                '$e'.contains('Add ${formatInr(price - free)} to your wallet'),
            'names the free balance and the shortfall',
          ),
        ),
      );
      expect((await repository.getWallet()).balance, 500000, reason: 'a refusal takes nothing');
      expect(await repository.listRemittancesDue(), hasLength(1));
    });

    test('a bank transfer moves no wallet money and is taken on their word', () async {
      final view = await reservedSeed();
      final sale = await repository.recordSale(_sale(view.artwork.id, soldPrice: 40000, route: cash));
      final before = await repository.getWallet();
      final ledger = (await repository.listWalletTransactions()).length;

      final paid = await repository.markRemitted(sale.id, via: RemitVia.bank);

      expect(paid.remittedVia, RemitVia.bank);
      expect((await repository.getWallet()).balance, before.balance);
      expect((await repository.listWalletTransactions()), hasLength(ledger));
      expect(await repository.listRemittancesDue(), isEmpty);
    });

    test('only a cash sale is paid in, and only once', () async {
      final views = (await repository.listCollection())
          .where((v) => v.holding.status == HoldingStatus.reserved)
          .take(2)
          .toList();
      final direct = await repository.recordSale(_sale(views[0].artwork.id));
      final owed = await repository.recordSale(_sale(views[1].artwork.id, route: cash));

      await expectLater(repository.markRemitted(direct.id), throwsA(isA<Exception>()));
      await repository.markRemitted(owed.id, via: RemitVia.bank);
      await expectLater(repository.markRemitted(owed.id, via: RemitVia.bank), throwsA(isA<Exception>()));
      await expectLater(repository.markRemitted('nope'), throwsA(isA<Exception>()));
    });
  });

  group('the profile', () {
    test('a client cannot award itself an approved GST number, the agreement or a bank account', () async {
      final before = await repository.getProfile();
      expect(before.gstStatus, ReviewStatus.approved, reason: 'the demo aggregator starts approved');
      expect(before.mouAcceptance, isNotNull, reason: 'setUp signed it');

      final saved = await repository.updateProfile(
        before.copyWith(
          companyName: 'Verandah Art Co',
          gstStatus: ReviewStatus.rejected,
          mouAcceptance: null,
          bankAccountMasked: '•••• •••• •••• 0000',
          aadhaarStatus: ReviewStatus.approved,
          aadhaarMasked: 'XXXX XXXX 1111',
        ),
      );

      expect(saved.companyName, 'Verandah Art Co');
      expect(saved.gstStatus, ReviewStatus.approved);
      expect(saved.mouAcceptance, isNotNull);
      expect(saved.bankAccountMasked, before.bankAccountMasked);
      expect(saved.aadhaarMasked, before.aadhaarMasked);
      expect(saved.aadhaarStatus, before.aadhaarStatus);
    });

    test('a different GST number goes back under review; the same one keeps its verdict; none clears it', () async {
      final profile = await repository.getProfile();

      final same = await repository.updateProfile(profile.copyWith(gstNumber: profile.gstNumber.toLowerCase()));
      expect(same.gstStatus, ReviewStatus.approved, reason: 'capitals do not make it a different number');

      final changed = await repository.updateProfile(profile.copyWith(gstNumber: '27ABCDE1234F1Z7'));
      expect(changed.gstNumber, '27ABCDE1234F1Z7');
      expect(changed.gstStatus, ReviewStatus.submitted);

      final cleared = await repository.updateProfile(changed.copyWith(gstNumber: ''));
      expect(cleared.gstStatus, ReviewStatus.notSubmitted);
      await expectLater(
        repository.reserve((await repository.listReservableInventory()).first.artwork.id),
        throwsA(isA<Exception>().having((e) => '$e', 'message', contains('GST number'))),
      );
    });

    test('a GST number that is not a GSTIN is refused, as the API refuses it', () async {
      final profile = await repository.getProfile();
      await expectLater(
        repository.updateProfile(profile.copyWith(gstNumber: 'NOT-A-GSTIN')),
        throwsA(isA<Exception>().having((e) => '$e', 'message', contains('15-character'))),
      );
      expect((await repository.getProfile()).gstNumber, profile.gstNumber, reason: 'a refusal changes nothing');
    });

    test('the conversion rate is over pieces that finished - sold or sent back - and not those still on display', () async {
      final seeded = seedHoldingsCollection();
      final sold = seeded.where((h) => h.status == HoldingStatus.soldPendingSettlement).length;
      final returned = seeded.where((h) => h.status == HoldingStatus.returned).length;
      int rate(int soldCount, int returnedCount) => (soldCount / (soldCount + returnedCount) * 100).round();
      expect(sold, greaterThan(0), reason: 'the demo has sales already');
      expect((await repository.getDashboardSummary()).conversionRate, rate(sold, returned));

      final pieces = (await repository.listReservableInventory()).take(2).toList();
      final first = await repository.reserve(pieces[0].artwork.id);
      await repository.reserve(pieces[1].artwork.id);
      expect((await repository.getDashboardSummary()).conversionRate, rate(sold, returned), reason: 'on display is neither');

      await repository.releaseHolding(first.id);
      expect((await repository.getDashboardSummary()).conversionRate, rate(sold, returned + 1));

      await repository.recordSale(_sale(pieces[1].artwork.id));
      expect((await repository.getDashboardSummary()).conversionRate, rate(sold + 1, returned + 1));
    });
  });

  test('the commission shown for a sale is the one credited for it', () async {
    final item = (await repository.listReservableInventory()).first;
    final holding = await repository.reserve(item.artwork.id, sellingPrice: item.offer.sellingPrice + 10000);
    final sale = await repository.recordSale(_sale(item.artwork.id));

    final expected = aggregatorCommissionFor(
      displayPrice: holding.displayPrice,
      artistPrice: artistPriceOf(item.artwork),
    );
    expect(expected, greaterThan(0));
    expect((await repository.saleCommissions())[sale.id], expected);
    expect((await repository.getWallet()).pendingBalance, expected);
  });

  test('sales come newest first and customers biggest spender first', () async {
    final views = (await repository.listCollection())
        .where((v) => v.holding.status == HoldingStatus.reserved)
        .take(2)
        .toList();
    final small = await repository.recordSale(_sale(views[0].artwork.id, soldPrice: 20000, email: 'small@example.com'));
    final big = await repository.recordSale(_sale(views[1].artwork.id, soldPrice: 90000, email: 'big@example.com'));

    expect((await repository.listSales()).map((sale) => sale.id), [big.id, small.id]);
    expect((await repository.listCustomers()).map((customer) => customer.buyerEmail), ['big@example.com', 'small@example.com']);
  });

  test('a shipment advances one step at a time and then stops', () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    final sale = await repository.recordSale(_sale(view.artwork.id));

    var updated = await repository.advanceShipment(sale.id);
    expect(updated.shipmentStatus, ShipmentStatus.dispatched);
    expect(updated.dispatchedAt, isNotNull);

    updated = await repository.advanceShipment(sale.id);
    expect(updated.shipmentStatus, ShipmentStatus.delivered);
    expect(updated.deliveredAt, isNotNull);

    await expectLater(
      repository.advanceShipment(sale.id),
      throwsA(isA<Exception>()),
    );
  });

  test('an aggregator who never raises the price still earns the markup share',
      () async {
    // GalleryZone's price to the aggregator already sits above the artist's,
    // so 20% of THAT gap is real money even with no uplift of their own. The
    // old code compared against GalleryZone's price and paid ₹0 here.
    final view = (await repository.listCollection()).firstWhere(
      (v) => v.holding.status == HoldingStatus.reserved,
    );
    final artistPrice = artistPriceOf(view.artwork);
    final sale = await repository.recordSale(_sale(view.artwork.id));

    final expected =
        (0.2 * (exGst(view.holding.displayPrice) - artistPrice)).round();
    expect(expected, greaterThan(0));
    expect((await repository.getWallet()).pendingBalance, expected);

    final settlement = await repository.processSettlement(sale.id);
    expect(settlement.aggregatorCommission, expected);
  });

  test('a sale below the artist price earns nothing, and cannot be settled',
      () async {
    // Not a bug: with no markup there is no share of a markup to take. The
    // repository says so rather than inventing a negative figure.
    final view = (await repository.listCollection()).firstWhere(
      (v) => v.holding.status == HoldingStatus.reserved,
    );
    // Reach past reserve, which will not price below the offer — this is about
    // what the commission does with such a number, not how one could be entered.
    MockDb.setCollection(
      'holdings',
      [
        for (final h in MockDb.getCollection('holdings', () => <AggregatorHolding>[],
            AggregatorHolding.fromJson, (h) => h.toJson()))
          if (h.id == view.holding.id)
            h.copyWith(displayPrice: withGst(artistPriceOf(view.artwork) - 1000))
          else
            h,
      ],
      (h) => h.toJson(),
    );

    final sale = await repository.recordSale(_sale(view.artwork.id));
    expect((await repository.getWallet()).pendingBalance, 0);
    await expectLater(
      repository.processSettlement(sale.id),
      throwsA(isA<Exception>()),
    );
  });

  test('only the last four digits of a bank account are ever stored', () async {
    final updated = await repository.updateBankDetails(
      accountNumber: '123456789012',
      ifsc: 'hdfc0001234',
    );
    expect(updated.bankAccountMasked, '•••• •••• •••• 9012');
    expect(updated.bankAccountMasked, isNot(contains('12345678')));
    expect(updated.ifsc, 'HDFC0001234');
  });

  test('analytics derive from live sales, not a fixture', () async {
    expect((await repository.getAnalytics()).salesCount, 0);

    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    await repository.recordSale(_sale(view.artwork.id, soldPrice: 40000));

    final analytics = await repository.getAnalytics();
    expect(analytics.salesCount, 1);
    expect(analytics.totalRevenue, 40000);
    expect(analytics.averageSoldPrice, 40000);
    expect(analytics.customerCount, 1);

    final categories = await repository.getCategoryPerformance();
    expect(categories, hasLength(1));
    expect(categories.single.category, view.artwork.category);
    expect(categories.single.revenue, 40000);
  });

  test('opening a message marks it read', () async {
    final unread = (await repository.listMessages()).firstWhere((m) => m.unread);
    await repository.markMessageRead(unread.id);

    final after =
        (await repository.listMessages()).firstWhere((m) => m.id == unread.id);
    expect(after.unread, isFalse);
  });

  test('a support ticket needs a subject and a message', () async {
    await expectLater(
      repository.submitSupportTicket(subject: '  ', message: 'Hello'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      repository.submitSupportTicket(subject: 'Hello', message: '  '),
      throwsA(isA<Exception>()),
    );

    await repository.submitSupportTicket(subject: 'Advance query', message: 'Details');
    final tickets = await repository.listSupportTickets();
    expect(tickets.first.subject, 'Advance query');
    expect(tickets.first.status, SupportTicketStatus.open);
  });
}
