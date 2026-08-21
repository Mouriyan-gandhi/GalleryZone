// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Address _$AddressFromJson(Map<String, dynamic> json) => _Address(
  id: json['id'] as String,
  line1: json['line1'] as String,
  line2: json['line2'] as String?,
  city: json['city'] as String,
  state: json['state'] as String,
  pincode: json['pincode'] as String,
  isDefault: json['isDefault'] as bool,
);

Map<String, dynamic> _$AddressToJson(_Address instance) => <String, dynamic>{
  'id': instance.id,
  'line1': instance.line1,
  'line2': instance.line2,
  'city': instance.city,
  'state': instance.state,
  'pincode': instance.pincode,
  'isDefault': instance.isDefault,
};

_OrderStatusEvent _$OrderStatusEventFromJson(Map<String, dynamic> json) =>
    _OrderStatusEvent(
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      changedAt: json['changedAt'] as String,
    );

Map<String, dynamic> _$OrderStatusEventToJson(_OrderStatusEvent instance) =>
    <String, dynamic>{
      'status': _$OrderStatusEnumMap[instance.status]!,
      'changedAt': instance.changedAt,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.paid: 'paid',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.packed: 'packed',
  OrderStatus.transit: 'transit',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  artworkId: json['artworkId'] as String,
  addressId: json['addressId'] as String,
  amount: (json['amount'] as num).toDouble(),
  gstAmount: (json['gstAmount'] as num).toDouble(),
  deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  createdAt: json['createdAt'] as String,
  statusHistory: (json['statusHistory'] as List<dynamic>)
      .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  paymentMethod: $enumDecodeNullable(
    _$PaymentMethodEnumMap,
    json['paymentMethod'],
  ),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'artworkId': instance.artworkId,
  'addressId': instance.addressId,
  'amount': instance.amount,
  'gstAmount': instance.gstAmount,
  'deliveryCharge': instance.deliveryCharge,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt,
  'statusHistory': instance.statusHistory,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.upi: 'upi',
  PaymentMethod.card: 'card',
  PaymentMethod.netbanking: 'netbanking',
};
