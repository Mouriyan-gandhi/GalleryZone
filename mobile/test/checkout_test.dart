import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/pricing.dart';
import 'package:gallery_zone/data/mock/mock_checkout_repository.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/order.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artwork _artwork({ArtworkStatus status = ArtworkStatus.marketplace}) => Artwork(
      id: 'aw-1',
      title: 'Monsoon, Madurai',
      artistId: 'ar-1',
      artistName: 'Ananya Rao',
      verifiedArtist: true,
      category: 'painting',
      medium: 'Oil on canvas',
      customerPrice: 48000,
      thumbnailUrl: '/artworks/bird.png',
      insured: true,
      status: status,
      listingType: ListingType.marketplaceOnly,
      description: 'A study in rain light.',
      images: const [],
      coaCertificateNumber: 'GZ-COA-0001',
      coaIssueDate: '2025-03-04',
      socialProofLinks: const [],
      statusHistory: const [],
    );

void _seedArtworks(List<Artwork> artworks) =>
    MockDb.setCollection('artworks', artworks, (a) => a.toJson());

List<Artwork> _readArtworks() => MockDb.getCollection(
      'artworks',
      () => const <Artwork>[],
      Artwork.fromJson,
      (a) => a.toJson(),
    );

void main() {
  late MockCheckoutRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    repository = MockCheckoutRepository();
  });

  test('createOrder charges 5% GST plus flat delivery, and takes the piece off the marketplace',
      () async {
    _seedArtworks([_artwork()]);

    final order = await repository.createOrder(
      artworkId: 'aw-1',
      addressId: 'addr-home-pune',
      paymentMethod: PaymentMethod.upi,
    );

    // GST is INSIDE the price, not added to it: 48,000 already contains
    // 2,286 of tax, and the buyer pays the price plus delivery only.
    expect(order.amount, 48000);
    expect(order.gstAmount, gstIncludedIn(48000));
    expect(order.deliveryCharge, deliveryCharge);
    expect(order.total, 48000 + deliveryCharge);
    // Payment succeeds inside createOrder, so an order is never observable
    // in `pending` — but the event is still on the timeline.
    expect(order.status, OrderStatus.paid);
    expect(order.paymentMethod, PaymentMethod.upi);
    expect(order.statusHistory.map((e) => e.status), [OrderStatus.pending, OrderStatus.paid]);

    // A one-of-a-kind original can't be bought twice.
    expect(_readArtworks().single.status, ArtworkStatus.sold);
    expect(_readArtworks().single.statusHistory.last.status, ArtworkStatus.sold);
    // Six seeded orders (ported from the web fixtures) plus this one.
    expect(await repository.listOrders(), hasLength(7));
    expect((await repository.listOrders()).first.id, order.id);
  });

  test('an artwork that is already sold cannot be ordered', () async {
    _seedArtworks([_artwork(status: ArtworkStatus.sold)]);

    expect(
      () => repository.createOrder(
        artworkId: 'aw-1',
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.upi,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('an unknown artwork cannot be ordered', () async {
    _seedArtworks([_artwork()]);

    expect(
      () => repository.createOrder(
        artworkId: 'nope',
        addressId: 'addr-home-pune',
        paymentMethod: PaymentMethod.upi,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
