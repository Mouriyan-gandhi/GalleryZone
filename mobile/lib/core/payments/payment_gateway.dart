/// The payment sheet, behind an interface.
///
/// The repositories decide *when* money moves (create the order, ask the API
/// for a gateway session, hand the signed result back for verification); the
/// gateway only draws the sheet and reports what the buyer did. That split
/// keeps the Razorpay SDK — a native plugin that needs a live Activity — out
/// of the data layer and out of the tests.
library;

/// What the API hands back for `POST …/payment/session` (and for an
/// aggregator's wallet top-up) when the real gateway is on: the public key
/// and the gateway's own order id. The secret never leaves the server.
class GatewaySession {
  const GatewaySession({
    required this.keyId,
    required this.gatewayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.description,
    this.prefillName = '',
    this.prefillEmail = '',
    this.prefillContact = '',
  });

  final String keyId;
  final String gatewayOrderId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final String prefillName;
  final String prefillEmail;
  final String prefillContact;

  factory GatewaySession.fromApi(Map<String, dynamic> json) {
    final prefill = json['prefill'] is Map ? Map<String, dynamic>.from(json['prefill'] as Map) : const <String, dynamic>{};
    return GatewaySession(
      keyId: json['keyId'] as String? ?? '',
      gatewayOrderId: json['razorpayOrderId'] as String? ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      name: json['name'] as String? ?? 'GalleryZone',
      description: json['description'] as String? ?? '',
      prefillName: prefill['name'] as String? ?? '',
      prefillEmail: prefill['email'] as String? ?? '',
      prefillContact: prefill['contact'] as String? ?? '',
    );
  }
}

/// The signed result of a successful payment — handed to the API, which
/// checks the signature before it believes any of it.
class GatewayPayment {
  const GatewayPayment({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

/// The buyer closed the payment sheet without paying. Not a failure: nothing
/// was charged, and the order simply stays pending.
class PaymentDismissedException implements Exception {
  const PaymentDismissedException();

  @override
  String toString() => 'Exception: Payment was cancelled';
}

/// The gateway reported a failed or declined payment.
class PaymentFailedException implements Exception {
  const PaymentFailedException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

abstract class PaymentGateway {
  /// Opens the payment sheet for [session] and resolves with the signed
  /// result. Throws [PaymentDismissedException] if it is closed without a
  /// payment and [PaymentFailedException] if the payment fails.
  Future<GatewayPayment> pay(GatewaySession session);
}

/// Stands in until a real gateway is registered, and in every test. Refuses
/// plainly rather than pretending a payment happened.
class UnavailablePaymentGateway implements PaymentGateway {
  const UnavailablePaymentGateway();

  @override
  Future<GatewayPayment> pay(GatewaySession session) {
    throw const PaymentFailedException("Online payment isn't available in this build.");
  }
}
