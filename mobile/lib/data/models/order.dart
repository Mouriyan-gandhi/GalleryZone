import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Mirrors `types/order.ts` and `types/customer.ts`'s `Address` — both are
/// checkout inputs/outputs, so they live in one file rather than two
/// three-field ones.
enum OrderStatus { pending, paid, confirmed, packed, transit, delivered, cancelled }

/// How the buyer paid. No gateway is contacted — see the payment sheet.
enum PaymentMethod { upi, card, netbanking }

const paymentMethodLabel = {
  PaymentMethod.upi: 'UPI',
  PaymentMethod.card: 'Card',
  PaymentMethod.netbanking: 'Net banking',
};

@freezed
abstract class Address with _$Address {
  const factory Address({
    required String id,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    required bool isDefault,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}

@freezed
abstract class OrderStatusEvent with _$OrderStatusEvent {
  const factory OrderStatusEvent({
    required OrderStatus status,
    required String changedAt, // ISO date, String like the web model
  }) = _OrderStatusEvent;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusEventFromJson(json);
}

/// What was bought, as it was when it was bought — the API joins this onto
/// every order so a list needs no second lookup per row (and so an order
/// still reads correctly after the piece has left the marketplace).
@freezed
abstract class OrderArtwork with _$OrderArtwork {
  const factory OrderArtwork({
    required String title,
    required String artistName,
    @Default('') String artistId,
    @Default('') String thumbnailUrl,
    @Default('') String productCode,
  }) = _OrderArtwork;

  factory OrderArtwork.fromJson(Map<String, dynamic> json) => _$OrderArtworkFromJson(json);
}

/// The gateway's record of how an order was paid.
@freezed
abstract class OrderPayment with _$OrderPayment {
  const factory OrderPayment({
    /// The gateway's payment id (empty when simulated).
    @Default('') String paymentId,
    @Default('') String method,

    /// True when no money moved — a test-mode / simulated payment.
    @Default(false) bool simulated,
  }) = _OrderPayment;

  factory OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String artworkId,
    required String addressId,
    /// The artwork's customerPrice at time of purchase. GST is already
    /// inside this figure — see [gstAmount].
    required double amount,

    /// The GST portion of [amount], recorded so a past receipt can show the
    /// tax component. Never added to [total]; it is already in [amount].
    required double gstAmount,
    required double deliveryCharge,
    required OrderStatus status,
    required String createdAt,
    required List<OrderStatusEvent> statusHistory,

    /// Null on the seeded fixture orders, which predate the payment step.
    PaymentMethod? paymentMethod,

    /// GalleryZone's convenience fee on the order, and the 18% service GST on
    /// that fee. Both are zero today (the sheet carries it "for future").
    @Default(0) double convenienceFee,
    @Default(0) double convenienceGst,

    /// The piece as bought. Null on the offline fixtures.
    OrderArtwork? artwork,

    /// Null until the gateway has captured a payment.
    OrderPayment? payment,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// GST is inside [amount], so adding [gstAmount] here would charge the
  /// buyer for it twice — which is exactly what this used to do. The
  /// convenience fee is a separate service charge (with its own GST), so it
  /// does add on.
  double get total => amount + deliveryCharge + convenienceFee + convenienceGst;
}

/// What an artwork costs at checkout, quoted by the server from the pricing
/// rules in force right now (`GET /v1/artworks/:id/quote`). The checkout
/// screens show this instead of computing a ladder locally, so a preview can
/// never disagree with the order the server then creates — and an admin
/// changing a rate moves every screen at once.
class CheckoutQuote {
  const CheckoutQuote({
    required this.artworkId,
    required this.displayPrice,
    required this.gstIncluded,
    required this.gstRate,
    required this.convenienceFee,
    required this.convenienceGst,
    required this.deliveryCharge,
    required this.total,
  });

  final String artworkId;

  /// The price shown on the card — GST already inside it.
  final double displayPrice;
  final double gstIncluded;

  /// The artwork GST rate in force, as a fraction (`0.05` = 5%).
  final double gstRate;
  final double convenienceFee;
  final double convenienceGst;
  final double deliveryCharge;
  final double total;
}
