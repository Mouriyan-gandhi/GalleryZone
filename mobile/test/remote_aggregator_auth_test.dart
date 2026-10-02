import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/api/api_error.dart';
import 'package:gallery_zone/core/auth/firebase_rest_auth.dart';
import 'package:gallery_zone/core/auth/token_manager.dart';
import 'package:gallery_zone/core/payments/payment_gateway.dart';
import 'package:gallery_zone/core/pricing.dart' show AdvanceBasis;
import 'package:gallery_zone/data/models/aggregator.dart';
import 'package:gallery_zone/data/models/artist_network.dart' show DeactivationStatus;
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/auth.dart';
import 'package:gallery_zone/data/remote/mappers/commerce_mappers.dart' show describeLedgerReason;
import 'package:gallery_zone/data/remote/mappers/portal_mappers.dart';
import 'package:gallery_zone/data/remote/remote_aggregator_repository.dart';
import 'package:gallery_zone/data/remote/remote_artist_network_repository.dart';
import 'package:gallery_zone/data/remote/remote_auth_repository.dart';
import 'package:gallery_zone/data/repositories/aggregator_repository.dart';

import 'support/fake_api.dart';

class _Gateway implements PaymentGateway {
  GatewaySession? opened;

  @override
  Future<GatewayPayment> pay(GatewaySession session) async {
    opened = session;
    return GatewayPayment(orderId: session.gatewayOrderId, paymentId: 'pay_9', signature: 'sig_9');
  }
}

Map<String, dynamic> _holding(String id, {String status = 'reserved', int month = 1}) => {
      'id': id,
      'artworkId': 'aw1',
      'artwork': {
        'id': 'aw1',
        'title': 'Monsoon',
        'artistId': 'a',
        'artistName': 'Meera',
        'category': 'painting',
        'medium': 'oil',
        'displayPricePaise': 13650000,
        'status': 'with_aggregator',
        'listingType': 'marketplace_and_aggregator',
        'images': <Object>[],
      },
      'cycleMonth': month,
      'advancePercent': 5,
      'advancePaise': 682500,
      'deliveryDepositPaise': 250000,
      'displayPricePaise': 13650000,
      'assignmentSource': 'self_reserved',
      'assignedAt': '2026-10-01T00:00:00.000Z',
      'expiresAt': '2026-10-31T00:00:00.000Z',
      'windowExtended': false,
      'status': status,
      'returnedAt': null,
      'appreciated': false,
      'priceWarning': false,
      'extensionRequest': null,
    };

Map<String, dynamic> _sale(
  String id, {
  String route = 'direct_to_galleryzone',
  String ship = 'preparing',
  String holdingId = 'h1',
  String? courierRef,
}) =>
    {
      'id': id,
      'holdingId': holdingId,
      'artworkId': 'aw1',
      'soldPricePaise': 13650000,
      'buyerName': 'Ravi',
      'buyerEmail': 'ravi@example.com',
      'buyerPhone': '9999999999',
      'deliveryAddress': '12, Park Street, Kolkata, West Bengal, 700016',
      'deliveryMode': 'courier',
      'paymentRoute': route,
      'remittedAt': null,
      'remitDueAt': '2026-10-04T00:00:00.000Z',
      'remittedVia': null,
      'shipmentStatus': ship,
      'dispatchedAt': null,
      'deliveredAt': null,
      'courierRef': courierRef,
      'soldAt': {'_seconds': 1790000000, '_nanoseconds': 0},
    };

void main() {
  group('RemoteAggregatorRepository', () {
    RemoteAggregatorRepository repoFor(FakeApi api, {PaymentGateway? gateway}) =>
        RemoteAggregatorRepository(api: api.client(), gateway: gateway ?? _Gateway());

    test('the inventory carries this month\'s terms, all from the server', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/inventory', {
          'artworks': [
            {
              'id': 'aw1',
              'title': 'Monsoon',
              'artistId': 'a',
              'artistName': 'Meera',
              'category': 'painting',
              'medium': 'oil',
              'displayPricePaise': 13650000,
              'status': 'marketplace',
              'listingType': 'marketplace_and_aggregator',
              'images': <Object>[],
              'offer': {
                'artworkId': 'aw1',
                'month': 1,
                'sellingPricePaise': 13000000,
                'offerPricePaise': 13650000,
                'standardPricePaise': 13000000,
                'monthlyReductionPaise': 0,
                'marketplacePricePaise': 13650000,
                'canSetPrice': true,
                'gstRate': 0.05,
                'priceWarnFromPaise': 26000000,
                'advancePaise': 650000,
                'advanceRate': 0.05,
                'advanceBasePaise': 13000000,
                'advanceBasis': 'selling_price',
                'daysLeftInListing': 180,
                'deliveryChargePaise': 250000,
                'payablePaise': 900000,
              },
            },
          ],
        });
      final offer = (await repoFor(api).listReservableInventory()).single.offer;
      expect(offer.month, 1);
      expect(offer.sellingPrice, 130000);
      expect(offer.offerPrice, 136500);
      expect(offer.canSetPrice, isTrue);
      expect(offer.priceWarnFrom, 260000);
      expect(offer.advance, 6500);
      expect(offer.advanceBasis, AdvanceBasis.sellingPrice);
      expect(offer.payable, 9000);
      expect(offer.daysLeftInListing, 180);
    });

    test('reserving sends the chosen price before GST, or nothing to take GalleryZone\'s', () async {
      final api = FakeApi()..json('POST /v1/aggregator/holdings', _holding('h1'), status: 201);
      final repo = repoFor(api);
      await repo.reserve('aw1');
      await repo.reserve('aw1', sellingPrice: 140000);
      final bodies = api.bodiesOf('POST /v1/aggregator/holdings');
      expect(bodies[0], {'artworkId': 'aw1'});
      expect(bodies[1], {'artworkId': 'aw1', 'sellingPricePaise': 14000000});
    });

    test('one holding comes with its artwork - a returned one too; one that is not theirs is null', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/holdings/h1', _holding('h1', status: 'returned'))
        ..problem('GET /v1/aggregator/holdings/nope', 404, 'not_found', 'Not found');
      final repo = repoFor(api);
      final view = await repo.getHolding('h1');
      expect(view!.holding.status, HoldingStatus.returned);
      expect(view.artwork.title, 'Monsoon');
      expect(await repo.getHolding('nope'), isNull);
    });

    test('the API\'s own reason reaches the person when reserving is refused', () async {
      final api = FakeApi()
        ..problem(
          'POST /v1/aggregator/holdings',
          403,
          'gst_required',
          'Add your GST number in My Profile, and wait for GalleryZone to approve it, before reserving artwork',
        );
      await expectLater(
        repoFor(api).reserve('aw1'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'gst_required')),
      );
    });

    test('a holding reads with its extension request and the cash flags', () {
      final holding = holdingFromApi({
        ..._holding('h1'),
        'appreciated': true,
        'priceWarning': true,
        'windowExtended': true,
        'extensionRequest': {
          'status': 'declined',
          'assurance': 'A collector has promised to buy it',
          'requestedAt': '2026-10-20T00:00:00.000Z',
          'decidedAt': '2026-10-21T00:00:00.000Z',
          'note': 'Not this time',
          'previousExpiresAt': '2026-10-31T00:00:00.000Z',
        },
      });
      expect(holding.appreciated, isTrue);
      expect(holding.priceWarning, isTrue);
      expect(holding.windowExtended, isTrue);
      expect(holding.extensionRequest!.status, ExtensionStatus.declined);
      expect(holding.extensionRequest!.note, 'Not this time');
      expect(holding.deliveryDeposit, 2500);
      expect(holding.advanceAmount, 6825);
    });

    test('asking to keep a piece needs a real assurance', () async {
      final api = FakeApi()..json('POST /v1/aggregator/holdings/h1/extension', _holding('h1'), status: 201);
      final repo = repoFor(api);
      await expectLater(repo.requestExtension('h1', 'too short'), throwsA(isA<Exception>()));
      expect(api.requests, isEmpty);
      await repo.requestExtension('h1', '  A collector in Pune has promised to buy it.  ');
      expect(api.bodiesOf('POST /v1/aggregator/holdings/h1/extension').single, {
        'assurance': 'A collector in Pune has promised to buy it.',
      });
    });

    test('returning a piece unsold gives back the advance and keeps the delivery', () async {
      final api = FakeApi()..json('POST /v1/aggregator/holdings/h1/return', _holding('h1', status: 'returned'), status: 201);
      final release = await repoFor(api).releaseHolding('h1');
      expect(release.refunded, 6825);
      expect(release.deliveryLost, 2500);
    });

    test('recording a sale sends the holding id in the body, as the API\'s schema requires', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1')]})
        ..json('POST /v1/aggregator/holdings/h1/sale', {'saleId': 's1'}, status: 201)
        ..json('GET /v1/aggregator/sales', [_sale('s1')]);

      final sale = await repoFor(api).recordSale(
        const RecordSaleInput(
          artworkId: 'aw1',
          soldPrice: 136500,
          buyerName: ' Ravi ',
          buyerEmail: 'ravi@example.com',
          buyerPhone: '9999999999',
          deliveryAddress: DeliveryAddress(line1: '12, Park Street', city: 'Kolkata', state: 'West Bengal', pincode: '700016'),
          deliveryMode: DeliveryMode.courier,
          paymentRoute: PaymentRoute.cashAtPremises,
        ),
      );
      expect(api.bodiesOf('POST /v1/aggregator/holdings/h1/sale').single, {
        'holdingId': 'h1',
        'soldPricePaise': 13650000,
        'buyerName': 'Ravi',
        'buyerEmail': 'ravi@example.com',
        'buyerPhone': '9999999999',
        'deliveryMode': 'courier',
        'paymentRoute': 'cash_at_premises',
        'deliveryAddress': '12, Park Street, Kolkata, West Bengal, 700016',
      });
      expect(sale.id, 's1');
      expect(sale.soldPrice, 136500);
      expect(sale.remitDueAt, isNotNull);
    });

    test('there is nothing to sell without a live reservation', () async {
      final api = FakeApi()..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1', status: 'returned')]});
      await expectLater(
        repoFor(api).recordSale(
          const RecordSaleInput(
            artworkId: 'aw1',
            soldPrice: 1,
            buyerName: 'R',
            buyerEmail: 'r@x.co',
            buyerPhone: '',
            deliveryAddress: DeliveryAddress(line1: '', city: '', state: '', pincode: ''),
            deliveryMode: DeliveryMode.selfPickup,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a street with commas in it survives the one-line address the API stores', () {
      final parsed = parseDeliveryAddress('12, Park Street, Kolkata, West Bengal, 700016');
      expect(parsed.line1, '12, Park Street');
      expect(parsed.city, 'Kolkata');
      expect(parsed.state, 'West Bengal');
      expect(parsed.pincode, '700016');
      expect(
        joinDeliveryAddress(const DeliveryAddress(line1: '12, Park Street', city: 'Kolkata', state: 'West Bengal', pincode: '700016')),
        '12, Park Street, Kolkata, West Bengal, 700016',
      );
      expect(parseDeliveryAddress(null).line1, '');
      expect(parseDeliveryAddress('Only a street').city, '');
    });

    test('moving a shipment on sends exactly {to, courierRef?} — the API\'s schema is strict', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales', [_sale('s1')])
        ..json('PATCH /v1/aggregator/sales/s1/shipment', _sale('s1', ship: 'dispatched'));
      final repo = repoFor(api);
      await repo.advanceShipment('s1', courierRef: ' BD-4471 ');
      expect(api.bodiesOf('PATCH /v1/aggregator/sales/s1/shipment').single, {'to': 'dispatched', 'courierRef': 'BD-4471'});

      final delivered = FakeApi()
        ..json('GET /v1/aggregator/sales', [_sale('s1', ship: 'dispatched')])
        ..json('PATCH /v1/aggregator/sales/s1/shipment', _sale('s1', ship: 'delivered'));
      await repoFor(delivered).advanceShipment('s1');
      expect(delivered.bodiesOf('PATCH /v1/aggregator/sales/s1/shipment').single, {'to': 'delivered'});
    });

    test('delivering a dispatched sale re-sends the courier reference dispatch recorded - the API writes null otherwise', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales', [_sale('s1', ship: 'dispatched', courierRef: 'BD-4471')])
        ..json('PATCH /v1/aggregator/sales/s1/shipment', _sale('s1', ship: 'delivered', courierRef: 'BD-4471'));
      await repoFor(api).advanceShipment('s1');
      expect(api.bodiesOf('PATCH /v1/aggregator/sales/s1/shipment').single, {'to': 'delivered', 'courierRef': 'BD-4471'});
    });

    test('loads that overlap share one request; nothing is kept once it lands', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales', [_sale('s1')])
        ..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1')]});
      final repo = repoFor(api);
      int gets(String path) => api.calls.where((c) => c == 'GET $path').length;

      await Future.wait([repo.listSales(), repo.listCustomers(), repo.listSales(), repo.listCollection(), repo.listCollection()]);
      expect(gets('/v1/aggregator/sales'), 1, reason: 'three asks, one download');
      expect(gets('/v1/aggregator/holdings'), 1);

      // Not a cache: asking again, after a change, reads again.
      await repo.listSales();
      expect(gets('/v1/aggregator/sales'), 2);
    });

    test('a sale\'s commission is what the ledger credited; the rule covers only sales the feed no longer reaches', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales', [_sale('s1', holdingId: 'h1'), _sale('s2', holdingId: 'h2')])
        ..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1'), _holding('h2')]})
        ..json('GET /v1/aggregator/wallet/transactions', {
          'transactions': [
            {'id': 't1', 'amountPaise': 1234500, 'reason': 'aggregator_commission', 'holdingId': 'h1', 'at': '2026-10-02T00:00:00.000Z'},
            {'id': 't2', 'amountPaise': -900000, 'reason': 'reservation_hold', 'holdingId': 'h2', 'at': '2026-10-01T00:00:00.000Z'},
          ],
        });
      final commissions = await repoFor(api).saleCommissions();
      expect(commissions['s1'], 12345, reason: 'credited');
      // 20% of the markup over the artist price, both before GST: a 1,36,500 piece listed from 1,00,000.
      expect(commissions['s2'], 6000, reason: 'no credit in the feed: worked out by the rule');
    });

    test('settlements carry that commission - the website\'s own sum comes to nothing - and processed dates', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales', [
          _sale('s1', holdingId: 'h1'),
          _sale('s2', holdingId: 'h2', route: 'cash_at_premises'),
        ])
        ..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1'), _holding('h2')]})
        ..json('GET /v1/aggregator/wallet/transactions', {
          'transactions': [
            {'id': 't1', 'amountPaise': 1234500, 'reason': 'aggregator_commission', 'holdingId': 'h1', 'at': '2026-10-02T00:00:00.000Z'},
          ],
        });
      final settlements = await repoFor(api).listSettlements();

      final direct = settlements.firstWhere((s) => s.orderId == 's1');
      expect(direct.aggregatorCommission, 12345);
      expect(direct.status, SettlementStatus.processed);
      expect(direct.processedAt, direct.createdAt, reason: 'the buyer paid GalleryZone, so it was settled the day of the sale');

      final owed = settlements.firstWhere((s) => s.orderId == 's2');
      expect(owed.aggregatorCommission, 6000);
      expect(owed.status, SettlementStatus.pending, reason: 'cash not yet paid in');
      expect(owed.processedAt, isNull);
    });

    test('the wallet ledger names cash paid in and money paid out', () {
      expect(describeLedgerReason('cash_sale_paid_from_wallet').label, 'Cash sale paid to GalleryZone');
      expect(describeLedgerReason('payable_discharged').label, 'Paid out to your bank');
    });

    test('a delivered shipment cannot be moved again', () async {
      final api = FakeApi()..json('GET /v1/aggregator/sales', [_sale('s1', ship: 'delivered')]);
      await expectLater(repoFor(api).advanceShipment('s1'), throwsA(isA<Exception>()));
      expect(api.calls.where((c) => c.startsWith('PATCH')), isEmpty);
    });

    test('the wallet is free money plus what is held; held is the locked part', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/wallet', {'balancePaise': 5000000, 'heldPaise': 900000})
        ..json('GET /v1/aggregator/holdings', {'holdings': [_holding('h1')]})
        ..json('GET /v1/aggregator/wallet/transactions', {
          'transactions': [
            {'id': 't1', 'amountPaise': 6000000, 'reason': 'wallet_topup', 'holdingId': null, 'at': '2026-10-01T00:00:00.000Z'},
            {'id': 't2', 'amountPaise': -900000, 'reason': 'reservation_hold', 'holdingId': 'h1', 'at': '2026-10-02T00:00:00.000Z'},
          ],
        });
      final repo = repoFor(api);
      final wallet = await repo.getWallet();
      expect(wallet.balance, 59000);
      expect(wallet.lockedBalance, 9000);

      final feed = await repo.listWalletTransactions();
      expect(feed.first.label, 'Held for reservation · Monsoon', reason: 'newest first, with the piece\'s name');
      expect(feed.last.label, 'Added to wallet');
    });

    test('topping up, simulated: the API credits it, no payment sheet', () async {
      final gateway = _Gateway();
      final api = FakeApi()
        ..json('POST /v1/aggregator/wallet/topups', {'mode': 'simulated', 'topupId': 'tp1', 'amountPaise': 5000000}, status: 201)
        ..json('POST /v1/aggregator/wallet/topups/tp1/simulate', {'status': 'paid'}, status: 201);
      final added = await repoFor(api, gateway: gateway).addFunds(50000);
      expect(api.bodiesOf('POST /v1/aggregator/wallet/topups').single, {'amountPaise': 5000000});
      expect(gateway.opened, isNull);
      expect(added.amount, 50000);
    });

    test('topping up, real gateway: pay, then hand the signed result back', () async {
      final gateway = _Gateway();
      final api = FakeApi()
        ..json('POST /v1/aggregator/wallet/topups', {
          'mode': 'razorpay',
          'topupId': 'tp2',
          'keyId': 'rzp_test_x',
          'razorpayOrderId': 'order_TOP',
          'amountPaise': 5000000,
          'currency': 'INR',
          'name': 'GalleryZone',
          'description': 'Add funds to your GalleryZone wallet',
          'prefill': {'name': 'A', 'email': 'a@b.co', 'contact': ''},
        }, status: 201)
        ..json('POST /v1/aggregator/wallet/topups/tp2/verify', {'status': 'paid', 'amountPaise': 5000000}, status: 201);
      await repoFor(api, gateway: gateway).addFunds(50000);
      expect(gateway.opened!.gatewayOrderId, 'order_TOP');
      expect(api.bodiesOf('POST /v1/aggregator/wallet/topups/tp2/verify').single, {
        'razorpayOrderId': 'order_TOP',
        'razorpayPaymentId': 'pay_9',
        'signature': 'sig_9',
      });
    });

    test('a top-up outside ₹1,000 to ₹5,00,000 is refused without asking the API', () async {
      final api = FakeApi();
      final repo = repoFor(api);
      await expectLater(repo.addFunds(999), throwsA(isA<Exception>()));
      await expectLater(repo.addFunds(500001), throwsA(isA<Exception>()));
      expect(api.requests, isEmpty);
    });

    test('aggregators cannot withdraw; settlements are GalleryZone\'s to process', () async {
      final repo = repoFor(FakeApi());
      await expectLater(repo.requestWithdrawal(1000), throwsA(isA<Exception>()));
      await expectLater(repo.processSettlement('s1'), throwsA(isA<Exception>()));
    });

    test('paying in cash says how: from the wallet or by bank transfer', () async {
      final api = FakeApi()
        ..json('POST /v1/aggregator/sales/s1/remit', {}, status: 201)
        ..json('GET /v1/aggregator/sales', [_sale('s1', route: 'cash_at_premises')]);
      final repo = repoFor(api);
      await repo.markRemitted('s1', via: RemitVia.bank);
      await repo.markRemitted('s1');
      expect(api.bodiesOf('POST /v1/aggregator/sales/s1/remit'), [
        {'via': 'bank'},
        {'via': 'wallet'},
      ]);
    });

    test('cash still owed comes from its own list', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/sales/remittances-due', [_sale('s1', route: 'cash_at_premises')]);
      final due = await repoFor(api).listRemittancesDue();
      expect(due.single.paymentRoute, PaymentRoute.cashAtPremises);
      expect(due.single.remitDueAt, '2026-10-04T00:00:00.000Z');
    });

    test('the dashboard\'s conversion rate is over finished pieces only', () async {
      final api = FakeApi()
        ..json('GET /v1/aggregator/holdings', {
          'holdings': [
            _holding('a'),
            _holding('b', status: 'sold_pending_settlement'),
            _holding('c', status: 'returned'),
            _holding('d', status: 'returned'),
          ],
        });
      final summary = await repoFor(api).getDashboardSummary();
      expect(summary.activeReservations, 1);
      expect(summary.pendingSettlements, 1);
      expect(summary.conversionRate, 33, reason: '1 sold of 3 finished; the live one does not count');

      final none = FakeApi()..json('GET /v1/aggregator/holdings', {'holdings': [_holding('a')]});
      expect((await repoFor(none).getDashboardSummary()).conversionRate, isNull);
    });

    test('adding premises sends only what was filled in', () async {
      final api = FakeApi()..json('POST /v1/aggregator/gallery-spaces', {'id': 'sp1'}, status: 201);
      final added = await repoFor(api).addGallerySpace(
        const GallerySpace(
          id: '',
          name: 'Verandah Art House',
          addressLine1: '4 Park Street',
          city: 'Kolkata',
          state: 'West Bengal',
          pincode: '700016',
          capacity: 0,
          coordinatorName: '',
        ),
      );
      expect(api.bodiesOf('POST /v1/aggregator/gallery-spaces').single, {
        'name': 'Verandah Art House',
        'addressLine1': '4 Park Street',
        'city': 'Kolkata',
        'state': 'West Bengal',
        'pincode': '700016',
      });
      expect(added.id, 'sp1');
    });

    test('the profile carries the GST verdict and the signature, and saves only what changed', () async {
      Map<String, dynamic> profile({String company = 'Verandah', String gstStatus = 'submitted'}) => {
            'uid': 'u2',
            'fullName': 'Anil Rao',
            'email': 'anil@verandah.in',
            'phone': '9000000000',
            'role': 'aggregator',
            'status': 'active',
            'createdAt': '2026-09-01T00:00:00.000Z',
            'companyName': company,
            'gstin': '19ABCDE1234F1Z5',
            'gstStatus': gstStatus,
            'aadhaarStatus': 'not_submitted',
            'aadhaarMasked': null,
            'bankAccountMasked': null,
            'ifsc': null,
            'headline': 'Gallery manager',
            'pickupLine1': '4 Park Street',
            'pickupCity': 'Kolkata',
            'pickupState': 'West Bengal',
            'pickupPincode': '700016',
          };
      final api = FakeApi()
        ..json('GET /v1/me/profile', profile())
        ..json('GET /v1/aggregator/mou', {
          'acceptance': null,
          'draft': {
            'version': '2026.2',
            'parties': {'party': {}, 'company': {}},
            'missing': <String>[],
            'asOf': '2026-10-02T00:00:00.000Z',
          },
        })
        ..json('PATCH /v1/me/profile', profile(company: 'Verandah Art House'));
      final repo = repoFor(api);
      final loaded = await repo.getProfile();
      expect(loaded.gstStatus, ReviewStatus.submitted);
      expect(loaded.companyName, 'Verandah');
      expect(loaded.coordinatorDesignation, 'Gallery manager');
      expect(loaded.mouAcceptance, isNull);

      await repo.updateProfile(loaded.copyWith(companyName: 'Verandah Art House'));
      expect(api.bodiesOf('PATCH /v1/me/profile').single, {'companyName': 'Verandah Art House'});
    });
  });

  group('RemoteAuthRepository', () {
    ({RemoteAuthRepository repo, FakeApi api, FakeApi firebase, TokenManager tokens}) build({
      String role = 'customer',
      bool hasProfile = true,
    }) {
      final firebase = FakeApi()
        ..json('POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword', {
          'localId': 'uid1',
          'email': 'a@b.co',
          'idToken': 'id1',
          'refreshToken': 'rt1',
          'expiresIn': '3600',
        })
        // A 401 makes the client refresh its token once before giving up.
        ..json('POST https://securetoken.googleapis.com/v1/token', {
          'id_token': 'id2',
          'refresh_token': 'rt1',
          'expires_in': '3600',
          'user_id': 'uid1',
        })
        ..json('POST https://identitytoolkit.googleapis.com/v1/accounts:resetPassword', {})
        ..json('POST https://identitytoolkit.googleapis.com/v1/accounts:update', {});
      final api = FakeApi();
      if (hasProfile) {
        api.json('GET /v1/auth/me', {
          'uid': 'uid1',
          'role': role,
          'status': 'active',
          'name': 'Aarav Shah',
          'email': 'a@b.co',
          'phone': null,
          'roleGrants': <String>[],
        });
      } else {
        api.problem('GET /v1/auth/me', 401, 'unauthorized', 'No account record for this token');
      }
      final tokens = TokenManager(auth: FirebaseRestAuth(apiKey: 'k', dio: firebase.http.dio()), store: _MemoryStore());
      return (
        // The client asks the token manager for its token, exactly as the app wires it.
        repo: RemoteAuthRepository(
          api: api.client(tokenSource: tokens.idToken),
          firebase: FirebaseRestAuth(apiKey: 'k', dio: firebase.http.dio()),
          tokens: tokens,
        ),
        api: api,
        firebase: firebase,
        tokens: tokens,
      );
    }

    test('signing in: the role comes from the server, not the form', () async {
      final t = build(role: 'aggregator');
      final ack = await t.repo.login(const LoginInput(email: 'a@b.co', password: 'Passw0rd123', rememberMe: true));
      expect(ack.role, Role.aggregator);
      expect(ack.name, 'Aarav Shah');
      expect(await t.tokens.idToken(), 'id1');
      expect(t.api.requests.single.headers['Authorization'], 'Bearer id1');
    });

    test('an account with nothing behind it on GalleryZone is told so, and signed out', () async {
      final t = build(hasProfile: false);
      await expectLater(
        t.repo.login(const LoginInput(email: 'a@b.co', password: 'Passw0rd123')),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No GalleryZone account exists'))),
      );
      expect(t.tokens.hasSession, isFalse);
    });

    test('an admin is a real account but has no portal here: told where to go, signed out', () async {
      final t = build(role: 'admin');
      await expectLater(
        t.repo.login(const LoginInput(email: 'a@b.co', password: 'Passw0rd123')),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Admin tools are on the GalleryZone website'))),
      );
      expect(t.tokens.hasSession, isFalse);
    });

    test('registering creates the account over the API then signs in; an aggregator\'s company is saved', () async {
      final t = build(role: 'aggregator');
      t.api
        ..json('POST /v1/auth/register', {'uid': 'uid1'}, status: 201)
        ..json('PATCH /v1/me/profile', {});
      final ack = await t.repo.register(
        const RegisterInput(
          role: Role.aggregator,
          name: ' Anil Rao ',
          email: 'a@b.co',
          phone: '9000000000',
          password: 'Passw0rd123',
          acceptedTerms: true,
          companyName: 'Verandah Art House',
          contactPerson: 'Anil Rao',
        ),
      );
      expect(t.api.bodiesOf('POST /v1/auth/register').single, {
        'email': 'a@b.co',
        'password': 'Passw0rd123',
        'name': 'Anil Rao',
        'role': 'aggregator',
        'phone': '9000000000',
      });
      expect(t.api.bodiesOf('PATCH /v1/me/profile').single, {'companyName': 'Verandah Art House'});
      expect(ack.role, Role.aggregator);
      // Registration itself needs no credential.
      expect(t.api.requests.first.headers.containsKey('Authorization'), isFalse);
    });

    test('a taken email is reported in the API\'s words', () async {
      final t = build();
      t.api.problem('POST /v1/auth/register', 409, 'email_taken', 'An account with this email already exists');
      await expectLater(
        t.repo.register(
          const RegisterInput(
            role: Role.customer,
            name: 'A',
            email: 'a@b.co',
            phone: '9000000000',
            password: 'Passw0rd123',
            acceptedTerms: true,
          ),
        ),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'An account with this email already exists')),
      );
    });

    test('forgot password asks the API and sends no credential', () async {
      final t = build();
      t.api.json('POST /v1/auth/password-reset', {'status': 'accepted'}, status: 202);
      final ack = await t.repo.forgotPassword(const ForgotPasswordInput(email: 'a@b.co'));
      expect(ack.email, 'a@b.co');
      expect(t.api.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a reset or verification link without its code is refused with a clear sentence', () async {
      final t = build();
      await expectLater(
        t.repo.resetPassword(const ResetPasswordInput(password: 'Passw0rd123', confirmPassword: 'Passw0rd123')),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('missing its code'))),
      );
      await expectLater(t.repo.verifyEmail(), throwsA(isA<Exception>()));
    });

    test('asking to delete the account raises a support ticket - the API has no delete route', () async {
      final t = build();
      t.api.json('POST /v1/support', {'id': 'tk-1'}, status: 201);
      await t.repo.requestAccountDeletion();
      final body = t.api.bodiesOf('POST /v1/support').single! as Map;
      expect(body['subject'], 'Account deletion request');
      expect(body['message'], contains('delete my data'));
      expect(t.api.calls, ['POST /v1/support'], reason: 'nothing else is called, nothing is signed out here');
    });

    test('a deletion request that did not go through says so', () async {
      final t = build();
      t.api.problem('POST /v1/support', 500, 'internal_error', 'Something went wrong');
      await expectLater(t.repo.requestAccountDeletion(), throwsA(isA<ApiError>()));
    });

    test('resuming a session: a refused one ends it, being offline does not', () async {
      final t = build(hasProfile: false);
      await t.tokens.start(
        FirebaseSession(uid: 'u', email: null, idToken: 'id', refreshToken: 'rt', expiresAt: DateTime.now().add(const Duration(hours: 1))),
        remember: true,
      );
      expect(await t.repo.resumeSession(), isNull);
      expect(t.tokens.hasSession, isFalse);

      final offline = build();
      offline.api.on('GET /v1/auth/me', (options) => throw DioException(requestOptions: options, type: DioExceptionType.connectionError));
      await offline.tokens.start(
        FirebaseSession(uid: 'u', email: null, idToken: 'id', refreshToken: 'rt', expiresAt: DateTime.now().add(const Duration(hours: 1))),
        remember: true,
      );
      await expectLater(offline.repo.resumeSession(), throwsA(isA<ApiError>().having((e) => e.isNetwork, 'isNetwork', isTrue)));
      expect(offline.tokens.hasSession, isTrue);
    });
  });

  group('RemoteArtistNetworkRepository', () {
    test('what the website does not have, the app does not invent', () async {
      final repo = RemoteArtistNetworkRepository(FakeApi().client());
      final rating = await repo.getRating('artist-1');
      expect(rating.count, 0);
      expect(rating.average, 0);
      expect(await repo.listReviews('artist-1'), isEmpty);
      expect(await repo.listConnections('artist-1'), isEmpty);
      await expectLater(
        repo.sendConnectionRequest(requesterId: 'a', recipientId: 'b'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('coming soon'))),
      );
    });

    test('closing an account is a real request, decided by an admin', () async {
      final api = FakeApi()
        ..json('GET /v1/artist/deactivation', {
          'request': {
            'id': 'd1',
            'userId': 'u1',
            'userName': 'Meera',
            'reason': 'Moving on',
            'status': 'pending',
            'requestedAt': '2026-10-01T00:00:00.000Z',
            'decidedAt': null,
            'decisionNote': null,
          },
        })
        ..json('POST /v1/artist/deactivation', {}, status: 201);
      final repo = RemoteArtistNetworkRepository(api.client());
      final request = await repo.requestDeactivation(reason: ' Moving on ');
      expect(api.bodiesOf('POST /v1/artist/deactivation').single, {'reason': 'Moving on'});
      expect(request.status, DeactivationStatus.pending);
      await expectLater(repo.requestDeactivation(reason: '  '), throwsA(isA<Exception>()));
      await expectLater(repo.withdrawDeactivation('d1'), throwsA(isA<Exception>()));
    });
  });
}

class _MemoryStore implements RefreshTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}
