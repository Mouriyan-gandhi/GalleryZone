// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aggregator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeliveryAddress {

 String get line1; String get city; String get state; String get pincode;
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<DeliveryAddress> get copyWith => _$DeliveryAddressCopyWithImpl<DeliveryAddress>(this as DeliveryAddress, _$identity);

  /// Serializes this DeliveryAddress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryAddress&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line1,city,state,pincode);

@override
String toString() {
  return 'DeliveryAddress(line1: $line1, city: $city, state: $state, pincode: $pincode)';
}


}

/// @nodoc
abstract mixin class $DeliveryAddressCopyWith<$Res>  {
  factory $DeliveryAddressCopyWith(DeliveryAddress value, $Res Function(DeliveryAddress) _then) = _$DeliveryAddressCopyWithImpl;
@useResult
$Res call({
 String line1, String city, String state, String pincode
});




}
/// @nodoc
class _$DeliveryAddressCopyWithImpl<$Res>
    implements $DeliveryAddressCopyWith<$Res> {
  _$DeliveryAddressCopyWithImpl(this._self, this._then);

  final DeliveryAddress _self;
  final $Res Function(DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line1 = null,Object? city = null,Object? state = null,Object? pincode = null,}) {
  return _then(DeliveryAddress(
line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryAddress].
extension DeliveryAddressPatterns on DeliveryAddress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryAddress value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryAddress value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String line1,  String city,  String state,  String pincode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.line1,_that.city,_that.state,_that.pincode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String line1,  String city,  String state,  String pincode)  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that.line1,_that.city,_that.state,_that.pincode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String line1,  String city,  String state,  String pincode)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.line1,_that.city,_that.state,_that.pincode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryAddress implements DeliveryAddress {
  const _DeliveryAddress({required this.line1, required this.city, required this.state, required this.pincode});
  factory _DeliveryAddress.fromJson(Map<String, dynamic> json) => _$DeliveryAddressFromJson(json);

@override final  String line1;
@override final  String city;
@override final  String state;
@override final  String pincode;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryAddressCopyWith<_DeliveryAddress> get copyWith => __$DeliveryAddressCopyWithImpl<_DeliveryAddress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryAddressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryAddress&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line1,city,state,pincode);

@override
String toString() {
  return 'DeliveryAddress(line1: $line1, city: $city, state: $state, pincode: $pincode)';
}


}

/// @nodoc
abstract mixin class _$DeliveryAddressCopyWith<$Res> implements $DeliveryAddressCopyWith<$Res> {
  factory _$DeliveryAddressCopyWith(_DeliveryAddress value, $Res Function(_DeliveryAddress) _then) = __$DeliveryAddressCopyWithImpl;
@override @useResult
$Res call({
 String line1, String city, String state, String pincode
});




}
/// @nodoc
class __$DeliveryAddressCopyWithImpl<$Res>
    implements _$DeliveryAddressCopyWith<$Res> {
  __$DeliveryAddressCopyWithImpl(this._self, this._then);

  final _DeliveryAddress _self;
  final $Res Function(_DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line1 = null,Object? city = null,Object? state = null,Object? pincode = null,}) {
  return _then(_DeliveryAddress(
line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AggregatorSale {

 String get id; String get holdingId; String get artworkId; double get soldPrice; String get buyerName; String get buyerEmail; String get buyerPhone; DeliveryAddress get deliveryAddress; DeliveryMode get deliveryMode; String get soldAt; ShipmentStatus get shipmentStatus; String? get dispatchedAt; String? get deliveredAt;/// Null when [deliveryMode] is [DeliveryMode.selfPickup].
 String? get courierRef;
/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AggregatorSaleCopyWith<AggregatorSale> get copyWith => _$AggregatorSaleCopyWithImpl<AggregatorSale>(this as AggregatorSale, _$identity);

  /// Serializes this AggregatorSale to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AggregatorSale&&(identical(other.id, id) || other.id == id)&&(identical(other.holdingId, holdingId) || other.holdingId == holdingId)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.soldPrice, soldPrice) || other.soldPrice == soldPrice)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.buyerEmail, buyerEmail) || other.buyerEmail == buyerEmail)&&(identical(other.buyerPhone, buyerPhone) || other.buyerPhone == buyerPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryMode, deliveryMode) || other.deliveryMode == deliveryMode)&&(identical(other.soldAt, soldAt) || other.soldAt == soldAt)&&(identical(other.shipmentStatus, shipmentStatus) || other.shipmentStatus == shipmentStatus)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.courierRef, courierRef) || other.courierRef == courierRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,holdingId,artworkId,soldPrice,buyerName,buyerEmail,buyerPhone,deliveryAddress,deliveryMode,soldAt,shipmentStatus,dispatchedAt,deliveredAt,courierRef);

@override
String toString() {
  return 'AggregatorSale(id: $id, holdingId: $holdingId, artworkId: $artworkId, soldPrice: $soldPrice, buyerName: $buyerName, buyerEmail: $buyerEmail, buyerPhone: $buyerPhone, deliveryAddress: $deliveryAddress, deliveryMode: $deliveryMode, soldAt: $soldAt, shipmentStatus: $shipmentStatus, dispatchedAt: $dispatchedAt, deliveredAt: $deliveredAt, courierRef: $courierRef)';
}


}

/// @nodoc
abstract mixin class $AggregatorSaleCopyWith<$Res>  {
  factory $AggregatorSaleCopyWith(AggregatorSale value, $Res Function(AggregatorSale) _then) = _$AggregatorSaleCopyWithImpl;
@useResult
$Res call({
 String id, String holdingId, String artworkId, double soldPrice, String buyerName, String buyerEmail, String buyerPhone, DeliveryAddress deliveryAddress, DeliveryMode deliveryMode, String soldAt, ShipmentStatus shipmentStatus, String? dispatchedAt, String? deliveredAt, String? courierRef
});


$DeliveryAddressCopyWith<$Res> get deliveryAddress;

}
/// @nodoc
class _$AggregatorSaleCopyWithImpl<$Res>
    implements $AggregatorSaleCopyWith<$Res> {
  _$AggregatorSaleCopyWithImpl(this._self, this._then);

  final AggregatorSale _self;
  final $Res Function(AggregatorSale) _then;

/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? holdingId = null,Object? artworkId = null,Object? soldPrice = null,Object? buyerName = null,Object? buyerEmail = null,Object? buyerPhone = null,Object? deliveryAddress = null,Object? deliveryMode = null,Object? soldAt = null,Object? shipmentStatus = null,Object? dispatchedAt = freezed,Object? deliveredAt = freezed,Object? courierRef = freezed,}) {
  return _then(AggregatorSale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,holdingId: null == holdingId ? _self.holdingId : holdingId // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,soldPrice: null == soldPrice ? _self.soldPrice : soldPrice // ignore: cast_nullable_to_non_nullable
as double,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,buyerEmail: null == buyerEmail ? _self.buyerEmail : buyerEmail // ignore: cast_nullable_to_non_nullable
as String,buyerPhone: null == buyerPhone ? _self.buyerPhone : buyerPhone // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress,deliveryMode: null == deliveryMode ? _self.deliveryMode : deliveryMode // ignore: cast_nullable_to_non_nullable
as DeliveryMode,soldAt: null == soldAt ? _self.soldAt : soldAt // ignore: cast_nullable_to_non_nullable
as String,shipmentStatus: null == shipmentStatus ? _self.shipmentStatus : shipmentStatus // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as String?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as String?,courierRef: freezed == courierRef ? _self.courierRef : courierRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res> get deliveryAddress {
  
  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}
}


/// Adds pattern-matching-related methods to [AggregatorSale].
extension AggregatorSalePatterns on AggregatorSale {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AggregatorSale value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AggregatorSale() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AggregatorSale value)  $default,){
final _that = this;
switch (_that) {
case _AggregatorSale():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AggregatorSale value)?  $default,){
final _that = this;
switch (_that) {
case _AggregatorSale() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String holdingId,  String artworkId,  double soldPrice,  String buyerName,  String buyerEmail,  String buyerPhone,  DeliveryAddress deliveryAddress,  DeliveryMode deliveryMode,  String soldAt,  ShipmentStatus shipmentStatus,  String? dispatchedAt,  String? deliveredAt,  String? courierRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AggregatorSale() when $default != null:
return $default(_that.id,_that.holdingId,_that.artworkId,_that.soldPrice,_that.buyerName,_that.buyerEmail,_that.buyerPhone,_that.deliveryAddress,_that.deliveryMode,_that.soldAt,_that.shipmentStatus,_that.dispatchedAt,_that.deliveredAt,_that.courierRef);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String holdingId,  String artworkId,  double soldPrice,  String buyerName,  String buyerEmail,  String buyerPhone,  DeliveryAddress deliveryAddress,  DeliveryMode deliveryMode,  String soldAt,  ShipmentStatus shipmentStatus,  String? dispatchedAt,  String? deliveredAt,  String? courierRef)  $default,) {final _that = this;
switch (_that) {
case _AggregatorSale():
return $default(_that.id,_that.holdingId,_that.artworkId,_that.soldPrice,_that.buyerName,_that.buyerEmail,_that.buyerPhone,_that.deliveryAddress,_that.deliveryMode,_that.soldAt,_that.shipmentStatus,_that.dispatchedAt,_that.deliveredAt,_that.courierRef);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String holdingId,  String artworkId,  double soldPrice,  String buyerName,  String buyerEmail,  String buyerPhone,  DeliveryAddress deliveryAddress,  DeliveryMode deliveryMode,  String soldAt,  ShipmentStatus shipmentStatus,  String? dispatchedAt,  String? deliveredAt,  String? courierRef)?  $default,) {final _that = this;
switch (_that) {
case _AggregatorSale() when $default != null:
return $default(_that.id,_that.holdingId,_that.artworkId,_that.soldPrice,_that.buyerName,_that.buyerEmail,_that.buyerPhone,_that.deliveryAddress,_that.deliveryMode,_that.soldAt,_that.shipmentStatus,_that.dispatchedAt,_that.deliveredAt,_that.courierRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AggregatorSale implements AggregatorSale {
  const _AggregatorSale({required this.id, required this.holdingId, required this.artworkId, required this.soldPrice, required this.buyerName, required this.buyerEmail, required this.buyerPhone, required this.deliveryAddress, required this.deliveryMode, required this.soldAt, required this.shipmentStatus, this.dispatchedAt, this.deliveredAt, this.courierRef});
  factory _AggregatorSale.fromJson(Map<String, dynamic> json) => _$AggregatorSaleFromJson(json);

@override final  String id;
@override final  String holdingId;
@override final  String artworkId;
@override final  double soldPrice;
@override final  String buyerName;
@override final  String buyerEmail;
@override final  String buyerPhone;
@override final  DeliveryAddress deliveryAddress;
@override final  DeliveryMode deliveryMode;
@override final  String soldAt;
@override final  ShipmentStatus shipmentStatus;
@override final  String? dispatchedAt;
@override final  String? deliveredAt;
/// Null when [deliveryMode] is [DeliveryMode.selfPickup].
@override final  String? courierRef;

/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AggregatorSaleCopyWith<_AggregatorSale> get copyWith => __$AggregatorSaleCopyWithImpl<_AggregatorSale>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AggregatorSaleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AggregatorSale&&(identical(other.id, id) || other.id == id)&&(identical(other.holdingId, holdingId) || other.holdingId == holdingId)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.soldPrice, soldPrice) || other.soldPrice == soldPrice)&&(identical(other.buyerName, buyerName) || other.buyerName == buyerName)&&(identical(other.buyerEmail, buyerEmail) || other.buyerEmail == buyerEmail)&&(identical(other.buyerPhone, buyerPhone) || other.buyerPhone == buyerPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryMode, deliveryMode) || other.deliveryMode == deliveryMode)&&(identical(other.soldAt, soldAt) || other.soldAt == soldAt)&&(identical(other.shipmentStatus, shipmentStatus) || other.shipmentStatus == shipmentStatus)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.courierRef, courierRef) || other.courierRef == courierRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,holdingId,artworkId,soldPrice,buyerName,buyerEmail,buyerPhone,deliveryAddress,deliveryMode,soldAt,shipmentStatus,dispatchedAt,deliveredAt,courierRef);

@override
String toString() {
  return 'AggregatorSale(id: $id, holdingId: $holdingId, artworkId: $artworkId, soldPrice: $soldPrice, buyerName: $buyerName, buyerEmail: $buyerEmail, buyerPhone: $buyerPhone, deliveryAddress: $deliveryAddress, deliveryMode: $deliveryMode, soldAt: $soldAt, shipmentStatus: $shipmentStatus, dispatchedAt: $dispatchedAt, deliveredAt: $deliveredAt, courierRef: $courierRef)';
}


}

/// @nodoc
abstract mixin class _$AggregatorSaleCopyWith<$Res> implements $AggregatorSaleCopyWith<$Res> {
  factory _$AggregatorSaleCopyWith(_AggregatorSale value, $Res Function(_AggregatorSale) _then) = __$AggregatorSaleCopyWithImpl;
@override @useResult
$Res call({
 String id, String holdingId, String artworkId, double soldPrice, String buyerName, String buyerEmail, String buyerPhone, DeliveryAddress deliveryAddress, DeliveryMode deliveryMode, String soldAt, ShipmentStatus shipmentStatus, String? dispatchedAt, String? deliveredAt, String? courierRef
});


@override $DeliveryAddressCopyWith<$Res> get deliveryAddress;

}
/// @nodoc
class __$AggregatorSaleCopyWithImpl<$Res>
    implements _$AggregatorSaleCopyWith<$Res> {
  __$AggregatorSaleCopyWithImpl(this._self, this._then);

  final _AggregatorSale _self;
  final $Res Function(_AggregatorSale) _then;

/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? holdingId = null,Object? artworkId = null,Object? soldPrice = null,Object? buyerName = null,Object? buyerEmail = null,Object? buyerPhone = null,Object? deliveryAddress = null,Object? deliveryMode = null,Object? soldAt = null,Object? shipmentStatus = null,Object? dispatchedAt = freezed,Object? deliveredAt = freezed,Object? courierRef = freezed,}) {
  return _then(_AggregatorSale(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,holdingId: null == holdingId ? _self.holdingId : holdingId // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,soldPrice: null == soldPrice ? _self.soldPrice : soldPrice // ignore: cast_nullable_to_non_nullable
as double,buyerName: null == buyerName ? _self.buyerName : buyerName // ignore: cast_nullable_to_non_nullable
as String,buyerEmail: null == buyerEmail ? _self.buyerEmail : buyerEmail // ignore: cast_nullable_to_non_nullable
as String,buyerPhone: null == buyerPhone ? _self.buyerPhone : buyerPhone // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress,deliveryMode: null == deliveryMode ? _self.deliveryMode : deliveryMode // ignore: cast_nullable_to_non_nullable
as DeliveryMode,soldAt: null == soldAt ? _self.soldAt : soldAt // ignore: cast_nullable_to_non_nullable
as String,shipmentStatus: null == shipmentStatus ? _self.shipmentStatus : shipmentStatus // ignore: cast_nullable_to_non_nullable
as ShipmentStatus,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as String?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as String?,courierRef: freezed == courierRef ? _self.courierRef : courierRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AggregatorSale
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res> get deliveryAddress {
  
  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}
}


/// @nodoc
mixin _$GallerySpace {

 String get id; String get name; String get addressLine1; String get city; String get state; String get pincode;/// Max pieces this location can display at once.
 int get capacity;/// MOU §10: "nominate one Galleryzone coordinator".
 String get coordinatorName;
/// Create a copy of GallerySpace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GallerySpaceCopyWith<GallerySpace> get copyWith => _$GallerySpaceCopyWithImpl<GallerySpace>(this as GallerySpace, _$identity);

  /// Serializes this GallerySpace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GallerySpace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.coordinatorName, coordinatorName) || other.coordinatorName == coordinatorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,addressLine1,city,state,pincode,capacity,coordinatorName);

@override
String toString() {
  return 'GallerySpace(id: $id, name: $name, addressLine1: $addressLine1, city: $city, state: $state, pincode: $pincode, capacity: $capacity, coordinatorName: $coordinatorName)';
}


}

/// @nodoc
abstract mixin class $GallerySpaceCopyWith<$Res>  {
  factory $GallerySpaceCopyWith(GallerySpace value, $Res Function(GallerySpace) _then) = _$GallerySpaceCopyWithImpl;
@useResult
$Res call({
 String id, String name, String addressLine1, String city, String state, String pincode, int capacity, String coordinatorName
});




}
/// @nodoc
class _$GallerySpaceCopyWithImpl<$Res>
    implements $GallerySpaceCopyWith<$Res> {
  _$GallerySpaceCopyWithImpl(this._self, this._then);

  final GallerySpace _self;
  final $Res Function(GallerySpace) _then;

/// Create a copy of GallerySpace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? addressLine1 = null,Object? city = null,Object? state = null,Object? pincode = null,Object? capacity = null,Object? coordinatorName = null,}) {
  return _then(GallerySpace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,coordinatorName: null == coordinatorName ? _self.coordinatorName : coordinatorName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GallerySpace].
extension GallerySpacePatterns on GallerySpace {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GallerySpace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GallerySpace() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GallerySpace value)  $default,){
final _that = this;
switch (_that) {
case _GallerySpace():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GallerySpace value)?  $default,){
final _that = this;
switch (_that) {
case _GallerySpace() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String addressLine1,  String city,  String state,  String pincode,  int capacity,  String coordinatorName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GallerySpace() when $default != null:
return $default(_that.id,_that.name,_that.addressLine1,_that.city,_that.state,_that.pincode,_that.capacity,_that.coordinatorName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String addressLine1,  String city,  String state,  String pincode,  int capacity,  String coordinatorName)  $default,) {final _that = this;
switch (_that) {
case _GallerySpace():
return $default(_that.id,_that.name,_that.addressLine1,_that.city,_that.state,_that.pincode,_that.capacity,_that.coordinatorName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String addressLine1,  String city,  String state,  String pincode,  int capacity,  String coordinatorName)?  $default,) {final _that = this;
switch (_that) {
case _GallerySpace() when $default != null:
return $default(_that.id,_that.name,_that.addressLine1,_that.city,_that.state,_that.pincode,_that.capacity,_that.coordinatorName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GallerySpace implements GallerySpace {
  const _GallerySpace({required this.id, required this.name, required this.addressLine1, required this.city, required this.state, required this.pincode, required this.capacity, required this.coordinatorName});
  factory _GallerySpace.fromJson(Map<String, dynamic> json) => _$GallerySpaceFromJson(json);

@override final  String id;
@override final  String name;
@override final  String addressLine1;
@override final  String city;
@override final  String state;
@override final  String pincode;
/// Max pieces this location can display at once.
@override final  int capacity;
/// MOU §10: "nominate one Galleryzone coordinator".
@override final  String coordinatorName;

/// Create a copy of GallerySpace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GallerySpaceCopyWith<_GallerySpace> get copyWith => __$GallerySpaceCopyWithImpl<_GallerySpace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GallerySpaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GallerySpace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.coordinatorName, coordinatorName) || other.coordinatorName == coordinatorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,addressLine1,city,state,pincode,capacity,coordinatorName);

@override
String toString() {
  return 'GallerySpace(id: $id, name: $name, addressLine1: $addressLine1, city: $city, state: $state, pincode: $pincode, capacity: $capacity, coordinatorName: $coordinatorName)';
}


}

/// @nodoc
abstract mixin class _$GallerySpaceCopyWith<$Res> implements $GallerySpaceCopyWith<$Res> {
  factory _$GallerySpaceCopyWith(_GallerySpace value, $Res Function(_GallerySpace) _then) = __$GallerySpaceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String addressLine1, String city, String state, String pincode, int capacity, String coordinatorName
});




}
/// @nodoc
class __$GallerySpaceCopyWithImpl<$Res>
    implements _$GallerySpaceCopyWith<$Res> {
  __$GallerySpaceCopyWithImpl(this._self, this._then);

  final _GallerySpace _self;
  final $Res Function(_GallerySpace) _then;

/// Create a copy of GallerySpace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? addressLine1 = null,Object? city = null,Object? state = null,Object? pincode = null,Object? capacity = null,Object? coordinatorName = null,}) {
  return _then(_GallerySpace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,coordinatorName: null == coordinatorName ? _self.coordinatorName : coordinatorName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AggregatorProfile {

 String get companyName; String get contactPerson; String get avatar; String get gstNumber; String get phone; String get addressLine1; String get bankAccountMasked; String get ifsc; String get securityDepositStatus;
/// Create a copy of AggregatorProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AggregatorProfileCopyWith<AggregatorProfile> get copyWith => _$AggregatorProfileCopyWithImpl<AggregatorProfile>(this as AggregatorProfile, _$identity);

  /// Serializes this AggregatorProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AggregatorProfile&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.securityDepositStatus, securityDepositStatus) || other.securityDepositStatus == securityDepositStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,companyName,contactPerson,avatar,gstNumber,phone,addressLine1,bankAccountMasked,ifsc,securityDepositStatus);

@override
String toString() {
  return 'AggregatorProfile(companyName: $companyName, contactPerson: $contactPerson, avatar: $avatar, gstNumber: $gstNumber, phone: $phone, addressLine1: $addressLine1, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, securityDepositStatus: $securityDepositStatus)';
}


}

/// @nodoc
abstract mixin class $AggregatorProfileCopyWith<$Res>  {
  factory $AggregatorProfileCopyWith(AggregatorProfile value, $Res Function(AggregatorProfile) _then) = _$AggregatorProfileCopyWithImpl;
@useResult
$Res call({
 String companyName, String contactPerson, String avatar, String gstNumber, String phone, String addressLine1, String bankAccountMasked, String ifsc, String securityDepositStatus
});




}
/// @nodoc
class _$AggregatorProfileCopyWithImpl<$Res>
    implements $AggregatorProfileCopyWith<$Res> {
  _$AggregatorProfileCopyWithImpl(this._self, this._then);

  final AggregatorProfile _self;
  final $Res Function(AggregatorProfile) _then;

/// Create a copy of AggregatorProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? companyName = null,Object? contactPerson = null,Object? avatar = null,Object? gstNumber = null,Object? phone = null,Object? addressLine1 = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? securityDepositStatus = null,}) {
  return _then(AggregatorProfile(
companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,contactPerson: null == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,gstNumber: null == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,bankAccountMasked: null == bankAccountMasked ? _self.bankAccountMasked : bankAccountMasked // ignore: cast_nullable_to_non_nullable
as String,ifsc: null == ifsc ? _self.ifsc : ifsc // ignore: cast_nullable_to_non_nullable
as String,securityDepositStatus: null == securityDepositStatus ? _self.securityDepositStatus : securityDepositStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AggregatorProfile].
extension AggregatorProfilePatterns on AggregatorProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AggregatorProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AggregatorProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AggregatorProfile value)  $default,){
final _that = this;
switch (_that) {
case _AggregatorProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AggregatorProfile value)?  $default,){
final _that = this;
switch (_that) {
case _AggregatorProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String companyName,  String contactPerson,  String avatar,  String gstNumber,  String phone,  String addressLine1,  String bankAccountMasked,  String ifsc,  String securityDepositStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AggregatorProfile() when $default != null:
return $default(_that.companyName,_that.contactPerson,_that.avatar,_that.gstNumber,_that.phone,_that.addressLine1,_that.bankAccountMasked,_that.ifsc,_that.securityDepositStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String companyName,  String contactPerson,  String avatar,  String gstNumber,  String phone,  String addressLine1,  String bankAccountMasked,  String ifsc,  String securityDepositStatus)  $default,) {final _that = this;
switch (_that) {
case _AggregatorProfile():
return $default(_that.companyName,_that.contactPerson,_that.avatar,_that.gstNumber,_that.phone,_that.addressLine1,_that.bankAccountMasked,_that.ifsc,_that.securityDepositStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String companyName,  String contactPerson,  String avatar,  String gstNumber,  String phone,  String addressLine1,  String bankAccountMasked,  String ifsc,  String securityDepositStatus)?  $default,) {final _that = this;
switch (_that) {
case _AggregatorProfile() when $default != null:
return $default(_that.companyName,_that.contactPerson,_that.avatar,_that.gstNumber,_that.phone,_that.addressLine1,_that.bankAccountMasked,_that.ifsc,_that.securityDepositStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AggregatorProfile implements AggregatorProfile {
  const _AggregatorProfile({required this.companyName, required this.contactPerson, required this.avatar, required this.gstNumber, required this.phone, required this.addressLine1, required this.bankAccountMasked, required this.ifsc, required this.securityDepositStatus});
  factory _AggregatorProfile.fromJson(Map<String, dynamic> json) => _$AggregatorProfileFromJson(json);

@override final  String companyName;
@override final  String contactPerson;
@override final  String avatar;
@override final  String gstNumber;
@override final  String phone;
@override final  String addressLine1;
@override final  String bankAccountMasked;
@override final  String ifsc;
@override final  String securityDepositStatus;

/// Create a copy of AggregatorProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AggregatorProfileCopyWith<_AggregatorProfile> get copyWith => __$AggregatorProfileCopyWithImpl<_AggregatorProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AggregatorProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AggregatorProfile&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.gstNumber, gstNumber) || other.gstNumber == gstNumber)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.securityDepositStatus, securityDepositStatus) || other.securityDepositStatus == securityDepositStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,companyName,contactPerson,avatar,gstNumber,phone,addressLine1,bankAccountMasked,ifsc,securityDepositStatus);

@override
String toString() {
  return 'AggregatorProfile(companyName: $companyName, contactPerson: $contactPerson, avatar: $avatar, gstNumber: $gstNumber, phone: $phone, addressLine1: $addressLine1, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, securityDepositStatus: $securityDepositStatus)';
}


}

/// @nodoc
abstract mixin class _$AggregatorProfileCopyWith<$Res> implements $AggregatorProfileCopyWith<$Res> {
  factory _$AggregatorProfileCopyWith(_AggregatorProfile value, $Res Function(_AggregatorProfile) _then) = __$AggregatorProfileCopyWithImpl;
@override @useResult
$Res call({
 String companyName, String contactPerson, String avatar, String gstNumber, String phone, String addressLine1, String bankAccountMasked, String ifsc, String securityDepositStatus
});




}
/// @nodoc
class __$AggregatorProfileCopyWithImpl<$Res>
    implements _$AggregatorProfileCopyWith<$Res> {
  __$AggregatorProfileCopyWithImpl(this._self, this._then);

  final _AggregatorProfile _self;
  final $Res Function(_AggregatorProfile) _then;

/// Create a copy of AggregatorProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? companyName = null,Object? contactPerson = null,Object? avatar = null,Object? gstNumber = null,Object? phone = null,Object? addressLine1 = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? securityDepositStatus = null,}) {
  return _then(_AggregatorProfile(
companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,contactPerson: null == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,gstNumber: null == gstNumber ? _self.gstNumber : gstNumber // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,bankAccountMasked: null == bankAccountMasked ? _self.bankAccountMasked : bankAccountMasked // ignore: cast_nullable_to_non_nullable
as String,ifsc: null == ifsc ? _self.ifsc : ifsc // ignore: cast_nullable_to_non_nullable
as String,securityDepositStatus: null == securityDepositStatus ? _self.securityDepositStatus : securityDepositStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AggregatorSettings {

 bool get notifyNewAssignment; bool get notifySaleRecorded; bool get notifySettlementProcessed; bool get notifyExpiryReminder;
/// Create a copy of AggregatorSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AggregatorSettingsCopyWith<AggregatorSettings> get copyWith => _$AggregatorSettingsCopyWithImpl<AggregatorSettings>(this as AggregatorSettings, _$identity);

  /// Serializes this AggregatorSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AggregatorSettings&&(identical(other.notifyNewAssignment, notifyNewAssignment) || other.notifyNewAssignment == notifyNewAssignment)&&(identical(other.notifySaleRecorded, notifySaleRecorded) || other.notifySaleRecorded == notifySaleRecorded)&&(identical(other.notifySettlementProcessed, notifySettlementProcessed) || other.notifySettlementProcessed == notifySettlementProcessed)&&(identical(other.notifyExpiryReminder, notifyExpiryReminder) || other.notifyExpiryReminder == notifyExpiryReminder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifyNewAssignment,notifySaleRecorded,notifySettlementProcessed,notifyExpiryReminder);

@override
String toString() {
  return 'AggregatorSettings(notifyNewAssignment: $notifyNewAssignment, notifySaleRecorded: $notifySaleRecorded, notifySettlementProcessed: $notifySettlementProcessed, notifyExpiryReminder: $notifyExpiryReminder)';
}


}

/// @nodoc
abstract mixin class $AggregatorSettingsCopyWith<$Res>  {
  factory $AggregatorSettingsCopyWith(AggregatorSettings value, $Res Function(AggregatorSettings) _then) = _$AggregatorSettingsCopyWithImpl;
@useResult
$Res call({
 bool notifyNewAssignment, bool notifySaleRecorded, bool notifySettlementProcessed, bool notifyExpiryReminder
});




}
/// @nodoc
class _$AggregatorSettingsCopyWithImpl<$Res>
    implements $AggregatorSettingsCopyWith<$Res> {
  _$AggregatorSettingsCopyWithImpl(this._self, this._then);

  final AggregatorSettings _self;
  final $Res Function(AggregatorSettings) _then;

/// Create a copy of AggregatorSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifyNewAssignment = null,Object? notifySaleRecorded = null,Object? notifySettlementProcessed = null,Object? notifyExpiryReminder = null,}) {
  return _then(AggregatorSettings(
notifyNewAssignment: null == notifyNewAssignment ? _self.notifyNewAssignment : notifyNewAssignment // ignore: cast_nullable_to_non_nullable
as bool,notifySaleRecorded: null == notifySaleRecorded ? _self.notifySaleRecorded : notifySaleRecorded // ignore: cast_nullable_to_non_nullable
as bool,notifySettlementProcessed: null == notifySettlementProcessed ? _self.notifySettlementProcessed : notifySettlementProcessed // ignore: cast_nullable_to_non_nullable
as bool,notifyExpiryReminder: null == notifyExpiryReminder ? _self.notifyExpiryReminder : notifyExpiryReminder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AggregatorSettings].
extension AggregatorSettingsPatterns on AggregatorSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AggregatorSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AggregatorSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AggregatorSettings value)  $default,){
final _that = this;
switch (_that) {
case _AggregatorSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AggregatorSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AggregatorSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool notifyNewAssignment,  bool notifySaleRecorded,  bool notifySettlementProcessed,  bool notifyExpiryReminder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AggregatorSettings() when $default != null:
return $default(_that.notifyNewAssignment,_that.notifySaleRecorded,_that.notifySettlementProcessed,_that.notifyExpiryReminder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool notifyNewAssignment,  bool notifySaleRecorded,  bool notifySettlementProcessed,  bool notifyExpiryReminder)  $default,) {final _that = this;
switch (_that) {
case _AggregatorSettings():
return $default(_that.notifyNewAssignment,_that.notifySaleRecorded,_that.notifySettlementProcessed,_that.notifyExpiryReminder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool notifyNewAssignment,  bool notifySaleRecorded,  bool notifySettlementProcessed,  bool notifyExpiryReminder)?  $default,) {final _that = this;
switch (_that) {
case _AggregatorSettings() when $default != null:
return $default(_that.notifyNewAssignment,_that.notifySaleRecorded,_that.notifySettlementProcessed,_that.notifyExpiryReminder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AggregatorSettings implements AggregatorSettings {
  const _AggregatorSettings({required this.notifyNewAssignment, required this.notifySaleRecorded, required this.notifySettlementProcessed, required this.notifyExpiryReminder});
  factory _AggregatorSettings.fromJson(Map<String, dynamic> json) => _$AggregatorSettingsFromJson(json);

@override final  bool notifyNewAssignment;
@override final  bool notifySaleRecorded;
@override final  bool notifySettlementProcessed;
@override final  bool notifyExpiryReminder;

/// Create a copy of AggregatorSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AggregatorSettingsCopyWith<_AggregatorSettings> get copyWith => __$AggregatorSettingsCopyWithImpl<_AggregatorSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AggregatorSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AggregatorSettings&&(identical(other.notifyNewAssignment, notifyNewAssignment) || other.notifyNewAssignment == notifyNewAssignment)&&(identical(other.notifySaleRecorded, notifySaleRecorded) || other.notifySaleRecorded == notifySaleRecorded)&&(identical(other.notifySettlementProcessed, notifySettlementProcessed) || other.notifySettlementProcessed == notifySettlementProcessed)&&(identical(other.notifyExpiryReminder, notifyExpiryReminder) || other.notifyExpiryReminder == notifyExpiryReminder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifyNewAssignment,notifySaleRecorded,notifySettlementProcessed,notifyExpiryReminder);

@override
String toString() {
  return 'AggregatorSettings(notifyNewAssignment: $notifyNewAssignment, notifySaleRecorded: $notifySaleRecorded, notifySettlementProcessed: $notifySettlementProcessed, notifyExpiryReminder: $notifyExpiryReminder)';
}


}

/// @nodoc
abstract mixin class _$AggregatorSettingsCopyWith<$Res> implements $AggregatorSettingsCopyWith<$Res> {
  factory _$AggregatorSettingsCopyWith(_AggregatorSettings value, $Res Function(_AggregatorSettings) _then) = __$AggregatorSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool notifyNewAssignment, bool notifySaleRecorded, bool notifySettlementProcessed, bool notifyExpiryReminder
});




}
/// @nodoc
class __$AggregatorSettingsCopyWithImpl<$Res>
    implements _$AggregatorSettingsCopyWith<$Res> {
  __$AggregatorSettingsCopyWithImpl(this._self, this._then);

  final _AggregatorSettings _self;
  final $Res Function(_AggregatorSettings) _then;

/// Create a copy of AggregatorSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifyNewAssignment = null,Object? notifySaleRecorded = null,Object? notifySettlementProcessed = null,Object? notifyExpiryReminder = null,}) {
  return _then(_AggregatorSettings(
notifyNewAssignment: null == notifyNewAssignment ? _self.notifyNewAssignment : notifyNewAssignment // ignore: cast_nullable_to_non_nullable
as bool,notifySaleRecorded: null == notifySaleRecorded ? _self.notifySaleRecorded : notifySaleRecorded // ignore: cast_nullable_to_non_nullable
as bool,notifySettlementProcessed: null == notifySettlementProcessed ? _self.notifySettlementProcessed : notifySettlementProcessed // ignore: cast_nullable_to_non_nullable
as bool,notifyExpiryReminder: null == notifyExpiryReminder ? _self.notifyExpiryReminder : notifyExpiryReminder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
