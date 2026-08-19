// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artwork.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtworkImage {

 String get url; String get thumbnailUrl; int get sortOrder; String get altText;
/// Create a copy of ArtworkImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkImageCopyWith<ArtworkImage> get copyWith => _$ArtworkImageCopyWithImpl<ArtworkImage>(this as ArtworkImage, _$identity);

  /// Serializes this ArtworkImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtworkImage&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.altText, altText) || other.altText == altText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,thumbnailUrl,sortOrder,altText);

@override
String toString() {
  return 'ArtworkImage(url: $url, thumbnailUrl: $thumbnailUrl, sortOrder: $sortOrder, altText: $altText)';
}


}

/// @nodoc
abstract mixin class $ArtworkImageCopyWith<$Res>  {
  factory $ArtworkImageCopyWith(ArtworkImage value, $Res Function(ArtworkImage) _then) = _$ArtworkImageCopyWithImpl;
@useResult
$Res call({
 String url, String thumbnailUrl, int sortOrder, String altText
});




}
/// @nodoc
class _$ArtworkImageCopyWithImpl<$Res>
    implements $ArtworkImageCopyWith<$Res> {
  _$ArtworkImageCopyWithImpl(this._self, this._then);

  final ArtworkImage _self;
  final $Res Function(ArtworkImage) _then;

/// Create a copy of ArtworkImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? thumbnailUrl = null,Object? sortOrder = null,Object? altText = null,}) {
  return _then(ArtworkImage(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtworkImage].
extension ArtworkImagePatterns on ArtworkImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtworkImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtworkImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtworkImage value)  $default,){
final _that = this;
switch (_that) {
case _ArtworkImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtworkImage value)?  $default,){
final _that = this;
switch (_that) {
case _ArtworkImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String thumbnailUrl,  int sortOrder,  String altText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtworkImage() when $default != null:
return $default(_that.url,_that.thumbnailUrl,_that.sortOrder,_that.altText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String thumbnailUrl,  int sortOrder,  String altText)  $default,) {final _that = this;
switch (_that) {
case _ArtworkImage():
return $default(_that.url,_that.thumbnailUrl,_that.sortOrder,_that.altText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String thumbnailUrl,  int sortOrder,  String altText)?  $default,) {final _that = this;
switch (_that) {
case _ArtworkImage() when $default != null:
return $default(_that.url,_that.thumbnailUrl,_that.sortOrder,_that.altText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtworkImage implements ArtworkImage {
  const _ArtworkImage({required this.url, required this.thumbnailUrl, required this.sortOrder, required this.altText});
  factory _ArtworkImage.fromJson(Map<String, dynamic> json) => _$ArtworkImageFromJson(json);

@override final  String url;
@override final  String thumbnailUrl;
@override final  int sortOrder;
@override final  String altText;

/// Create a copy of ArtworkImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkImageCopyWith<_ArtworkImage> get copyWith => __$ArtworkImageCopyWithImpl<_ArtworkImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtworkImage&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.altText, altText) || other.altText == altText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,thumbnailUrl,sortOrder,altText);

@override
String toString() {
  return 'ArtworkImage(url: $url, thumbnailUrl: $thumbnailUrl, sortOrder: $sortOrder, altText: $altText)';
}


}

/// @nodoc
abstract mixin class _$ArtworkImageCopyWith<$Res> implements $ArtworkImageCopyWith<$Res> {
  factory _$ArtworkImageCopyWith(_ArtworkImage value, $Res Function(_ArtworkImage) _then) = __$ArtworkImageCopyWithImpl;
@override @useResult
$Res call({
 String url, String thumbnailUrl, int sortOrder, String altText
});




}
/// @nodoc
class __$ArtworkImageCopyWithImpl<$Res>
    implements _$ArtworkImageCopyWith<$Res> {
  __$ArtworkImageCopyWithImpl(this._self, this._then);

  final _ArtworkImage _self;
  final $Res Function(_ArtworkImage) _then;

/// Create a copy of ArtworkImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? thumbnailUrl = null,Object? sortOrder = null,Object? altText = null,}) {
  return _then(_ArtworkImage(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,altText: null == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SocialProofLink {

 SocialProofPlatform get platform; String get url;
/// Create a copy of SocialProofLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialProofLinkCopyWith<SocialProofLink> get copyWith => _$SocialProofLinkCopyWithImpl<SocialProofLink>(this as SocialProofLink, _$identity);

  /// Serializes this SocialProofLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialProofLink&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,url);

@override
String toString() {
  return 'SocialProofLink(platform: $platform, url: $url)';
}


}

/// @nodoc
abstract mixin class $SocialProofLinkCopyWith<$Res>  {
  factory $SocialProofLinkCopyWith(SocialProofLink value, $Res Function(SocialProofLink) _then) = _$SocialProofLinkCopyWithImpl;
@useResult
$Res call({
 SocialProofPlatform platform, String url
});




}
/// @nodoc
class _$SocialProofLinkCopyWithImpl<$Res>
    implements $SocialProofLinkCopyWith<$Res> {
  _$SocialProofLinkCopyWithImpl(this._self, this._then);

  final SocialProofLink _self;
  final $Res Function(SocialProofLink) _then;

/// Create a copy of SocialProofLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? url = null,}) {
  return _then(SocialProofLink(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SocialProofPlatform,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialProofLink].
extension SocialProofLinkPatterns on SocialProofLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialProofLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialProofLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialProofLink value)  $default,){
final _that = this;
switch (_that) {
case _SocialProofLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialProofLink value)?  $default,){
final _that = this;
switch (_that) {
case _SocialProofLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SocialProofPlatform platform,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialProofLink() when $default != null:
return $default(_that.platform,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SocialProofPlatform platform,  String url)  $default,) {final _that = this;
switch (_that) {
case _SocialProofLink():
return $default(_that.platform,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SocialProofPlatform platform,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SocialProofLink() when $default != null:
return $default(_that.platform,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialProofLink implements SocialProofLink {
  const _SocialProofLink({required this.platform, required this.url});
  factory _SocialProofLink.fromJson(Map<String, dynamic> json) => _$SocialProofLinkFromJson(json);

@override final  SocialProofPlatform platform;
@override final  String url;

/// Create a copy of SocialProofLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialProofLinkCopyWith<_SocialProofLink> get copyWith => __$SocialProofLinkCopyWithImpl<_SocialProofLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialProofLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialProofLink&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,url);

@override
String toString() {
  return 'SocialProofLink(platform: $platform, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SocialProofLinkCopyWith<$Res> implements $SocialProofLinkCopyWith<$Res> {
  factory _$SocialProofLinkCopyWith(_SocialProofLink value, $Res Function(_SocialProofLink) _then) = __$SocialProofLinkCopyWithImpl;
@override @useResult
$Res call({
 SocialProofPlatform platform, String url
});




}
/// @nodoc
class __$SocialProofLinkCopyWithImpl<$Res>
    implements _$SocialProofLinkCopyWith<$Res> {
  __$SocialProofLinkCopyWithImpl(this._self, this._then);

  final _SocialProofLink _self;
  final $Res Function(_SocialProofLink) _then;

/// Create a copy of SocialProofLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? url = null,}) {
  return _then(_SocialProofLink(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SocialProofPlatform,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ArtworkStatusEvent {

 ArtworkStatus get status; String get changedAt;
/// Create a copy of ArtworkStatusEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkStatusEventCopyWith<ArtworkStatusEvent> get copyWith => _$ArtworkStatusEventCopyWithImpl<ArtworkStatusEvent>(this as ArtworkStatusEvent, _$identity);

  /// Serializes this ArtworkStatusEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtworkStatusEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,changedAt);

@override
String toString() {
  return 'ArtworkStatusEvent(status: $status, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class $ArtworkStatusEventCopyWith<$Res>  {
  factory $ArtworkStatusEventCopyWith(ArtworkStatusEvent value, $Res Function(ArtworkStatusEvent) _then) = _$ArtworkStatusEventCopyWithImpl;
@useResult
$Res call({
 ArtworkStatus status, String changedAt
});




}
/// @nodoc
class _$ArtworkStatusEventCopyWithImpl<$Res>
    implements $ArtworkStatusEventCopyWith<$Res> {
  _$ArtworkStatusEventCopyWithImpl(this._self, this._then);

  final ArtworkStatusEvent _self;
  final $Res Function(ArtworkStatusEvent) _then;

/// Create a copy of ArtworkStatusEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? changedAt = null,}) {
  return _then(ArtworkStatusEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ArtworkStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtworkStatusEvent].
extension ArtworkStatusEventPatterns on ArtworkStatusEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtworkStatusEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtworkStatusEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtworkStatusEvent value)  $default,){
final _that = this;
switch (_that) {
case _ArtworkStatusEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtworkStatusEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ArtworkStatusEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArtworkStatus status,  String changedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtworkStatusEvent() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArtworkStatus status,  String changedAt)  $default,) {final _that = this;
switch (_that) {
case _ArtworkStatusEvent():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArtworkStatus status,  String changedAt)?  $default,) {final _that = this;
switch (_that) {
case _ArtworkStatusEvent() when $default != null:
return $default(_that.status,_that.changedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtworkStatusEvent implements ArtworkStatusEvent {
  const _ArtworkStatusEvent({required this.status, required this.changedAt});
  factory _ArtworkStatusEvent.fromJson(Map<String, dynamic> json) => _$ArtworkStatusEventFromJson(json);

@override final  ArtworkStatus status;
@override final  String changedAt;

/// Create a copy of ArtworkStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkStatusEventCopyWith<_ArtworkStatusEvent> get copyWith => __$ArtworkStatusEventCopyWithImpl<_ArtworkStatusEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkStatusEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtworkStatusEvent&&(identical(other.status, status) || other.status == status)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,changedAt);

@override
String toString() {
  return 'ArtworkStatusEvent(status: $status, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class _$ArtworkStatusEventCopyWith<$Res> implements $ArtworkStatusEventCopyWith<$Res> {
  factory _$ArtworkStatusEventCopyWith(_ArtworkStatusEvent value, $Res Function(_ArtworkStatusEvent) _then) = __$ArtworkStatusEventCopyWithImpl;
@override @useResult
$Res call({
 ArtworkStatus status, String changedAt
});




}
/// @nodoc
class __$ArtworkStatusEventCopyWithImpl<$Res>
    implements _$ArtworkStatusEventCopyWith<$Res> {
  __$ArtworkStatusEventCopyWithImpl(this._self, this._then);

  final _ArtworkStatusEvent _self;
  final $Res Function(_ArtworkStatusEvent) _then;

/// Create a copy of ArtworkStatusEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? changedAt = null,}) {
  return _then(_ArtworkStatusEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ArtworkStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Artwork {

 String get id; String get title; String get artistId; String get artistName; bool get verifiedArtist; String get category; String get medium; double get customerPrice; String get thumbnailUrl; bool get insured; ArtworkStatus get status; ListingType get listingType; String get description; String? get dimensions; int? get yearCreated; List<ArtworkImage> get images; String get coaCertificateNumber; String get coaIssueDate; List<SocialProofLink> get socialProofLinks; List<ArtworkStatusEvent> get statusHistory; String? get nfcTagId;
/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkCopyWith<Artwork> get copyWith => _$ArtworkCopyWithImpl<Artwork>(this as Artwork, _$identity);

  /// Serializes this Artwork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artwork&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.verifiedArtist, verifiedArtist) || other.verifiedArtist == verifiedArtist)&&(identical(other.category, category) || other.category == category)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.customerPrice, customerPrice) || other.customerPrice == customerPrice)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.insured, insured) || other.insured == insured)&&(identical(other.status, status) || other.status == status)&&(identical(other.listingType, listingType) || other.listingType == listingType)&&(identical(other.description, description) || other.description == description)&&(identical(other.dimensions, dimensions) || other.dimensions == dimensions)&&(identical(other.yearCreated, yearCreated) || other.yearCreated == yearCreated)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.coaIssueDate, coaIssueDate) || other.coaIssueDate == coaIssueDate)&&const DeepCollectionEquality().equals(other.socialProofLinks, socialProofLinks)&&const DeepCollectionEquality().equals(other.statusHistory, statusHistory)&&(identical(other.nfcTagId, nfcTagId) || other.nfcTagId == nfcTagId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,artistId,artistName,verifiedArtist,category,medium,customerPrice,thumbnailUrl,insured,status,listingType,description,dimensions,yearCreated,const DeepCollectionEquality().hash(images),coaCertificateNumber,coaIssueDate,const DeepCollectionEquality().hash(socialProofLinks),const DeepCollectionEquality().hash(statusHistory),nfcTagId]);

@override
String toString() {
  return 'Artwork(id: $id, title: $title, artistId: $artistId, artistName: $artistName, verifiedArtist: $verifiedArtist, category: $category, medium: $medium, customerPrice: $customerPrice, thumbnailUrl: $thumbnailUrl, insured: $insured, status: $status, listingType: $listingType, description: $description, dimensions: $dimensions, yearCreated: $yearCreated, images: $images, coaCertificateNumber: $coaCertificateNumber, coaIssueDate: $coaIssueDate, socialProofLinks: $socialProofLinks, statusHistory: $statusHistory, nfcTagId: $nfcTagId)';
}


}

/// @nodoc
abstract mixin class $ArtworkCopyWith<$Res>  {
  factory $ArtworkCopyWith(Artwork value, $Res Function(Artwork) _then) = _$ArtworkCopyWithImpl;
@useResult
$Res call({
 String id, String title, String artistId, String artistName, bool verifiedArtist, String category, String medium, double customerPrice, String thumbnailUrl, bool insured, ArtworkStatus status, ListingType listingType, String description, String? dimensions, int? yearCreated, List<ArtworkImage> images, String coaCertificateNumber, String coaIssueDate, List<SocialProofLink> socialProofLinks, List<ArtworkStatusEvent> statusHistory, String? nfcTagId
});




}
/// @nodoc
class _$ArtworkCopyWithImpl<$Res>
    implements $ArtworkCopyWith<$Res> {
  _$ArtworkCopyWithImpl(this._self, this._then);

  final Artwork _self;
  final $Res Function(Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artistId = null,Object? artistName = null,Object? verifiedArtist = null,Object? category = null,Object? medium = null,Object? customerPrice = null,Object? thumbnailUrl = null,Object? insured = null,Object? status = null,Object? listingType = null,Object? description = null,Object? dimensions = freezed,Object? yearCreated = freezed,Object? images = null,Object? coaCertificateNumber = null,Object? coaIssueDate = null,Object? socialProofLinks = null,Object? statusHistory = null,Object? nfcTagId = freezed,}) {
  return _then(Artwork(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,verifiedArtist: null == verifiedArtist ? _self.verifiedArtist : verifiedArtist // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,medium: null == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as String,customerPrice: null == customerPrice ? _self.customerPrice : customerPrice // ignore: cast_nullable_to_non_nullable
as double,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,insured: null == insured ? _self.insured : insured // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ArtworkStatus,listingType: null == listingType ? _self.listingType : listingType // ignore: cast_nullable_to_non_nullable
as ListingType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dimensions: freezed == dimensions ? _self.dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as String?,yearCreated: freezed == yearCreated ? _self.yearCreated : yearCreated // ignore: cast_nullable_to_non_nullable
as int?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ArtworkImage>,coaCertificateNumber: null == coaCertificateNumber ? _self.coaCertificateNumber : coaCertificateNumber // ignore: cast_nullable_to_non_nullable
as String,coaIssueDate: null == coaIssueDate ? _self.coaIssueDate : coaIssueDate // ignore: cast_nullable_to_non_nullable
as String,socialProofLinks: null == socialProofLinks ? _self.socialProofLinks : socialProofLinks // ignore: cast_nullable_to_non_nullable
as List<SocialProofLink>,statusHistory: null == statusHistory ? _self.statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<ArtworkStatusEvent>,nfcTagId: freezed == nfcTagId ? _self.nfcTagId : nfcTagId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Artwork].
extension ArtworkPatterns on Artwork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Artwork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Artwork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Artwork value)  $default,){
final _that = this;
switch (_that) {
case _Artwork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Artwork value)?  $default,){
final _that = this;
switch (_that) {
case _Artwork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId)  $default,) {final _that = this;
switch (_that) {
case _Artwork():
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId)?  $default,) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artwork implements Artwork {
  const _Artwork({required this.id, required this.title, required this.artistId, required this.artistName, required this.verifiedArtist, required this.category, required this.medium, required this.customerPrice, required this.thumbnailUrl, required this.insured, required this.status, required this.listingType, required this.description, this.dimensions, this.yearCreated, required  List<ArtworkImage> images, required this.coaCertificateNumber, required this.coaIssueDate, required  List<SocialProofLink> socialProofLinks, required  List<ArtworkStatusEvent> statusHistory, this.nfcTagId}): _images = images,_socialProofLinks = socialProofLinks,_statusHistory = statusHistory;
  factory _Artwork.fromJson(Map<String, dynamic> json) => _$ArtworkFromJson(json);

@override final  String id;
@override final  String title;
@override final  String artistId;
@override final  String artistName;
@override final  bool verifiedArtist;
@override final  String category;
@override final  String medium;
@override final  double customerPrice;
@override final  String thumbnailUrl;
@override final  bool insured;
@override final  ArtworkStatus status;
@override final  ListingType listingType;
@override final  String description;
@override final  String? dimensions;
@override final  int? yearCreated;
 final  List<ArtworkImage> _images;
@override List<ArtworkImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override final  String coaCertificateNumber;
@override final  String coaIssueDate;
 final  List<SocialProofLink> _socialProofLinks;
@override List<SocialProofLink> get socialProofLinks {
  if (_socialProofLinks is EqualUnmodifiableListView) return _socialProofLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_socialProofLinks);
}

 final  List<ArtworkStatusEvent> _statusHistory;
@override List<ArtworkStatusEvent> get statusHistory {
  if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusHistory);
}

@override final  String? nfcTagId;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkCopyWith<_Artwork> get copyWith => __$ArtworkCopyWithImpl<_Artwork>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artwork&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.verifiedArtist, verifiedArtist) || other.verifiedArtist == verifiedArtist)&&(identical(other.category, category) || other.category == category)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.customerPrice, customerPrice) || other.customerPrice == customerPrice)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.insured, insured) || other.insured == insured)&&(identical(other.status, status) || other.status == status)&&(identical(other.listingType, listingType) || other.listingType == listingType)&&(identical(other.description, description) || other.description == description)&&(identical(other.dimensions, dimensions) || other.dimensions == dimensions)&&(identical(other.yearCreated, yearCreated) || other.yearCreated == yearCreated)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.coaIssueDate, coaIssueDate) || other.coaIssueDate == coaIssueDate)&&const DeepCollectionEquality().equals(other._socialProofLinks, _socialProofLinks)&&const DeepCollectionEquality().equals(other._statusHistory, _statusHistory)&&(identical(other.nfcTagId, nfcTagId) || other.nfcTagId == nfcTagId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,artistId,artistName,verifiedArtist,category,medium,customerPrice,thumbnailUrl,insured,status,listingType,description,dimensions,yearCreated,const DeepCollectionEquality().hash(_images),coaCertificateNumber,coaIssueDate,const DeepCollectionEquality().hash(_socialProofLinks),const DeepCollectionEquality().hash(_statusHistory),nfcTagId]);

@override
String toString() {
  return 'Artwork(id: $id, title: $title, artistId: $artistId, artistName: $artistName, verifiedArtist: $verifiedArtist, category: $category, medium: $medium, customerPrice: $customerPrice, thumbnailUrl: $thumbnailUrl, insured: $insured, status: $status, listingType: $listingType, description: $description, dimensions: $dimensions, yearCreated: $yearCreated, images: $images, coaCertificateNumber: $coaCertificateNumber, coaIssueDate: $coaIssueDate, socialProofLinks: $socialProofLinks, statusHistory: $statusHistory, nfcTagId: $nfcTagId)';
}


}

/// @nodoc
abstract mixin class _$ArtworkCopyWith<$Res> implements $ArtworkCopyWith<$Res> {
  factory _$ArtworkCopyWith(_Artwork value, $Res Function(_Artwork) _then) = __$ArtworkCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String artistId, String artistName, bool verifiedArtist, String category, String medium, double customerPrice, String thumbnailUrl, bool insured, ArtworkStatus status, ListingType listingType, String description, String? dimensions, int? yearCreated, List<ArtworkImage> images, String coaCertificateNumber, String coaIssueDate, List<SocialProofLink> socialProofLinks, List<ArtworkStatusEvent> statusHistory, String? nfcTagId
});




}
/// @nodoc
class __$ArtworkCopyWithImpl<$Res>
    implements _$ArtworkCopyWith<$Res> {
  __$ArtworkCopyWithImpl(this._self, this._then);

  final _Artwork _self;
  final $Res Function(_Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artistId = null,Object? artistName = null,Object? verifiedArtist = null,Object? category = null,Object? medium = null,Object? customerPrice = null,Object? thumbnailUrl = null,Object? insured = null,Object? status = null,Object? listingType = null,Object? description = null,Object? dimensions = freezed,Object? yearCreated = freezed,Object? images = null,Object? coaCertificateNumber = null,Object? coaIssueDate = null,Object? socialProofLinks = null,Object? statusHistory = null,Object? nfcTagId = freezed,}) {
  return _then(_Artwork(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,verifiedArtist: null == verifiedArtist ? _self.verifiedArtist : verifiedArtist // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,medium: null == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as String,customerPrice: null == customerPrice ? _self.customerPrice : customerPrice // ignore: cast_nullable_to_non_nullable
as double,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,insured: null == insured ? _self.insured : insured // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ArtworkStatus,listingType: null == listingType ? _self.listingType : listingType // ignore: cast_nullable_to_non_nullable
as ListingType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dimensions: freezed == dimensions ? _self.dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as String?,yearCreated: freezed == yearCreated ? _self.yearCreated : yearCreated // ignore: cast_nullable_to_non_nullable
as int?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ArtworkImage>,coaCertificateNumber: null == coaCertificateNumber ? _self.coaCertificateNumber : coaCertificateNumber // ignore: cast_nullable_to_non_nullable
as String,coaIssueDate: null == coaIssueDate ? _self.coaIssueDate : coaIssueDate // ignore: cast_nullable_to_non_nullable
as String,socialProofLinks: null == socialProofLinks ? _self._socialProofLinks : socialProofLinks // ignore: cast_nullable_to_non_nullable
as List<SocialProofLink>,statusHistory: null == statusHistory ? _self._statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<ArtworkStatusEvent>,nfcTagId: freezed == nfcTagId ? _self.nfcTagId : nfcTagId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ArtistArtwork {

 Artwork get artwork; double get artistPrice;
/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistArtworkCopyWith<ArtistArtwork> get copyWith => _$ArtistArtworkCopyWithImpl<ArtistArtwork>(this as ArtistArtwork, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistArtwork&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.artistPrice, artistPrice) || other.artistPrice == artistPrice));
}


@override
int get hashCode => Object.hash(runtimeType,artwork,artistPrice);

@override
String toString() {
  return 'ArtistArtwork(artwork: $artwork, artistPrice: $artistPrice)';
}


}

/// @nodoc
abstract mixin class $ArtistArtworkCopyWith<$Res>  {
  factory $ArtistArtworkCopyWith(ArtistArtwork value, $Res Function(ArtistArtwork) _then) = _$ArtistArtworkCopyWithImpl;
@useResult
$Res call({
 Artwork artwork, double artistPrice
});


$ArtworkCopyWith<$Res> get artwork;

}
/// @nodoc
class _$ArtistArtworkCopyWithImpl<$Res>
    implements $ArtistArtworkCopyWith<$Res> {
  _$ArtistArtworkCopyWithImpl(this._self, this._then);

  final ArtistArtwork _self;
  final $Res Function(ArtistArtwork) _then;

/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artwork = null,Object? artistPrice = null,}) {
  return _then(ArtistArtwork(
artwork: null == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork,artistPrice: null == artistPrice ? _self.artistPrice : artistPrice // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res> get artwork {
  
  return $ArtworkCopyWith<$Res>(_self.artwork, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistArtwork].
extension ArtistArtworkPatterns on ArtistArtwork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistArtwork value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistArtwork() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistArtwork value)  $default,){
final _that = this;
switch (_that) {
case _ArtistArtwork():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistArtwork value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistArtwork() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Artwork artwork,  double artistPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistArtwork() when $default != null:
return $default(_that.artwork,_that.artistPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Artwork artwork,  double artistPrice)  $default,) {final _that = this;
switch (_that) {
case _ArtistArtwork():
return $default(_that.artwork,_that.artistPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Artwork artwork,  double artistPrice)?  $default,) {final _that = this;
switch (_that) {
case _ArtistArtwork() when $default != null:
return $default(_that.artwork,_that.artistPrice);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistArtwork implements ArtistArtwork {
  const _ArtistArtwork({required this.artwork, required this.artistPrice});
  

@override final  Artwork artwork;
@override final  double artistPrice;

/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistArtworkCopyWith<_ArtistArtwork> get copyWith => __$ArtistArtworkCopyWithImpl<_ArtistArtwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistArtwork&&(identical(other.artwork, artwork) || other.artwork == artwork)&&(identical(other.artistPrice, artistPrice) || other.artistPrice == artistPrice));
}


@override
int get hashCode => Object.hash(runtimeType,artwork,artistPrice);

@override
String toString() {
  return 'ArtistArtwork(artwork: $artwork, artistPrice: $artistPrice)';
}


}

/// @nodoc
abstract mixin class _$ArtistArtworkCopyWith<$Res> implements $ArtistArtworkCopyWith<$Res> {
  factory _$ArtistArtworkCopyWith(_ArtistArtwork value, $Res Function(_ArtistArtwork) _then) = __$ArtistArtworkCopyWithImpl;
@override @useResult
$Res call({
 Artwork artwork, double artistPrice
});


@override $ArtworkCopyWith<$Res> get artwork;

}
/// @nodoc
class __$ArtistArtworkCopyWithImpl<$Res>
    implements _$ArtistArtworkCopyWith<$Res> {
  __$ArtistArtworkCopyWithImpl(this._self, this._then);

  final _ArtistArtwork _self;
  final $Res Function(_ArtistArtwork) _then;

/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artwork = null,Object? artistPrice = null,}) {
  return _then(_ArtistArtwork(
artwork: null == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Artwork,artistPrice: null == artistPrice ? _self.artistPrice : artistPrice // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of ArtistArtwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCopyWith<$Res> get artwork {
  
  return $ArtworkCopyWith<$Res>(_self.artwork, (value) {
    return _then(_self.copyWith(artwork: value));
  });
}
}

// dart format on
