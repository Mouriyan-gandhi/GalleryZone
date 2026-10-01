import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/api/api_error.dart';
import 'package:gallery_zone/data/models/aggregator.dart' show DeliveryAddress;
import 'package:gallery_zone/data/models/artist_portal.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/customer.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/remote/remote_artist_repository.dart';
import 'package:gallery_zone/data/remote/remote_customer_repository.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';
import 'support/fake_http.dart';

Map<String, dynamic> _profile({
  String name = 'Meera Nair',
  String? phone = '9876543210',
  String? gstin,
  String gstStatus = 'not_submitted',
  String? bankMasked = '•••• 6142',
  String? ifsc = 'HDFC0001234',
  String? instagram = 'meera.art',
}) =>
    {
      'uid': 'u1',
      'fullName': name,
      'email': 'meera@example.com',
      'phone': phone,
      'role': 'artist',
      'status': 'active',
      'createdAt': '2026-09-01T00:00:00.000Z',
      'bio': 'Painter.',
      'profileImageUrl': null,
      'headline': null,
      'location': 'Pune, Maharashtra',
      'instagram': instagram,
      'website': null,
      'pan': 'ABCDE1234F',
      'gstin': gstin,
      'gstStatus': gstStatus,
      'aadhaarStatus': 'submitted',
      'aadhaarMasked': '•••• 4821',
      'bankAccountMasked': bankMasked,
      'ifsc': ifsc,
      'pickupLine1': '12 Laburnum Road',
      'pickupLine2': null,
      'pickupCity': 'Pune',
      'pickupState': 'Maharashtra',
      'pickupPincode': '411001',
      'earningsAbove5L': false,
      'socialProofVideoUrl': null,
      'companyName': null,
      'freeAccess': {'until': '2027-03-01T00:00:00.000Z', 'months': 6, 'surveyRespondent': false, 'active': true},
    };

Map<String, dynamic> _ownerArtwork(String id, {String status = 'marketplace', List<Map<String, dynamic>>? images}) => {
      'id': id,
      'productCode': 'GZ0000$id',
      'artistId': 'u1',
      'artistName': 'Meera Nair',
      'title': 'Monsoon $id',
      'description': 'Rain.',
      'category': 'painting',
      'medium': 'oil',
      'dimensions': '24 x 36 in',
      'yearCreated': 2024,
      'images': images ?? <Map<String, dynamic>>[],
      'displayPricePaise': 13650000,
      'insured': false,
      'status': status,
      'listingType': 'marketplace_and_aggregator',
      'rarityType': 'R',
      'coaCertificateNumber': 'GZ-COA-2026-0001',
      'coaIssuedAt': '2026-09-16T00:00:00.000Z',
      'createdAt': '2026-09-16T00:00:00.000Z',
      'artistLocation': 'Pune, Maharashtra',
      'sizeBand': 'medium',
      'artistPricePaise': 10000000,
      'artistNet': {'marketplace': 10000000, 'aggregatorEstimate': 9505000},
      'insuranceOpted': true,
      'insuranceNumber': 'POL-1',
      'insuranceStatus': 'submitted',
      'nfcTagId': null,
      'artworkType': 'original',
      'paintingStyle': 'tanjore',
      'physical': {
        'weightKg': 2.5,
        'framing': 'framed',
        'format': 'canvas',
        'hangingHardwareIncluded': true,
        'packagingConfirmed': true,
      },
      'editableUntil': '2026-09-23T00:00:00.000Z',
      'statusHistory': [
        {'status': 'pending_approval', 'changedAt': '2026-09-16T00:00:00.000Z', 'reason': null},
        {'status': 'marketplace', 'changedAt': '2026-09-17T00:00:00.000Z', 'reason': null},
      ],
    };

SubmitArtworkInput _input({
  List<ArtworkImage> images = const [],
  bool asDraft = false,
  String title = 'Monsoon',
}) =>
    SubmitArtworkInput(
      title: title,
      description: 'Rain.',
      category: 'painting',
      medium: 'oil',
      artistPrice: 100000,
      listingType: ListingType.marketplaceAndAggregator,
      insuranceOpted: true,
      images: images,
      asDraft: asDraft,
      dimensions: '24 x 36 in',
      yearCreated: 2024,
      artworkType: 'original',
      paintingStyle: 'tanjore',
      insuranceNumber: 'POL-1',
      physical: const ArtworkPhysical(
        weightKg: 2.5,
        framing: FramingState.framed,
        format: 'canvas',
        hangingHardwareIncluded: true,
        packagingConfirmed: true,
      ),
    );

ArtworkImage _local(String path) => ArtworkImage(url: path, thumbnailUrl: path, sortOrder: 0, altText: 'alt');

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  group('RemoteCustomerRepository', () {
    test('saving a profile sends only what changed, and never echoes the masked account', () async {
      final api = FakeApi()
        ..json('GET /v1/me/profile', _profile(name: 'Aarav Shah', bankMasked: '•••• 6142'))
        ..json('PATCH /v1/me/profile', _profile(name: 'Aarav S Shah', bankMasked: '•••• 6142'));
      final repo = RemoteCustomerRepository(api.client());

      final current = await repo.getProfile();
      expect(current.bankAccountNumber, '•••• 6142');
      expect(current.joinedAt, '2026-09-01T00:00:00.000Z');

      await repo.updateProfile(current.copyWith(name: 'Aarav S Shah'));
      expect(api.bodiesOf('PATCH /v1/me/profile').single, {'fullName': 'Aarav S Shah'});
    });

    test('a new account number is sent; the masked one means "untouched"', () async {
      final api = FakeApi()
        ..json('GET /v1/me/profile', _profile())
        ..json('PATCH /v1/me/profile', _profile());
      final repo = RemoteCustomerRepository(api.client());
      final current = await repo.getProfile();

      await repo.updateProfile(current.copyWith(bankAccountNumber: '123456789012', bankIfsc: 'sbin0001234'));
      expect(api.bodiesOf('PATCH /v1/me/profile').single, {'bankAccountNumber': '123456789012', 'ifsc': 'SBIN0001234'});
    });

    test('nothing changed sends nothing', () async {
      final api = FakeApi()..json('GET /v1/me/profile', _profile());
      final repo = RemoteCustomerRepository(api.client());
      await repo.updateProfile(await repo.getProfile());
      expect(api.calls.where((c) => c.startsWith('PATCH')), isEmpty);
    });

    test('adding an address returns it with the server id', () async {
      final api = FakeApi()..json('POST /v1/account/addresses', {'id': 'ad9'}, status: 201);
      final saved = await RemoteCustomerRepository(api.client()).addAddress(
        const Address(id: 'new', line1: '1 MG Road', city: 'Pune', state: 'MH', pincode: '411001', isDefault: true),
      );
      expect(saved.id, 'ad9');
      final sent = api.bodiesOf('POST /v1/account/addresses').single as Map;
      expect(sent['line1'], '1 MG Road');
      expect(sent['isDefault'], true);
      expect(sent.containsKey('line2'), isFalse);
    });

    test('a collection can hold a piece that has no order behind it', () async {
      final api = FakeApi()
        ..json('GET /v1/account/collection', {
          'items': [
            {
              'artwork': {
                'id': 'aw1',
                'title': 'Gifted',
                'artistId': 'a',
                'artistName': 'A',
                'category': 'painting',
                'medium': 'oil',
                'displayPricePaise': 5000000,
                'status': 'sold',
                'listingType': 'marketplace_only',
                'images': <Object>[],
              },
              'order': null,
              'source': 'transfer',
              'acquiredAt': '2026-09-25T00:00:00.000Z',
              'fromName': 'Priya',
            },
          ],
        });
      final items = await RemoteCustomerRepository(api.client()).listCollection();
      expect(items.single.order, isNull);
      expect(items.single.source, CollectionSource.transfer);
      expect(items.single.fromName, 'Priya');
      expect(items.single.paidPrice, 0);
    });

    test('a paper certificate is requested with a structured address', () async {
      final api = FakeApi()
        ..json('POST /v1/coa/requests', {
          'id': 'r1',
          'artworkId': 'aw1',
          'artworkTitle': 'Monsoon',
          'coaCertificateNumber': 'GZ-COA-2026-0001',
          'requestedByUserId': 'u1',
          'requestedByName': 'Aarav',
          'requestedAt': '2026-10-01T00:00:00.000Z',
          'delivery': {'line1': '1 MG Road', 'city': 'Pune', 'state': 'Maharashtra', 'pincode': '411001'},
          'status': 'requested',
          'dispatchedAt': null,
          'courierRef': null,
        }, status: 201);
      final request = await RemoteCustomerRepository(api.client()).requestPhysicalCoa(
        artworkId: 'aw1',
        delivery: const DeliveryAddress(line1: '1 MG Road', city: 'Pune', state: 'Maharashtra', pincode: '411001'),
      );
      expect(api.bodiesOf('POST /v1/coa/requests').single, {
        'artworkId': 'aw1',
        'delivery': {'line1': '1 MG Road', 'city': 'Pune', 'state': 'Maharashtra', 'pincode': '411001'},
      });
      expect(request.status, PhysicalCoaStatus.requested);
      expect(request.deliveryAddress, '1 MG Road, Pune, Maharashtra 411001');
    });

    test('listing for resale sends paise and reads the listing back', () async {
      final api = FakeApi()
        ..json('POST /v1/account/resale', {'id': 'rs1'}, status: 201)
        ..json('GET /v1/account/resale', [
          {
            'id': 'rs1',
            'artworkId': 'aw1',
            'sellerId': 'u1',
            'listedPricePaise': 15000000,
            'status': 'active',
            'listedAt': {'_seconds': 1790000000, '_nanoseconds': 0},
          },
        ]);
      final listing = await RemoteCustomerRepository(api.client())
          .createResaleListing(artworkId: 'aw1', listedPrice: 150000);
      expect(api.bodiesOf('POST /v1/account/resale').single, {'artworkId': 'aw1', 'listedPricePaise': 15000000});
      expect(listing.listedPrice, 150000);
      expect(listing.status, ResaleListingStatus.active);
    });

    test('an owner not owning the piece gets the API\'s own sentence', () async {
      final api = FakeApi()..problem('POST /v1/account/resale', 409, 'resale_rejected', 'Artwork aw1 is not yours to list');
      await expectLater(
        RemoteCustomerRepository(api.client()).createResaleListing(artworkId: 'aw1', listedPrice: 100),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'Artwork aw1 is not yours to list')),
      );
    });

    test('collector withdrawal is refused, and the wallet feed is honestly empty', () async {
      final api = FakeApi()..json('GET /v1/customer/wallet', {'accountType': 'customer_wallet', 'balancePaise': 250000});
      final repo = RemoteCustomerRepository(api.client());
      expect((await repo.getWallet()).balance, 2500);
      expect(await repo.listWalletTransactions(), isEmpty);
      await expectLater(repo.requestWithdrawal(1000), throwsA(isA<Exception>()));
    });
  });

  group('RemoteArtistRepository', () {
    RemoteArtistRepository repoFor(FakeApi api, {FileBytes? read}) =>
        RemoteArtistRepository(api.client(), readFile: read ?? (_) async => List.filled(2048, 7));

    test('the owner view keeps the private price, the take-home and the edit window', () async {
      final api = FakeApi()..json('GET /v1/artist/artworks', {'artworks': [_ownerArtwork('1')]});
      final owned = (await repoFor(api).listArtworks()).single;
      expect(owned.artistPrice, 100000);
      expect(owned.artistNetMarketplace, 100000);
      expect(owned.artistNetAggregator, 95050);
      expect(owned.editableUntil, '2026-09-23T00:00:00.000Z');
      expect(owned.insuranceOpted, isTrue);
      expect(owned.artwork.customerPrice, 136500);
      expect(owned.artwork.rarityType, ArtworkRarity.rare);
      expect(owned.artwork.insuranceStatus, ReviewStatus.submitted);
      expect(owned.artwork.paintingStyle, 'tanjore');
      expect(owned.artwork.physical!.framing, FramingState.framed);
      expect(owned.artwork.statusHistory.first.status, ArtworkStatus.pendingApproval);
    });

    test('a submission with photos is a draft until every photo is in, then goes to review', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/artworks', _ownerArtwork('7', status: 'draft'), status: 201)
        ..json('POST /v1/artist/artworks/7/images/upload-url', {
          'key': 'artworks/7/abc.png',
          'uploadUrl': 'https://bucket.example/obj?sig=1',
          'headers': {'Content-Type': 'image/png'},
        }, status: 201)
        ..on('PUT https://bucket.example/obj?sig=1', (_) => ResponseBody.fromString('', 200))
        ..json('POST /v1/artist/artworks/7/images/confirm', {'id': 'img1'}, status: 201)
        ..json('PATCH /v1/artist/artworks/7', _ownerArtwork('7', status: 'pending_approval'))
        ..json('GET /v1/artist/artworks/7', _ownerArtwork('7', status: 'pending_approval'));

      final saved = await repoFor(api).submitArtwork(_input(images: [_local('/storage/pic.PNG')]));

      expect(api.calls, [
        'POST /v1/artist/artworks',
        'POST /v1/artist/artworks/7/images/upload-url',
        'PUT https://bucket.example/obj?sig=1',
        'POST /v1/artist/artworks/7/images/confirm',
        'PATCH /v1/artist/artworks/7',
        'GET /v1/artist/artworks/7',
      ]);
      final created = api.bodiesOf('POST /v1/artist/artworks').single as Map;
      expect(created['mode'], 'draft', reason: 'never "review" while photos are still to upload');
      expect(created['artistPricePaise'], 10000000);
      expect(created['dimensions'], '24 x 36 in');
      expect(created['listingType'], 'marketplace_and_aggregator');
      expect(created['physical'], containsPair('framing', 'framed'));
      expect(created.containsKey('rarityType'), isFalse, reason: 'rank is GalleryZone\'s call');
      expect(api.bodiesOf('POST /v1/artist/artworks/7/images/upload-url').single, {
        'contentType': 'image/png',
        'contentLength': 2048,
      });
      expect(api.bodiesOf('PATCH /v1/artist/artworks/7').single, {'mode': 'review'});
      expect(saved.status, ArtworkStatus.pendingApproval);

      // The signed URL is the credential; ours never goes to the bucket.
      final put = api.requests.firstWhere((r) => r.method == 'PUT');
      expect(put.headers.containsKey('Authorization'), isFalse);
    });

    test('a photo that cannot be uploaded leaves a saved draft and says so', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/artworks', _ownerArtwork('7', status: 'draft'), status: 201)
        ..problem('POST /v1/artist/artworks/7/images/upload-url', 409, 'conflict', 'A piece can have at most 8 photos');
      await expectLater(
        repoFor(api).submitArtwork(_input(images: [_local('/storage/pic.jpg')], title: 'Monsoon')),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('Saved "Monsoon" as a draft'), contains('at most 8 photos')),
          ),
        ),
      );
    });

    test('a file that is not a JPEG, PNG or WebP is refused in plain words', () async {
      final api = FakeApi()..json('POST /v1/artist/artworks', _ownerArtwork('7', status: 'draft'), status: 201);
      await expectLater(
        repoFor(api).submitArtwork(_input(images: [_local('/storage/scan.tiff')])),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('isn\'t a JPEG, PNG or WebP'))),
      );
    });

    test('a photo over 15 MB is refused before anything is uploaded', () async {
      final api = FakeApi()..json('POST /v1/artist/artworks', _ownerArtwork('7', status: 'draft'), status: 201);
      await expectLater(
        repoFor(api, read: (_) async => List.filled(RemoteArtistRepository.maxImageBytes + 1, 0))
            .submitArtwork(_input(images: [_local('/storage/huge.jpg')])),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('larger than 15 MB'))),
      );
      expect(api.calls.any((c) => c.contains('upload-url')), isFalse);
    });

    test('when the bucket cannot be reached the bytes go through the API instead', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/artworks', _ownerArtwork('7', status: 'draft'), status: 201)
        ..json('POST /v1/artist/artworks/7/images/upload-url', {
          'key': 'artworks/7/abc.jpg',
          'uploadUrl': 'https://bucket.example/obj?sig=2',
          'headers': <String, String>{},
        }, status: 201)
        ..on('PUT https://bucket.example/obj?sig=2', (options) => offline(options))
        ..json('POST /v1/artist/artworks/7/images/upload', {'id': 'img2'}, status: 201)
        ..json('GET /v1/artist/artworks/7', _ownerArtwork('7', status: 'draft'));
      await repoFor(api).submitArtwork(_input(images: [_local('/storage/pic.jpg')], asDraft: true));
      expect(api.calls, contains('POST /v1/artist/artworks/7/images/upload'));
      final upload = api.requests.firstWhere((r) => r.path.endsWith('/images/upload'));
      expect(upload.headers['Content-Type'], 'image/jpeg');
      expect(upload.headers['X-Alt-Text'], 'alt');
    });

    test('editing deletes removed photos, uploads new ones and applies the order', () async {
      final existing = [
        {'id': 'i1', 'url': 'https://x/1.png', 'thumbnailUrl': null, 'altText': 'a', 'sortOrder': 0, 'storagePath': 'p'},
        {'id': 'i2', 'url': 'https://x/2.png', 'thumbnailUrl': null, 'altText': 'b', 'sortOrder': 1, 'storagePath': 'p'},
      ];
      final api = FakeApi()
        ..json('GET /v1/artist/artworks/7', _ownerArtwork('7', images: existing))
        ..json('PATCH /v1/artist/artworks/7', _ownerArtwork('7', images: existing))
        ..json('DELETE /v1/artist/artworks/7/images/i1', {})
        ..json('POST /v1/artist/artworks/7/images/upload-url', {
          'key': 'artworks/7/n.jpg',
          'uploadUrl': 'https://bucket.example/n?sig=3',
          'headers': <String, String>{},
        }, status: 201)
        ..on('PUT https://bucket.example/n?sig=3', (_) => ResponseBody.fromString('', 200))
        ..json('POST /v1/artist/artworks/7/images/confirm', {'id': 'i3'}, status: 201)
        ..json('PUT /v1/artist/artworks/7/images/order', {});

      await repoFor(api).updateArtwork(
        artworkId: '7',
        patch: _input(images: [
          _local('/storage/new.jpg'),
          const ArtworkImage(url: 'https://x/2.png', thumbnailUrl: 'https://x/2.png', sortOrder: 1, altText: 'b', id: 'i2'),
        ]),
      );
      expect(api.calls, contains('DELETE /v1/artist/artworks/7/images/i1'));
      expect(api.bodiesOf('PUT /v1/artist/artworks/7/images/order').single, {
        'imageIds': ['i3', 'i2'],
      });
      expect(api.bodiesOf('PATCH /v1/artist/artworks/7').single, isNot(contains('mode')),
          reason: 'an edit never moves a piece between the draft and review queues');
    });

    test('sold elsewhere returns the piece in its new state', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/artworks/7/sold-elsewhere', {
          'penaltyId': 'p1',
          'artwork': _ownerArtwork('7', status: 'sold_externally'),
        }, status: 201);
      final piece = await repoFor(api).markSoldElsewhere('7');
      expect(piece.status, ArtworkStatus.soldExternally);
    });

    test('the wallet shows what can be withdrawn and what is awaiting approval', () async {
      final api = FakeApi()
        ..json('GET /v1/artist/wallet', {'balancePaise': 5000000, 'lockedPaise': 1000000, 'availablePaise': 4000000})
        ..json('GET /v1/artist/wallet/transactions', {
          'transactions': [
            {'id': 't1', 'kind': 'ledger', 'amountPaise': 10000000, 'reason': 'marketplace_settlement', 'status': 'completed', 'at': '2026-09-20T00:00:00.000Z'},
            {'id': 't2', 'kind': 'withdrawal', 'amountPaise': -1000000, 'reason': 'withdrawal', 'status': 'pending', 'at': '2026-09-25T00:00:00.000Z'},
            {'id': 't3', 'kind': 'ledger', 'amountPaise': -100000, 'reason': 'external_sale_penalty', 'status': 'completed', 'at': '2026-09-26T00:00:00.000Z'},
            {'id': 't4', 'kind': 'ledger', 'amountPaise': 5000, 'reason': 'order:abc123', 'status': 'completed', 'at': '2026-09-27T00:00:00.000Z'},
          ],
        });
      final repo = repoFor(api);
      final wallet = await repo.getWallet();
      expect(wallet.balance, 40000, reason: 'available, not the gross balance');
      expect(wallet.lockedBalance, 10000);

      final feed = await repo.listWalletTransactions();
      expect(feed[0].type, WalletTransactionType.settlement);
      expect(feed[0].label, 'Marketplace sale settled');
      expect(feed[1].type, WalletTransactionType.withdrawal);
      expect(feed[1].status, WalletTransactionStatus.pending);
      expect(feed[2].label, 'Off-platform sale fee');
      expect(feed[3].label, 'Order abc123');
    });

    test('withdrawals under the minimum are refused before the API is asked', () async {
      final api = FakeApi()..json('POST /v1/artist/withdrawals', {'withdrawalId': 'w1'}, status: 201);
      final repo = repoFor(api);
      await expectLater(repo.requestWithdrawal(999), throwsA(isA<Exception>()));
      expect(api.requests, isEmpty);

      final requested = await repo.requestWithdrawal(1500);
      expect(api.bodiesOf('POST /v1/artist/withdrawals').single, {'amountPaise': 150000});
      expect(requested.status, WalletTransactionStatus.pending);
      expect(requested.amount, -1500);
    });

    test('profile saves send only what changed; the payout account has its own call', () async {
      final api = FakeApi()
        ..json('GET /v1/me/profile', _profile())
        ..json('PATCH /v1/me/profile', _profile(gstin: '27ABCDE1234F1Z5', gstStatus: 'submitted'));
      final repo = repoFor(api);
      final current = await repo.getProfile();
      expect(current.freeAccess!.months, 6);
      expect(current.aadhaarStatus, ReviewStatus.submitted);

      final saved = await repo.updateProfile(current.copyWith(gstin: '27abcde1234f1z5', instagram: 'meera.art'));
      expect(api.bodiesOf('PATCH /v1/me/profile').single, {'gstin': '27ABCDE1234F1Z5'});
      expect(saved.gstStatus, ReviewStatus.submitted, reason: 'a new GST number goes back to review');

      await repo.updateBankDetails(accountNumber: ' 123456789012 ', ifsc: 'hdfc0001234');
      expect(api.bodiesOf('PATCH /v1/me/profile').last, {'bankAccountNumber': '123456789012', 'ifsc': 'HDFC0001234'});
    });

    test('settlements are the orders, pending until delivery plus the payout window', () async {
      Map<String, dynamic> row(String id, String status, List<Map<String, dynamic>> history) => {
            ..._order(id, status),
            'artistNetPaise': 10000000,
            'statusHistory': history,
          };
      final old = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final recent = DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String();
      final api = FakeApi()
        ..json('GET /v1/artist/orders', {
          'orders': [
            row('a', 'delivered', [
              {'status': 'paid', 'changedAt': old},
              {'status': 'delivered', 'changedAt': old},
            ]),
            row('b', 'delivered', [
              {'status': 'paid', 'changedAt': recent},
              {'status': 'delivered', 'changedAt': recent},
            ]),
            row('c', 'transit', [
              {'status': 'paid', 'changedAt': recent},
            ]),
            row('d', 'pending', [
              {'status': 'pending', 'changedAt': recent},
            ]),
          ],
        });
      final settlements = await repoFor(api).listSettlements();
      expect(settlements.map((s) => s.orderId), ['a', 'b', 'c'], reason: 'a pending order is not a sale yet');
      expect(settlements[0].status, SettlementStatus.processed);
      expect(settlements[1].status, SettlementStatus.pending);
      expect(settlements[1].releaseAfter, isNotNull);
      expect(settlements[2].status, SettlementStatus.pending);
      expect(settlements[2].releaseAfter, isNull, reason: 'no clock until it is delivered');
      expect(settlements[0].artistAmount, 100000);
    });

    test('the MOU: a signature of an older version reads as unsigned', () async {
      Map<String, dynamic> mou(String signedVersion) => {
            'acceptance': {
              'party': 'artist',
              'version': signedVersion,
              'signatureName': 'Meera Nair',
              'signatureDataUrl': 'data:image/png;base64,AAAA',
              'acceptedAt': '2026-09-20T10:00:00.000Z',
              'parties': {
                'party': {'name': 'Meera Nair', 'gstNo': null},
                'company': {'name': 'Galleryzone Private Limited', 'designation': null},
              },
            },
            'draft': {
              'version': '2026.3',
              'parties': {
                'party': {'name': 'Meera Nair'},
                'company': {'name': 'Galleryzone Private Limited'},
              },
              'missing': ['address'],
              'asOf': '2026-10-02T00:00:00.000Z',
            },
          };
      final api = FakeApi()..json('GET /v1/artist/mou', mou('2026.2'));
      final repo = repoFor(api);
      final stale = await repo.getMouState();
      expect(stale.acceptance, isNull);
      expect(stale.draft.version, '2026.3');
      expect(stale.draft.canSign, isFalse);
      expect(stale.draft.missing, ['address']);

      api.json('GET /v1/artist/mou', mou('2026.3'));
      final current = await repo.getMouState();
      expect(current.acceptance!.signatureName, 'Meera Nair');
      expect(current.acceptance!.parties!.company.name, 'Galleryzone Private Limited');
    });

    test('signing sends the version, the typed name and the drawn signature', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/mou/accept', {
          'party': 'artist',
          'version': '2026.3',
          'signatureName': 'Meera Nair',
          'signatureDataUrl': 'data:image/png;base64,AAAA',
          'acceptedAt': '2026-10-02T10:00:00.000Z',
          'parties': {'party': {}, 'company': {}},
        }, status: 201);
      final signed = await repoFor(api).acceptMou(
        signatureName: ' Meera Nair ',
        version: '2026.3',
        signatureDataUrl: 'data:image/png;base64,AAAA',
      );
      expect(api.bodiesOf('POST /v1/artist/mou/accept').single, {
        'version': '2026.3',
        'signatureName': 'Meera Nair',
        'signatureDataUrl': 'data:image/png;base64,AAAA',
      });
      expect(signed.version, '2026.3');
    });

    test('the published rules read as fractions and rupees', () async {
      final api = FakeApi()
        ..json('GET /v1/pricing-rules', {
          'rateConfigVersionId': 'v1',
          'rates': {
            'gstRate': 0.05,
            'platformMarkup': 0.3,
            'artistListingFeeRate': 0.01,
            'serviceGstRate': 0.18,
            'artistTdsRate': 0.001,
            'artistConvenienceRate': 0.02,
            'aggregatorCommissionRate': 0.2,
            'aggregatorAdvanceRate': 0.05,
            'nfcTagChargePaise': 10000,
            'subscriptionFeePaise': 120000,
            'deliveryChargePaise': 250000,
            'insuranceThresholdPaise': 2000000,
          },
        });
      final rules = (await repoFor(api).getPricingRules())!;
      expect(rules.artistListingFeeRate, 0.01);
      expect(rules.nfcTagCharge, 100);
      expect(rules.deliveryCharge, 2500);
      expect(rules.insuranceThreshold, 20000);
      expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('no rules in force reads as null', () async {
      final api = FakeApi()..json('GET /v1/pricing-rules', {'rates': null, 'rateConfigVersionId': null});
      expect(await repoFor(api).getPricingRules(), isNull);
    });
  });
}

Map<String, dynamic> _order(String id, String status) => {
      'id': id,
      'artworkId': 'aw-$id',
      'customerId': 'c',
      'addressId': 'ad',
      'displayPricePaise': 13650000,
      'gstPaise': 650000,
      'deliveryChargePaise': 250000,
      'convenienceFeePaise': 0,
      'convenienceGstPaise': 0,
      'totalPaise': 13900000,
      'status': status,
      'createdAt': '2026-09-01T00:00:00.000Z',
      'artwork': {'title': 'Piece $id', 'artistName': 'A', 'artistId': 'u1', 'thumbnailUrl': null, 'productCode': 'GZ1'},
    };
