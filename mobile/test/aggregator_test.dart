import 'package:flutter_test/flutter_test.dart';
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
    for (final artwork in reservable) {
      expect(claimed.contains(artwork.id), isFalse);
      expect(artwork.status, ArtworkStatus.marketplace);
      // Aggregator-eligible, not specifically marketplaceAndAggregator: an
      // aggregator-only piece is reservable here precisely because it never
      // appears in the online grid. Asserting the literal passed only while
      // no unclaimed aggregator-only fixture existed.
      expect(isAggregatorListed(artwork.listingType), isTrue);
    }
  });

  test('reserving opens at the floor price and cannot happen twice', () async {
    final artwork = (await repository.listReservableInventory()).first;
    final holding = await repository.reserve(artwork.id);

    expect(holding.displayPrice, artwork.customerPrice);
    expect(holding.status, HoldingStatus.reserved);
    expect(holding.assignmentSource, AssignmentSource.selfReserved);
    expect(holding.advancePercent, advancePercentFor(artwork.customerPrice));
    expect(
      DateTime.parse(holding.expiresAt).difference(DateTime.parse(holding.assignedAt)),
      holdingWindow,
    );

    // Gone from the browse grid, present in the collection.
    final reservable = await repository.listReservableInventory();
    expect(reservable.map((a) => a.id), isNot(contains(artwork.id)));
    expect(
      (await repository.listCollection()).map((v) => v.artwork.id),
      contains(artwork.id),
    );

    await expectLater(repository.reserve(artwork.id), throwsA(isA<Exception>()));
  });

  test('the display price floor is enforced by the repository, not just the form',
      () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    final floor = view.artwork.customerPrice;

    await expectLater(
      repository.updateDisplayPrice(view.holding.id, floor - 1),
      throwsA(isA<Exception>()),
    );

    final raised = await repository.updateDisplayPrice(view.holding.id, floor + 5000);
    expect(raised.displayPrice, floor + 5000);
  });

  test('a sale credits pending commission, and settling makes it withdrawable',
      () async {
    final view = (await repository.listCollection())
        .firstWhere((v) => v.holding.status == HoldingStatus.reserved);
    final floor = view.artwork.customerPrice;
    await repository.updateDisplayPrice(view.holding.id, floor + 10000);
    final expected = aggregatorCommissionFor(
      displayPrice: floor + 10000,
      customerPrice: floor,
    );
    expect(expected, 2000); // 20% of the 10,000 markup.

    final sale = await repository.recordSale(_sale(view.artwork.id));
    expect(sale.shipmentStatus, ShipmentStatus.preparing);
    expect(sale.courierRef, isNotNull);

    // Pending, not available: the money isn't withdrawable until settled.
    var wallet = await repository.getWallet();
    expect(wallet.pendingBalance, expected);
    expect(wallet.balance, 0);
    await expectLater(
      repository.requestWithdrawal(expected),
      throwsA(isA<Exception>()),
    );

    final settlement = await repository.processSettlement(sale.id);
    expect(settlement.aggregatorCommission, expected);
    expect(settlement.status, SettlementStatus.processed);

    wallet = await repository.getWallet();
    expect(wallet.pendingBalance, 0);
    expect(wallet.balance, expected);

    // One sale, one ledger line — the pending row became the settlement row.
    final transactions = await repository.listWalletTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.single.type, WalletTransactionType.settlement);
    expect(transactions.single.status, WalletTransactionStatus.completed);

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
    final artwork = (await repository.listReservableInventory()).first;
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

  test('a sale at the floor price earns nothing, and cannot be settled', () async {
    // Not a bug: with no markup there is no share of a markup to take. The
    // repository says so rather than inventing a figure.
    final view = (await repository.listCollection()).firstWhere(
      (v) =>
          v.holding.status == HoldingStatus.reserved &&
          v.holding.displayPrice == v.artwork.customerPrice,
      orElse: () => throw StateError('no floor-priced holding in the fixtures'),
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
