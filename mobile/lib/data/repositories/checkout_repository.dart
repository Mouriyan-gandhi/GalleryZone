import '../models/order.dart';

/// Order placement and history (`orderService`). The delivery address book
/// lives on `CustomerRepository` — checkout reads it, but the collector's
/// account owns it.
///
/// Matches SAD §3.5's Order & Wallet module grouping; a dio-backed
/// implementation swaps in behind it unchanged.
abstract class CheckoutRepository {
  /// Places an order at the artwork's current `customerPrice`. Throws when
  /// the artwork is gone or already off the marketplace — a one-of-a-kind
  /// original can't be bought twice.
  /// Places an order and takes payment in one call, because the mock
  /// "gateway" is not a separate system. [simulateFailure] drives the
  /// declined-payment path from the payment sheet's own toggle.
  Future<Order> createOrder({
    required String artworkId,
    required String addressId,
    required PaymentMethod paymentMethod,
    bool simulateFailure,
  });

  /// Moves an order one step along `orderProgression`. Nothing else advances
  /// an order in this build — there is no fulfilment system behind it, so the
  /// demo drives it by hand from the order screen.
  Future<Order> advanceOrder(String id);

  Future<List<Order>> listOrders();

  Future<Order?> getOrder(String id);
}
