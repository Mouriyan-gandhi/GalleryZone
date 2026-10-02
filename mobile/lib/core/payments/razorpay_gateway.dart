import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_gateway.dart';

/// The real payment sheet: Razorpay's own checkout, drawn by their SDK.
///
/// The app only ever holds the public key id and the gateway's order id the API
/// hands back for this purchase. The secret stays on the server, which checks
/// the signed result before it believes any of it - so a tampered result from
/// a modified app buys nothing.
class RazorpayGateway implements PaymentGateway {
  const RazorpayGateway();

  @override
  Future<GatewayPayment> pay(GatewaySession session) {
    final result = Completer<GatewayPayment>();
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (result.isCompleted) return;
      result.complete(
        GatewayPayment(
          orderId: response.orderId ?? session.gatewayOrderId,
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (result.isCompleted) return;
      // Closing the sheet is not a failed payment: nothing was charged and the
      // order stays pending.
      result.completeError(
        response.code == Razorpay.PAYMENT_CANCELLED
            ? const PaymentDismissedException()
            : PaymentFailedException(
                (response.message ?? '').trim().isEmpty
                    ? 'The payment did not go through. Nothing was charged.'
                    : response.message!.trim(),
              ),
      );
    });
    // A wallet app took over (Paytm etc.); Razorpay reports the outcome through
    // the success / error events above, so there is nothing to do here.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {});

    razorpay.open({
      'key': session.keyId,
      'order_id': session.gatewayOrderId,
      'amount': session.amountPaise,
      'currency': session.currency,
      'name': session.name,
      'description': session.description,
      'prefill': {
        'name': session.prefillName,
        'email': session.prefillEmail,
        'contact': session.prefillContact,
      },
      'theme': {'color': '#B8892B'},
    });

    return result.future.whenComplete(razorpay.clear);
  }
}
