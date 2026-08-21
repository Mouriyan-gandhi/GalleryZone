// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aggregator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeliveryAddress _$DeliveryAddressFromJson(Map<String, dynamic> json) =>
    _DeliveryAddress(
      line1: json['line1'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
    );

Map<String, dynamic> _$DeliveryAddressToJson(_DeliveryAddress instance) =>
    <String, dynamic>{
      'line1': instance.line1,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
    };

_AggregatorSale _$AggregatorSaleFromJson(Map<String, dynamic> json) =>
    _AggregatorSale(
      id: json['id'] as String,
      holdingId: json['holdingId'] as String,
      artworkId: json['artworkId'] as String,
      soldPrice: (json['soldPrice'] as num).toDouble(),
      buyerName: json['buyerName'] as String,
      buyerEmail: json['buyerEmail'] as String,
      buyerPhone: json['buyerPhone'] as String,
      deliveryAddress: DeliveryAddress.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>,
      ),
      deliveryMode: $enumDecode(_$DeliveryModeEnumMap, json['deliveryMode']),
      soldAt: json['soldAt'] as String,
      shipmentStatus: $enumDecode(
        _$ShipmentStatusEnumMap,
        json['shipmentStatus'],
      ),
      dispatchedAt: json['dispatchedAt'] as String?,
      deliveredAt: json['deliveredAt'] as String?,
      courierRef: json['courierRef'] as String?,
    );

Map<String, dynamic> _$AggregatorSaleToJson(_AggregatorSale instance) =>
    <String, dynamic>{
      'id': instance.id,
      'holdingId': instance.holdingId,
      'artworkId': instance.artworkId,
      'soldPrice': instance.soldPrice,
      'buyerName': instance.buyerName,
      'buyerEmail': instance.buyerEmail,
      'buyerPhone': instance.buyerPhone,
      'deliveryAddress': instance.deliveryAddress,
      'deliveryMode': _$DeliveryModeEnumMap[instance.deliveryMode]!,
      'soldAt': instance.soldAt,
      'shipmentStatus': _$ShipmentStatusEnumMap[instance.shipmentStatus]!,
      'dispatchedAt': instance.dispatchedAt,
      'deliveredAt': instance.deliveredAt,
      'courierRef': instance.courierRef,
    };

const _$DeliveryModeEnumMap = {
  DeliveryMode.courier: 'courier',
  DeliveryMode.selfPickup: 'self_pickup',
};

const _$ShipmentStatusEnumMap = {
  ShipmentStatus.preparing: 'preparing',
  ShipmentStatus.dispatched: 'dispatched',
  ShipmentStatus.delivered: 'delivered',
};

_GallerySpace _$GallerySpaceFromJson(Map<String, dynamic> json) =>
    _GallerySpace(
      id: json['id'] as String,
      name: json['name'] as String,
      addressLine1: json['addressLine1'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      capacity: (json['capacity'] as num).toInt(),
      coordinatorName: json['coordinatorName'] as String,
    );

Map<String, dynamic> _$GallerySpaceToJson(_GallerySpace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'addressLine1': instance.addressLine1,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'capacity': instance.capacity,
      'coordinatorName': instance.coordinatorName,
    };

_AggregatorProfile _$AggregatorProfileFromJson(Map<String, dynamic> json) =>
    _AggregatorProfile(
      companyName: json['companyName'] as String,
      contactPerson: json['contactPerson'] as String,
      avatar: json['avatar'] as String,
      gstNumber: json['gstNumber'] as String,
      phone: json['phone'] as String,
      addressLine1: json['addressLine1'] as String,
      bankAccountMasked: json['bankAccountMasked'] as String,
      ifsc: json['ifsc'] as String,
      securityDepositStatus: json['securityDepositStatus'] as String,
    );

Map<String, dynamic> _$AggregatorProfileToJson(_AggregatorProfile instance) =>
    <String, dynamic>{
      'companyName': instance.companyName,
      'contactPerson': instance.contactPerson,
      'avatar': instance.avatar,
      'gstNumber': instance.gstNumber,
      'phone': instance.phone,
      'addressLine1': instance.addressLine1,
      'bankAccountMasked': instance.bankAccountMasked,
      'ifsc': instance.ifsc,
      'securityDepositStatus': instance.securityDepositStatus,
    };

_AggregatorSettings _$AggregatorSettingsFromJson(Map<String, dynamic> json) =>
    _AggregatorSettings(
      notifyNewAssignment: json['notifyNewAssignment'] as bool,
      notifySaleRecorded: json['notifySaleRecorded'] as bool,
      notifySettlementProcessed: json['notifySettlementProcessed'] as bool,
      notifyExpiryReminder: json['notifyExpiryReminder'] as bool,
    );

Map<String, dynamic> _$AggregatorSettingsToJson(_AggregatorSettings instance) =>
    <String, dynamic>{
      'notifyNewAssignment': instance.notifyNewAssignment,
      'notifySaleRecorded': instance.notifySaleRecorded,
      'notifySettlementProcessed': instance.notifySettlementProcessed,
      'notifyExpiryReminder': instance.notifyExpiryReminder,
    };
