import '../models/artwork.dart';
import '../models/order.dart';
import '../repositories/checkout_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/customer_seed.dart';

/// GST rate and flat delivery charge, pinned here as the single source of
/// truth exactly as `orderService.ts` pins them — the checkout review step
/// mirrors this math for its price preview, so the two must stay in sync.
const checkoutGstRate = 0.05;
const checkoutDeliveryCharge = 250.0;

const _ordersKey = 'orders';
const _artworksKey = 'artworks';

class MockCheckoutRepository implements CheckoutRepository {
  List<Order> _readOrders() =>
      MockDb.getCollection(_ordersKey, seedOrders, Order.fromJson, (o) => o.toJson());

  @override
  Future<List<Order>> listOrders() => mockDelay(_readOrders);

  @override
  Future<Order?> getOrder(String id) =>
      mockDelay(() => _readOrders().where((o) => o.id == id).firstOrNull);

  @override
  Future<Order> createOrder({required String artworkId, required String addressId}) {
    final artworks = MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
    final artwork = artworks.where((a) => a.id == artworkId).firstOrNull;
    if (artwork == null) return mockError('Artwork not found');
    if (artwork.status != ArtworkStatus.marketplace) {
      return mockError('This artwork is no longer available for purchase');
    }

    final now = DateTime.now().toIso8601String();
    final order = Order(
      id: 'order-${DateTime.now().microsecondsSinceEpoch}',
      artworkId: artworkId,
      addressId: addressId,
      amount: artwork.customerPrice,
      gstAmount: (artwork.customerPrice * checkoutGstRate * 100).round() / 100,
      deliveryCharge: checkoutDeliveryCharge,
      status: OrderStatus.pending,
      createdAt: now,
      statusHistory: [OrderStatusEvent(status: OrderStatus.pending, changedAt: now)],
    );
    MockDb.setCollection(_ordersKey, [order, ..._readOrders()], (o) => o.toJson());

    // Sold artworks come off the open marketplace — pipeline Stage 9 ("Sale
    // & Ownership Transfer"): a sold one-of-a-kind original can't be bought
    // twice. The web's `create` also settles the sale into the artist's
    // wallet; those collections don't exist here until Phase 5 builds the
    // artist portal, so that half lands with them.
    MockDb.setCollection(
      _artworksKey,
      artworks
          .map(
            (a) => a.id != artworkId
                ? a
                : a.copyWith(
                    status: ArtworkStatus.sold,
                    statusHistory: [
                      ...a.statusHistory,
                      ArtworkStatusEvent(status: ArtworkStatus.sold, changedAt: now),
                    ],
                  ),
          )
          .toList(),
      (a) => a.toJson(),
    );

    return mockDelay(() => order);
  }
}
