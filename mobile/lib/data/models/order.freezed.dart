// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Address {

 String get id; String get line1; String? get line2; String get city; String get state; String get pincode; bool get isDefault;
/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressCopyWith<Address> get copyWith => _$AddressCopyWithImpl<Address>(this as Address, _$identity);

  /// Serializes this Address to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Address&&(identical(other.id, id) || other.id == id)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.line2, line2) || other.line2 == line2)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,line1,line2,city,state,pincode,isDefault);

@override
String toString() {
  return 'Address(id: $id, line1: $line1, line2: $line2, city: $city, state: $state, pincode: $pincode, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $AddressCopyWith<$Res>  {
  factory $AddressCopyWith(Address value, $Res Function(Address) _then) = _$AddressCopyWithImpl;
@useResult
$Res call({
 String id, String line1, String? line2, String city, String state, String pincode, bool isDefault
});




}
/// @nodoc
class _$AddressCopyWithImpl<$Res>
    implements $AddressCopyWith<$Res> {
  _$AddressCopyWithImpl(this._self, this._then);

  final Address _self;
  final $Res Function(Address) _then;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? line1 = null,Object? line2 = freezed,Object? city = null,Object? state = null,Object? pincode = null,Object? isDefault = null,}) {
  return _then(Address(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,line2: freezed == line2 ? _self.line2 : line2 // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Address].
extension AddressPatterns on Address {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Address value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Address() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Address value)  $default,){
final _that = this;
switch (_that) {
case _Address():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Address value)?  $default,){
final _that = this;
switch (_that) {
case _Address() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String line1,  String? line2,  String city,  String state,  String pincode,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Address() when $default != null:
return $default(_that.id,_that.line1,_that.line2,_that.city,_that.state,_that.pincode,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String line1,  String? line2,  String city,  String state,  String pincode,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _Address():
return $default(_that.id,_that.line1,_that.line2,_that.city,_that.state,_that.pincode,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String line1,  String? line2,  String city,  String state,  String pincode,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _Address() when $default != null:
return $default(_that.id,_that.line1,_that.line2,_that.city,_that.state,_that.pincode,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Address implements Address {
  const _Address({required this.id, required this.line1, this.line2, required this.city, required this.state, required this.pincode, required this.isDefault});
  factory _Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);

@override final  String id;
@override final  String line1;
@override final  String? line2;
@override final  String city;
@override final  String state;
@override final  String pincode;
@override final  bool isDefault;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddressCopyWith<_Address> get copyWith => __$AddressCopyWithImpl<_Address>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Address&&(identical(other.id, id) || other.id == id)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.line2, line2) || other.line2 == line2)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.pincode, pincode) || other.pincode == pincode)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,line1,line2,city,state,pincode,isDefault);

@override
String toString() {
  return 'Address(id: $id, line1: $line1, line2: $line2, city: $city, state: $state, pincode: $pincode, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$AddressCopyWith<$Res> implements $AddressCopyWith<$Res> {
  factory _$AddressCopyWith(_Address value, $Res Function(_Address) _then) = __$AddressCopyWithImpl;
@override @useResult
$Res call({
 String id, String line1, String? line2, String city, String state, String pincode, bool isDefault
});




}
/// @nodoc
class __$AddressCopyWithImpl<$Res>
    implements _$AddressCopyWith<$Res> {
  __$AddressCopyWithImpl(this._self, this._then);

  final _Address _self;
  final $Res Function(_Address) _then;

/// Create a copy of Address
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? line1 = null,Object? line2 = freezed,Object? city = null,Object? state = null,Object? pincode = null,Object? isDefault = null,}) {
  return _then(_Address(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,line2: freezed == line2 ? _self.line2 : line2 // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,pincode: null == pincode ? _self.pincode : pincode // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OrderStatusEvent {

 OrderStatus get status; String get changedAt;
/// Create a copy of OrderStatusEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStatusEventCopyWith<OrderStatusEvent> get copyWith => _$OrderStatusEventCopyWithImpl<OrderStatusEvent>(this as OrderStatusEvent, _$identity);

  /// Serializes this OrderStatusEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,changedAt);

@override
String toString() {
  return 'OrderStatusEvent(status: $status, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class $OrderStatusEventCopyWith<$Res>  {
  factory $OrderStatusEventCopyWith(OrderStatusEvent value, $Res Function(OrderStatusEvent) _then) = _$OrderStatusEventCopyWithImpl;
@useResult
$Res call({
 OrderStatus status, String changedAt
});




}
/// @nodoc
class _$OrderStatusEventCopyWithImpl<$Res>
    implements $OrderStatusEventCopyWith<$Res> {
  _$OrderStatusEventCopyWithImpl(this._self, this._then);

  final OrderStatusEvent _self;
  final $Res Function(OrderStatusEvent) _then;

/// Create a copy of OrderStatusEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? changedAt = null,}) {
  return _then(OrderStatusEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderStatusEvent].
extension OrderStatusEventPatterns on OrderStatusEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderStatusEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderStatusEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderStatusEvent value)  $default,){
final _that = this;
switch (_that) {
case _OrderStatusEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderStatusEvent value)?  $default,){
final _that = this;
switch (_that) {
case _OrderStatusEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderStatus status,  String changedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderStatusEvent() when $default != null:
return $default(_that.status,_that.changedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderStatus status,  String changedAt)  $default,) {final _that = this;
switch (_that) {
case _OrderStatusEvent():
return $default(_that.status,_that.changedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderStatus status,  String changedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderStatusEvent() when $default != null:
return $default(_that.status,_that.changedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderStatusEvent implements OrderStatusEvent {
  const _OrderStatusEvent({required this.status, required this.changedAt});
  factory _OrderStatusEvent.fromJson(Map<String, dynamic> json) => _$OrderStatusEventFromJson(json);

@override final  OrderStatus status;
@override final  String changedAt;

/// Create a copy of OrderStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStatusEventCopyWith<_OrderStatusEvent> get copyWith => __$OrderStatusEventCopyWithImpl<_OrderStatusEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderStatusEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderStatusEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,changedAt);

@override
String toString() {
  return 'OrderStatusEvent(status: $status, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderStatusEventCopyWith<$Res> implements $OrderStatusEventCopyWith<$Res> {
  factory _$OrderStatusEventCopyWith(_OrderStatusEvent value, $Res Function(_OrderStatusEvent) _then) = __$OrderStatusEventCopyWithImpl;
@override @useResult
$Res call({
 OrderStatus status, String changedAt
});




}
/// @nodoc
class __$OrderStatusEventCopyWithImpl<$Res>
    implements _$OrderStatusEventCopyWith<$Res> {
  __$OrderStatusEventCopyWithImpl(this._self, this._then);

  final _OrderStatusEvent _self;
  final $Res Function(_OrderStatusEvent) _then;

/// Create a copy of OrderStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? changedAt = null,}) {
  return _then(_OrderStatusEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderArtwork {

 String get title; String get artistName; String get artistId; String get thumbnailUrl; String get productCode;
/// Create a copy of OrderArtwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderArtworkCopyWith<OrderArtwork> get copyWith => _$OrderArtworkCopyWithImpl<OrderArtwork>(this as OrderArtwork, _$identity);

  /// Serializes this OrderArtwork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderArtwork&&(identical(other.title, title) || other.title == title)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.productCode, productCode) || other.productCode == productCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,artistName,artistId,thumbnailUrl,productCode);

@override
String toString() {
  return 'OrderArtwork(title: $title, artistName: $artistName, artistId: $artistId, thumbnailUrl: $thumbnailUrl, productCode: $productCode)';
}


}

/// @nodoc
abstract mixin class $OrderArtworkCopyWith<$Res>  {
  factory $OrderArtworkCopyWith(OrderArtwork value, $Res Function(OrderArtwork) _then) = _$OrderArtworkCopyWithImpl;
@useResult
$Res call({
 String title, String artistName, String artistId, String thumbnailUrl, String productCode
});




}
/// @nodoc
class _$OrderArtworkCopyWithImpl<$Res>
    implements $OrderArtworkCopyWith<$Res> {
  _$OrderArtworkCopyWithImpl(this._self, this._then);

  final OrderArtwork _self;
  final $Res Function(OrderArtwork) _then;

/// Create a copy of OrderArtwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? artistName = null,Object? artistId = null,Object? thumbnailUrl = null,Object? productCode = null,}) {
  return _then(OrderArtwork(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,productCode: null == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderArtwork].
extension OrderArtworkPatterns on OrderArtwork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderArtwork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderArtwork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderArtwork value)  $default,){
final _that = this;
switch (_that) {
case _OrderArtwork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderArtwork value)?  $default,){
final _that = this;
switch (_that) {
case _OrderArtwork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String artistName,  String artistId,  String thumbnailUrl,  String productCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderArtwork() when $default != null:
return $default(_that.title,_that.artistName,_that.artistId,_that.thumbnailUrl,_that.productCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String artistName,  String artistId,  String thumbnailUrl,  String productCode)  $default,) {final _that = this;
switch (_that) {
case _OrderArtwork():
return $default(_that.title,_that.artistName,_that.artistId,_that.thumbnailUrl,_that.productCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String artistName,  String artistId,  String thumbnailUrl,  String productCode)?  $default,) {final _that = this;
switch (_that) {
case _OrderArtwork() when $default != null:
return $default(_that.title,_that.artistName,_that.artistId,_that.thumbnailUrl,_that.productCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderArtwork implements OrderArtwork {
  const _OrderArtwork({required this.title, required this.artistName, this.artistId = '', this.thumbnailUrl = '', this.productCode = ''});
  factory _OrderArtwork.fromJson(Map<String, dynamic> json) => _$OrderArtworkFromJson(json);

@override final  String title;
@override final  String artistName;
@override@JsonKey() final  String artistId;
@override@JsonKey() final  String thumbnailUrl;
@override@JsonKey() final  String productCode;

/// Create a copy of OrderArtwork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderArtworkCopyWith<_OrderArtwork> get copyWith => __$OrderArtworkCopyWithImpl<_OrderArtwork>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderArtworkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderArtwork&&(identical(other.title, title) || other.title == title)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.productCode, productCode) || other.productCode == productCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,artistName,artistId,thumbnailUrl,productCode);

@override
String toString() {
  return 'OrderArtwork(title: $title, artistName: $artistName, artistId: $artistId, thumbnailUrl: $thumbnailUrl, productCode: $productCode)';
}


}

/// @nodoc
abstract mixin class _$OrderArtworkCopyWith<$Res> implements $OrderArtworkCopyWith<$Res> {
  factory _$OrderArtworkCopyWith(_OrderArtwork value, $Res Function(_OrderArtwork) _then) = __$OrderArtworkCopyWithImpl;
@override @useResult
$Res call({
 String title, String artistName, String artistId, String thumbnailUrl, String productCode
});




}
/// @nodoc
class __$OrderArtworkCopyWithImpl<$Res>
    implements _$OrderArtworkCopyWith<$Res> {
  __$OrderArtworkCopyWithImpl(this._self, this._then);

  final _OrderArtwork _self;
  final $Res Function(_OrderArtwork) _then;

/// Create a copy of OrderArtwork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? artistName = null,Object? artistId = null,Object? thumbnailUrl = null,Object? productCode = null,}) {
  return _then(_OrderArtwork(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,productCode: null == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderPayment {

/// The gateway's payment id (empty when simulated).
 String get paymentId; String get method;/// True when no money moved — a test-mode / simulated payment.
 bool get simulated;
/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<OrderPayment> get copyWith => _$OrderPaymentCopyWithImpl<OrderPayment>(this as OrderPayment, _$identity);

  /// Serializes this OrderPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPayment&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.method, method) || other.method == method)&&(identical(other.simulated, simulated) || other.simulated == simulated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,method,simulated);

@override
String toString() {
  return 'OrderPayment(paymentId: $paymentId, method: $method, simulated: $simulated)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentCopyWith<$Res>  {
  factory $OrderPaymentCopyWith(OrderPayment value, $Res Function(OrderPayment) _then) = _$OrderPaymentCopyWithImpl;
@useResult
$Res call({
 String paymentId, String method, bool simulated
});




}
/// @nodoc
class _$OrderPaymentCopyWithImpl<$Res>
    implements $OrderPaymentCopyWith<$Res> {
  _$OrderPaymentCopyWithImpl(this._self, this._then);

  final OrderPayment _self;
  final $Res Function(OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paymentId = null,Object? method = null,Object? simulated = null,}) {
  return _then(OrderPayment(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,simulated: null == simulated ? _self.simulated : simulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderPayment].
extension OrderPaymentPatterns on OrderPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPayment value)  $default,){
final _that = this;
switch (_that) {
case _OrderPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPayment value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String paymentId,  String method,  bool simulated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.paymentId,_that.method,_that.simulated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String paymentId,  String method,  bool simulated)  $default,) {final _that = this;
switch (_that) {
case _OrderPayment():
return $default(_that.paymentId,_that.method,_that.simulated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String paymentId,  String method,  bool simulated)?  $default,) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.paymentId,_that.method,_that.simulated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderPayment implements OrderPayment {
  const _OrderPayment({this.paymentId = '', this.method = '', this.simulated = false});
  factory _OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);

/// The gateway's payment id (empty when simulated).
@override@JsonKey() final  String paymentId;
@override@JsonKey() final  String method;
/// True when no money moved — a test-mode / simulated payment.
@override@JsonKey() final  bool simulated;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPaymentCopyWith<_OrderPayment> get copyWith => __$OrderPaymentCopyWithImpl<_OrderPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPayment&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.method, method) || other.method == method)&&(identical(other.simulated, simulated) || other.simulated == simulated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentId,method,simulated);

@override
String toString() {
  return 'OrderPayment(paymentId: $paymentId, method: $method, simulated: $simulated)';
}


}

/// @nodoc
abstract mixin class _$OrderPaymentCopyWith<$Res> implements $OrderPaymentCopyWith<$Res> {
  factory _$OrderPaymentCopyWith(_OrderPayment value, $Res Function(_OrderPayment) _then) = __$OrderPaymentCopyWithImpl;
@override @useResult
$Res call({
 String paymentId, String method, bool simulated
});




}
/// @nodoc
class __$OrderPaymentCopyWithImpl<$Res>
    implements _$OrderPaymentCopyWith<$Res> {
  __$OrderPaymentCopyWithImpl(this._self, this._then);

  final _OrderPayment _self;
  final $Res Function(_OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paymentId = null,Object? method = null,Object? simulated = null,}) {
  return _then(_OrderPayment(
paymentId: null == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,simulated: null == simulated ? _self.simulated : simulated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Order {

 String get id; String get artworkId; String get addressId;/// The artwork's customerPrice at time of purchase. GST is already
/// inside this figure — see [gstAmount].
 double get amount;/// The GST portion of [amount], recorded so a past receipt can show the
/// tax component. Never added to [total]; it is already in [amount].
 double get gstAmount; double get deliveryCharge; OrderStatus get status; String get createdAt; List<OrderStatusEvent> get statusHistory;/// Null on the seeded fixture orders, which predate the payment step.
 PaymentMethod? get paymentMethod;/// GalleryZone's convenience fee on the order, and the 18% service GST on
/// that fee. Both are zero today (the sheet carries it "for future").
 double get convenienceFee; double get convenienceGst;/// The piece as bought. Null on the offline fixtures.
 OrderArtwork? get artwork;/// Null until the gateway has captured a payment.
 OrderPayment? get payment;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.statusHistory, statusHistory)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.convenienceFee, convenienceFee) || other.convenienceFee == convenienceFee)&&(identical(other.convenienceGst, convenienceGst) || other.convenienceGst == convenienceGst)&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.payment, payment) || other.payment == payment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,addressId,amount,gstAmount,deliveryCharge,status,createdAt,const DeepCollectionEquality().hash(statusHistory),paymentMethod,convenienceFee,convenienceGst,artwork,payment);

@override
String toString() {
  return 'Order(id: $id, artworkId: $artworkId, addressId: $addressId, amount: $amount, gstAmount: $gstAmount, deliveryCharge: $deliveryCharge, status: $status, createdAt: $createdAt, statusHistory: $statusHistory, paymentMethod: $paymentMethod, convenienceFee: $convenienceFee, convenienceGst: $convenienceGst, artwork: $artwork, payment: $payment)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, String addressId, double amount, double gstAmount, double deliveryCharge, OrderStatus status, String createdAt, List<OrderStatusEvent> statusHistory, PaymentMethod? paymentMethod, double convenienceFee, double convenienceGst, OrderArtwork? artwork, OrderPayment? payment
});


$OrderArtworkCopyWith<$Res>? get artwork;$OrderPaymentCopyWith<$Res>? get payment;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? addressId = null,Object? amount = null,Object? gstAmount = null,Object? deliveryCharge = null,Object? status = null,Object? createdAt = null,Object? statusHistory = null,Object? paymentMethod = freezed,Object? convenienceFee = null,Object? convenienceGst = null,Object? artwork = freezed,Object? payment = freezed,}) {
  return _then(Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,addressId: null == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,statusHistory: null == statusHistory ? _self.statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<OrderStatusEvent>,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,convenienceFee: null == convenienceFee ? _self.convenienceFee : convenienceFee // ignore: cast_nullable_to_non_nullable
as double,convenienceGst: null == convenienceGst ? _self.convenienceGst : convenienceGst // ignore: cast_nullable_to_non_nullable
as double,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as OrderArtwork?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $OrderArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $OrderPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  String addressId,  double amount,  double gstAmount,  double deliveryCharge,  OrderStatus status,  String createdAt,  List<OrderStatusEvent> statusHistory,  PaymentMethod? paymentMethod,  double convenienceFee,  double convenienceGst,  OrderArtwork? artwork,  OrderPayment? payment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.artworkId,_that.addressId,_that.amount,_that.gstAmount,_that.deliveryCharge,_that.status,_that.createdAt,_that.statusHistory,_that.paymentMethod,_that.convenienceFee,_that.convenienceGst,_that.artwork,_that.payment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  String addressId,  double amount,  double gstAmount,  double deliveryCharge,  OrderStatus status,  String createdAt,  List<OrderStatusEvent> statusHistory,  PaymentMethod? paymentMethod,  double convenienceFee,  double convenienceGst,  OrderArtwork? artwork,  OrderPayment? payment)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.artworkId,_that.addressId,_that.amount,_that.gstAmount,_that.deliveryCharge,_that.status,_that.createdAt,_that.statusHistory,_that.paymentMethod,_that.convenienceFee,_that.convenienceGst,_that.artwork,_that.payment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  String addressId,  double amount,  double gstAmount,  double deliveryCharge,  OrderStatus status,  String createdAt,  List<OrderStatusEvent> statusHistory,  PaymentMethod? paymentMethod,  double convenienceFee,  double convenienceGst,  OrderArtwork? artwork,  OrderPayment? payment)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.artworkId,_that.addressId,_that.amount,_that.gstAmount,_that.deliveryCharge,_that.status,_that.createdAt,_that.statusHistory,_that.paymentMethod,_that.convenienceFee,_that.convenienceGst,_that.artwork,_that.payment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order extends Order {
  const _Order({required this.id, required this.artworkId, required this.addressId, required this.amount, required this.gstAmount, required this.deliveryCharge, required this.status, required this.createdAt, required  List<OrderStatusEvent> statusHistory, this.paymentMethod, this.convenienceFee = 0, this.convenienceGst = 0, this.artwork, this.payment}): _statusHistory = statusHistory,super._();
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  String id;
@override final  String artworkId;
@override final  String addressId;
/// The artwork's customerPrice at time of purchase. GST is already
/// inside this figure — see [gstAmount].
@override final  double amount;
/// The GST portion of [amount], recorded so a past receipt can show the
/// tax component. Never added to [total]; it is already in [amount].
@override final  double gstAmount;
@override final  double deliveryCharge;
@override final  OrderStatus status;
@override final  String createdAt;
 final  List<OrderStatusEvent> _statusHistory;
@override List<OrderStatusEvent> get statusHistory {
  if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusHistory);
}

/// Null on the seeded fixture orders, which predate the payment step.
@override final  PaymentMethod? paymentMethod;
/// GalleryZone's convenience fee on the order, and the 18% service GST on
/// that fee. Both are zero today (the sheet carries it "for future").
@override@JsonKey() final  double convenienceFee;
@override@JsonKey() final  double convenienceGst;
/// The piece as bought. Null on the offline fixtures.
@override final  OrderArtwork? artwork;
/// Null until the gateway has captured a payment.
@override final  OrderPayment? payment;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.gstAmount, gstAmount) || other.gstAmount == gstAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._statusHistory, _statusHistory)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.convenienceFee, convenienceFee) || other.convenienceFee == convenienceFee)&&(identical(other.convenienceGst, convenienceGst) || other.convenienceGst == convenienceGst)&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.payment, payment) || other.payment == payment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,addressId,amount,gstAmount,deliveryCharge,status,createdAt,const DeepCollectionEquality().hash(_statusHistory),paymentMethod,convenienceFee,convenienceGst,artwork,payment);

@override
String toString() {
  return 'Order(id: $id, artworkId: $artworkId, addressId: $addressId, amount: $amount, gstAmount: $gstAmount, deliveryCharge: $deliveryCharge, status: $status, createdAt: $createdAt, statusHistory: $statusHistory, paymentMethod: $paymentMethod, convenienceFee: $convenienceFee, convenienceGst: $convenienceGst, artwork: $artwork, payment: $payment)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, String addressId, double amount, double gstAmount, double deliveryCharge, OrderStatus status, String createdAt, List<OrderStatusEvent> statusHistory, PaymentMethod? paymentMethod, double convenienceFee, double convenienceGst, OrderArtwork? artwork, OrderPayment? payment
});


@override $OrderArtworkCopyWith<$Res>? get artwork;@override $OrderPaymentCopyWith<$Res>? get payment;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? addressId = null,Object? amount = null,Object? gstAmount = null,Object? deliveryCharge = null,Object? status = null,Object? createdAt = null,Object? statusHistory = null,Object? paymentMethod = freezed,Object? convenienceFee = null,Object? convenienceGst = null,Object? artwork = freezed,Object? payment = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,addressId: null == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,gstAmount: null == gstAmount ? _self.gstAmount : gstAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,statusHistory: null == statusHistory ? _self._statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<OrderStatusEvent>,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,convenienceFee: null == convenienceFee ? _self.convenienceFee : convenienceFee // ignore: cast_nullable_to_non_nullable
as double,convenienceGst: null == convenienceGst ? _self.convenienceGst : convenienceGst // ignore: cast_nullable_to_non_nullable
as double,artwork: freezed == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as OrderArtwork?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderArtworkCopyWith<$Res>? get artwork {
    if (_self.artwork == null) {
    return null;
  }

  return $OrderArtworkCopyWith<$Res>(_self.artwork!, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $OrderPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}
}

// dart format on
