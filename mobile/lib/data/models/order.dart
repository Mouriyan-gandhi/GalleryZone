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

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String artworkId,
    required String addressId,
    required double amount, // artwork's customerPrice at time of purchase
    required double gstAmount,
    required double deliveryCharge,
    required OrderStatus status,
    required String createdAt,
    required List<OrderStatusEvent> statusHistory,

    /// Null on the seeded fixture orders, which predate the payment step.
    PaymentMethod? paymentMethod,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  double get total => amount + gstAmount + deliveryCharge;
}
