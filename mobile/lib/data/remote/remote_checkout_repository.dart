import 'dart:math';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/api/json_utils.dart';
import '../../core/payments/payment_gateway.dart';
import '../models/order.dart';
import '../repositories/checkout_repository.dart';
import 'mappers/commerce_mappers.dart';

/// Buying, against the real API.
///
/// Money is computed on the server from the artwork's pricing record and the
/// pricing rules in force; the order a buyer sees is exactly what the ledger
/// was posted from. The flow mirrors the website's `orderService.create`:
///
///  1. create the order (pending) with a once-per-attempt idempotency key;
///  2. ask the API for a payment session;
///  3. real gateway: open the payment sheet, then hand the SIGNED result back
///     — the API checks the signature before it marks anything paid;
///     simulated mode (the API says so): the buyer's own simulate call;
///  4. read the order back.
class RemoteCheckoutRepository implements CheckoutRepository {
  RemoteCheckoutRepository({required this.api, required this.gateway, Random? random})
      : _random = random ?? Random.secure();

  final ApiClient api;
  final PaymentGateway gateway;
  final Random _random;

  /// 32 hex characters; the API requires at least 16. One per checkout
  /// attempt, so a double tap or a retried request cannot create two orders.
  String _idempotencyKey() =>
      List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  @override
  Future<CheckoutQuote> getQuote(String artworkId) async =>
      quoteFromApi(await api.getMap('/v1/artworks/${Uri.encodeComponent(artworkId)}/quote', auth: false));

  @override
  Future<Order> createOrder({
    required String artworkId,
    required String addressId,
    required PaymentMethod paymentMethod,
    bool simulateFailure = false,
  }) async {
    final created = await api.post(
      '/v1/orders',
      body: {'artworkId': artworkId, 'addressId': addressId, 'idempotencyKey': _idempotencyKey()},
    );
    final orderId = asMap(created)['orderId'] as String? ?? '';
    if (orderId.isEmpty) throw const ApiError(status: 0, code: 'bad_response', message: 'The order could not be created.');
    final base = '/v1/orders/${Uri.encodeComponent(orderId)}';

    final session = asMap(await api.post('$base/payment/session'));
    if (session['mode'] == 'razorpay') {
      // Closing the sheet leaves the order pending; the exception says so.
      final paid = await gateway.pay(GatewaySession.fromApi(session));
      await api.post(
        '$base/payment/verify',
        body: {
          'razorpayOrderId': paid.orderId,
          'razorpayPaymentId': paid.paymentId,
          'signature': paid.signature,
        },
      );
    } else {
      await api.post('$base/simulate-payment');
    }

    final order = await getOrder(orderId);
    if (order == null) {
      throw const ApiError(status: 0, code: 'bad_response', message: 'Your order was placed but could not be read back.');
    }
    return order;
  }

  /// Nothing advances an order from the phone: fulfilment belongs to
  /// GalleryZone's operations team, who move it forward in the admin console.
  @override
  Future<Order> advanceOrder(String id) =>
      Future.error(UnsupportedError('Orders are moved along by GalleryZone, not from the app.'));

  @override
  Future<List<Order>> listOrders() async {
    final rows = await api.getList('/v1/orders');
    return rows.map(orderFromApi).toList();
  }

  @override
  Future<Order?> getOrder(String id) async {
    try {
      return orderFromApi(await api.getMap('/v1/orders/${Uri.encodeComponent(id)}'));
    } on ApiError catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }
}
