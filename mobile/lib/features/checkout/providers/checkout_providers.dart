import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/payments/payment_gateway.dart';
import '../../../data/mock/mock_checkout_repository.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return MockCheckoutRepository();
});

/// The payment sheet. `main()` registers the real one; until then (and in
/// every test) it is a stand-in that says online payment isn't available.
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return const UnavailablePaymentGateway();
});

/// What an artwork costs at checkout, quoted by the server from the pricing
/// rules in force right now — price (GST inside), the convenience fee and its
/// GST, delivery, total. The review and payment steps show exactly this, so a
/// preview can never disagree with the order that follows.
final checkoutQuoteProvider = FutureProvider.autoDispose.family<CheckoutQuote, String>((ref, artworkId) {
  return ref.watch(checkoutRepositoryProvider).getQuote(artworkId);
});
