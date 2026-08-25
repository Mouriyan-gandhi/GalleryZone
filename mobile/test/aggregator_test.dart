import 'package:flutter_test/flutter_test.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

const _address = DeliveryAddress(
  line1: '14 Church Street',
  city: 'Bengaluru',
  state: 'Karnataka',
  pincode: '560001',
);

RecordSaleInput _sale(String artworkId, {double soldPrice = 50000, String email = 'buyer@example.com'}) =>
    RecordSaleInput(
      artworkId: artworkId,
      soldPrice: soldPrice,
      buyerName: 'Anita Sen',
      buyerEmail: email,
      buyerPhone: '9845012345',
      deliveryAddress: _address,
      deliveryMode: DeliveryMode.courier,
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
    await repository.acceptMou(signatureName: 'Meher Kapadia', version: 'v1');
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
    expect(holding.advanceAmount, aggregatorAdvanceOf(item.offer.offerPrice));
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
    await fresh.acceptMou(signatureName: 'Meher Kapadia', version: 'v1');
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
    // 3%, because the first aggregator never used their price change.
    expect(second.offer.advanceRate, 0.03);
  });

  test('only the first aggregator of a cycle may price the piece', () async {
    final first = (await repository.listReservableInventory()).first;
    final holding = await repository.reserve(first.artwork.id);
    await repository.releaseHolding(holding.id);

    final second = await repository.reserve(first.artwork.id);
    expect(second.cycleMonth, 2);
    await expectLater(
      repository.updateDisplayPrice(second.id, second.displayPrice + 5000),
      throwsA(isA<Exception>()),
    );
  });

  test('the display price floor is enforced by the repository, not just the form',
      () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    final floor = view.holding.displayPrice;

    await expectLater(
      repository.updateDisplayPrice(view.holding.id, floor - 1),
      throwsA(isA<Exception>()),
    );

    final raised = await repository.updateDisplayPrice(view.holding.id, floor + 5000);
    expect(raised.displayPrice, floor + 5000);
    expect(raised.displayPriceSetAt, isNotNull);

    // MOU §6: one opportunity only, enforced here and not just by hiding the
    // button.
    await expectLater(
      repository.updateDisplayPrice(view.holding.id, floor + 9000),
      throwsA(isA<Exception>()),
    );
  });

  test('a sale credits pending commission, and settling makes it withdrawable',
      () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    final floor = view.holding.displayPrice;
    await repository.updateDisplayPrice(view.holding.id, floor + 10000);
    // MOU §8: 20% of the markup over the ARTIST's price, both before GST —
    // not over GalleryZone's price to the aggregator, which is what the old
    // formula compared against and paid far too little for.
    final expected = aggregatorCommissionFor(
      displayPrice: floor + 10000,
      artistPrice: artistPriceOf(view.artwork),
    );
    expect(
      expected,
      (0.2 * (exGst(floor + 10000) - artistPriceOf(view.artwork))).round(),
    );

    final sale = await repository.recordSale(_sale(view.artwork.id));
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
    // Reach past updateDisplayPrice, which will not price below the offer —
    // this is about what the commission does with such a number, not how one
    // could be entered.
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
