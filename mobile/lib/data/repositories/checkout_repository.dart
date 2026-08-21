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
  Future<Order> createOrder({required String artworkId, required String addressId});

  Future<List<Order>> listOrders();

  Future<Order?> getOrder(String id);
}
