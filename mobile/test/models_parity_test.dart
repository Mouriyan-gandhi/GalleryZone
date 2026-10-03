import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/marketplace.dart';
import 'package:gallery_zone/data/models/order.dart';

Map<String, dynamic> _artworkJson({Object? rarity = 'S'}) => {
      'id': 'aw-1',
      'title': 'Monsoon',
      'artistId': 'ar-1',
      'artistName': 'Ananya Rao',
      'verifiedArtist': false,
      'category': 'painting',
      'medium': 'oil',
      'customerPrice': 48000.0,
      'thumbnailUrl': 'https://x/y.png',
      'insured': false,
      'status': 'marketplace',
      'listingType': 'marketplace_only',
      'description': '',
      'images': <Object>[],
      'socialProofLinks': <Object>[],
      'statusHistory': <Object>[],
      'rarityType': rarity,
    };

void main() {
  group('rank', () {
    test('reads S, and the retired N as Standard', () {
      expect(artworkRarityFromCode('S'), ArtworkRarity.standard);
      expect(artworkRarityFromCode('N'), ArtworkRarity.standard);
      expect(artworkRarityFromCode('R'), ArtworkRarity.rare);
      expect(artworkRarityFromCode('U'), ArtworkRarity.unique);
      expect(artworkRarityFromCode('O'), ArtworkRarity.original);
    });

    test('anything unrecognised is unranked, not a crash', () {
      expect(artworkRarityFromCode(null), isNull);
      expect(artworkRarityFromCode('Z'), isNull);
    });

    test('saved data with the old N code still loads, and is written back as S', () {
      final artwork = Artwork.fromJson(_artworkJson(rarity: 'N'));
      expect(artwork.rarityType, ArtworkRarity.standard);
      expect(artwork.toJson()['rarityType'], 'S');
    });

    test('an unranked piece round-trips as null', () {
      final artwork = Artwork.fromJson(_artworkJson(rarity: null));
      expect(artwork.rarityType, isNull);
      expect(artwork.toJson()['rarityType'], isNull);
    });

    test('labels are the words the website uses', () {
      expect(artworkRarityLabel[ArtworkRarity.standard], 'Standard');
      expect(artworkRarityCode[ArtworkRarity.standard], 'S');
    });
  });

  group('artwork without a certificate', () {
    test('the marketplace no longer carries one, so the fields default to empty', () {
      final artwork = Artwork.fromJson(_artworkJson());
      expect(artwork.coaCertificateNumber, '');
      expect(artwork.coaIssueDate, '');
      expect(artwork.insuranceStatus, ReviewStatus.notSubmitted);
      expect(artwork.productCode, isNull);
    });
  });

  group('review status', () {
    test('maps the four wire values and defaults to not submitted', () {
      expect(reviewStatusFromCode('submitted'), ReviewStatus.submitted);
      expect(reviewStatusFromCode('approved'), ReviewStatus.approved);
      expect(reviewStatusFromCode('rejected'), ReviewStatus.rejected);
      expect(reviewStatusFromCode('not_submitted'), ReviewStatus.notSubmitted);
      expect(reviewStatusFromCode(null), ReviewStatus.notSubmitted);
    });
  });

  group('order total', () {
    Order order({double fee = 0, double feeGst = 0}) => Order(
          id: 'o1',
          artworkId: 'aw-1',
          addressId: 'ad-1',
          amount: 136500,
          gstAmount: 6500,
          deliveryCharge: 2500,
          status: OrderStatus.paid,
          createdAt: '2026-10-01T00:00:00Z',
          statusHistory: const [],
          convenienceFee: fee,
          convenienceGst: feeGst,
        );

    test('GST is inside the price, so it is not added again', () {
      expect(order().total, 139000);
    });

    test('the convenience fee and its own GST do add on', () {
      expect(order(fee: 100, feeGst: 18).total, 139118);
    });
  });

  group('collection item', () {
    test('a bought piece reports what was paid; a hand-over reports nothing', () {
      final artwork = Artwork.fromJson(_artworkJson());
      final bought = CollectionItem(
        artwork: artwork,
        order: Order(
          id: 'o1',
          artworkId: 'aw-1',
          addressId: 'ad-1',
          amount: 1000,
          gstAmount: 48,
          deliveryCharge: 250,
          status: OrderStatus.delivered,
          createdAt: '2026-10-01T00:00:00Z',
          statusHistory: const [],
        ),
      );
      expect(bought.paidPrice, 1250);
      expect(CollectionItem(artwork: artwork, source: CollectionSource.transfer).paidPrice, 0);
    });
  });

  group('marketplace page', () {
    test('knows whether there is another page', () {
      const first = MarketplacePage(artworks: [], total: 45, page: 1, pageSize: 20);
      const last = MarketplacePage(artworks: [], total: 45, page: 3, pageSize: 20);
      expect(first.hasMore, isTrue);
      expect(last.hasMore, isFalse);
    });
  });
}
