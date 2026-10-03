import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/api/api_error.dart';
import 'package:gallery_zone/core/payments/payment_gateway.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/artwork_filters.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/remote/remote_artwork_repository.dart';
import 'package:gallery_zone/data/remote/remote_checkout_repository.dart';
import 'package:gallery_zone/data/remote/remote_ownership_repository.dart';

import 'support/fake_api.dart';

Object? _fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

class _Gateway implements PaymentGateway {
  _Gateway({this.dismiss = false});

  final bool dismiss;
  GatewaySession? opened;

  @override
  Future<GatewayPayment> pay(GatewaySession session) async {
    opened = session;
    if (dismiss) throw const PaymentDismissedException();
    return GatewayPayment(orderId: session.gatewayOrderId, paymentId: 'pay_123', signature: 'sig_abc');
  }
}

Map<String, dynamic> _order(String status, {Map<String, dynamic>? payment}) => {
      'id': 'ord1',
      'artworkId': 'aw1',
      'customerId': 'u1',
      'addressId': 'ad1',
      'displayPricePaise': 13650000,
      'gstPaise': 650000,
      'deliveryChargePaise': 250000,
      'convenienceFeePaise': 0,
      'convenienceGstPaise': 0,
      'totalPaise': 13900000,
      'status': status,
      'rateConfigVersionId': 'v1',
      // Routes that spread a raw Firestore document send timestamps like this.
      'createdAt': {'_seconds': 1790000000, '_nanoseconds': 0},
      'payment': ?payment,
      'artwork': {
        'title': 'Monsoon',
        'artistName': 'Test Artist 1',
        'artistId': 'artist-1',
        'thumbnailUrl': null,
        'productCode': 'GZ000004',
      },
    };

void main() {
  group('RemoteArtworkRepository', () {
    test('turns filters into the query the API understands', () {
      final query = RemoteArtworkRepository.queryOf(
        const ArtworkFilters(
          categories: ['painting', 'sculpture'],
          mediums: ['oil'],
          rarity: ArtworkRarity.standard,
          artistId: 'artist-1',
          location: 'Pune, Maharashtra',
          size: ArtworkSizeBand.large,
          minPrice: 10000,
          maxPrice: 250000.5,
          query: '  monsoon ',
          sortBy: ArtworkSortBy.priceDesc,
          page: 3,
        ),
      );
      expect(query, {
        'pageSize': '20',
        'category': 'painting,sculpture',
        'medium': 'oil',
        'rarity': 'S',
        'artistId': 'artist-1',
        'location': 'Pune, Maharashtra',
        'size': 'large',
        'minPricePaise': '1000000',
        'maxPricePaise': '25000050',
        'q': 'monsoon',
        'sort': 'price_desc',
        'page': '3',
      });
    });

    test('the default view sends nothing but the page size', () {
      expect(RemoteArtworkRepository.queryOf(const ArtworkFilters()), {'pageSize': '20'});
    });

    test('reads a real listing page: paise become rupees, facets come through', () async {
      final api = FakeApi()..json('GET /v1/artworks', _fixture('live_artworks_page.json'));
      final page = await RemoteArtworkRepository(api.client()).list(const ArtworkFilters());

      expect(page.total, 4);
      expect(page.artworks, hasLength(3));
      final first = page.artworks.first;
      expect(first.customerPrice, 25290.72);
      expect(first.status, ArtworkStatus.marketplace);
      expect(first.listingType, ListingType.marketplaceAndAggregator);
      expect(first.productCode, 'GZ000004');
      expect(first.artistLocation, 'Udaipur, Rajasthan');
      expect(first.sizeBand, ArtworkSizeBand.small);
      expect(first.rarityType, isNull, reason: 'nobody has ranked it yet');
      // The marketplace no longer carries a certificate.
      expect(first.coaCertificateNumber, '');
      // The cover is the first image, by sort order.
      expect(first.thumbnailUrl, startsWith('https://api-production-9fd9.up.railway.app/v1/images/'));

      expect(page.facets.categories, contains('painting'));
      expect(page.facets.artists, hasLength(2));
      expect(page.facets.priceMin, 6825);
      expect(page.facets.priceMax, 136500);
      expect(page.hasMore, isTrue, reason: '3 of 4 on page 1 at pageSize 3');
    });

    test('the public catalogue never sends a credential', () async {
      final api = FakeApi()..json('GET /v1/artworks', _fixture('live_artworks_page.json'));
      await RemoteArtworkRepository(api.client()).list(const ArtworkFilters());
      expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('an unknown piece is null, not an error', () async {
      final api = FakeApi()..problem('GET /v1/artworks/nope', 404, 'not_found', 'Not found');
      expect(await RemoteArtworkRepository(api.client()).get('nope'), isNull);
    });

    test('a piece with no photo reads as an empty image, for an honest placeholder', () async {
      final api = FakeApi()
        ..json('GET /v1/artworks/aw1', {
          'id': 'aw1',
          'title': 'Bare',
          'artistId': 'a',
          'artistName': 'A',
          'category': 'painting',
          'medium': 'oil',
          'displayPricePaise': 100000,
          'status': 'marketplace',
          'listingType': 'marketplace_only',
          'images': <Object>[],
          'rarityType': 'N',
        });
      final artwork = (await RemoteArtworkRepository(api.client()).get('aw1'))!;
      expect(artwork.thumbnailUrl, '');
      expect(artwork.rarityType, ArtworkRarity.standard, reason: 'the old N reads as S');
    });

    test('getMany leaves out what no longer resolves and keeps the order asked for', () async {
      Map<String, dynamic> piece(String id) => {
            'id': id,
            'title': id,
            'artistId': 'a',
            'artistName': 'A',
            'category': 'painting',
            'medium': 'oil',
            'displayPricePaise': 100,
            'status': 'sold',
            'listingType': 'marketplace_only',
            'images': <Object>[],
          };
      final api = FakeApi()
        ..json('GET /v1/artworks/b', piece('b'))
        ..json('GET /v1/artworks/a', piece('a'))
        ..problem('GET /v1/artworks/gone', 404, 'not_found', 'Not found');
      final found = await RemoteArtworkRepository(api.client()).getMany(['b', 'gone', 'a']);
      expect(found.map((a) => a.id), ['b', 'a']);
    });
  });

  group('RemoteCheckoutRepository', () {
    test('quote reads the server figures and sends no credential', () async {
      final api = FakeApi()
        ..json('GET /v1/artworks/aw1/quote', {
          'artworkId': 'aw1',
          'displayPricePaise': 13650000,
          'gstPaise': 650000,
          'gstRate': 0.05,
          'convenienceFeePaise': 10000,
          'convenienceGstPaise': 1800,
          'deliveryChargePaise': 250000,
          'totalPaise': 13911800,
        });
      final quote = await RemoteCheckoutRepository(api: api.client(), gateway: _Gateway()).getQuote('aw1');
      expect(quote.displayPrice, 136500);
      expect(quote.gstIncluded, 6500);
      expect(quote.convenienceFee, 100);
      expect(quote.convenienceGst, 18);
      expect(quote.deliveryCharge, 2500);
      expect(quote.total, 139118);
      expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('real gateway: order, session, signed payment, verify, read back', () async {
      final gateway = _Gateway();
      final api = FakeApi()
        ..json('POST /v1/orders', {'orderId': 'ord1', 'totalPaise': 13900000}, status: 201)
        ..json('POST /v1/orders/ord1/payment/session', {
          'mode': 'razorpay',
          'keyId': 'rzp_test_x',
          'razorpayOrderId': 'order_9A',
          'amountPaise': 13900000,
          'currency': 'INR',
          'name': 'GalleryZone',
          'description': 'Monsoon (GZ000004)',
          'prefill': {'name': 'A', 'email': 'a@b.co', 'contact': '9999999999'},
        }, status: 201)
        ..json('POST /v1/orders/ord1/payment/verify', {'status': 'paid', 'transactionId': 't'}, status: 201)
        ..json('GET /v1/orders/ord1', _order('paid', payment: {'status': 'captured', 'method': 'card', 'providerPaymentId': 'pay_123'}));

      final order = await RemoteCheckoutRepository(api: api.client(), gateway: gateway)
          .createOrder(artworkId: 'aw1', addressId: 'ad1', paymentMethod: PaymentMethod.card);

      expect(api.calls, [
        'POST /v1/orders',
        'POST /v1/orders/ord1/payment/session',
        'POST /v1/orders/ord1/payment/verify',
        'GET /v1/orders/ord1',
      ]);
      final created = api.bodiesOf('POST /v1/orders').single as Map;
      expect(created['artworkId'], 'aw1');
      expect(created['addressId'], 'ad1');
      expect((created['idempotencyKey'] as String).length, greaterThanOrEqualTo(16));
      expect(gateway.opened!.keyId, 'rzp_test_x');
      expect(api.bodiesOf('POST /v1/orders/ord1/payment/verify').single, {
        'razorpayOrderId': 'order_9A',
        'razorpayPaymentId': 'pay_123',
        'signature': 'sig_abc',
      });

      expect(order.status, OrderStatus.paid);
      expect(order.amount, 136500);
      expect(order.total, 139000, reason: 'GST is inside the price; delivery adds on');
      expect(order.payment!.paymentId, 'pay_123');
      expect(order.payment!.simulated, isFalse);
      expect(order.createdAt, startsWith('2026-'), reason: 'a Firestore timestamp object reads as ISO');
      expect(order.artwork!.title, 'Monsoon');
    });

    test('simulated mode: the buyer\'s own simulate call, no gateway sheet', () async {
      final gateway = _Gateway();
      final api = FakeApi()
        ..json('POST /v1/orders', {'orderId': 'ord1', 'totalPaise': 1}, status: 201)
        ..json('POST /v1/orders/ord1/payment/session', {'mode': 'simulated'}, status: 201)
        ..json('POST /v1/orders/ord1/simulate-payment', {'status': 'paid'}, status: 201)
        ..json('GET /v1/orders/ord1', _order('paid', payment: {'status': 'captured', 'method': 'simulated', 'providerPaymentId': null}));
      final order = await RemoteCheckoutRepository(api: api.client(), gateway: gateway)
          .createOrder(artworkId: 'aw1', addressId: 'ad1', paymentMethod: PaymentMethod.upi);
      expect(gateway.opened, isNull);
      expect(order.payment!.simulated, isTrue);
    });

    test('closing the payment sheet charges nothing and never verifies', () async {
      final api = FakeApi()
        ..json('POST /v1/orders', {'orderId': 'ord1', 'totalPaise': 1}, status: 201)
        ..json('POST /v1/orders/ord1/payment/session', {
          'mode': 'razorpay',
          'keyId': 'k',
          'razorpayOrderId': 'o',
          'amountPaise': 1,
        }, status: 201);
      await expectLater(
        RemoteCheckoutRepository(api: api.client(), gateway: _Gateway(dismiss: true))
            .createOrder(artworkId: 'aw1', addressId: 'ad1', paymentMethod: PaymentMethod.card),
        throwsA(isA<PaymentDismissedException>()),
      );
      expect(api.calls.any((c) => c.contains('verify')), isFalse);
    });

    test('a piece that is gone is refused before any money moves', () async {
      final api = FakeApi()
        ..problem('POST /v1/orders', 409, 'conflict', 'This artwork is not available to buy');
      await expectLater(
        RemoteCheckoutRepository(api: api.client(), gateway: _Gateway())
            .createOrder(artworkId: 'aw1', addressId: 'ad1', paymentMethod: PaymentMethod.card),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'This artwork is not available to buy')),
      );
    });

    test('an order that is not yours reads as missing', () async {
      final api = FakeApi()..problem('GET /v1/orders/x', 404, 'not_found', 'Not found');
      expect(await RemoteCheckoutRepository(api: api.client(), gateway: _Gateway()).getOrder('x'), isNull);
    });
  });

  group('RemoteOwnershipRepository', () {
    test('a display loan is sent with an ISO end date; an ownership gift with none', () async {
      final api = FakeApi()
        ..json('POST /v1/artworks/aw1/transfers', {
          'id': 'aw1.ev1',
          'artworkId': 'aw1',
          'artworkTitle': 'Monsoon',
          'kind': 'display',
          'status': 'pending',
          'fromName': 'Me',
          'toName': 'Gallery',
          'toEmail': 'g@x.co',
          'viaSale': false,
          'initiatedAt': '2026-10-02T10:00:00.000Z',
          'acceptedAt': null,
          'cancelledAt': null,
          'displayEndsAt': '2026-11-01T00:00:00.000Z',
          'displayEndedAt': null,
        }, status: 201);
      final repo = RemoteOwnershipRepository(api.client());
      final loan = await repo.initiate(
        artworkId: 'aw1',
        fromName: 'ignored',
        toName: ' Gallery ',
        toEmail: ' g@x.co ',
        kind: TransferKind.display,
        displayEndsAt: '2026-11-01',
      );
      final sent = api.bodiesOf('POST /v1/artworks/aw1/transfers').single as Map;
      expect(sent['kind'], 'display');
      expect(sent['toName'], 'Gallery');
      expect(sent['toEmail'], 'g@x.co');
      expect(sent['displayEndsAt'], '2026-11-01T00:00:00.000Z');
      expect(sent.containsKey('fromName'), isFalse, reason: 'the sender is whoever is signed in');
      expect(loan.kind, TransferKind.display);
      expect(loan.status, TransferStatus.pending);
    });

    test('a display loan without an end date is refused before it is sent', () async {
      final api = FakeApi();
      await expectLater(
        RemoteOwnershipRepository(api.client()).initiate(
          artworkId: 'aw1',
          fromName: '',
          toName: 'G',
          toEmail: 'g@x.co',
          kind: TransferKind.display,
        ),
        throwsA(isA<Exception>()),
      );
      expect(api.requests, isEmpty);
    });

    test('the history of a piece is its public passport, newest first', () async {
      final api = FakeApi()
        ..json('GET /v1/verify/aw1', {
          'artworkId': 'aw1',
          'productCode': 'GZ000004',
          'title': 'Monsoon',
          'artistId': 'a',
          'artistName': 'A',
          'category': 'painting',
          'medium': 'oil',
          'dimensions': null,
          'yearCreated': 2024,
          'images': <Object>[],
          'status': 'sold',
          'coaCertificateNumber': 'GZ-COA-2026-0001',
          'coaIssuedAt': '2026-09-16T00:00:00.000Z',
          'listedAt': '2026-09-16T00:00:00.000Z',
          'owner': {'kind': 'collector', 'displayName': 'Priya'},
          'events': [
            {
              'id': 'aw1.e1',
              'kind': 'ownership',
              'status': 'accepted',
              'fromName': 'A',
              'toName': 'Priya',
              'viaSale': true,
              'initiatedAt': '2026-09-20T00:00:00.000Z',
              'acceptedAt': '2026-09-20T00:00:00.000Z',
              'cancelledAt': null,
              'displayEndsAt': null,
              'displayEndedAt': null,
            },
            {
              'id': 'aw1.e2',
              'kind': 'ownership',
              'status': 'accepted',
              'fromName': 'Priya',
              'toName': 'Ravi',
              'viaSale': false,
              'initiatedAt': '2026-09-25T00:00:00.000Z',
              'acceptedAt': '2026-09-26T00:00:00.000Z',
              'cancelledAt': null,
              'displayEndsAt': null,
              'displayEndedAt': null,
            },
          ],
        });
      final repo = RemoteOwnershipRepository(api.client());
      final history = await repo.listForArtwork('aw1');
      expect(history.map((t) => t.toName), ['Ravi', 'Priya']);
      expect(history.every((t) => t.toEmail.isEmpty), isTrue, reason: 'a scan never shows an email');

      final passport = (await repo.getPassport('aw1'))!;
      expect(passport.coaCertificateNumber, 'GZ-COA-2026-0001');
      expect(passport.ownerName, 'Priya');
      expect(api.requests.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    });
  });
}
