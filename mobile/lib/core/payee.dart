/// GalleryZone's own collection account — where buyers send money.
///
/// The client's rule: the aggregator collects "on behalf of GalleryZone",
/// never for themselves. A buyer standing in a partner gallery pays into THIS
/// account, either by transfer or by scanning the UPI code. If they hand over
/// cash instead, the aggregator owes GalleryZone the WHOLE sale price and
/// their commission is settled separately afterwards — they never net it off
/// themselves.
///
/// Placeholder values until the real account is handed over, same as the logo
/// and the insurance partner URL. [payeeUpiId] being null is what keeps the
/// checkout from showing a QR that scans to nowhere.
///
/// Port of `frontend-web/lib/payee.ts` — one account number, typed once.
library;

class Payee {
  const Payee._();

  static const accountName = 'GalleryZone Art Ventures Pvt Ltd';
  static const accountNumber = '50200098765432';
  static const ifsc = 'HDFC0001234';
  static const bankName = 'HDFC Bank';
  static const branch = 'Udaipur Main';
}

/// Null until the live VPA is provided — see the QR panel in checkout.
const String? payeeUpiId = null;

/// The UPI intent a QR would encode. Returned only when there is a real VPA to
/// encode, so nothing ever renders a code that resolves to nothing.
String? upiIntentFor(double amount, String note) {
  final vpa = payeeUpiId;
  if (vpa == null) return null;
  final params = <String, String>{
    'pa': vpa,
    'pn': Payee.accountName,
    'am': amount.toStringAsFixed(2),
    'cu': 'INR',
    'tn': note,
  };
  final query = params.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return 'upi://pay?$query';
}
