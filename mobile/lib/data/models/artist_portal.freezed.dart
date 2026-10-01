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
mixin _$FreeAccess {

/// When the free period ends (ISO).
 String get until; int get months; bool get surveyRespondent; bool get active;
/// Create a copy of FreeAccess
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeAccessCopyWith<FreeAccess> get copyWith => _$FreeAccessCopyWithImpl<FreeAccess>(this as FreeAccess, _$identity);

  /// Serializes this FreeAccess to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeAccess&&(identical(other.until, until) || other.until == until)&&(identical(other.months, months) || other.months == months)&&(identical(other.surveyRespondent, surveyRespondent) || other.surveyRespondent == surveyRespondent)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,until,months,surveyRespondent,active);

@override
String toString() {
  return 'FreeAccess(until: $until, months: $months, surveyRespondent: $surveyRespondent, active: $active)';
}


}

/// @nodoc
abstract mixin class $FreeAccessCopyWith<$Res>  {
  factory $FreeAccessCopyWith(FreeAccess value, $Res Function(FreeAccess) _then) = _$FreeAccessCopyWithImpl;
@useResult
$Res call({
 String until, int months, bool surveyRespondent, bool active
});




}
/// @nodoc
class _$FreeAccessCopyWithImpl<$Res>
    implements $FreeAccessCopyWith<$Res> {
  _$FreeAccessCopyWithImpl(this._self, this._then);

  final FreeAccess _self;
  final $Res Function(FreeAccess) _then;

/// Create a copy of FreeAccess
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? until = null,Object? months = null,Object? surveyRespondent = null,Object? active = null,}) {
  return _then(FreeAccess(
until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as String,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,surveyRespondent: null == surveyRespondent ? _self.surveyRespondent : surveyRespondent // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FreeAccess].
extension FreeAccessPatterns on FreeAccess {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreeAccess value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreeAccess() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreeAccess value)  $default,){
final _that = this;
switch (_that) {
case _FreeAccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreeAccess value)?  $default,){
final _that = this;
switch (_that) {
case _FreeAccess() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String until,  int months,  bool surveyRespondent,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeAccess() when $default != null:
return $default(_that.until,_that.months,_that.surveyRespondent,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String until,  int months,  bool surveyRespondent,  bool active)  $default,) {final _that = this;
switch (_that) {
case _FreeAccess():
return $default(_that.until,_that.months,_that.surveyRespondent,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String until,  int months,  bool surveyRespondent,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _FreeAccess() when $default != null:
return $default(_that.until,_that.months,_that.surveyRespondent,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FreeAccess implements FreeAccess {
  const _FreeAccess({required this.until, required this.months, this.surveyRespondent = false, this.active = true});
  factory _FreeAccess.fromJson(Map<String, dynamic> json) => _$FreeAccessFromJson(json);

/// When the free period ends (ISO).
@override final  String until;
@override final  int months;
@override@JsonKey() final  bool surveyRespondent;
@override@JsonKey() final  bool active;

/// Create a copy of FreeAccess
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeAccessCopyWith<_FreeAccess> get copyWith => __$FreeAccessCopyWithImpl<_FreeAccess>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FreeAccessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeAccess&&(identical(other.until, until) || other.until == until)&&(identical(other.months, months) || other.months == months)&&(identical(other.surveyRespondent, surveyRespondent) || other.surveyRespondent == surveyRespondent)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,until,months,surveyRespondent,active);

@override
String toString() {
  return 'FreeAccess(until: $until, months: $months, surveyRespondent: $surveyRespondent, active: $active)';
}


}

/// @nodoc
abstract mixin class _$FreeAccessCopyWith<$Res> implements $FreeAccessCopyWith<$Res> {
  factory _$FreeAccessCopyWith(_FreeAccess value, $Res Function(_FreeAccess) _then) = __$FreeAccessCopyWithImpl;
@override @useResult
$Res call({
 String until, int months, bool surveyRespondent, bool active
});




}
/// @nodoc
class __$FreeAccessCopyWithImpl<$Res>
    implements _$FreeAccessCopyWith<$Res> {
  __$FreeAccessCopyWithImpl(this._self, this._then);

  final _FreeAccess _self;
  final $Res Function(_FreeAccess) _then;

/// Create a copy of FreeAccess
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? until = null,Object? months = null,Object? surveyRespondent = null,Object? active = null,}) {
  return _then(_FreeAccess(
until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as String,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,surveyRespondent: null == surveyRespondent ? _self.surveyRespondent : surveyRespondent // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ArtistProfileDetails {

 String get fullName; String get email; String get phone; String get bio; String get instagram; String get website; String get bankAccountMasked; String get ifsc; ReviewStatus get aadhaarStatus; String get aadhaarMasked;/// Mandatory for an artist to go live (client, 30 Aug 2026), reviewed by
/// GalleryZone — see [gstStatus]. Validated for shape only: there is no
/// GST portal integration, which the business deliberately does not want.
 String? get gstin;/// Where the GST number stands with GalleryZone's reviewers. A new or
/// changed number goes back to "submitted".
 ReviewStatus get gstStatus;/// PAN, kept private (admin-only; never on the public profile).
 String? get pan;/// One public line of what they make, and where they work. Mirrored onto
/// the public artist page.
 String? get headline; String? get location;/// A link to a short video that vouches for the work.
 String? get socialProofVideoUrl;/// On GalleryZone since (ISO).
 String get joinedAt;/// The Early Artist Program's free period. Null once it has no meaning
/// (not an artist) or the API didn't say.
 FreeAccess? get freeAccess;/// Where the courier collects. Private, and the one thing without which a
/// delivery cannot be quoted at all: shipping is priced on the distance
/// between two pincodes, and this is the origin for both the leg to an
/// aggregator and the leg to a buyer.
 String get pickupLine1; String get pickupLine2; String get pickupCity; String get pickupState; String get pickupPincode;
/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistProfileDetailsCopyWith<ArtistProfileDetails> get copyWith => _$ArtistProfileDetailsCopyWithImpl<ArtistProfileDetails>(this as ArtistProfileDetails, _$identity);

  /// Serializes this ArtistProfileDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistProfileDetails&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.website, website) || other.website == website)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.aadhaarStatus, aadhaarStatus) || other.aadhaarStatus == aadhaarStatus)&&(identical(other.aadhaarMasked, aadhaarMasked) || other.aadhaarMasked == aadhaarMasked)&&(identical(other.gstin, gstin) || other.gstin == gstin)&&(identical(other.gstStatus, gstStatus) || other.gstStatus == gstStatus)&&(identical(other.pan, pan) || other.pan == pan)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.location, location) || other.location == location)&&(identical(other.socialProofVideoUrl, socialProofVideoUrl) || other.socialProofVideoUrl == socialProofVideoUrl)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.freeAccess, freeAccess) || other.freeAccess == freeAccess)&&(identical(other.pickupLine1, pickupLine1) || other.pickupLine1 == pickupLine1)&&(identical(other.pickupLine2, pickupLine2) || other.pickupLine2 == pickupLine2)&&(identical(other.pickupCity, pickupCity) || other.pickupCity == pickupCity)&&(identical(other.pickupState, pickupState) || other.pickupState == pickupState)&&(identical(other.pickupPincode, pickupPincode) || other.pickupPincode == pickupPincode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,fullName,email,phone,bio,instagram,website,bankAccountMasked,ifsc,aadhaarStatus,aadhaarMasked,gstin,gstStatus,pan,headline,location,socialProofVideoUrl,joinedAt,freeAccess,pickupLine1,pickupLine2,pickupCity,pickupState,pickupPincode]);

@override
String toString() {
  return 'ArtistProfileDetails(fullName: $fullName, email: $email, phone: $phone, bio: $bio, instagram: $instagram, website: $website, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, aadhaarStatus: $aadhaarStatus, aadhaarMasked: $aadhaarMasked, gstin: $gstin, gstStatus: $gstStatus, pan: $pan, headline: $headline, location: $location, socialProofVideoUrl: $socialProofVideoUrl, joinedAt: $joinedAt, freeAccess: $freeAccess, pickupLine1: $pickupLine1, pickupLine2: $pickupLine2, pickupCity: $pickupCity, pickupState: $pickupState, pickupPincode: $pickupPincode)';
}


}

/// @nodoc
abstract mixin class $ArtistProfileDetailsCopyWith<$Res>  {
  factory $ArtistProfileDetailsCopyWith(ArtistProfileDetails value, $Res Function(ArtistProfileDetails) _then) = _$ArtistProfileDetailsCopyWithImpl;
@useResult
$Res call({
 String fullName, String email, String phone, String bio, String instagram, String website, String bankAccountMasked, String ifsc, ReviewStatus aadhaarStatus, String aadhaarMasked, String? gstin, ReviewStatus gstStatus, String? pan, String? headline, String? location, String? socialProofVideoUrl, String joinedAt, FreeAccess? freeAccess, String pickupLine1, String pickupLine2, String pickupCity, String pickupState, String pickupPincode
});


$FreeAccessCopyWith<$Res>? get freeAccess;

}
/// @nodoc
class _$ArtistProfileDetailsCopyWithImpl<$Res>
    implements $ArtistProfileDetailsCopyWith<$Res> {
  _$ArtistProfileDetailsCopyWithImpl(this._self, this._then);

  final ArtistProfileDetails _self;
  final $Res Function(ArtistProfileDetails) _then;

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? email = null,Object? phone = null,Object? bio = null,Object? instagram = null,Object? website = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? aadhaarStatus = null,Object? aadhaarMasked = null,Object? gstin = freezed,Object? gstStatus = null,Object? pan = freezed,Object? headline = freezed,Object? location = freezed,Object? socialProofVideoUrl = freezed,Object? joinedAt = null,Object? freeAccess = freezed,Object? pickupLine1 = null,Object? pickupLine2 = null,Object? pickupCity = null,Object? pickupState = null,Object? pickupPincode = null,}) {
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
as ReviewStatus,aadhaarMasked: null == aadhaarMasked ? _self.aadhaarMasked : aadhaarMasked // ignore: cast_nullable_to_non_nullable
as String,gstin: freezed == gstin ? _self.gstin : gstin // ignore: cast_nullable_to_non_nullable
as String?,gstStatus: null == gstStatus ? _self.gstStatus : gstStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,pan: freezed == pan ? _self.pan : pan // ignore: cast_nullable_to_non_nullable
as String?,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,socialProofVideoUrl: freezed == socialProofVideoUrl ? _self.socialProofVideoUrl : socialProofVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,freeAccess: freezed == freeAccess ? _self.freeAccess : freeAccess // ignore: cast_nullable_to_non_nullable
as FreeAccess?,pickupLine1: null == pickupLine1 ? _self.pickupLine1 : pickupLine1 // ignore: cast_nullable_to_non_nullable
as String,pickupLine2: null == pickupLine2 ? _self.pickupLine2 : pickupLine2 // ignore: cast_nullable_to_non_nullable
as String,pickupCity: null == pickupCity ? _self.pickupCity : pickupCity // ignore: cast_nullable_to_non_nullable
as String,pickupState: null == pickupState ? _self.pickupState : pickupState // ignore: cast_nullable_to_non_nullable
as String,pickupPincode: null == pickupPincode ? _self.pickupPincode : pickupPincode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeAccessCopyWith<$Res>? get freeAccess {
    if (_self.freeAccess == null) {
    return null;
  }

  return $FreeAccessCopyWith<$Res>(_self.freeAccess!, (value) {
    return _then(_self.copyWith(freeAccess: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  ReviewStatus aadhaarStatus,  String aadhaarMasked,  String? gstin,  ReviewStatus gstStatus,  String? pan,  String? headline,  String? location,  String? socialProofVideoUrl,  String joinedAt,  FreeAccess? freeAccess,  String pickupLine1,  String pickupLine2,  String pickupCity,  String pickupState,  String pickupPincode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked,_that.gstin,_that.gstStatus,_that.pan,_that.headline,_that.location,_that.socialProofVideoUrl,_that.joinedAt,_that.freeAccess,_that.pickupLine1,_that.pickupLine2,_that.pickupCity,_that.pickupState,_that.pickupPincode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  ReviewStatus aadhaarStatus,  String aadhaarMasked,  String? gstin,  ReviewStatus gstStatus,  String? pan,  String? headline,  String? location,  String? socialProofVideoUrl,  String joinedAt,  FreeAccess? freeAccess,  String pickupLine1,  String pickupLine2,  String pickupCity,  String pickupState,  String pickupPincode)  $default,) {final _that = this;
switch (_that) {
case _ArtistProfileDetails():
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked,_that.gstin,_that.gstStatus,_that.pan,_that.headline,_that.location,_that.socialProofVideoUrl,_that.joinedAt,_that.freeAccess,_that.pickupLine1,_that.pickupLine2,_that.pickupCity,_that.pickupState,_that.pickupPincode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String email,  String phone,  String bio,  String instagram,  String website,  String bankAccountMasked,  String ifsc,  ReviewStatus aadhaarStatus,  String aadhaarMasked,  String? gstin,  ReviewStatus gstStatus,  String? pan,  String? headline,  String? location,  String? socialProofVideoUrl,  String joinedAt,  FreeAccess? freeAccess,  String pickupLine1,  String pickupLine2,  String pickupCity,  String pickupState,  String pickupPincode)?  $default,) {final _that = this;
switch (_that) {
case _ArtistProfileDetails() when $default != null:
return $default(_that.fullName,_that.email,_that.phone,_that.bio,_that.instagram,_that.website,_that.bankAccountMasked,_that.ifsc,_that.aadhaarStatus,_that.aadhaarMasked,_that.gstin,_that.gstStatus,_that.pan,_that.headline,_that.location,_that.socialProofVideoUrl,_that.joinedAt,_that.freeAccess,_that.pickupLine1,_that.pickupLine2,_that.pickupCity,_that.pickupState,_that.pickupPincode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistProfileDetails extends ArtistProfileDetails {
  const _ArtistProfileDetails({required this.fullName, required this.email, required this.phone, required this.bio, required this.instagram, required this.website, required this.bankAccountMasked, required this.ifsc, required this.aadhaarStatus, required this.aadhaarMasked, this.gstin, this.gstStatus = ReviewStatus.notSubmitted, this.pan, this.headline, this.location, this.socialProofVideoUrl, this.joinedAt = '', this.freeAccess, this.pickupLine1 = '', this.pickupLine2 = '', this.pickupCity = '', this.pickupState = '', this.pickupPincode = ''}): super._();
  factory _ArtistProfileDetails.fromJson(Map<String, dynamic> json) => _$ArtistProfileDetailsFromJson(json);

@override final  String fullName;
@override final  String email;
@override final  String phone;
@override final  String bio;
@override final  String instagram;
@override final  String website;
@override final  String bankAccountMasked;
@override final  String ifsc;
@override final  ReviewStatus aadhaarStatus;
@override final  String aadhaarMasked;
/// Mandatory for an artist to go live (client, 30 Aug 2026), reviewed by
/// GalleryZone — see [gstStatus]. Validated for shape only: there is no
/// GST portal integration, which the business deliberately does not want.
@override final  String? gstin;
/// Where the GST number stands with GalleryZone's reviewers. A new or
/// changed number goes back to "submitted".
@override@JsonKey() final  ReviewStatus gstStatus;
/// PAN, kept private (admin-only; never on the public profile).
@override final  String? pan;
/// One public line of what they make, and where they work. Mirrored onto
/// the public artist page.
@override final  String? headline;
@override final  String? location;
/// A link to a short video that vouches for the work.
@override final  String? socialProofVideoUrl;
/// On GalleryZone since (ISO).
@override@JsonKey() final  String joinedAt;
/// The Early Artist Program's free period. Null once it has no meaning
/// (not an artist) or the API didn't say.
@override final  FreeAccess? freeAccess;
/// Where the courier collects. Private, and the one thing without which a
/// delivery cannot be quoted at all: shipping is priced on the distance
/// between two pincodes, and this is the origin for both the leg to an
/// aggregator and the leg to a buyer.
@override@JsonKey() final  String pickupLine1;
@override@JsonKey() final  String pickupLine2;
@override@JsonKey() final  String pickupCity;
@override@JsonKey() final  String pickupState;
@override@JsonKey() final  String pickupPincode;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistProfileDetails&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.instagram, instagram) || other.instagram == instagram)&&(identical(other.website, website) || other.website == website)&&(identical(other.bankAccountMasked, bankAccountMasked) || other.bankAccountMasked == bankAccountMasked)&&(identical(other.ifsc, ifsc) || other.ifsc == ifsc)&&(identical(other.aadhaarStatus, aadhaarStatus) || other.aadhaarStatus == aadhaarStatus)&&(identical(other.aadhaarMasked, aadhaarMasked) || other.aadhaarMasked == aadhaarMasked)&&(identical(other.gstin, gstin) || other.gstin == gstin)&&(identical(other.gstStatus, gstStatus) || other.gstStatus == gstStatus)&&(identical(other.pan, pan) || other.pan == pan)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.location, location) || other.location == location)&&(identical(other.socialProofVideoUrl, socialProofVideoUrl) || other.socialProofVideoUrl == socialProofVideoUrl)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.freeAccess, freeAccess) || other.freeAccess == freeAccess)&&(identical(other.pickupLine1, pickupLine1) || other.pickupLine1 == pickupLine1)&&(identical(other.pickupLine2, pickupLine2) || other.pickupLine2 == pickupLine2)&&(identical(other.pickupCity, pickupCity) || other.pickupCity == pickupCity)&&(identical(other.pickupState, pickupState) || other.pickupState == pickupState)&&(identical(other.pickupPincode, pickupPincode) || other.pickupPincode == pickupPincode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,fullName,email,phone,bio,instagram,website,bankAccountMasked,ifsc,aadhaarStatus,aadhaarMasked,gstin,gstStatus,pan,headline,location,socialProofVideoUrl,joinedAt,freeAccess,pickupLine1,pickupLine2,pickupCity,pickupState,pickupPincode]);

@override
String toString() {
  return 'ArtistProfileDetails(fullName: $fullName, email: $email, phone: $phone, bio: $bio, instagram: $instagram, website: $website, bankAccountMasked: $bankAccountMasked, ifsc: $ifsc, aadhaarStatus: $aadhaarStatus, aadhaarMasked: $aadhaarMasked, gstin: $gstin, gstStatus: $gstStatus, pan: $pan, headline: $headline, location: $location, socialProofVideoUrl: $socialProofVideoUrl, joinedAt: $joinedAt, freeAccess: $freeAccess, pickupLine1: $pickupLine1, pickupLine2: $pickupLine2, pickupCity: $pickupCity, pickupState: $pickupState, pickupPincode: $pickupPincode)';
}


}

/// @nodoc
abstract mixin class _$ArtistProfileDetailsCopyWith<$Res> implements $ArtistProfileDetailsCopyWith<$Res> {
  factory _$ArtistProfileDetailsCopyWith(_ArtistProfileDetails value, $Res Function(_ArtistProfileDetails) _then) = __$ArtistProfileDetailsCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String email, String phone, String bio, String instagram, String website, String bankAccountMasked, String ifsc, ReviewStatus aadhaarStatus, String aadhaarMasked, String? gstin, ReviewStatus gstStatus, String? pan, String? headline, String? location, String? socialProofVideoUrl, String joinedAt, FreeAccess? freeAccess, String pickupLine1, String pickupLine2, String pickupCity, String pickupState, String pickupPincode
});


@override $FreeAccessCopyWith<$Res>? get freeAccess;

}
/// @nodoc
class __$ArtistProfileDetailsCopyWithImpl<$Res>
    implements _$ArtistProfileDetailsCopyWith<$Res> {
  __$ArtistProfileDetailsCopyWithImpl(this._self, this._then);

  final _ArtistProfileDetails _self;
  final $Res Function(_ArtistProfileDetails) _then;

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? email = null,Object? phone = null,Object? bio = null,Object? instagram = null,Object? website = null,Object? bankAccountMasked = null,Object? ifsc = null,Object? aadhaarStatus = null,Object? aadhaarMasked = null,Object? gstin = freezed,Object? gstStatus = null,Object? pan = freezed,Object? headline = freezed,Object? location = freezed,Object? socialProofVideoUrl = freezed,Object? joinedAt = null,Object? freeAccess = freezed,Object? pickupLine1 = null,Object? pickupLine2 = null,Object? pickupCity = null,Object? pickupState = null,Object? pickupPincode = null,}) {
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
as ReviewStatus,aadhaarMasked: null == aadhaarMasked ? _self.aadhaarMasked : aadhaarMasked // ignore: cast_nullable_to_non_nullable
as String,gstin: freezed == gstin ? _self.gstin : gstin // ignore: cast_nullable_to_non_nullable
as String?,gstStatus: null == gstStatus ? _self.gstStatus : gstStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,pan: freezed == pan ? _self.pan : pan // ignore: cast_nullable_to_non_nullable
as String?,headline: freezed == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,socialProofVideoUrl: freezed == socialProofVideoUrl ? _self.socialProofVideoUrl : socialProofVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,freeAccess: freezed == freeAccess ? _self.freeAccess : freeAccess // ignore: cast_nullable_to_non_nullable
as FreeAccess?,pickupLine1: null == pickupLine1 ? _self.pickupLine1 : pickupLine1 // ignore: cast_nullable_to_non_nullable
as String,pickupLine2: null == pickupLine2 ? _self.pickupLine2 : pickupLine2 // ignore: cast_nullable_to_non_nullable
as String,pickupCity: null == pickupCity ? _self.pickupCity : pickupCity // ignore: cast_nullable_to_non_nullable
as String,pickupState: null == pickupState ? _self.pickupState : pickupState // ignore: cast_nullable_to_non_nullable
as String,pickupPincode: null == pickupPincode ? _self.pickupPincode : pickupPincode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ArtistProfileDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeAccessCopyWith<$Res>? get freeAccess {
    if (_self.freeAccess == null) {
    return null;
  }

  return $FreeAccessCopyWith<$Res>(_self.freeAccess!, (value) {
    return _then(_self.copyWith(freeAccess: value));
  });
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

 String get id; String get orderId; String get artworkTitle; String get artistName; double get artistAmount; double get aggregatorCommission; double get platformRevenue; SettlementStatus get status; String get createdAt; String? get processedAt;/// When this money becomes withdrawable — 7 days after the piece was
/// DELIVERED, not after it sold. Null until delivery, because until then
/// there is no clock running.
 String? get releaseAfter;
/// Create a copy of Settlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementCopyWith<Settlement> get copyWith => _$SettlementCopyWithImpl<Settlement>(this as Settlement, _$identity);

  /// Serializes this Settlement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Settlement&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistAmount, artistAmount) || other.artistAmount == artistAmount)&&(identical(other.aggregatorCommission, aggregatorCommission) || other.aggregatorCommission == aggregatorCommission)&&(identical(other.platformRevenue, platformRevenue) || other.platformRevenue == platformRevenue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.releaseAfter, releaseAfter) || other.releaseAfter == releaseAfter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,artworkTitle,artistName,artistAmount,aggregatorCommission,platformRevenue,status,createdAt,processedAt,releaseAfter);

@override
String toString() {
  return 'Settlement(id: $id, orderId: $orderId, artworkTitle: $artworkTitle, artistName: $artistName, artistAmount: $artistAmount, aggregatorCommission: $aggregatorCommission, platformRevenue: $platformRevenue, status: $status, createdAt: $createdAt, processedAt: $processedAt, releaseAfter: $releaseAfter)';
}


}

/// @nodoc
abstract mixin class $SettlementCopyWith<$Res>  {
  factory $SettlementCopyWith(Settlement value, $Res Function(Settlement) _then) = _$SettlementCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String artworkTitle, String artistName, double artistAmount, double aggregatorCommission, double platformRevenue, SettlementStatus status, String createdAt, String? processedAt, String? releaseAfter
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? artworkTitle = null,Object? artistName = null,Object? artistAmount = null,Object? aggregatorCommission = null,Object? platformRevenue = null,Object? status = null,Object? createdAt = null,Object? processedAt = freezed,Object? releaseAfter = freezed,}) {
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
as String?,releaseAfter: freezed == releaseAfter ? _self.releaseAfter : releaseAfter // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt,  String? releaseAfter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Settlement() when $default != null:
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt,_that.releaseAfter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt,  String? releaseAfter)  $default,) {final _that = this;
switch (_that) {
case _Settlement():
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt,_that.releaseAfter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String artworkTitle,  String artistName,  double artistAmount,  double aggregatorCommission,  double platformRevenue,  SettlementStatus status,  String createdAt,  String? processedAt,  String? releaseAfter)?  $default,) {final _that = this;
switch (_that) {
case _Settlement() when $default != null:
return $default(_that.id,_that.orderId,_that.artworkTitle,_that.artistName,_that.artistAmount,_that.aggregatorCommission,_that.platformRevenue,_that.status,_that.createdAt,_that.processedAt,_that.releaseAfter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Settlement implements Settlement {
  const _Settlement({required this.id, required this.orderId, required this.artworkTitle, required this.artistName, required this.artistAmount, required this.aggregatorCommission, required this.platformRevenue, required this.status, required this.createdAt, this.processedAt, this.releaseAfter});
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
/// When this money becomes withdrawable — 7 days after the piece was
/// DELIVERED, not after it sold. Null until delivery, because until then
/// there is no clock running.
@override final  String? releaseAfter;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Settlement&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistAmount, artistAmount) || other.artistAmount == artistAmount)&&(identical(other.aggregatorCommission, aggregatorCommission) || other.aggregatorCommission == aggregatorCommission)&&(identical(other.platformRevenue, platformRevenue) || other.platformRevenue == platformRevenue)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt)&&(identical(other.releaseAfter, releaseAfter) || other.releaseAfter == releaseAfter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,artworkTitle,artistName,artistAmount,aggregatorCommission,platformRevenue,status,createdAt,processedAt,releaseAfter);

@override
String toString() {
  return 'Settlement(id: $id, orderId: $orderId, artworkTitle: $artworkTitle, artistName: $artistName, artistAmount: $artistAmount, aggregatorCommission: $aggregatorCommission, platformRevenue: $platformRevenue, status: $status, createdAt: $createdAt, processedAt: $processedAt, releaseAfter: $releaseAfter)';
}


}

/// @nodoc
abstract mixin class _$SettlementCopyWith<$Res> implements $SettlementCopyWith<$Res> {
  factory _$SettlementCopyWith(_Settlement value, $Res Function(_Settlement) _then) = __$SettlementCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String artworkTitle, String artistName, double artistAmount, double aggregatorCommission, double platformRevenue, SettlementStatus status, String createdAt, String? processedAt, String? releaseAfter
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? artworkTitle = null,Object? artistName = null,Object? artistAmount = null,Object? aggregatorCommission = null,Object? platformRevenue = null,Object? status = null,Object? createdAt = null,Object? processedAt = freezed,Object? releaseAfter = freezed,}) {
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
as String?,releaseAfter: freezed == releaseAfter ? _self.releaseAfter : releaseAfter // ignore: cast_nullable_to_non_nullable
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
mixin _$HoldingExtensionRequest {

 ExtensionStatus get status; String get assurance; String get requestedAt; String? get decidedAt;/// GalleryZone's note with its answer, if it left one.
 String? get note;/// Where the window ended before this request.
 String get previousExpiresAt;
/// Create a copy of HoldingExtensionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HoldingExtensionRequestCopyWith<HoldingExtensionRequest> get copyWith => _$HoldingExtensionRequestCopyWithImpl<HoldingExtensionRequest>(this as HoldingExtensionRequest, _$identity);

  /// Serializes this HoldingExtensionRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HoldingExtensionRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.assurance, assurance) || other.assurance == assurance)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.previousExpiresAt, previousExpiresAt) || other.previousExpiresAt == previousExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,assurance,requestedAt,decidedAt,note,previousExpiresAt);

@override
String toString() {
  return 'HoldingExtensionRequest(status: $status, assurance: $assurance, requestedAt: $requestedAt, decidedAt: $decidedAt, note: $note, previousExpiresAt: $previousExpiresAt)';
}


}

/// @nodoc
abstract mixin class $HoldingExtensionRequestCopyWith<$Res>  {
  factory $HoldingExtensionRequestCopyWith(HoldingExtensionRequest value, $Res Function(HoldingExtensionRequest) _then) = _$HoldingExtensionRequestCopyWithImpl;
@useResult
$Res call({
 ExtensionStatus status, String assurance, String requestedAt, String? decidedAt, String? note, String previousExpiresAt
});




}
/// @nodoc
class _$HoldingExtensionRequestCopyWithImpl<$Res>
    implements $HoldingExtensionRequestCopyWith<$Res> {
  _$HoldingExtensionRequestCopyWithImpl(this._self, this._then);

  final HoldingExtensionRequest _self;
  final $Res Function(HoldingExtensionRequest) _then;

/// Create a copy of HoldingExtensionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? assurance = null,Object? requestedAt = null,Object? decidedAt = freezed,Object? note = freezed,Object? previousExpiresAt = null,}) {
  return _then(HoldingExtensionRequest(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExtensionStatus,assurance: null == assurance ? _self.assurance : assurance // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,previousExpiresAt: null == previousExpiresAt ? _self.previousExpiresAt : previousExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HoldingExtensionRequest].
extension HoldingExtensionRequestPatterns on HoldingExtensionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HoldingExtensionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HoldingExtensionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HoldingExtensionRequest value)  $default,){
final _that = this;
switch (_that) {
case _HoldingExtensionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HoldingExtensionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _HoldingExtensionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExtensionStatus status,  String assurance,  String requestedAt,  String? decidedAt,  String? note,  String previousExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HoldingExtensionRequest() when $default != null:
return $default(_that.status,_that.assurance,_that.requestedAt,_that.decidedAt,_that.note,_that.previousExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExtensionStatus status,  String assurance,  String requestedAt,  String? decidedAt,  String? note,  String previousExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _HoldingExtensionRequest():
return $default(_that.status,_that.assurance,_that.requestedAt,_that.decidedAt,_that.note,_that.previousExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExtensionStatus status,  String assurance,  String requestedAt,  String? decidedAt,  String? note,  String previousExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _HoldingExtensionRequest() when $default != null:
return $default(_that.status,_that.assurance,_that.requestedAt,_that.decidedAt,_that.note,_that.previousExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HoldingExtensionRequest implements HoldingExtensionRequest {
  const _HoldingExtensionRequest({required this.status, required this.assurance, required this.requestedAt, this.decidedAt, this.note, this.previousExpiresAt = ''});
  factory _HoldingExtensionRequest.fromJson(Map<String, dynamic> json) => _$HoldingExtensionRequestFromJson(json);

@override final  ExtensionStatus status;
@override final  String assurance;
@override final  String requestedAt;
@override final  String? decidedAt;
/// GalleryZone's note with its answer, if it left one.
@override final  String? note;
/// Where the window ended before this request.
@override@JsonKey() final  String previousExpiresAt;

/// Create a copy of HoldingExtensionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HoldingExtensionRequestCopyWith<_HoldingExtensionRequest> get copyWith => __$HoldingExtensionRequestCopyWithImpl<_HoldingExtensionRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HoldingExtensionRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HoldingExtensionRequest&&(identical(other.status, status) || other.status == status)&&(identical(other.assurance, assurance) || other.assurance == assurance)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.previousExpiresAt, previousExpiresAt) || other.previousExpiresAt == previousExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,assurance,requestedAt,decidedAt,note,previousExpiresAt);

@override
String toString() {
  return 'HoldingExtensionRequest(status: $status, assurance: $assurance, requestedAt: $requestedAt, decidedAt: $decidedAt, note: $note, previousExpiresAt: $previousExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$HoldingExtensionRequestCopyWith<$Res> implements $HoldingExtensionRequestCopyWith<$Res> {
  factory _$HoldingExtensionRequestCopyWith(_HoldingExtensionRequest value, $Res Function(_HoldingExtensionRequest) _then) = __$HoldingExtensionRequestCopyWithImpl;
@override @useResult
$Res call({
 ExtensionStatus status, String assurance, String requestedAt, String? decidedAt, String? note, String previousExpiresAt
});




}
/// @nodoc
class __$HoldingExtensionRequestCopyWithImpl<$Res>
    implements _$HoldingExtensionRequestCopyWith<$Res> {
  __$HoldingExtensionRequestCopyWithImpl(this._self, this._then);

  final _HoldingExtensionRequest _self;
  final $Res Function(_HoldingExtensionRequest) _then;

/// Create a copy of HoldingExtensionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? assurance = null,Object? requestedAt = null,Object? decidedAt = freezed,Object? note = freezed,Object? previousExpiresAt = null,}) {
  return _then(_HoldingExtensionRequest(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExtensionStatus,assurance: null == assurance ? _self.assurance : assurance // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,previousExpiresAt: null == previousExpiresAt ? _self.previousExpiresAt : previousExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AggregatorHolding {

 String get id; String get artworkId;/// 5% in month one, 3% from month two onwards — see `core/pricing.dart`.
 int get advancePercent; double get advanceAmount; double get displayPrice; String get assignedAt; String get expiresAt; HoldingStatus get status; AssignmentSource get assignmentSource;/// Paid with the advance before taking possession (MOU §7). The
/// money-flow sheet returns it only if the piece sells — an unsold piece
/// going back to GalleryZone refunds the advance alone.
 double get deliveryDeposit;/// Which month of the artwork's five-month aggregator cycle this
/// placement is. A piece that doesn't sell moves to a DIFFERENT
/// aggregator each month, at a lower price and a different advance rate,
/// so the month is a property of the artwork's journey rather than of any
/// one aggregator. Seeded holdings predate the field; 1 is the default.
 int get cycleMonth;/// Aggregator MOU §6: the aggregator gets ONE opportunity to set the
/// selling price. Stamped the first time they set it; after that the
/// price is locked.
 String? get displayPriceSetAt;/// Set when the piece went back to GalleryZone unsold.
 String? get returnedAt;/// True when this placement runs past the usual thirty days because what
/// would have been left of the artist's 180 days was too short to hand to
/// anyone else. The last aggregator keeps it rather than the piece making
/// one more journey for a fortnight.
 bool get windowExtended;/// Month 1: the aggregator priced above GalleryZone's offer, which starts
/// the next aggregator's monthly drops a month later.
 bool get appreciated;/// Priced far enough above the offer that GalleryZone was warned. It never
/// blocks the reservation.
 bool get priceWarning;/// The latest request to keep the piece past its window, and GalleryZone's
/// answer.
 HoldingExtensionRequest? get extensionRequest;
/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AggregatorHoldingCopyWith<AggregatorHolding> get copyWith => _$AggregatorHoldingCopyWithImpl<AggregatorHolding>(this as AggregatorHolding, _$identity);

  /// Serializes this AggregatorHolding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AggregatorHolding&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.advancePercent, advancePercent) || other.advancePercent == advancePercent)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.displayPrice, displayPrice) || other.displayPrice == displayPrice)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignmentSource, assignmentSource) || other.assignmentSource == assignmentSource)&&(identical(other.deliveryDeposit, deliveryDeposit) || other.deliveryDeposit == deliveryDeposit)&&(identical(other.cycleMonth, cycleMonth) || other.cycleMonth == cycleMonth)&&(identical(other.displayPriceSetAt, displayPriceSetAt) || other.displayPriceSetAt == displayPriceSetAt)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.windowExtended, windowExtended) || other.windowExtended == windowExtended)&&(identical(other.appreciated, appreciated) || other.appreciated == appreciated)&&(identical(other.priceWarning, priceWarning) || other.priceWarning == priceWarning)&&(identical(other.extensionRequest, extensionRequest) || other.extensionRequest == extensionRequest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,advancePercent,advanceAmount,displayPrice,assignedAt,expiresAt,status,assignmentSource,deliveryDeposit,cycleMonth,displayPriceSetAt,returnedAt,windowExtended,appreciated,priceWarning,extensionRequest);

@override
String toString() {
  return 'AggregatorHolding(id: $id, artworkId: $artworkId, advancePercent: $advancePercent, advanceAmount: $advanceAmount, displayPrice: $displayPrice, assignedAt: $assignedAt, expiresAt: $expiresAt, status: $status, assignmentSource: $assignmentSource, deliveryDeposit: $deliveryDeposit, cycleMonth: $cycleMonth, displayPriceSetAt: $displayPriceSetAt, returnedAt: $returnedAt, windowExtended: $windowExtended, appreciated: $appreciated, priceWarning: $priceWarning, extensionRequest: $extensionRequest)';
}


}

/// @nodoc
abstract mixin class $AggregatorHoldingCopyWith<$Res>  {
  factory $AggregatorHoldingCopyWith(AggregatorHolding value, $Res Function(AggregatorHolding) _then) = _$AggregatorHoldingCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, int advancePercent, double advanceAmount, double displayPrice, String assignedAt, String expiresAt, HoldingStatus status, AssignmentSource assignmentSource, double deliveryDeposit, int cycleMonth, String? displayPriceSetAt, String? returnedAt, bool windowExtended, bool appreciated, bool priceWarning, HoldingExtensionRequest? extensionRequest
});


$HoldingExtensionRequestCopyWith<$Res>? get extensionRequest;

}
/// @nodoc
class _$AggregatorHoldingCopyWithImpl<$Res>
    implements $AggregatorHoldingCopyWith<$Res> {
  _$AggregatorHoldingCopyWithImpl(this._self, this._then);

  final AggregatorHolding _self;
  final $Res Function(AggregatorHolding) _then;

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? advancePercent = null,Object? advanceAmount = null,Object? displayPrice = null,Object? assignedAt = null,Object? expiresAt = null,Object? status = null,Object? assignmentSource = null,Object? deliveryDeposit = null,Object? cycleMonth = null,Object? displayPriceSetAt = freezed,Object? returnedAt = freezed,Object? windowExtended = null,Object? appreciated = null,Object? priceWarning = null,Object? extensionRequest = freezed,}) {
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
as AssignmentSource,deliveryDeposit: null == deliveryDeposit ? _self.deliveryDeposit : deliveryDeposit // ignore: cast_nullable_to_non_nullable
as double,cycleMonth: null == cycleMonth ? _self.cycleMonth : cycleMonth // ignore: cast_nullable_to_non_nullable
as int,displayPriceSetAt: freezed == displayPriceSetAt ? _self.displayPriceSetAt : displayPriceSetAt // ignore: cast_nullable_to_non_nullable
as String?,returnedAt: freezed == returnedAt ? _self.returnedAt : returnedAt // ignore: cast_nullable_to_non_nullable
as String?,windowExtended: null == windowExtended ? _self.windowExtended : windowExtended // ignore: cast_nullable_to_non_nullable
as bool,appreciated: null == appreciated ? _self.appreciated : appreciated // ignore: cast_nullable_to_non_nullable
as bool,priceWarning: null == priceWarning ? _self.priceWarning : priceWarning // ignore: cast_nullable_to_non_nullable
as bool,extensionRequest: freezed == extensionRequest ? _self.extensionRequest : extensionRequest // ignore: cast_nullable_to_non_nullable
as HoldingExtensionRequest?,
  ));
}
/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HoldingExtensionRequestCopyWith<$Res>? get extensionRequest {
    if (_self.extensionRequest == null) {
    return null;
  }

  return $HoldingExtensionRequestCopyWith<$Res>(_self.extensionRequest!, (value) {
    return _then(_self.copyWith(extensionRequest: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource,  double deliveryDeposit,  int cycleMonth,  String? displayPriceSetAt,  String? returnedAt,  bool windowExtended,  bool appreciated,  bool priceWarning,  HoldingExtensionRequest? extensionRequest)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource,_that.deliveryDeposit,_that.cycleMonth,_that.displayPriceSetAt,_that.returnedAt,_that.windowExtended,_that.appreciated,_that.priceWarning,_that.extensionRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource,  double deliveryDeposit,  int cycleMonth,  String? displayPriceSetAt,  String? returnedAt,  bool windowExtended,  bool appreciated,  bool priceWarning,  HoldingExtensionRequest? extensionRequest)  $default,) {final _that = this;
switch (_that) {
case _AggregatorHolding():
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource,_that.deliveryDeposit,_that.cycleMonth,_that.displayPriceSetAt,_that.returnedAt,_that.windowExtended,_that.appreciated,_that.priceWarning,_that.extensionRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  int advancePercent,  double advanceAmount,  double displayPrice,  String assignedAt,  String expiresAt,  HoldingStatus status,  AssignmentSource assignmentSource,  double deliveryDeposit,  int cycleMonth,  String? displayPriceSetAt,  String? returnedAt,  bool windowExtended,  bool appreciated,  bool priceWarning,  HoldingExtensionRequest? extensionRequest)?  $default,) {final _that = this;
switch (_that) {
case _AggregatorHolding() when $default != null:
return $default(_that.id,_that.artworkId,_that.advancePercent,_that.advanceAmount,_that.displayPrice,_that.assignedAt,_that.expiresAt,_that.status,_that.assignmentSource,_that.deliveryDeposit,_that.cycleMonth,_that.displayPriceSetAt,_that.returnedAt,_that.windowExtended,_that.appreciated,_that.priceWarning,_that.extensionRequest);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AggregatorHolding implements AggregatorHolding {
  const _AggregatorHolding({required this.id, required this.artworkId, required this.advancePercent, required this.advanceAmount, required this.displayPrice, required this.assignedAt, required this.expiresAt, required this.status, required this.assignmentSource, this.deliveryDeposit = 0.0, this.cycleMonth = 1, this.displayPriceSetAt, this.returnedAt, this.windowExtended = false, this.appreciated = false, this.priceWarning = false, this.extensionRequest});
  factory _AggregatorHolding.fromJson(Map<String, dynamic> json) => _$AggregatorHoldingFromJson(json);

@override final  String id;
@override final  String artworkId;
/// 5% in month one, 3% from month two onwards — see `core/pricing.dart`.
@override final  int advancePercent;
@override final  double advanceAmount;
@override final  double displayPrice;
@override final  String assignedAt;
@override final  String expiresAt;
@override final  HoldingStatus status;
@override final  AssignmentSource assignmentSource;
/// Paid with the advance before taking possession (MOU §7). The
/// money-flow sheet returns it only if the piece sells — an unsold piece
/// going back to GalleryZone refunds the advance alone.
@override@JsonKey() final  double deliveryDeposit;
/// Which month of the artwork's five-month aggregator cycle this
/// placement is. A piece that doesn't sell moves to a DIFFERENT
/// aggregator each month, at a lower price and a different advance rate,
/// so the month is a property of the artwork's journey rather than of any
/// one aggregator. Seeded holdings predate the field; 1 is the default.
@override@JsonKey() final  int cycleMonth;
/// Aggregator MOU §6: the aggregator gets ONE opportunity to set the
/// selling price. Stamped the first time they set it; after that the
/// price is locked.
@override final  String? displayPriceSetAt;
/// Set when the piece went back to GalleryZone unsold.
@override final  String? returnedAt;
/// True when this placement runs past the usual thirty days because what
/// would have been left of the artist's 180 days was too short to hand to
/// anyone else. The last aggregator keeps it rather than the piece making
/// one more journey for a fortnight.
@override@JsonKey() final  bool windowExtended;
/// Month 1: the aggregator priced above GalleryZone's offer, which starts
/// the next aggregator's monthly drops a month later.
@override@JsonKey() final  bool appreciated;
/// Priced far enough above the offer that GalleryZone was warned. It never
/// blocks the reservation.
@override@JsonKey() final  bool priceWarning;
/// The latest request to keep the piece past its window, and GalleryZone's
/// answer.
@override final  HoldingExtensionRequest? extensionRequest;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AggregatorHolding&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.advancePercent, advancePercent) || other.advancePercent == advancePercent)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.displayPrice, displayPrice) || other.displayPrice == displayPrice)&&(identical(other.assignedAt, assignedAt) || other.assignedAt == assignedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignmentSource, assignmentSource) || other.assignmentSource == assignmentSource)&&(identical(other.deliveryDeposit, deliveryDeposit) || other.deliveryDeposit == deliveryDeposit)&&(identical(other.cycleMonth, cycleMonth) || other.cycleMonth == cycleMonth)&&(identical(other.displayPriceSetAt, displayPriceSetAt) || other.displayPriceSetAt == displayPriceSetAt)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.windowExtended, windowExtended) || other.windowExtended == windowExtended)&&(identical(other.appreciated, appreciated) || other.appreciated == appreciated)&&(identical(other.priceWarning, priceWarning) || other.priceWarning == priceWarning)&&(identical(other.extensionRequest, extensionRequest) || other.extensionRequest == extensionRequest));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,advancePercent,advanceAmount,displayPrice,assignedAt,expiresAt,status,assignmentSource,deliveryDeposit,cycleMonth,displayPriceSetAt,returnedAt,windowExtended,appreciated,priceWarning,extensionRequest);

@override
String toString() {
  return 'AggregatorHolding(id: $id, artworkId: $artworkId, advancePercent: $advancePercent, advanceAmount: $advanceAmount, displayPrice: $displayPrice, assignedAt: $assignedAt, expiresAt: $expiresAt, status: $status, assignmentSource: $assignmentSource, deliveryDeposit: $deliveryDeposit, cycleMonth: $cycleMonth, displayPriceSetAt: $displayPriceSetAt, returnedAt: $returnedAt, windowExtended: $windowExtended, appreciated: $appreciated, priceWarning: $priceWarning, extensionRequest: $extensionRequest)';
}


}

/// @nodoc
abstract mixin class _$AggregatorHoldingCopyWith<$Res> implements $AggregatorHoldingCopyWith<$Res> {
  factory _$AggregatorHoldingCopyWith(_AggregatorHolding value, $Res Function(_AggregatorHolding) _then) = __$AggregatorHoldingCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, int advancePercent, double advanceAmount, double displayPrice, String assignedAt, String expiresAt, HoldingStatus status, AssignmentSource assignmentSource, double deliveryDeposit, int cycleMonth, String? displayPriceSetAt, String? returnedAt, bool windowExtended, bool appreciated, bool priceWarning, HoldingExtensionRequest? extensionRequest
});


@override $HoldingExtensionRequestCopyWith<$Res>? get extensionRequest;

}
/// @nodoc
class __$AggregatorHoldingCopyWithImpl<$Res>
    implements _$AggregatorHoldingCopyWith<$Res> {
  __$AggregatorHoldingCopyWithImpl(this._self, this._then);

  final _AggregatorHolding _self;
  final $Res Function(_AggregatorHolding) _then;

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? advancePercent = null,Object? advanceAmount = null,Object? displayPrice = null,Object? assignedAt = null,Object? expiresAt = null,Object? status = null,Object? assignmentSource = null,Object? deliveryDeposit = null,Object? cycleMonth = null,Object? displayPriceSetAt = freezed,Object? returnedAt = freezed,Object? windowExtended = null,Object? appreciated = null,Object? priceWarning = null,Object? extensionRequest = freezed,}) {
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
as AssignmentSource,deliveryDeposit: null == deliveryDeposit ? _self.deliveryDeposit : deliveryDeposit // ignore: cast_nullable_to_non_nullable
as double,cycleMonth: null == cycleMonth ? _self.cycleMonth : cycleMonth // ignore: cast_nullable_to_non_nullable
as int,displayPriceSetAt: freezed == displayPriceSetAt ? _self.displayPriceSetAt : displayPriceSetAt // ignore: cast_nullable_to_non_nullable
as String?,returnedAt: freezed == returnedAt ? _self.returnedAt : returnedAt // ignore: cast_nullable_to_non_nullable
as String?,windowExtended: null == windowExtended ? _self.windowExtended : windowExtended // ignore: cast_nullable_to_non_nullable
as bool,appreciated: null == appreciated ? _self.appreciated : appreciated // ignore: cast_nullable_to_non_nullable
as bool,priceWarning: null == priceWarning ? _self.priceWarning : priceWarning // ignore: cast_nullable_to_non_nullable
as bool,extensionRequest: freezed == extensionRequest ? _self.extensionRequest : extensionRequest // ignore: cast_nullable_to_non_nullable
as HoldingExtensionRequest?,
  ));
}

/// Create a copy of AggregatorHolding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HoldingExtensionRequestCopyWith<$Res>? get extensionRequest {
    if (_self.extensionRequest == null) {
    return null;
  }

  return $HoldingExtensionRequestCopyWith<$Res>(_self.extensionRequest!, (value) {
    return _then(_self.copyWith(extensionRequest: value));
  });
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
