// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_portal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityEntry {

 String get id; ActivityKind get kind; String get title; String get detail; String get time;
/// Create a copy of ActivityEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityEntryCopyWith<ActivityEntry> get copyWith => _$ActivityEntryCopyWithImpl<ActivityEntry>(this as ActivityEntry, _$identity);

  /// Serializes this ActivityEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,detail,time);

@override
String toString() {
  return 'ActivityEntry(id: $id, kind: $kind, title: $title, detail: $detail, time: $time)';
}


}

/// @nodoc
abstract mixin class $ActivityEntryCopyWith<$Res>  {
  factory $ActivityEntryCopyWith(ActivityEntry value, $Res Function(ActivityEntry) _then) = _$ActivityEntryCopyWithImpl;
@useResult
$Res call({
 String id, ActivityKind kind, String title, String detail, String time
});




}
/// @nodoc
class _$ActivityEntryCopyWithImpl<$Res>
    implements $ActivityEntryCopyWith<$Res> {
  _$ActivityEntryCopyWithImpl(this._self, this._then);

  final ActivityEntry _self;
  final $Res Function(ActivityEntry) _then;

/// Create a copy of ActivityEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? detail = null,Object? time = null,}) {
  return _then(ActivityEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityEntry].
extension ActivityEntryPatterns on ActivityEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityEntry value)  $default,){
final _that = this;
switch (_that) {
case _ActivityEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ActivityKind kind,  String title,  String detail,  String time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityEntry() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ActivityKind kind,  String title,  String detail,  String time)  $default,) {final _that = this;
switch (_that) {
case _ActivityEntry():
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ActivityKind kind,  String title,  String detail,  String time)?  $default,) {final _that = this;
switch (_that) {
case _ActivityEntry() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityEntry implements ActivityEntry {
  const _ActivityEntry({required this.id, required this.kind, required this.title, required this.detail, required this.time});
  factory _ActivityEntry.fromJson(Map<String, dynamic> json) => _$ActivityEntryFromJson(json);

@override final  String id;
@override final  ActivityKind kind;
@override final  String title;
@override final  String detail;
@override final  String time;

/// Create a copy of ActivityEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityEntryCopyWith<_ActivityEntry> get copyWith => __$ActivityEntryCopyWithImpl<_ActivityEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,detail,time);

@override
String toString() {
  return 'ActivityEntry(id: $id, kind: $kind, title: $title, detail: $detail, time: $time)';
}


}

/// @nodoc
abstract mixin class _$ActivityEntryCopyWith<$Res> implements $ActivityEntryCopyWith<$Res> {
  factory _$ActivityEntryCopyWith(_ActivityEntry value, $Res Function(_ActivityEntry) _then) = __$ActivityEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, ActivityKind kind, String title, String detail, String time
});




}
/// @nodoc
class __$ActivityEntryCopyWithImpl<$Res>
    implements _$ActivityEntryCopyWith<$Res> {
  __$ActivityEntryCopyWithImpl(this._self, this._then);

  final _ActivityEntry _self;
  final $Res Function(_ActivityEntry) _then;

/// Create a copy of ActivityEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? detail = null,Object? time = null,}) {
  return _then(_ActivityEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ArtistProfileDetails {

 String get fullName; String get email; String get phone; String get bio; String get instagram; String get website; String get bankAccountMasked; String get ifsc; AadhaarStatus get aadhaarStatus; String get aadhaarMasked;
/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistProfileDetailsCopyWith<ArtistProfileDetails> get copyWith => _$ArtistProfileDetailsCopyWithImpl<ArtistProfileDetails>(this as ArtistProfileDetails, _$identity);

  /// Serializes this ArtistProfileDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistProfileDetails&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.website, website) || other.website == website)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.aadhaarStatus, aadhaarStatus) || other.aadhaarStatus == aadhaarStatus)&&(identical(other.aadhaarMasked, aadhaarMasked) || other.aadhaarMasked == aadhaarMasked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,email,phone,bio,instagram,website,bankAccountMasked,ifsc,aadhaarStatus,aadhaarMasked);

@override
String toString() {
  return 'ArtistProfileDetails(fullName: $fullName, email: $email, phone: $phone, bio: $bio, instagram: $instagram, website: $website, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, aadhaarStatus: $aadhaarStatus, aadhaarMasked: $aadhaarMasked)';
}


}

/// @nodoc
abstract mixin class $ArtistProfileDetailsCopyWith<$Res>  {
  factory $ArtistProfileDetailsCopyWith(ArtistProfileDetails value, $Res Function(ArtistProfileDetails) _then) = _$ArtistProfileDetailsCopyWithImpl;
@useResult
$Res call({
 String fullName, String email, String phone, String bio, String instagram, String website, String bankAccountMasked, String ifsc, AadhaarStatus aadhaarStatus, String aadhaarMasked
});




}
/// @nodoc
class _$ArtistProfileDetailsCopyWithImpl<$Res>
    implements $ArtistProfileDetailsCopyWith<$Res> {
  _$ArtistProfileDetailsCopyWithImpl(this._self, this._then);

  final ArtistProfileDetails _self;
  final $Res Function(ArtistProfileDetails) _then;

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? email = null,Object? phone = null,Object? bio = null,Object? instagram = null,Object? website = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? aadhaarStatus = null,Object? aadhaarMasked = null,}) {
  return _then(ArtistProfileDetails(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,instagram: null == instagram ? _self.instagram : instagram // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,bankAccountMasked: null == bankAccountMasked ? _self.bankAccountMasked : bankAccountMasked // ignore: cast_nullable_to_non_nullable
as String,ifsc: null == ifsc ? _self.ifsc : ifsc // ignore: cast_nullable_to_non_nullable
as String,aadhaarStatus: null == aadhaarStatus ? _self.aadhaarStatus : aadhaarStatus // ignore: cast_nullable_to_non_nullable
as AadhaarStatus,aadhaarMasked: null == aadhaarMasked ? _self.aadhaarMasked : aadhaarMasked // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistProfileDetails].
extension ArtistProfileDetailsPatterns on ArtistProfileDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistProfileDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistProfileDetails value)  $default,){
final _that = this;
switch (_that) {
case _ArtistProfileDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistProfileDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  AadhaarStatus aadhaarStatus,  String aadhaarMasked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  AadhaarStatus aadhaarStatus,  String aadhaarMasked)  $default,) {final _that = this;
switch (_that) {
case _ArtistProfileDetails():
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  AadhaarStatus aadhaarStatus,  String aadhaarMasked)?  $default,) {final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistProfileDetails implements ArtistProfileDetails {
  const _ArtistProfileDetails({required this.fullName, required this.email, required this.phone, required this.bio, required this.instagram, required this.website, required this.bankAccountMasked, required this.ifsc, required this.aadhaarStatus, required this.aadhaarMasked});
  factory _ArtistProfileDetails.fromJson(Map<String, dynamic> json) => _$ArtistProfileDetailsFromJson(json);

@override final  String fullName;
@override final  String email;
@override final  String phone;
@override final  String bio;
@override final  String instagram;
@override final  String website;
@override final  String bankAccountMasked;
@override final  String ifsc;
@override final  AadhaarStatus aadhaarStatus;
@override final  String aadhaarMasked;

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistProfileDetailsCopyWith<_ArtistProfileDetails> get copyWith => __$ArtistProfileDetailsCopyWithImpl<_ArtistProfileDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistProfileDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistProfileDetails&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.website, website) || other.website == website)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.aadhaarStatus, aadhaarStatus) || other.aadhaarStatus == aadhaarStatus)&&(identical(other.aadhaarMasked, aadhaarMasked) || other.aadhaarMasked == aadhaarMasked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,email,phone,bio,instagram,website,bankAccountMasked,ifsc,aadhaarStatus,aadhaarMasked);

@override
String toString() {
  return 'ArtistProfileDetails(fullName: $fullName, email: $email, phone: $phone, bio: $bio, instagram: $instagram, website: $website, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, aadhaarStatus: $aadhaarStatus, aadhaarMasked: $aadhaarMasked)';
}


}

/// @nodoc
abstract mixin class _$ArtistProfileDetailsCopyWith<$Res> implements $ArtistProfileDetailsCopyWith<$Res> {
  factory _$ArtistProfileDetailsCopyWith(_ArtistProfileDetails value, $Res Function(_ArtistProfileDetails) _then) = __$ArtistProfileDetailsCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String email, String phone, String bio, String instagram, String website, String bankAccountMasked, String ifsc, AadhaarStatus aadhaarStatus, String aadhaarMasked
});




}
/// @nodoc
class __$ArtistProfileDetailsCopyWithImpl<$Res>
    implements _$ArtistProfileDetailsCopyWith<$Res> {
  __$ArtistProfileDetailsCopyWithImpl(this._self, this._then);

  final _ArtistProfileDetails _self;
  final $Res Function(_ArtistProfileDetails) _then;

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? email = null,Object? phone = null,Object? bio = null,Object? instagram = null,Object? website = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? aadhaarStatus = null,Object? aadhaarMasked = null,}) {
  return _then(_ArtistProfileDetails(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,instagram: null == instagram ? _self.instagram : instagram // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,bankAccountMasked: null == bankAccountMasked ? _self.bankAccountMasked : bankAccountMasked // ignore: cast_nullable_to_non_nullable
as String,ifsc: null == ifsc ? _self.ifsc : ifsc // ignore: cast_nullable_to_non_nullable
as String,aadhaarStatus: null == aadhaarStatus ? _self.aadhaarStatus : aadhaarStatus // ignore: cast_nullable_to_non_nullable
as AadhaarStatus,aadhaarMasked: null == aadhaarMasked ? _self.aadhaarMasked : aadhaarMasked // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ArtistSettings {

 bool get notifyArtworkApproved; bool get notifyNewSale; bool get notifyWithdrawalProcessed; bool get notifyNewMessage;
/// Create a copy of ArtistSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistSettingsCopyWith<ArtistSettings> get copyWith => _$ArtistSettingsCopyWithImpl<ArtistSettings>(this as ArtistSettings, _$identity);

  /// Serializes this ArtistSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistSettings&&(identical(other.notifyArtworkApproved, notifyArtworkApproved) || other.notifyArtworkApproved == notifyArtworkApproved)&&(identical(other.notifyNewSale, notifyNewSale) || other.notifyNewSale == notifyNewSale)&&(identical(other.notifyWithdrawalProcessed, notifyWithdrawalProcessed) || other.notifyWithdrawalProcessed == notifyWithdrawalProcessed)&&(identical(other.notifyNewMessage, notifyNewMessage) || other.notifyNewMessage == notifyNewMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifyArtworkApproved,notifyNewSale,notifyWithdrawalProcessed,notifyNewMessage);

@override
String toString() {
  return 'ArtistSettings(notifyArtworkApproved: $notifyArtworkApproved, notifyNewSale: $notifyNewSale, notifyWithdrawalProcessed: $notifyWithdrawalProcessed, notifyNewMessage: $notifyNewMessage)';
}


}

/// @nodoc
abstract mixin class $ArtistSettingsCopyWith<$Res>  {
  factory $ArtistSettingsCopyWith(ArtistSettings value, $Res Function(ArtistSettings) _then) = _$ArtistSettingsCopyWithImpl;
@useResult
$Res call({
 bool notifyArtworkApproved, bool notifyNewSale, bool notifyWithdrawalProcessed, bool notifyNewMessage
});




}
/// @nodoc
class _$ArtistSettingsCopyWithImpl<$Res>
    implements $ArtistSettingsCopyWith<$Res> {
  _$ArtistSettingsCopyWithImpl(this._self, this._then);

  final ArtistSettings _self;
  final $Res Function(ArtistSettings) _then;

/// Create a copy of ArtistSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifyArtworkApproved = null,Object? notifyNewSale = null,Object? notifyWithdrawalProcessed = null,Object? notifyNewMessage = null,}) {
  return _then(ArtistSettings(
notifyArtworkApproved: null == notifyArtworkApproved ? _self.notifyArtworkApproved : notifyArtworkApproved // ignore: cast_nullable_to_non_nullable
as bool,notifyNewSale: null == notifyNewSale ? _self.notifyNewSale : notifyNewSale // ignore: cast_nullable_to_non_nullable
as bool,notifyWithdrawalProcessed: null == notifyWithdrawalProcessed ? _self.notifyWithdrawalProcessed : notifyWithdrawalProcessed // ignore: cast_nullable_to_non_nullable
as bool,notifyNewMessage: null == notifyNewMessage ? _self.notifyNewMessage : notifyNewMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistSettings].
extension ArtistSettingsPatterns on ArtistSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistSettings value)  $default,){
final _that = this;
switch (_that) {
case _ArtistSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool notifyArtworkApproved,  bool notifyNewSale,  bool notifyWithdrawalProcessed,  bool notifyNewMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistSettings() when $default != null:
return $default(_that.notifyArtworkApproved,_that.notifyNewSale,_that.notifyWithdrawalProcessed,_that.notifyNewMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool notifyArtworkApproved,  bool notifyNewSale,  bool notifyWithdrawalProcessed,  bool notifyNewMessage)  $default,) {final _that = this;
switch (_that) {
case _ArtistSettings():
return $default(_that.notifyArtworkApproved,_that.notifyNewSale,_that.notifyWithdrawalProcessed,_that.notifyNewMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool notifyArtworkApproved,  bool notifyNewSale,  bool notifyWithdrawalProcessed,  bool notifyNewMessage)?  $default,) {final _that = this;
switch (_that) {
case _ArtistSettings() when $default != null:
return $default(_that.notifyArtworkApproved,_that.notifyNewSale,_that.notifyWithdrawalProcessed,_that.notifyNewMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistSettings implements ArtistSettings {
  const _ArtistSettings({required this.notifyArtworkApproved, required this.notifyNewSale, required this.notifyWithdrawalProcessed, required this.notifyNewMessage});
  factory _ArtistSettings.fromJson(Map<String, dynamic> json) => _$ArtistSettingsFromJson(json);

@override final  bool notifyArtworkApproved;
@override final  bool notifyNewSale;
@override final  bool notifyWithdrawalProcessed;
@override final  bool notifyNewMessage;

/// Create a copy of ArtistSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistSettingsCopyWith<_ArtistSettings> get copyWith => __$ArtistSettingsCopyWithImpl<_ArtistSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistSettings&&(identical(other.notifyArtworkApproved, notifyArtworkApproved) || other.notifyArtworkApproved == notifyArtworkApproved)&&(identical(other.notifyNewSale, notifyNewSale) || other.notifyNewSale == notifyNewSale)&&(identical(other.notifyWithdrawalProcessed, notifyWithdrawalProcessed) || other.notifyWithdrawalProcessed == notifyWithdrawalProcessed)&&(identical(other.notifyNewMessage, notifyNewMessage) || other.notifyNewMessage == notifyNewMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notifyArtworkApproved,notifyNewSale,notifyWithdrawalProcessed,notifyNewMessage);

@override
String toString() {
  return 'ArtistSettings(notifyArtworkApproved: $notifyArtworkApproved, notifyNewSale: $notifyNewSale, notifyWithdrawalProcessed: $notifyWithdrawalProcessed, notifyNewMessage: $notifyNewMessage)';
}


}

/// @nodoc
abstract mixin class _$ArtistSettingsCopyWith<$Res> implements $ArtistSettingsCopyWith<$Res> {
  factory _$ArtistSettingsCopyWith(_ArtistSettings value, $Res Function(_ArtistSettings) _then) = __$ArtistSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool notifyArtworkApproved, bool notifyNewSale, bool notifyWithdrawalProcessed, bool notifyNewMessage
});




}
/// @nodoc
class __$ArtistSettingsCopyWithImpl<$Res>
    implements _$ArtistSettingsCopyWith<$Res> {
  __$ArtistSettingsCopyWithImpl(this._self, this._then);

  final _ArtistSettings _self;
  final $Res Function(_ArtistSettings) _then;

/// Create a copy of ArtistSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifyArtworkApproved = null,Object? notifyNewSale = null,Object? notifyWithdrawalProcessed = null,Object? notifyNewMessage = null,}) {
  return _then(_ArtistSettings(
notifyArtworkApproved: null == notifyArtworkApproved ? _self.notifyArtworkApproved : notifyArtworkApproved // ignore: cast_nullable_to_non_nullable
as bool,notifyNewSale: null == notifyNewSale ? _self.notifyNewSale : notifyNewSale // ignore: cast_nullable_to_non_nullable
as bool,notifyWithdrawalProcessed: null == notifyWithdrawalProcessed ? _self.notifyWithdrawalProcessed : notifyWithdrawalProcessed // ignore: cast_nullable_to_non_nullable
as bool,notifyNewMessage: null == notifyNewMessage ? _self.notifyNewMessage : notifyNewMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Settlement {

 String get id; String get orderId; String get artworkTitle; String get artistName; double get artistAmount; double get aggregatorCommission; double get platformRevenue; SettlementStatus get status; String get createdAt; String? get processedAt;
/// Create a copy of Settlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementCopyWith<Settlement> get copyWith => _$SettlementCopyWithImpl<Settlement>(this as Settlement, _$identity);

  /// Serializes this Settlement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settlement&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistAmount, artistAmount) || other.artistAmount == artistAmount)&&(identical(other.aggregatorCommission, aggregatorCommission) || other.aggregatorCommission == aggregatorCommission)&&(identical(other.platformRevenue, platformRevenue) || other.platformRevenue == platformRevenue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,artworkTitle,artistName,artistAmount,aggregatorCommission,platformRevenue,status,createdAt,processedAt);

@override
String toString() {
  return 'Settlement(id: $id, orderId: $orderId, artworkTitle: $artworkTitle, artistName: $artistName, artistAmount: $artistAmount, aggregatorCommission: $aggregatorCommission, platformRevenue: $platformRevenue, status: $status, createdAt: $createdAt, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class $SettlementCopyWith<$Res>  {
  factory $SettlementCopyWith(Settlement value, $Res Function(Settlement) _then) = _$SettlementCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String artworkTitle, String artistName, double artistAmount, double aggregatorCommission, double platformRevenue, SettlementStatus status, String createdAt, String? processedAt
});




}
/// @nodoc
class _$SettlementCopyWithImpl<$Res>
    implements $SettlementCopyWith<$Res> {
  _$SettlementCopyWithImpl(this._self, this._then);

  final Settlement _self;
  final $Res Function(Settlement) _then;

/// Create a copy of Settlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? artworkTitle = null,Object? artistName = null,Object? artistAmount = null,Object? aggregatorCommission = null,Object? platformRevenue = null,Object? status = null,Object? createdAt = null,Object? processedAt = freezed,}) {
  return _then(Settlement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistAmount: null == artistAmount ? _self.artistAmount : artistAmount // ignore: cast_nullable_to_non_nullable
as double,aggregatorCommission: null == aggregatorCommission ? _self.aggregatorCommission : aggregatorCommission // ignore: cast_nullable_to_non_nullable
as double,platformRevenue: null == platformRevenue ? _self.platformRevenue : platformRevenue // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SettlementStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Settlement].
extension SettlementPatterns on Settlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Settlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Settlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Settlement value)  $default,){
final _that = this;
switch (_that) {
case _Settlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Settlement value)?  $default,){
final _that = this;
switch (_that) {
case _Settlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settlement() when $default != null:
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt)  $default,) {final _that = this;
switch (_that) {
case _Settlement():
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt)?  $default,) {final _that = this;
switch (_that) {
case _Settlement() when $default != null:
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settlement implements Settlement {
  const _Settlement({required this.id, required this.orderId, required this.artworkTitle, required this.artistName, required this.artistAmount, required this.aggregatorCommission, required this.platformRevenue, required this.status, required this.createdAt, this.processedAt});
  factory _Settlement.fromJson(Map<String, dynamic> json) => _$SettlementFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String artworkTitle;
@override final  String artistName;
@override final  double artistAmount;
@override final  double aggregatorCommission;
@override final  double platformRevenue;
@override final  SettlementStatus status;
@override final  String createdAt;
@override final  String? processedAt;

/// Create a copy of Settlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementCopyWith<_Settlement> get copyWith => __$SettlementCopyWithImpl<_Settlement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settlement&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistAmount, artistAmount) || other.artistAmount == artistAmount)&&(identical(other.aggregatorCommission, aggregatorCommission) || other.aggregatorCommission == aggregatorCommission)&&(identical(other.platformRevenue, platformRevenue) || other.platformRevenue == platformRevenue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,artworkTitle,artistName,artistAmount,aggregatorCommission,platformRevenue,status,createdAt,processedAt);

@override
String toString() {
  return 'Settlement(id: $id, orderId: $orderId, artworkTitle: $artworkTitle, artistName: $artistName, artistAmount: $artistAmount, aggregatorCommission: $aggregatorCommission, platformRevenue: $platformRevenue, status: $status, createdAt: $createdAt, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class _$SettlementCopyWith<$Res> implements $SettlementCopyWith<$Res> {
  factory _$SettlementCopyWith(_Settlement value, $Res Function(_Settlement) _then) = __$SettlementCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String artworkTitle, String artistName, double artistAmount, double aggregatorCommission, double platformRevenue, SettlementStatus status, String createdAt, String? processedAt
});




}
/// @nodoc
class __$SettlementCopyWithImpl<$Res>
    implements _$SettlementCopyWith<$Res> {
  __$SettlementCopyWithImpl(this._self, this._then);

  final _Settlement _self;
  final $Res Function(_Settlement) _then;

/// Create a copy of Settlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? artworkTitle = null,Object? artistName = null,Object? artistAmount = null,Object? aggregatorCommission = null,Object? platformRevenue = null,Object? status = null,Object? createdAt = null,Object? processedAt = freezed,}) {
  return _then(_Settlement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistAmount: null == artistAmount ? _self.artistAmount : artistAmount // ignore: cast_nullable_to_non_nullable
as double,aggregatorCommission: null == aggregatorCommission ? _self.aggregatorCommission : aggregatorCommission // ignore: cast_nullable_to_non_nullable
as double,platformRevenue: null == platformRevenue ? _self.platformRevenue : platformRevenue // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SettlementStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MessageThread {

 String get id; String get from; String get subject; String get preview; String get body; bool get unread; String get receivedAt;
/// Create a copy of MessageThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageThreadCopyWith<MessageThread> get copyWith => _$MessageThreadCopyWithImpl<MessageThread>(this as MessageThread, _$identity);

  /// Serializes this MessageThread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageThread&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.body, body) || other.body == body)&&(identical(other.unread, unread) || other.unread == unread)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,subject,preview,body,unread,receivedAt);

@override
String toString() {
  return 'MessageThread(id: $id, from: $from, subject: $subject, preview: $preview, body: $body, unread: $unread, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class $MessageThreadCopyWith<$Res>  {
  factory $MessageThreadCopyWith(MessageThread value, $Res Function(MessageThread) _then) = _$MessageThreadCopyWithImpl;
@useResult
$Res call({
 String id, String from, String subject, String preview, String body, bool unread, String receivedAt
});




}
/// @nodoc
class _$MessageThreadCopyWithImpl<$Res>
    implements $MessageThreadCopyWith<$Res> {
  _$MessageThreadCopyWithImpl(this._self, this._then);

  final MessageThread _self;
  final $Res Function(MessageThread) _then;

/// Create a copy of MessageThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? from = null,Object? subject = null,Object? preview = null,Object? body = null,Object? unread = null,Object? receivedAt = null,}) {
  return _then(MessageThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as bool,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageThread].
extension MessageThreadPatterns on MessageThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageThread value)  $default,){
final _that = this;
switch (_that) {
case _MessageThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageThread value)?  $default,){
final _that = this;
switch (_that) {
case _MessageThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String from,  String subject,  String preview,  String body,  bool unread,  String receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageThread() when $default != null:
return $default(_that.id,_that.from,_that.subject,_that.preview,_that.body,_that.unread,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String from,  String subject,  String preview,  String body,  bool unread,  String receivedAt)  $default,) {final _that = this;
switch (_that) {
case _MessageThread():
return $default(_that.id,_that.from,_that.subject,_that.preview,_that.body,_that.unread,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String from,  String subject,  String preview,  String body,  bool unread,  String receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageThread() when $default != null:
return $default(_that.id,_that.from,_that.subject,_that.preview,_that.body,_that.unread,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageThread implements MessageThread {
  const _MessageThread({required this.id, required this.from, required this.subject, required this.preview, required this.body, required this.unread, required this.receivedAt});
  factory _MessageThread.fromJson(Map<String, dynamic> json) => _$MessageThreadFromJson(json);

@override final  String id;
@override final  String from;
@override final  String subject;
@override final  String preview;
@override final  String body;
@override final  bool unread;
@override final  String receivedAt;

/// Create a copy of MessageThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageThreadCopyWith<_MessageThread> get copyWith => __$MessageThreadCopyWithImpl<_MessageThread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageThreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageThread&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.body, body) || other.body == body)&&(identical(other.unread, unread) || other.unread == unread)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,subject,preview,body,unread,receivedAt);

@override
String toString() {
  return 'MessageThread(id: $id, from: $from, subject: $subject, preview: $preview, body: $body, unread: $unread, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageThreadCopyWith<$Res> implements $MessageThreadCopyWith<$Res> {
  factory _$MessageThreadCopyWith(_MessageThread value, $Res Function(_MessageThread) _then) = __$MessageThreadCopyWithImpl;
@override @useResult
$Res call({
 String id, String from, String subject, String preview, String body, bool unread, String receivedAt
});




}
/// @nodoc
class __$MessageThreadCopyWithImpl<$Res>
    implements _$MessageThreadCopyWith<$Res> {
  __$MessageThreadCopyWithImpl(this._self, this._then);

  final _MessageThread _self;
  final $Res Function(_MessageThread) _then;

/// Create a copy of MessageThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? from = null,Object? subject = null,Object? preview = null,Object? body = null,Object? unread = null,Object? receivedAt = null,}) {
  return _then(_MessageThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as bool,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AggregatorHolding {

 String get id; String get artworkId; int get advancePercent; double get advanceAmount; double get displayPrice; String get assignedAt; String get expiresAt; HoldingStatus get status; AssignmentSource get assignmentSource;
/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AggregatorHoldingCopyWith<AggregatorHolding> get copyWith => _$AggregatorHoldingCopyWithImpl<AggregatorHolding>(this as AggregatorHolding, _$identity);

  /// Serializes this AggregatorHolding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AggregatorHolding&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.advancePercent, advancePercent) || other.advancePercent == advancePercent)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.displayPrice, displayPrice) || other.displayPrice == displayPrice)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignmentSource, assignmentSource) || other.assignmentSource == assignmentSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,advancePercent,advanceAmount,displayPrice,assignedAt,expiresAt,status,assignmentSource);

@override
String toString() {
  return 'AggregatorHolding(id: $id, artworkId: $artworkId, advancePercent: $advancePercent, advanceAmount: $advanceAmount, displayPrice: $displayPrice, assignedAt: $assignedAt, expiresAt: $expiresAt, status: $status, assignmentSource: $assignmentSource)';
}


}

/// @nodoc
abstract mixin class $AggregatorHoldingCopyWith<$Res>  {
  factory $AggregatorHoldingCopyWith(AggregatorHolding value, $Res Function(AggregatorHolding) _then) = _$AggregatorHoldingCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, int advancePercent, double advanceAmount, double displayPrice, String assignedAt, String expiresAt, HoldingStatus status, AssignmentSource assignmentSource
});




}
/// @nodoc
class _$AggregatorHoldingCopyWithImpl<$Res>
    implements $AggregatorHoldingCopyWith<$Res> {
  _$AggregatorHoldingCopyWithImpl(this._self, this._then);

  final AggregatorHolding _self;
  final $Res Function(AggregatorHolding) _then;

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? advancePercent = null,Object? advanceAmount = null,Object? displayPrice = null,Object? assignedAt = null,Object? expiresAt = null,Object? status = null,Object? assignmentSource = null,}) {
  return _then(AggregatorHolding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,advancePercent: null == advancePercent ? _self.advancePercent : advancePercent // ignore: cast_nullable_to_non_nullable
as int,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,displayPrice: null == displayPrice ? _self.displayPrice : displayPrice // ignore: cast_nullable_to_non_nullable
as double,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HoldingStatus,assignmentSource: null == assignmentSource ? _self.assignmentSource : assignmentSource // ignore: cast_nullable_to_non_nullable
as AssignmentSource,
  ));
}

}


/// Adds pattern-matching-related methods to [AggregatorHolding].
extension AggregatorHoldingPatterns on AggregatorHolding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AggregatorHolding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AggregatorHolding value)  $default,){
final _that = this;
switch (_that) {
case _AggregatorHolding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AggregatorHolding value)?  $default,){
final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource)  $default,) {final _that = this;
switch (_that) {
case _AggregatorHolding():
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource)?  $default,) {final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AggregatorHolding implements AggregatorHolding {
  const _AggregatorHolding({required this.id, required this.artworkId, required this.advancePercent, required this.advanceAmount, required this.displayPrice, required this.assignedAt, required this.expiresAt, required this.status, required this.assignmentSource});
  factory _AggregatorHolding.fromJson(Map<String, dynamic> json) => _$AggregatorHoldingFromJson(json);

@override final  String id;
@override final  String artworkId;
@override final  int advancePercent;
@override final  double advanceAmount;
@override final  double displayPrice;
@override final  String assignedAt;
@override final  String expiresAt;
@override final  HoldingStatus status;
@override final  AssignmentSource assignmentSource;

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AggregatorHoldingCopyWith<_AggregatorHolding> get copyWith => __$AggregatorHoldingCopyWithImpl<_AggregatorHolding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AggregatorHoldingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AggregatorHolding&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.advancePercent, advancePercent) || other.advancePercent == advancePercent)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.displayPrice, displayPrice) || other.displayPrice == displayPrice)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignmentSource, assignmentSource) || other.assignmentSource == assignmentSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,advancePercent,advanceAmount,displayPrice,assignedAt,expiresAt,status,assignmentSource);

@override
String toString() {
  return 'AggregatorHolding(id: $id, artworkId: $artworkId, advancePercent: $advancePercent, advanceAmount: $advanceAmount, displayPrice: $displayPrice, assignedAt: $assignedAt, expiresAt: $expiresAt, status: $status, assignmentSource: $assignmentSource)';
}


}

/// @nodoc
abstract mixin class _$AggregatorHoldingCopyWith<$Res> implements $AggregatorHoldingCopyWith<$Res> {
  factory _$AggregatorHoldingCopyWith(_AggregatorHolding value, $Res Function(_AggregatorHolding) _then) = __$AggregatorHoldingCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, int advancePercent, double advanceAmount, double displayPrice, String assignedAt, String expiresAt, HoldingStatus status, AssignmentSource assignmentSource
});




}
/// @nodoc
class __$AggregatorHoldingCopyWithImpl<$Res>
    implements _$AggregatorHoldingCopyWith<$Res> {
  __$AggregatorHoldingCopyWithImpl(this._self, this._then);

  final _AggregatorHolding _self;
  final $Res Function(_AggregatorHolding) _then;

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? advancePercent = null,Object? advanceAmount = null,Object? displayPrice = null,Object? assignedAt = null,Object? expiresAt = null,Object? status = null,Object? assignmentSource = null,}) {
  return _then(_AggregatorHolding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,advancePercent: null == advancePercent ? _self.advancePercent : advancePercent // ignore: cast_nullable_to_non_nullable
as int,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,displayPrice: null == displayPrice ? _self.displayPrice : displayPrice // ignore: cast_nullable_to_non_nullable
as double,assignedAt: null == assignedAt ? _self.assignedAt : assignedAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HoldingStatus,assignmentSource: null == assignmentSource ? _self.assignmentSource : assignmentSource // ignore: cast_nullable_to_non_nullable
as AssignmentSource,
  ));
}


}


/// @nodoc
mixin _$RevenuePoint {

 String get month; double get amount;
/// Create a copy of RevenuePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevenuePointCopyWith<RevenuePoint> get copyWith => _$RevenuePointCopyWithImpl<RevenuePoint>(this as RevenuePoint, _$identity);

  /// Serializes this RevenuePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevenuePoint&&(identical(other.month, month) || other.month == month)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,amount);

@override
String toString() {
  return 'RevenuePoint(month: $month, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $RevenuePointCopyWith<$Res>  {
  factory $RevenuePointCopyWith(RevenuePoint value, $Res Function(RevenuePoint) _then) = _$RevenuePointCopyWithImpl;
@useResult
$Res call({
 String month, double amount
});




}
/// @nodoc
class _$RevenuePointCopyWithImpl<$Res>
    implements $RevenuePointCopyWith<$Res> {
  _$RevenuePointCopyWithImpl(this._self, this._then);

  final RevenuePoint _self;
  final $Res Function(RevenuePoint) _then;

/// Create a copy of RevenuePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? amount = null,}) {
  return _then(RevenuePoint(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RevenuePoint].
extension RevenuePointPatterns on RevenuePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevenuePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevenuePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevenuePoint value)  $default,){
final _that = this;
switch (_that) {
case _RevenuePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevenuePoint value)?  $default,){
final _that = this;
switch (_that) {
case _RevenuePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevenuePoint() when $default != null:
return $default(_that.month,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  double amount)  $default,) {final _that = this;
switch (_that) {
case _RevenuePoint():
return $default(_that.month,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  double amount)?  $default,) {final _that = this;
switch (_that) {
case _RevenuePoint() when $default != null:
return $default(_that.month,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevenuePoint implements RevenuePoint {
  const _RevenuePoint({required this.month, required this.amount});
  factory _RevenuePoint.fromJson(Map<String, dynamic> json) => _$RevenuePointFromJson(json);

@override final  String month;
@override final  double amount;

/// Create a copy of RevenuePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevenuePointCopyWith<_RevenuePoint> get copyWith => __$RevenuePointCopyWithImpl<_RevenuePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevenuePointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevenuePoint&&(identical(other.month, month) || other.month == month)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,amount);

@override
String toString() {
  return 'RevenuePoint(month: $month, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$RevenuePointCopyWith<$Res> implements $RevenuePointCopyWith<$Res> {
  factory _$RevenuePointCopyWith(_RevenuePoint value, $Res Function(_RevenuePoint) _then) = __$RevenuePointCopyWithImpl;
@override @useResult
$Res call({
 String month, double amount
});




}
/// @nodoc
class __$RevenuePointCopyWithImpl<$Res>
    implements _$RevenuePointCopyWith<$Res> {
  __$RevenuePointCopyWithImpl(this._self, this._then);

  final _RevenuePoint _self;
  final $Res Function(_RevenuePoint) _then;

/// Create a copy of RevenuePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? amount = null,}) {
  return _then(_RevenuePoint(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
