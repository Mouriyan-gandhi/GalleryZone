import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/mock/mock_checkout_repository.dart';
import 'package:gallery_zone/data/mock/mock_customer_repository.dart';
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The end-to-end demo chain: an artist lists a piece, it clears review, a
/// collector pays for it, the order is walked to delivery, and the artist is
/// paid. Every link here was missing before — an order used to sit at
/// `pending` forever and nothing ever left the review queue.

SubmitArtworkInput _input({bool asDraft = false, String title = 'Harbour Light'}) =>
    SubmitArtworkInput(
      title: title,
      description: 'A demo piece.',
      category: 'painting',
      medium: 'Oil on Canvas',
      artistPrice: 10000,
      listingType: ListingType.marketplaceOnly,
      insuranceOpted: false,
      images: const [
        ArtworkImage(
          url: '/artworks/bird.png',
          thumbnailUrl: '/artworks/bird.png',
          sortOrder: 0,
          altText: 'Harbour Light',
        ),
      ],
      asDraft: asDraft,
    );

/// Past the review delay without waiting it out.
void _runReview() =>
    promoteApprovedSubmissions(now: DateTime.now().add(demoReviewDelay).add(const Duration(seconds: 1)));

void main() {
  late MockArtistRepository artist;
  late MockArtworkRepository artworks;
  late MockCheckoutRepository checkout;
  late MockCustomerRepository customer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    artist = MockArtistRepository();
    artworks = MockArtworkRepository();
    checkout = MockCheckoutRepository();
    customer = MockCustomerRepository();
  });

  group('review', () {
    test('a submission goes live only after the review delay', () async {
      final submitted = await artist.submitArtwork(_input());
      expect(submitted.status, ArtworkStatus.pendingApproval);

      // Nothing has elapsed yet, so it is still off the marketplace.
      var live = await artworks.list(const ArtworkFilters());
      expect(live.map((a) => a.id), isNot(contains(submitted.id)));

      _runReview();

      live = await artworks.list(const ArtworkFilters());
      expect(live.map((a) => a.id), contains(submitted.id));
      final approved = live.firstWhere((a) => a.id == submitted.id);
      expect(approved.status, ArtworkStatus.marketplace);
      expect(approved.statusHistory.last.status, ArtworkStatus.marketplace);

      final activity = await artist.listActivity();
      expect(activity.first.title, contains('was approved'));
    });

    test('a draft never enters review on its own', () async {
      final draft = await artist.submitArtwork(_input(asDraft: true, title: 'A draft'));
      _runReview();

      final live = await artworks.list(const ArtworkFilters());
      expect(live.map((a) => a.id), isNot(contains(draft.id)));

      // Sending it explicitly is what starts the clock.
      await artist.submitForReview(draft.id);
      _runReview();
      expect(
        (await artworks.list(const ArtworkFilters())).map((a) => a.id),
        contains(draft.id),
      );
    });

    test('the seeded in-review fixture stays in review', () async {
      // aw-2 has been "in review" since long before the app started. It must
      // not be swept up by the demo approval.
      _runReview();
      final live = await artworks.list(const ArtworkFilters());
      expect(live.map((a) => a.id), isNot(contains('aw-2')));
    });
  });

  group('payment', () {
    test('a declined payment places no order and leaves the piece for sale', () async {
      expect(
        checkout.createOrder(
          artworkId: 'aw-5',
          addressId: 'addr-home-pune',
          paymentMethod: PaymentMethod.card,
          simulateFailure: true,
        ),
        throwsA(isA<Exception>()),
      );

      final live = await artworks.list(const ArtworkFilters());
      expect(live.map((a) => a.id), contains('aw-5'));
    });
  });

  group('the full chain', () {
    test('list, approve, pay, deliver, get paid', () async {
      final submitted = await artist.submitArtwork(_input());
      _runReview();

      final walletBefore = await artist.getWallet();
      final order = await checkout.createOrder(
        artworkId: submitted.id,
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.upi,
      );
      expect(order.status, OrderStatus.paid);

      // The piece stays in the grid but stops being buyable — it carries a
      // "Sold" badge there, the same as the web. What must not happen is a
      // second sale of a one-of-a-kind original.
      final listed = await artworks.list(const ArtworkFilters());
      expect(listed.firstWhere((a) => a.id == submitted.id).status, ArtworkStatus.sold);
      expect(
        checkout.createOrder(
          artworkId: submitted.id,
          addressId: 'addr-home-pune',
          paymentMethod: PaymentMethod.upi,
        ),
        throwsA(isA<Exception>()),
      );

      // The artist is credited — pending, not withdrawable.
      final payout = artistPayoutFor(10000);
      var wallet = await artist.getWallet();
      expect(wallet.pendingBalance, walletBefore.pendingBalance + payout);
      expect(wallet.balance, walletBefore.balance);
      expect((await artist.listWalletTransactions()).first.status,
          WalletTransactionStatus.pending);

      // Nothing is in the collection until it is actually delivered.
      expect(
        (await customer.listCollection()).map((item) => item.artwork.id),
        isNot(contains(submitted.id)),
      );

      var current = order;
      while (current.status != OrderStatus.delivered) {
        current = await checkout.advanceOrder(order.id);
      }
      expect(current.statusHistory.last.status, OrderStatus.delivered);

      // Delivery moves the record, but NOT yet the money: the money-flow
      // sheets pay the artist within 7 days of delivery, so delivery only
      // starts the clock.
      final delivered = await artworks.get(submitted.id);
      expect(delivered!.status, ArtworkStatus.delivered);
      expect(resolveCustody(delivered).legalOwner, CustodyParty.customer);
      expect(resolveCustody(delivered).custodian, CustodyParty.customer);

      wallet = await artist.getWallet();
      expect(wallet.pendingBalance, walletBefore.pendingBalance + payout,
          reason: 'still pending — the 7 days have not run');
      expect(wallet.balance, walletBefore.balance);

      var settlements = await artist.listSettlements();
      expect(settlements.first.orderId, order.id);
      expect(settlements.first.artistAmount, payout);
      expect(settlements.first.status, SettlementStatus.pending);
      expect(settlements.first.releaseAfter, isNotNull,
          reason: 'delivery stamps the release date');

      // Seven days on, the money is withdrawable. Nothing runs on a timer, so
      // this backdates the delivery and reads the wallet, which is where the
      // release actually happens.
      simulateDeliveryAndRelease(settlements.first.id);

      wallet = await artist.getWallet();
      expect(wallet.pendingBalance, walletBefore.pendingBalance);
      expect(wallet.balance, walletBefore.balance + payout);

      settlements = await artist.listSettlements();
      expect(settlements.first.status, SettlementStatus.processed);

      // One sale, one ledger line: the pending row became the settlement row
      // rather than a second entry appearing beside it.
      final transactions = await artist.listWalletTransactions();
      expect(
        transactions.where((t) => t.label.contains(submitted.title)),
        hasLength(1),
      );
      expect(transactions.first.status, WalletTransactionStatus.completed);

      expect(
        (await customer.listCollection()).map((item) => item.artwork.id),
        contains(submitted.id),
      );
    });

    test('a delivered order cannot be advanced again', () async {
      final submitted = await artist.submitArtwork(_input(title: 'One more'));
      _runReview();
      final order = await checkout.createOrder(
        artworkId: submitted.id,
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.netbanking,
      );

      var current = order;
      while (current.status != OrderStatus.delivered) {
        current = await checkout.advanceOrder(order.id);
      }
      expect(checkout.advanceOrder(order.id), throwsA(isA<Exception>()));

      // And releasing twice never doubles the artist's money — a settlement
      // leaves `pending` on the first release and is never seen again.
      final settlement = (await artist.listSettlements())
          .firstWhere((s) => s.orderId == order.id);
      simulateDeliveryAndRelease(settlement.id);
      final balance = (await artist.getWallet()).balance;
      simulateDeliveryAndRelease(settlement.id);
      releaseDueArtistSettlements();
      expect((await artist.getWallet()).balance, balance);
    });
  });
}
