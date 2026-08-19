// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistVerificationState {

 bool get tier1SocialMedia; bool get tier2ActivePlan; bool get tier3FirstSale;
/// Create a copy of ArtistVerificationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistVerificationStateCopyWith<ArtistVerificationState> get copyWith => _$ArtistVerificationStateCopyWithImpl<ArtistVerificationState>(this as ArtistVerificationState, _$identity);

  /// Serializes this ArtistVerificationState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistVerificationState&&(identical(other.tier1SocialMedia, tier1SocialMedia) || other.tier1SocialMedia == tier1SocialMedia)&&(identical(other.tier2ActivePlan, tier2ActivePlan) || other.tier2ActivePlan == tier2ActivePlan)&&(identical(other.tier3FirstSale, tier3FirstSale) || other.tier3FirstSale == tier3FirstSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier1SocialMedia,tier2ActivePlan,tier3FirstSale);

@override
String toString() {
  return 'ArtistVerificationState(tier1SocialMedia: $tier1SocialMedia, tier2ActivePlan: $tier2ActivePlan, tier3FirstSale: $tier3FirstSale)';
}


}

/// @nodoc
abstract mixin class $ArtistVerificationStateCopyWith<$Res>  {
  factory $ArtistVerificationStateCopyWith(ArtistVerificationState value, $Res Function(ArtistVerificationState) _then) = _$ArtistVerificationStateCopyWithImpl;
@useResult
$Res call({
 bool tier1SocialMedia, bool tier2ActivePlan, bool tier3FirstSale
});




}
/// @nodoc
class _$ArtistVerificationStateCopyWithImpl<$Res>
    implements $ArtistVerificationStateCopyWith<$Res> {
  _$ArtistVerificationStateCopyWithImpl(this._self, this._then);

  final ArtistVerificationState _self;
  final $Res Function(ArtistVerificationState) _then;

/// Create a copy of ArtistVerificationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier1SocialMedia = null,Object? tier2ActivePlan = null,Object? tier3FirstSale = null,}) {
  return _then(ArtistVerificationState(
tier1SocialMedia: null == tier1SocialMedia ? _self.tier1SocialMedia : tier1SocialMedia // ignore: cast_nullable_to_non_nullable
as bool,tier2ActivePlan: null == tier2ActivePlan ? _self.tier2ActivePlan : tier2ActivePlan // ignore: cast_nullable_to_non_nullable
as bool,tier3FirstSale: null == tier3FirstSale ? _self.tier3FirstSale : tier3FirstSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistVerificationState].
extension ArtistVerificationStatePatterns on ArtistVerificationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistVerificationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistVerificationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistVerificationState value)  $default,){
final _that = this;
switch (_that) {
case _ArtistVerificationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistVerificationState value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistVerificationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool tier1SocialMedia,  bool tier2ActivePlan,  bool tier3FirstSale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistVerificationState() when $default != null:
return $default(_that.tier1SocialMedia,_that.tier2ActivePlan,_that.tier3FirstSale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool tier1SocialMedia,  bool tier2ActivePlan,  bool tier3FirstSale)  $default,) {final _that = this;
switch (_that) {
case _ArtistVerificationState():
return $default(_that.tier1SocialMedia,_that.tier2ActivePlan,_that.tier3FirstSale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool tier1SocialMedia,  bool tier2ActivePlan,  bool tier3FirstSale)?  $default,) {final _that = this;
switch (_that) {
case _ArtistVerificationState() when $default != null:
return $default(_that.tier1SocialMedia,_that.tier2ActivePlan,_that.tier3FirstSale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistVerificationState implements ArtistVerificationState {
  const _ArtistVerificationState({required this.tier1SocialMedia, required this.tier2ActivePlan, required this.tier3FirstSale});
  factory _ArtistVerificationState.fromJson(Map<String, dynamic> json) => _$ArtistVerificationStateFromJson(json);

@override final  bool tier1SocialMedia;
@override final  bool tier2ActivePlan;
@override final  bool tier3FirstSale;

/// Create a copy of ArtistVerificationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistVerificationStateCopyWith<_ArtistVerificationState> get copyWith => __$ArtistVerificationStateCopyWithImpl<_ArtistVerificationState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistVerificationStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistVerificationState&&(identical(other.tier1SocialMedia, tier1SocialMedia) || other.tier1SocialMedia == tier1SocialMedia)&&(identical(other.tier2ActivePlan, tier2ActivePlan) || other.tier2ActivePlan == tier2ActivePlan)&&(identical(other.tier3FirstSale, tier3FirstSale) || other.tier3FirstSale == tier3FirstSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier1SocialMedia,tier2ActivePlan,tier3FirstSale);

@override
String toString() {
  return 'ArtistVerificationState(tier1SocialMedia: $tier1SocialMedia, tier2ActivePlan: $tier2ActivePlan, tier3FirstSale: $tier3FirstSale)';
}


}

/// @nodoc
abstract mixin class _$ArtistVerificationStateCopyWith<$Res> implements $ArtistVerificationStateCopyWith<$Res> {
  factory _$ArtistVerificationStateCopyWith(_ArtistVerificationState value, $Res Function(_ArtistVerificationState) _then) = __$ArtistVerificationStateCopyWithImpl;
@override @useResult
$Res call({
 bool tier1SocialMedia, bool tier2ActivePlan, bool tier3FirstSale
});




}
/// @nodoc
class __$ArtistVerificationStateCopyWithImpl<$Res>
    implements _$ArtistVerificationStateCopyWith<$Res> {
  __$ArtistVerificationStateCopyWithImpl(this._self, this._then);

  final _ArtistVerificationState _self;
  final $Res Function(_ArtistVerificationState) _then;

/// Create a copy of ArtistVerificationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier1SocialMedia = null,Object? tier2ActivePlan = null,Object? tier3FirstSale = null,}) {
  return _then(_ArtistVerificationState(
tier1SocialMedia: null == tier1SocialMedia ? _self.tier1SocialMedia : tier1SocialMedia // ignore: cast_nullable_to_non_nullable
as bool,tier2ActivePlan: null == tier2ActivePlan ? _self.tier2ActivePlan : tier2ActivePlan // ignore: cast_nullable_to_non_nullable
as bool,tier3FirstSale: null == tier3FirstSale ? _self.tier3FirstSale : tier3FirstSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ArtistProfile {

 String get id; String get name; String get bio; String get profileImageUrl; ArtistVerificationState get verification; List<SocialProofLink> get socialLinks;
/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistProfileCopyWith<ArtistProfile> get copyWith => _$ArtistProfileCopyWithImpl<ArtistProfile>(this as ArtistProfile, _$identity);

  /// Serializes this ArtistProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.verification, verification) || other.verification == verification)&&const DeepCollectionEquality().equals(other.socialLinks, socialLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,bio,profileImageUrl,verification,const DeepCollectionEquality().hash(socialLinks));

@override
String toString() {
  return 'ArtistProfile(id: $id, name: $name, bio: $bio, profileImageUrl: $profileImageUrl, verification: $verification, socialLinks: $socialLinks)';
}


}

/// @nodoc
abstract mixin class $ArtistProfileCopyWith<$Res>  {
  factory $ArtistProfileCopyWith(ArtistProfile value, $Res Function(ArtistProfile) _then) = _$ArtistProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String bio, String profileImageUrl, ArtistVerificationState verification, List<SocialProofLink> socialLinks
});


$ArtistVerificationStateCopyWith<$Res> get verification;

}
/// @nodoc
class _$ArtistProfileCopyWithImpl<$Res>
    implements $ArtistProfileCopyWith<$Res> {
  _$ArtistProfileCopyWithImpl(this._self, this._then);

  final ArtistProfile _self;
  final $Res Function(ArtistProfile) _then;

/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? bio = null,Object? profileImageUrl = null,Object? verification = null,Object? socialLinks = null,}) {
  return _then(ArtistProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: null == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String,verification: null == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as ArtistVerificationState,socialLinks: null == socialLinks ? _self.socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<SocialProofLink>,
  ));
}
/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistVerificationStateCopyWith<$Res> get verification {
  
  return $ArtistVerificationStateCopyWith<$Res>(_self.verification, (value) {
    return _then(_self.copyWith(verification: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistProfile].
extension ArtistProfilePatterns on ArtistProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistProfile value)  $default,){
final _that = this;
switch (_that) {
case _ArtistProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String bio,  String profileImageUrl,  ArtistVerificationState verification,  List<SocialProofLink> socialLinks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistProfile() when $default != null:
return $default(_that.id,_that.name,_that.bio,_that.profileImageUrl,_that.verification,_that.socialLinks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String bio,  String profileImageUrl,  ArtistVerificationState verification,  List<SocialProofLink> socialLinks)  $default,) {final _that = this;
switch (_that) {
case _ArtistProfile():
return $default(_that.id,_that.name,_that.bio,_that.profileImageUrl,_that.verification,_that.socialLinks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String bio,  String profileImageUrl,  ArtistVerificationState verification,  List<SocialProofLink> socialLinks)?  $default,) {final _that = this;
switch (_that) {
case _ArtistProfile() when $default != null:
return $default(_that.id,_that.name,_that.bio,_that.profileImageUrl,_that.verification,_that.socialLinks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistProfile implements ArtistProfile {
  const _ArtistProfile({required this.id, required this.name, required this.bio, required this.profileImageUrl, required this.verification, required  List<SocialProofLink> socialLinks}): _socialLinks = socialLinks;
  factory _ArtistProfile.fromJson(Map<String, dynamic> json) => _$ArtistProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  String bio;
@override final  String profileImageUrl;
@override final  ArtistVerificationState verification;
 final  List<SocialProofLink> _socialLinks;
@override List<SocialProofLink> get socialLinks {
  if (_socialLinks is EqualUnmodifiableListView) return _socialLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialLinks);
}


/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistProfileCopyWith<_ArtistProfile> get copyWith => __$ArtistProfileCopyWithImpl<_ArtistProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.verification, verification) || other.verification == verification)&&const DeepCollectionEquality().equals(other._socialLinks, _socialLinks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,bio,profileImageUrl,verification,const DeepCollectionEquality().hash(_socialLinks));

@override
String toString() {
  return 'ArtistProfile(id: $id, name: $name, bio: $bio, profileImageUrl: $profileImageUrl, verification: $verification, socialLinks: $socialLinks)';
}


}

/// @nodoc
abstract mixin class _$ArtistProfileCopyWith<$Res> implements $ArtistProfileCopyWith<$Res> {
  factory _$ArtistProfileCopyWith(_ArtistProfile value, $Res Function(_ArtistProfile) _then) = __$ArtistProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String bio, String profileImageUrl, ArtistVerificationState verification, List<SocialProofLink> socialLinks
});


@override $ArtistVerificationStateCopyWith<$Res> get verification;

}
/// @nodoc
class __$ArtistProfileCopyWithImpl<$Res>
    implements _$ArtistProfileCopyWith<$Res> {
  __$ArtistProfileCopyWithImpl(this._self, this._then);

  final _ArtistProfile _self;
  final $Res Function(_ArtistProfile) _then;

/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? bio = null,Object? profileImageUrl = null,Object? verification = null,Object? socialLinks = null,}) {
  return _then(_ArtistProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,profileImageUrl: null == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String,verification: null == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as ArtistVerificationState,socialLinks: null == socialLinks ? _self._socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as List<SocialProofLink>,
  ));
}

/// Create a copy of ArtistProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistVerificationStateCopyWith<$Res> get verification {
  
  return $ArtistVerificationStateCopyWith<$Res>(_self.verification, (value) {
    return _then(_self.copyWith(verification: value));
  });
}
}

// dart format on
