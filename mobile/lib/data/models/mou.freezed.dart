// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mou.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MouPartyDetails {

 String? get name; String? get businessName; String? get address; String? get mobile; String? get email; String? get governmentId; String? get gstNo;
/// Create a copy of MouPartyDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MouPartyDetailsCopyWith<MouPartyDetails> get copyWith => _$MouPartyDetailsCopyWithImpl<MouPartyDetails>(this as MouPartyDetails, _$identity);

  /// Serializes this MouPartyDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MouPartyDetails&&(identical(other.name, name) || other.name == name)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.address, address) || other.address == address)&&(identical(other.mobile, mobile) || other.mobile == mobile)&&(identical(other.email, email) || other.email == email)&&(identical(other.governmentId, governmentId) || other.governmentId == governmentId)&&(identical(other.gstNo, gstNo) || other.gstNo == gstNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,businessName,address,mobile,email,governmentId,gstNo);

@override
String toString() {
  return 'MouPartyDetails(name: $name, businessName: $businessName, address: $address, mobile: $mobile, email: $email, governmentId: $governmentId, gstNo: $gstNo)';
}


}

/// @nodoc
abstract mixin class $MouPartyDetailsCopyWith<$Res>  {
  factory $MouPartyDetailsCopyWith(MouPartyDetails value, $Res Function(MouPartyDetails) _then) = _$MouPartyDetailsCopyWithImpl;
@useResult
$Res call({
 String? name, String? businessName, String? address, String? mobile, String? email, String? governmentId, String? gstNo
});




}
/// @nodoc
class _$MouPartyDetailsCopyWithImpl<$Res>
    implements $MouPartyDetailsCopyWith<$Res> {
  _$MouPartyDetailsCopyWithImpl(this._self, this._then);

  final MouPartyDetails _self;
  final $Res Function(MouPartyDetails) _then;

/// Create a copy of MouPartyDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? businessName = freezed,Object? address = freezed,Object? mobile = freezed,Object? email = freezed,Object? governmentId = freezed,Object? gstNo = freezed,}) {
  return _then(MouPartyDetails(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,businessName: freezed == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,mobile: freezed == mobile ? _self.mobile : mobile // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,governmentId: freezed == governmentId ? _self.governmentId : governmentId // ignore: cast_nullable_to_non_nullable
as String?,gstNo: freezed == gstNo ? _self.gstNo : gstNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MouPartyDetails].
extension MouPartyDetailsPatterns on MouPartyDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MouPartyDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MouPartyDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MouPartyDetails value)  $default,){
final _that = this;
switch (_that) {
case _MouPartyDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MouPartyDetails value)?  $default,){
final _that = this;
switch (_that) {
case _MouPartyDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? businessName,  String? address,  String? mobile,  String? email,  String? governmentId,  String? gstNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MouPartyDetails() when $default != null:
return $default(_that.name,_that.businessName,_that.address,_that.mobile,_that.email,_that.governmentId,_that.gstNo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? businessName,  String? address,  String? mobile,  String? email,  String? governmentId,  String? gstNo)  $default,) {final _that = this;
switch (_that) {
case _MouPartyDetails():
return $default(_that.name,_that.businessName,_that.address,_that.mobile,_that.email,_that.governmentId,_that.gstNo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? businessName,  String? address,  String? mobile,  String? email,  String? governmentId,  String? gstNo)?  $default,) {final _that = this;
switch (_that) {
case _MouPartyDetails() when $default != null:
return $default(_that.name,_that.businessName,_that.address,_that.mobile,_that.email,_that.governmentId,_that.gstNo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MouPartyDetails implements MouPartyDetails {
  const _MouPartyDetails({this.name, this.businessName, this.address, this.mobile, this.email, this.governmentId, this.gstNo});
  factory _MouPartyDetails.fromJson(Map<String, dynamic> json) => _$MouPartyDetailsFromJson(json);

@override final  String? name;
@override final  String? businessName;
@override final  String? address;
@override final  String? mobile;
@override final  String? email;
@override final  String? governmentId;
@override final  String? gstNo;

/// Create a copy of MouPartyDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MouPartyDetailsCopyWith<_MouPartyDetails> get copyWith => __$MouPartyDetailsCopyWithImpl<_MouPartyDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MouPartyDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MouPartyDetails&&(identical(other.name, name) || other.name == name)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.address, address) || other.address == address)&&(identical(other.mobile, mobile) || other.mobile == mobile)&&(identical(other.email, email) || other.email == email)&&(identical(other.governmentId, governmentId) || other.governmentId == governmentId)&&(identical(other.gstNo, gstNo) || other.gstNo == gstNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,businessName,address,mobile,email,governmentId,gstNo);

@override
String toString() {
  return 'MouPartyDetails(name: $name, businessName: $businessName, address: $address, mobile: $mobile, email: $email, governmentId: $governmentId, gstNo: $gstNo)';
}


}

/// @nodoc
abstract mixin class _$MouPartyDetailsCopyWith<$Res> implements $MouPartyDetailsCopyWith<$Res> {
  factory _$MouPartyDetailsCopyWith(_MouPartyDetails value, $Res Function(_MouPartyDetails) _then) = __$MouPartyDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? businessName, String? address, String? mobile, String? email, String? governmentId, String? gstNo
});




}
/// @nodoc
class __$MouPartyDetailsCopyWithImpl<$Res>
    implements _$MouPartyDetailsCopyWith<$Res> {
  __$MouPartyDetailsCopyWithImpl(this._self, this._then);

  final _MouPartyDetails _self;
  final $Res Function(_MouPartyDetails) _then;

/// Create a copy of MouPartyDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? businessName = freezed,Object? address = freezed,Object? mobile = freezed,Object? email = freezed,Object? governmentId = freezed,Object? gstNo = freezed,}) {
  return _then(_MouPartyDetails(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,businessName: freezed == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,mobile: freezed == mobile ? _self.mobile : mobile // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,governmentId: freezed == governmentId ? _self.governmentId : governmentId // ignore: cast_nullable_to_non_nullable
as String?,gstNo: freezed == gstNo ? _self.gstNo : gstNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MouCompanyDetails {

 String? get name; String? get designation;
/// Create a copy of MouCompanyDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MouCompanyDetailsCopyWith<MouCompanyDetails> get copyWith => _$MouCompanyDetailsCopyWithImpl<MouCompanyDetails>(this as MouCompanyDetails, _$identity);

  /// Serializes this MouCompanyDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MouCompanyDetails&&(identical(other.name, name) || other.name == name)&&(identical(other.designation, designation) || other.designation == designation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,designation);

@override
String toString() {
  return 'MouCompanyDetails(name: $name, designation: $designation)';
}


}

/// @nodoc
abstract mixin class $MouCompanyDetailsCopyWith<$Res>  {
  factory $MouCompanyDetailsCopyWith(MouCompanyDetails value, $Res Function(MouCompanyDetails) _then) = _$MouCompanyDetailsCopyWithImpl;
@useResult
$Res call({
 String? name, String? designation
});




}
/// @nodoc
class _$MouCompanyDetailsCopyWithImpl<$Res>
    implements $MouCompanyDetailsCopyWith<$Res> {
  _$MouCompanyDetailsCopyWithImpl(this._self, this._then);

  final MouCompanyDetails _self;
  final $Res Function(MouCompanyDetails) _then;

/// Create a copy of MouCompanyDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? designation = freezed,}) {
  return _then(MouCompanyDetails(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,designation: freezed == designation ? _self.designation : designation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MouCompanyDetails].
extension MouCompanyDetailsPatterns on MouCompanyDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MouCompanyDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MouCompanyDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MouCompanyDetails value)  $default,){
final _that = this;
switch (_that) {
case _MouCompanyDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MouCompanyDetails value)?  $default,){
final _that = this;
switch (_that) {
case _MouCompanyDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? designation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MouCompanyDetails() when $default != null:
return $default(_that.name,_that.designation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? designation)  $default,) {final _that = this;
switch (_that) {
case _MouCompanyDetails():
return $default(_that.name,_that.designation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? designation)?  $default,) {final _that = this;
switch (_that) {
case _MouCompanyDetails() when $default != null:
return $default(_that.name,_that.designation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MouCompanyDetails implements MouCompanyDetails {
  const _MouCompanyDetails({this.name, this.designation});
  factory _MouCompanyDetails.fromJson(Map<String, dynamic> json) => _$MouCompanyDetailsFromJson(json);

@override final  String? name;
@override final  String? designation;

/// Create a copy of MouCompanyDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MouCompanyDetailsCopyWith<_MouCompanyDetails> get copyWith => __$MouCompanyDetailsCopyWithImpl<_MouCompanyDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MouCompanyDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MouCompanyDetails&&(identical(other.name, name) || other.name == name)&&(identical(other.designation, designation) || other.designation == designation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,designation);

@override
String toString() {
  return 'MouCompanyDetails(name: $name, designation: $designation)';
}


}

/// @nodoc
abstract mixin class _$MouCompanyDetailsCopyWith<$Res> implements $MouCompanyDetailsCopyWith<$Res> {
  factory _$MouCompanyDetailsCopyWith(_MouCompanyDetails value, $Res Function(_MouCompanyDetails) _then) = __$MouCompanyDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? designation
});




}
/// @nodoc
class __$MouCompanyDetailsCopyWithImpl<$Res>
    implements _$MouCompanyDetailsCopyWith<$Res> {
  __$MouCompanyDetailsCopyWithImpl(this._self, this._then);

  final _MouCompanyDetails _self;
  final $Res Function(_MouCompanyDetails) _then;

/// Create a copy of MouCompanyDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? designation = freezed,}) {
  return _then(_MouCompanyDetails(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,designation: freezed == designation ? _self.designation : designation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MouParties {

 MouPartyDetails get party; MouCompanyDetails get company;
/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MouPartiesCopyWith<MouParties> get copyWith => _$MouPartiesCopyWithImpl<MouParties>(this as MouParties, _$identity);

  /// Serializes this MouParties to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MouParties&&(identical(other.party, party) || other.party == party)&&(identical(other.company, company) || other.company == company));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,party,company);

@override
String toString() {
  return 'MouParties(party: $party, company: $company)';
}


}

/// @nodoc
abstract mixin class $MouPartiesCopyWith<$Res>  {
  factory $MouPartiesCopyWith(MouParties value, $Res Function(MouParties) _then) = _$MouPartiesCopyWithImpl;
@useResult
$Res call({
 MouPartyDetails party, MouCompanyDetails company
});


$MouPartyDetailsCopyWith<$Res> get party;$MouCompanyDetailsCopyWith<$Res> get company;

}
/// @nodoc
class _$MouPartiesCopyWithImpl<$Res>
    implements $MouPartiesCopyWith<$Res> {
  _$MouPartiesCopyWithImpl(this._self, this._then);

  final MouParties _self;
  final $Res Function(MouParties) _then;

/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? party = null,Object? company = null,}) {
  return _then(MouParties(
party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as MouPartyDetails,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as MouCompanyDetails,
  ));
}
/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouPartyDetailsCopyWith<$Res> get party {
  
  return $MouPartyDetailsCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouCompanyDetailsCopyWith<$Res> get company {
  
  return $MouCompanyDetailsCopyWith<$Res>(_self.company, (value) {
    return _then(_self.copyWith(company: value));
  });
}
}


/// Adds pattern-matching-related methods to [MouParties].
extension MouPartiesPatterns on MouParties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MouParties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MouParties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MouParties value)  $default,){
final _that = this;
switch (_that) {
case _MouParties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MouParties value)?  $default,){
final _that = this;
switch (_that) {
case _MouParties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MouPartyDetails party,  MouCompanyDetails company)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MouParties() when $default != null:
return $default(_that.party,_that.company);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MouPartyDetails party,  MouCompanyDetails company)  $default,) {final _that = this;
switch (_that) {
case _MouParties():
return $default(_that.party,_that.company);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MouPartyDetails party,  MouCompanyDetails company)?  $default,) {final _that = this;
switch (_that) {
case _MouParties() when $default != null:
return $default(_that.party,_that.company);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MouParties implements MouParties {
  const _MouParties({this.party = const MouPartyDetails(), this.company = const MouCompanyDetails()});
  factory _MouParties.fromJson(Map<String, dynamic> json) => _$MouPartiesFromJson(json);

@override@JsonKey() final  MouPartyDetails party;
@override@JsonKey() final  MouCompanyDetails company;

/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MouPartiesCopyWith<_MouParties> get copyWith => __$MouPartiesCopyWithImpl<_MouParties>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MouPartiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MouParties&&(identical(other.party, party) || other.party == party)&&(identical(other.company, company) || other.company == company));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,party,company);

@override
String toString() {
  return 'MouParties(party: $party, company: $company)';
}


}

/// @nodoc
abstract mixin class _$MouPartiesCopyWith<$Res> implements $MouPartiesCopyWith<$Res> {
  factory _$MouPartiesCopyWith(_MouParties value, $Res Function(_MouParties) _then) = __$MouPartiesCopyWithImpl;
@override @useResult
$Res call({
 MouPartyDetails party, MouCompanyDetails company
});


@override $MouPartyDetailsCopyWith<$Res> get party;@override $MouCompanyDetailsCopyWith<$Res> get company;

}
/// @nodoc
class __$MouPartiesCopyWithImpl<$Res>
    implements _$MouPartiesCopyWith<$Res> {
  __$MouPartiesCopyWithImpl(this._self, this._then);

  final _MouParties _self;
  final $Res Function(_MouParties) _then;

/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? party = null,Object? company = null,}) {
  return _then(_MouParties(
party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as MouPartyDetails,company: null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as MouCompanyDetails,
  ));
}

/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouPartyDetailsCopyWith<$Res> get party {
  
  return $MouPartyDetailsCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of MouParties
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouCompanyDetailsCopyWith<$Res> get company {
  
  return $MouCompanyDetailsCopyWith<$Res>(_self.company, (value) {
    return _then(_self.copyWith(company: value));
  });
}
}


/// @nodoc
mixin _$MouAcceptance {

 String get version; String get acceptedAt;/// Typed by the signer; must match the account's name. Empty on records
/// that predate the field.
 String get signatureName;/// The drawn signature as a PNG data URL. Empty on records that predate
/// the signature pad (and on the offline mock, which only types a name).
 String get signatureDataUrl;/// The blanks as they stood when it was signed — what the signed copy
/// shows, whatever the profile says since.
 MouParties? get parties;
/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MouAcceptanceCopyWith<MouAcceptance> get copyWith => _$MouAcceptanceCopyWithImpl<MouAcceptance>(this as MouAcceptance, _$identity);

  /// Serializes this MouAcceptance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MouAcceptance&&(identical(other.version, version) || other.version == version)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.signatureName, signatureName) || other.signatureName == signatureName)&&(identical(other.signatureDataUrl, signatureDataUrl) || other.signatureDataUrl == signatureDataUrl)&&(identical(other.parties, parties) || other.parties == parties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,acceptedAt,signatureName,signatureDataUrl,parties);

@override
String toString() {
  return 'MouAcceptance(version: $version, acceptedAt: $acceptedAt, signatureName: $signatureName, signatureDataUrl: $signatureDataUrl, parties: $parties)';
}


}

/// @nodoc
abstract mixin class $MouAcceptanceCopyWith<$Res>  {
  factory $MouAcceptanceCopyWith(MouAcceptance value, $Res Function(MouAcceptance) _then) = _$MouAcceptanceCopyWithImpl;
@useResult
$Res call({
 String version, String acceptedAt, String signatureName, String signatureDataUrl, MouParties? parties
});


$MouPartiesCopyWith<$Res>? get parties;

}
/// @nodoc
class _$MouAcceptanceCopyWithImpl<$Res>
    implements $MouAcceptanceCopyWith<$Res> {
  _$MouAcceptanceCopyWithImpl(this._self, this._then);

  final MouAcceptance _self;
  final $Res Function(MouAcceptance) _then;

/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? acceptedAt = null,Object? signatureName = null,Object? signatureDataUrl = null,Object? parties = freezed,}) {
  return _then(MouAcceptance(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: null == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String,signatureName: null == signatureName ? _self.signatureName : signatureName // ignore: cast_nullable_to_non_nullable
as String,signatureDataUrl: null == signatureDataUrl ? _self.signatureDataUrl : signatureDataUrl // ignore: cast_nullable_to_non_nullable
as String,parties: freezed == parties ? _self.parties : parties // ignore: cast_nullable_to_non_nullable
as MouParties?,
  ));
}
/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouPartiesCopyWith<$Res>? get parties {
    if (_self.parties == null) {
    return null;
  }

  return $MouPartiesCopyWith<$Res>(_self.parties!, (value) {
    return _then(_self.copyWith(parties: value));
  });
}
}


/// Adds pattern-matching-related methods to [MouAcceptance].
extension MouAcceptancePatterns on MouAcceptance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MouAcceptance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MouAcceptance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MouAcceptance value)  $default,){
final _that = this;
switch (_that) {
case _MouAcceptance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MouAcceptance value)?  $default,){
final _that = this;
switch (_that) {
case _MouAcceptance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String acceptedAt,  String signatureName,  String signatureDataUrl,  MouParties? parties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MouAcceptance() when $default != null:
return $default(_that.version,_that.acceptedAt,_that.signatureName,_that.signatureDataUrl,_that.parties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String acceptedAt,  String signatureName,  String signatureDataUrl,  MouParties? parties)  $default,) {final _that = this;
switch (_that) {
case _MouAcceptance():
return $default(_that.version,_that.acceptedAt,_that.signatureName,_that.signatureDataUrl,_that.parties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String acceptedAt,  String signatureName,  String signatureDataUrl,  MouParties? parties)?  $default,) {final _that = this;
switch (_that) {
case _MouAcceptance() when $default != null:
return $default(_that.version,_that.acceptedAt,_that.signatureName,_that.signatureDataUrl,_that.parties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MouAcceptance implements MouAcceptance {
  const _MouAcceptance({required this.version, required this.acceptedAt, this.signatureName = '', this.signatureDataUrl = '', this.parties});
  factory _MouAcceptance.fromJson(Map<String, dynamic> json) => _$MouAcceptanceFromJson(json);

@override final  String version;
@override final  String acceptedAt;
/// Typed by the signer; must match the account's name. Empty on records
/// that predate the field.
@override@JsonKey() final  String signatureName;
/// The drawn signature as a PNG data URL. Empty on records that predate
/// the signature pad (and on the offline mock, which only types a name).
@override@JsonKey() final  String signatureDataUrl;
/// The blanks as they stood when it was signed — what the signed copy
/// shows, whatever the profile says since.
@override final  MouParties? parties;

/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MouAcceptanceCopyWith<_MouAcceptance> get copyWith => __$MouAcceptanceCopyWithImpl<_MouAcceptance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MouAcceptanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MouAcceptance&&(identical(other.version, version) || other.version == version)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.signatureName, signatureName) || other.signatureName == signatureName)&&(identical(other.signatureDataUrl, signatureDataUrl) || other.signatureDataUrl == signatureDataUrl)&&(identical(other.parties, parties) || other.parties == parties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,acceptedAt,signatureName,signatureDataUrl,parties);

@override
String toString() {
  return 'MouAcceptance(version: $version, acceptedAt: $acceptedAt, signatureName: $signatureName, signatureDataUrl: $signatureDataUrl, parties: $parties)';
}


}

/// @nodoc
abstract mixin class _$MouAcceptanceCopyWith<$Res> implements $MouAcceptanceCopyWith<$Res> {
  factory _$MouAcceptanceCopyWith(_MouAcceptance value, $Res Function(_MouAcceptance) _then) = __$MouAcceptanceCopyWithImpl;
@override @useResult
$Res call({
 String version, String acceptedAt, String signatureName, String signatureDataUrl, MouParties? parties
});


@override $MouPartiesCopyWith<$Res>? get parties;

}
/// @nodoc
class __$MouAcceptanceCopyWithImpl<$Res>
    implements _$MouAcceptanceCopyWith<$Res> {
  __$MouAcceptanceCopyWithImpl(this._self, this._then);

  final _MouAcceptance _self;
  final $Res Function(_MouAcceptance) _then;

/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? acceptedAt = null,Object? signatureName = null,Object? signatureDataUrl = null,Object? parties = freezed,}) {
  return _then(_MouAcceptance(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: null == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String,signatureName: null == signatureName ? _self.signatureName : signatureName // ignore: cast_nullable_to_non_nullable
as String,signatureDataUrl: null == signatureDataUrl ? _self.signatureDataUrl : signatureDataUrl // ignore: cast_nullable_to_non_nullable
as String,parties: freezed == parties ? _self.parties : parties // ignore: cast_nullable_to_non_nullable
as MouParties?,
  ));
}

/// Create a copy of MouAcceptance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MouPartiesCopyWith<$Res>? get parties {
    if (_self.parties == null) {
    return null;
  }

  return $MouPartiesCopyWith<$Res>(_self.parties!, (value) {
    return _then(_self.copyWith(parties: value));
  });
}
}

// dart format on
