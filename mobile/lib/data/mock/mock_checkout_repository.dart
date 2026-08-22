import '../models/artwork.dart';
import '../models/order.dart';
import '../repositories/checkout_repository.dart';
import '../storage/mock_db.dart';
import '../models/customer.dart';
import 'mock_artist_repository.dart' show creditArtistForSale, settleArtistForOrder;
import 'mock_customer_repository.dart'
    show activeResaleListing, creditSellerForResale, settleSellerForResale;
import 'mock_artwork_repository.dart' show promoteApprovedSubmissions, seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/customer_seed.dart';

/// GST rate and flat delivery charge, pinned here as the single source of
/// truth exactly as `orderService.ts` pins them — the checkout review step
/// mirrors this math for its price preview, so the two must stay in sync.
const checkoutGstRate = 0.05;
const checkoutDeliveryCharge = 250.0;

/// Platform fee and convenience fee are ₹0 during the early launch period.
/// They apply equally to marketplace and aggregator-channel sales. Change
/// them here when pricing is finalised — nowhere else.
const checkoutPlatformFee = 0.0;
const checkoutConvenienceFee = 0.0;

const _ordersKey = 'orders';
const _artworksKey = 'artworks';

/// The order lifecycle, in order. `cancelled` is not on this path — nothing
/// in the app cancels an order.
const orderProgression = [
  OrderStatus.pending,
  OrderStatus.paid,
  OrderStatus.confirmed,
  OrderStatus.packed,
  OrderStatus.transit,
  OrderStatus.delivered,
];

class MockCheckoutRepository implements CheckoutRepository {
  List<Order> _readOrders() =>
      MockDb.getCollection(_ordersKey, seedOrders, Order.fromJson, (o) => o.toJson());

  List<Artwork> _readArtworks() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
  }

  void _writeArtwork(Artwork updated) => MockDb.setCollection(
    _artworksKey,
    [for (final a in _readArtworks()) a.id == updated.id ? updated : a],
    (a) => a.toJson(),
  );

  @override
  Future<List<Order>> listOrders() => mockDelay(_readOrders);

  @override
  Future<Order?> getOrder(String id) =>
      mockDelay(() => _readOrders().where((o) => o.id == id).firstOrNull);

  @override
  Future<Order> createOrder({
    required String artworkId,
    required String addressId,
    required PaymentMethod paymentMethod,
    bool simulateFailure = false,
  }) {
    // The mock payment "gateway": the only thing standing between the buyer
    // and an order. A real one goes here, behind this same call — which is
    // why the declined path is exercised rather than assumed.
    if (simulateFailure) {
      return mockError('Payment declined by your bank. No money has been taken.');
    }

    final artworks = _readArtworks();
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
      // Paid on arrival: payment succeeded a line ago, so the order is never
      // observable in `pending`. The event stays in the history because the
      // buyer's status timeline should still show that it happened.
      status: OrderStatus.paid,
      createdAt: now,
      paymentMethod: paymentMethod,
      statusHistory: [
        OrderStatusEvent(status: OrderStatus.pending, changedAt: now),
        OrderStatusEvent(status: OrderStatus.paid, changedAt: now),
      ],
    );
    MockDb.setCollection(_ordersKey, [order, ..._readOrders()], (o) => o.toJson());

    // Sold artworks come off the open marketplace — pipeline Stage 9 ("Sale
    // & Ownership Transfer"): a sold one-of-a-kind original can't be bought
    // twice.
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

    // Who gets paid depends on who is selling. On a resale the money is the
    // reselling collector's, not the artist's — the artist was paid the first
    // time this piece sold, and paying them again for someone else's sale is
    // the obvious bug in a marketplace that handles both.
    final resale = activeResaleListing(artworkId);
    if (resale != null) {
      creditSellerForResale(listing: resale, amount: artwork.customerPrice);
    } else {
      creditArtistForSale(artwork: artwork, orderId: order.id);
    }

    return mockDelay(() => order);
  }

  /// The resale listing this order bought, if any. Matched on the pending
  /// wallet row rather than the listing's status, because the listing was
  /// already closed at purchase time.
  ResaleListing? _resaleListingFor(Order order) => MockDb.getCollection(
    'customerResaleListings',
    () => const <ResaleListing>[],
    ResaleListing.fromJson,
    (l) => l.toJson(),
  ).where((l) => l.artworkId == order.artworkId && l.status == ResaleListingStatus.sold).firstOrNull;

  @override
  Future<Order> advanceOrder(String id) {
    final orders = _readOrders();
    final order = orders.where((o) => o.id == id).firstOrNull;
    if (order == null) return mockError('Order not found');

    final index = orderProgression.indexOf(order.status);
    if (index == -1 || index == orderProgression.length - 1) {
      return mockError('This order is already delivered');
    }

    return mockDelay(() {
      final next = orderProgression[index + 1];
      final now = DateTime.now().toIso8601String();
      final updated = order.copyWith(
        status: next,
        statusHistory: [
          ...order.statusHistory,
          OrderStatusEvent(status: next, changedAt: now),
        ],
      );
      MockDb.setCollection(
        _ordersKey,
        [for (final o in orders) o.id == id ? updated : o],
        (o) => o.toJson(),
      );

      if (next == OrderStatus.delivered) {
        final artwork = _readArtworks().where((a) => a.id == order.artworkId).firstOrNull;
        if (artwork != null) {
          // Delivery moves both the record and the money: the piece is now
          // owned by and with the collector, and the artist's pending credit
          // becomes withdrawable.
          _writeArtwork(
            artwork.copyWith(
              status: ArtworkStatus.delivered,
              statusHistory: [
                ...artwork.statusHistory,
                ArtworkStatusEvent(status: ArtworkStatus.delivered, changedAt: now),
              ],
              custody: const ArtworkCustody(
                legalOwner: CustodyParty.customer,
                custodian: CustodyParty.customer,
                locationLabel: 'With the collector',
              ),
            ),
          );
          final soldResale = _resaleListingFor(order);
          if (soldResale != null) {
            settleSellerForResale(listingId: soldResale.id, amount: order.amount);
          } else {
            settleArtistForOrder(
              artwork: artwork,
              orderId: order.id,
              orderAmount: order.amount,
            );
          }
        }
      }

      return updated;
    });
  }
}
