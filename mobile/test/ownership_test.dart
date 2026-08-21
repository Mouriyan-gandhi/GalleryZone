import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/mock/mock_checkout_repository.dart';
import 'package:gallery_zone/data/mock/mock_customer_repository.dart';
import 'package:gallery_zone/data/mock/mock_ownership_repository.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ownership transfer, resale and the paper certificate — the `e1b65fc`
/// features, plus the resale loop that runs through them.

void main() {
  late MockOwnershipRepository ownership;
  late MockArtworkRepository artworks;
  late MockCustomerRepository customer;
  late MockCheckoutRepository checkout;
  late MockArtistRepository artist;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    ownership = MockOwnershipRepository();
    artworks = MockArtworkRepository();
    customer = MockCustomerRepository();
    checkout = MockCheckoutRepository();
    artist = MockArtistRepository();
  });

  group('ownership transfer', () {
    test('ownership moves only when the recipient accepts', () async {
      final transfer = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Meera Rao',
        toName: 'Anil Kumar',
        toEmail: 'anil@example.com',
      );
      expect(transfer.status, TransferStatus.pending);

      // Nothing on the artwork has changed yet — that is the whole point of
      // an accept step.
      var artwork = await artworks.get('aw-1');
      expect(resolveCustody(artwork!).legalOwnerName, isNull);

      await ownership.accept(transfer.id);
      artwork = await artworks.get('aw-1');
      final custody = resolveCustody(artwork!);
      expect(custody.legalOwner, CustodyParty.customer);
      expect(custody.legalOwnerName, 'Anil Kumar');
      expect(custody.locationLabel, 'With Anil Kumar');
    });

    test('only one transfer can be open per artwork', () async {
      await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Meera Rao',
        toName: 'Anil Kumar',
        toEmail: 'anil@example.com',
      );
      // Two pending transfers would let two people each claim the same piece.
      expect(
        ownership.initiate(
          artworkId: 'aw-1',
          fromName: 'Meera Rao',
          toName: 'Someone Else',
          toEmail: 'else@example.com',
        ),
        throwsA(isA<Exception>()),
      );

      // Cancelling frees it up again.
      final open = (await ownership.listForArtwork('aw-1')).single;
      await ownership.cancel(open.id);
      final second = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Meera Rao',
        toName: 'Someone Else',
        toEmail: 'else@example.com',
      );
      expect(second.status, TransferStatus.pending);
    });

    test('a cancelled transfer cannot be accepted', () async {
      final transfer = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Meera Rao',
        toName: 'Anil Kumar',
        toEmail: 'anil@example.com',
      );
      await ownership.cancel(transfer.id);
      expect(ownership.accept(transfer.id), throwsA(isA<Exception>()));
    });

    test('an invalid email is refused', () async {
      expect(
        ownership.initiate(
          artworkId: 'aw-1',
          fromName: 'Meera Rao',
          toName: 'Anil Kumar',
          toEmail: 'not-an-email',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('resale', () {
    /// A delivered piece in the collector's hands, ready to be resold.
    Future<String> ownAPiece() async {
      final order = await checkout.createOrder(
        artworkId: 'monsoon-over-madurai',
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.upi,
      );
      var current = order;
      while (current.status != OrderStatus.delivered) {
        current = await checkout.advanceOrder(order.id);
      }
      return 'monsoon-over-madurai';
    }

    test('listing puts the piece back on the marketplace at the asking price', () async {
      final artworkId = await ownAPiece();
      await customer.createResaleListing(artworkId: artworkId, listedPrice: 99000);

      final listed = (await artworks.list(const ArtworkFilters()))
          .firstWhere((a) => a.id == artworkId);
      expect(listed.status, ArtworkStatus.marketplace);
      expect(listed.customerPrice, 99000);

      // Withdrawing takes it off again.
      final listing = (await customer.listResaleListings()).first;
      await customer.withdrawResaleListing(listing.id);
      expect((await artworks.get(artworkId))!.status, ArtworkStatus.delivered);
    });

    test('the reseller is paid for a resale, not the artist', () async {
      final artworkId = await ownAPiece();
      await customer.createResaleListing(artworkId: artworkId, listedPrice: 99000);

      final artistWalletBefore = await artist.getWallet();
      final sellerWalletBefore = await customer.getWallet();

      final order = await checkout.createOrder(
        artworkId: artworkId,
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.card,
      );
      // The listing closes at purchase, not at delivery — it is no longer
      // available to anyone else the moment it is bought.
      expect(
        (await customer.listResaleListings()).first.status,
        ResaleListingStatus.sold,
      );

      var seller = await customer.getWallet();
      expect(seller.pendingBalance, sellerWalletBefore.pendingBalance + 99000);
      expect(
        (await artist.getWallet()).pendingBalance,
        artistWalletBefore.pendingBalance,
        reason: 'the artist was already paid when this piece first sold',
      );

      var current = order;
      while (current.status != OrderStatus.delivered) {
        current = await checkout.advanceOrder(order.id);
      }
      seller = await customer.getWallet();
      expect(seller.pendingBalance, sellerWalletBefore.pendingBalance);
      expect(seller.balance, sellerWalletBefore.balance + 99000);
    });

    test('a piece cannot be listed for resale twice at once', () async {
      final artworkId = await ownAPiece();
      await customer.createResaleListing(artworkId: artworkId, listedPrice: 99000);
      expect(
        customer.createResaleListing(artworkId: artworkId, listedPrice: 120000),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('paper certificate', () {
    test('a request reaches the artist and can be dispatched once', () async {
      final request = await customer.requestPhysicalCoa(
        artworkId: 'aw-1',
        deliveryAddress: '12 Laburnum Road, Pune 411001',
      );
      expect(request.status, PhysicalCoaStatus.requested);

      // One shared collection: what the collector wrote is what the artist reads.
      final queue = await artist.listPhysicalCoaRequests();
      expect(queue.single.id, request.id);

      final dispatched = await artist.dispatchPhysicalCoa(request.id, 'BD-4471');
      expect(dispatched.status, PhysicalCoaStatus.dispatched);
      expect(dispatched.courierRef, 'BD-4471');
      expect(artist.dispatchPhysicalCoa(request.id, 'BD-4471'), throwsA(isA<Exception>()));
    });

    test('the same piece cannot be requested twice while one is open', () async {
      await customer.requestPhysicalCoa(
        artworkId: 'aw-1',
        deliveryAddress: '12 Laburnum Road, Pune 411001',
      );
      expect(
        customer.requestPhysicalCoa(
          artworkId: 'aw-1',
          deliveryAddress: '12 Laburnum Road, Pune 411001',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('framing', () {
    test('aggregator readiness names exactly what is missing', () {
      expect(missingForAggregator(null), contains('weight'));

      const rolled = ArtworkPhysical(
        weightKg: 4,
        framing: FramingState.unframedRolled,
        format: 'canvas',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      );
      expect(
        missingForAggregator(rolled),
        ['framed or stretched-canvas presentation'],
      );

      const ready = ArtworkPhysical(
        weightKg: 4,
        framing: FramingState.framed,
        format: 'canvas',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      );
      expect(missingForAggregator(ready), isEmpty);
    });
  });
}
