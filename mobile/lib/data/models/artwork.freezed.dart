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

 String get id; String get title; String get artistId; String get artistName; bool get verifiedArtist; String get category; String get medium; double get customerPrice; String get thumbnailUrl; bool get insured; ArtworkStatus get status; ListingType get listingType; String get description; String? get dimensions; int? get yearCreated; List<ArtworkImage> get images; String get coaCertificateNumber; String get coaIssueDate; List<SocialProofLink> get socialProofLinks; List<ArtworkStatusEvent> get statusHistory; String? get nfcTagId;/// R / U / O / N. Null on fixtures that predate the field.
 ArtworkRarity? get rarityType;/// Weight, framing and packing. Nullable because the fixture records
/// predate the fields; the submit form collects them and requires them
/// once the aggregator channel is picked.
 ArtworkPhysical? get physical;/// Ownership, physical custody and location are three independent
/// states, never one "owner" field — a piece can be legally owned by
/// GalleryZone, physically held by an aggregator, and located in a third
/// city all at once. Nullable so the seeded fixtures don't need a value:
/// [resolveCustody] derives one from `status` when it's absent.
 ArtworkCustody? get custody;
/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkCopyWith<Artwork> get copyWith => _$ArtworkCopyWithImpl<Artwork>(this as Artwork, _$identity);

  /// Serializes this Artwork to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artwork&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.verifiedArtist, verifiedArtist) || other.verifiedArtist == verifiedArtist)&&(identical(other.category, category) || other.category == category)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.customerPrice, customerPrice) || other.customerPrice == customerPrice)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.insured, insured) || other.insured == insured)&&(identical(other.status, status) || other.status == status)&&(identical(other.listingType, listingType) || other.listingType == listingType)&&(identical(other.description, description) || other.description == description)&&(identical(other.dimensions, dimensions) || other.dimensions == dimensions)&&(identical(other.yearCreated, yearCreated) || other.yearCreated == yearCreated)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.coaIssueDate, coaIssueDate) || other.coaIssueDate == coaIssueDate)&&const DeepCollectionEquality().equals(other.socialProofLinks, socialProofLinks)&&const DeepCollectionEquality().equals(other.statusHistory, statusHistory)&&(identical(other.nfcTagId, nfcTagId) || other.nfcTagId == nfcTagId)&&(identical(other.rarityType, rarityType) || other.rarityType == rarityType)&&(identical(other.physical, physical) || other.physical == physical)&&(identical(other.custody, custody) || other.custody == custody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,artistId,artistName,verifiedArtist,category,medium,customerPrice,thumbnailUrl,insured,status,listingType,description,dimensions,yearCreated,const DeepCollectionEquality().hash(images),coaCertificateNumber,coaIssueDate,const DeepCollectionEquality().hash(socialProofLinks),const DeepCollectionEquality().hash(statusHistory),nfcTagId,rarityType,physical,custody]);

@override
String toString() {
  return 'Artwork(id: $id, title: $title, artistId: $artistId, artistName: $artistName, verifiedArtist: $verifiedArtist, category: $category, medium: $medium, customerPrice: $customerPrice, thumbnailUrl: $thumbnailUrl, insured: $insured, status: $status, listingType: $listingType, description: $description, dimensions: $dimensions, yearCreated: $yearCreated, images: $images, coaCertificateNumber: $coaCertificateNumber, coaIssueDate: $coaIssueDate, socialProofLinks: $socialProofLinks, statusHistory: $statusHistory, nfcTagId: $nfcTagId, rarityType: $rarityType, physical: $physical, custody: $custody)';
}


}

/// @nodoc
abstract mixin class $ArtworkCopyWith<$Res>  {
  factory $ArtworkCopyWith(Artwork value, $Res Function(Artwork) _then) = _$ArtworkCopyWithImpl;
@useResult
$Res call({
 String id, String title, String artistId, String artistName, bool verifiedArtist, String category, String medium, double customerPrice, String thumbnailUrl, bool insured, ArtworkStatus status, ListingType listingType, String description, String? dimensions, int? yearCreated, List<ArtworkImage> images, String coaCertificateNumber, String coaIssueDate, List<SocialProofLink> socialProofLinks, List<ArtworkStatusEvent> statusHistory, String? nfcTagId, ArtworkRarity? rarityType, ArtworkPhysical? physical, ArtworkCustody? custody
});


$ArtworkPhysicalCopyWith<$Res>? get physical;$ArtworkCustodyCopyWith<$Res>? get custody;

}
/// @nodoc
class _$ArtworkCopyWithImpl<$Res>
    implements $ArtworkCopyWith<$Res> {
  _$ArtworkCopyWithImpl(this._self, this._then);

  final Artwork _self;
  final $Res Function(Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artistId = null,Object? artistName = null,Object? verifiedArtist = null,Object? category = null,Object? medium = null,Object? customerPrice = null,Object? thumbnailUrl = null,Object? insured = null,Object? status = null,Object? listingType = null,Object? description = null,Object? dimensions = freezed,Object? yearCreated = freezed,Object? images = null,Object? coaCertificateNumber = null,Object? coaIssueDate = null,Object? socialProofLinks = null,Object? statusHistory = null,Object? nfcTagId = freezed,Object? rarityType = freezed,Object? physical = freezed,Object? custody = freezed,}) {
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
as String?,rarityType: freezed == rarityType ? _self.rarityType : rarityType // ignore: cast_nullable_to_non_nullable
as ArtworkRarity?,physical: freezed == physical ? _self.physical : physical // ignore: cast_nullable_to_non_nullable
as ArtworkPhysical?,custody: freezed == custody ? _self.custody : custody // ignore: cast_nullable_to_non_nullable
as ArtworkCustody?,
  ));
}
/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkPhysicalCopyWith<$Res>? get physical {
    if (_self.physical == null) {
    return null;
  }

  return $ArtworkPhysicalCopyWith<$Res>(_self.physical!, (value) {
    return _then(_self.copyWith(physical: value));
  });
}/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCustodyCopyWith<$Res>? get custody {
    if (_self.custody == null) {
    return null;
  }

  return $ArtworkCustodyCopyWith<$Res>(_self.custody!, (value) {
    return _then(_self.copyWith(custody: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId,  ArtworkRarity? rarityType,  ArtworkPhysical? physical,  ArtworkCustody? custody)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId,_that.rarityType,_that.physical,_that.custody);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId,  ArtworkRarity? rarityType,  ArtworkPhysical? physical,  ArtworkCustody? custody)  $default,) {final _that = this;
switch (_that) {
case _Artwork():
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId,_that.rarityType,_that.physical,_that.custody);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String artistId,  String artistName,  bool verifiedArtist,  String category,  String medium,  double customerPrice,  String thumbnailUrl,  bool insured,  ArtworkStatus status,  ListingType listingType,  String description,  String? dimensions,  int? yearCreated,  List<ArtworkImage> images,  String coaCertificateNumber,  String coaIssueDate,  List<SocialProofLink> socialProofLinks,  List<ArtworkStatusEvent> statusHistory,  String? nfcTagId,  ArtworkRarity? rarityType,  ArtworkPhysical? physical,  ArtworkCustody? custody)?  $default,) {final _that = this;
switch (_that) {
case _Artwork() when $default != null:
return $default(_that.id,_that.title,_that.artistId,_that.artistName,_that.verifiedArtist,_that.category,_that.medium,_that.customerPrice,_that.thumbnailUrl,_that.insured,_that.status,_that.listingType,_that.description,_that.dimensions,_that.yearCreated,_that.images,_that.coaCertificateNumber,_that.coaIssueDate,_that.socialProofLinks,_that.statusHistory,_that.nfcTagId,_that.rarityType,_that.physical,_that.custody);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artwork implements Artwork {
  const _Artwork({required this.id, required this.title, required this.artistId, required this.artistName, required this.verifiedArtist, required this.category, required this.medium, required this.customerPrice, required this.thumbnailUrl, required this.insured, required this.status, required this.listingType, required this.description, this.dimensions, this.yearCreated, required  List<ArtworkImage> images, required this.coaCertificateNumber, required this.coaIssueDate, required  List<SocialProofLink> socialProofLinks, required  List<ArtworkStatusEvent> statusHistory, this.nfcTagId, this.rarityType, this.physical, this.custody}): _images = images,_socialProofLinks = socialProofLinks,_statusHistory = statusHistory;
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
/// R / U / O / N. Null on fixtures that predate the field.
@override final  ArtworkRarity? rarityType;
/// Weight, framing and packing. Nullable because the fixture records
/// predate the fields; the submit form collects them and requires them
/// once the aggregator channel is picked.
@override final  ArtworkPhysical? physical;
/// Ownership, physical custody and location are three independent
/// states, never one "owner" field — a piece can be legally owned by
/// GalleryZone, physically held by an aggregator, and located in a third
/// city all at once. Nullable so the seeded fixtures don't need a value:
/// [resolveCustody] derives one from `status` when it's absent.
@override final  ArtworkCustody? custody;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artwork&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.verifiedArtist, verifiedArtist) || other.verifiedArtist == verifiedArtist)&&(identical(other.category, category) || other.category == category)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.customerPrice, customerPrice) || other.customerPrice == customerPrice)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.insured, insured) || other.insured == insured)&&(identical(other.status, status) || other.status == status)&&(identical(other.listingType, listingType) || other.listingType == listingType)&&(identical(other.description, description) || other.description == description)&&(identical(other.dimensions, dimensions) || other.dimensions == dimensions)&&(identical(other.yearCreated, yearCreated) || other.yearCreated == yearCreated)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.coaIssueDate, coaIssueDate) || other.coaIssueDate == coaIssueDate)&&const DeepCollectionEquality().equals(other._socialProofLinks, _socialProofLinks)&&const DeepCollectionEquality().equals(other._statusHistory, _statusHistory)&&(identical(other.nfcTagId, nfcTagId) || other.nfcTagId == nfcTagId)&&(identical(other.rarityType, rarityType) || other.rarityType == rarityType)&&(identical(other.physical, physical) || other.physical == physical)&&(identical(other.custody, custody) || other.custody == custody));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,artistId,artistName,verifiedArtist,category,medium,customerPrice,thumbnailUrl,insured,status,listingType,description,dimensions,yearCreated,const DeepCollectionEquality().hash(_images),coaCertificateNumber,coaIssueDate,const DeepCollectionEquality().hash(_socialProofLinks),const DeepCollectionEquality().hash(_statusHistory),nfcTagId,rarityType,physical,custody]);

@override
String toString() {
  return 'Artwork(id: $id, title: $title, artistId: $artistId, artistName: $artistName, verifiedArtist: $verifiedArtist, category: $category, medium: $medium, customerPrice: $customerPrice, thumbnailUrl: $thumbnailUrl, insured: $insured, status: $status, listingType: $listingType, description: $description, dimensions: $dimensions, yearCreated: $yearCreated, images: $images, coaCertificateNumber: $coaCertificateNumber, coaIssueDate: $coaIssueDate, socialProofLinks: $socialProofLinks, statusHistory: $statusHistory, nfcTagId: $nfcTagId, rarityType: $rarityType, physical: $physical, custody: $custody)';
}


}

/// @nodoc
abstract mixin class _$ArtworkCopyWith<$Res> implements $ArtworkCopyWith<$Res> {
  factory _$ArtworkCopyWith(_Artwork value, $Res Function(_Artwork) _then) = __$ArtworkCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String artistId, String artistName, bool verifiedArtist, String category, String medium, double customerPrice, String thumbnailUrl, bool insured, ArtworkStatus status, ListingType listingType, String description, String? dimensions, int? yearCreated, List<ArtworkImage> images, String coaCertificateNumber, String coaIssueDate, List<SocialProofLink> socialProofLinks, List<ArtworkStatusEvent> statusHistory, String? nfcTagId, ArtworkRarity? rarityType, ArtworkPhysical? physical, ArtworkCustody? custody
});


@override $ArtworkPhysicalCopyWith<$Res>? get physical;@override $ArtworkCustodyCopyWith<$Res>? get custody;

}
/// @nodoc
class __$ArtworkCopyWithImpl<$Res>
    implements _$ArtworkCopyWith<$Res> {
  __$ArtworkCopyWithImpl(this._self, this._then);

  final _Artwork _self;
  final $Res Function(_Artwork) _then;

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artistId = null,Object? artistName = null,Object? verifiedArtist = null,Object? category = null,Object? medium = null,Object? customerPrice = null,Object? thumbnailUrl = null,Object? insured = null,Object? status = null,Object? listingType = null,Object? description = null,Object? dimensions = freezed,Object? yearCreated = freezed,Object? images = null,Object? coaCertificateNumber = null,Object? coaIssueDate = null,Object? socialProofLinks = null,Object? statusHistory = null,Object? nfcTagId = freezed,Object? rarityType = freezed,Object? physical = freezed,Object? custody = freezed,}) {
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
as String?,rarityType: freezed == rarityType ? _self.rarityType : rarityType // ignore: cast_nullable_to_non_nullable
as ArtworkRarity?,physical: freezed == physical ? _self.physical : physical // ignore: cast_nullable_to_non_nullable
as ArtworkPhysical?,custody: freezed == custody ? _self.custody : custody // ignore: cast_nullable_to_non_nullable
as ArtworkCustody?,
  ));
}

/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkPhysicalCopyWith<$Res>? get physical {
    if (_self.physical == null) {
    return null;
  }

  return $ArtworkPhysicalCopyWith<$Res>(_self.physical!, (value) {
    return _then(_self.copyWith(physical: value));
  });
}/// Create a copy of Artwork
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtworkCustodyCopyWith<$Res>? get custody {
    if (_self.custody == null) {
    return null;
  }

  return $ArtworkCustodyCopyWith<$Res>(_self.custody!, (value) {
    return _then(_self.copyWith(custody: value));
  });
}
}


/// @nodoc
mixin _$ArtworkPhysical {

 double? get weightKg; FramingState? get framing;/// Surface or format — canvas, paper, board, panel, bronze.
 String? get format;/// MOU §12: hangers must ship with the artwork.
 bool get hangingHardwareIncluded;/// Artist has confirmed packing to GalleryZone's shipping standard.
 bool get packagingConfirmed;
/// Create a copy of ArtworkPhysical
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkPhysicalCopyWith<ArtworkPhysical> get copyWith => _$ArtworkPhysicalCopyWithImpl<ArtworkPhysical>(this as ArtworkPhysical, _$identity);

  /// Serializes this ArtworkPhysical to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtworkPhysical&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.framing, framing) || other.framing == framing)&&(identical(other.format, format) || other.format == format)&&(identical(other.hangingHardwareIncluded, hangingHardwareIncluded) || other.hangingHardwareIncluded == hangingHardwareIncluded)&&(identical(other.packagingConfirmed, packagingConfirmed) || other.packagingConfirmed == packagingConfirmed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightKg,framing,format,hangingHardwareIncluded,packagingConfirmed);

@override
String toString() {
  return 'ArtworkPhysical(weightKg: $weightKg, framing: $framing, format: $format, hangingHardwareIncluded: $hangingHardwareIncluded, packagingConfirmed: $packagingConfirmed)';
}


}

/// @nodoc
abstract mixin class $ArtworkPhysicalCopyWith<$Res>  {
  factory $ArtworkPhysicalCopyWith(ArtworkPhysical value, $Res Function(ArtworkPhysical) _then) = _$ArtworkPhysicalCopyWithImpl;
@useResult
$Res call({
 double? weightKg, FramingState? framing, String? format, bool hangingHardwareIncluded, bool packagingConfirmed
});




}
/// @nodoc
class _$ArtworkPhysicalCopyWithImpl<$Res>
    implements $ArtworkPhysicalCopyWith<$Res> {
  _$ArtworkPhysicalCopyWithImpl(this._self, this._then);

  final ArtworkPhysical _self;
  final $Res Function(ArtworkPhysical) _then;

/// Create a copy of ArtworkPhysical
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weightKg = freezed,Object? framing = freezed,Object? format = freezed,Object? hangingHardwareIncluded = null,Object? packagingConfirmed = null,}) {
  return _then(ArtworkPhysical(
weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,framing: freezed == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as FramingState?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,hangingHardwareIncluded: null == hangingHardwareIncluded ? _self.hangingHardwareIncluded : hangingHardwareIncluded // ignore: cast_nullable_to_non_nullable
as bool,packagingConfirmed: null == packagingConfirmed ? _self.packagingConfirmed : packagingConfirmed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtworkPhysical].
extension ArtworkPhysicalPatterns on ArtworkPhysical {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtworkPhysical value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtworkPhysical() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtworkPhysical value)  $default,){
final _that = this;
switch (_that) {
case _ArtworkPhysical():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtworkPhysical value)?  $default,){
final _that = this;
switch (_that) {
case _ArtworkPhysical() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? weightKg,  FramingState? framing,  String? format,  bool hangingHardwareIncluded,  bool packagingConfirmed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtworkPhysical() when $default != null:
return $default(_that.weightKg,_that.framing,_that.format,_that.hangingHardwareIncluded,_that.packagingConfirmed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? weightKg,  FramingState? framing,  String? format,  bool hangingHardwareIncluded,  bool packagingConfirmed)  $default,) {final _that = this;
switch (_that) {
case _ArtworkPhysical():
return $default(_that.weightKg,_that.framing,_that.format,_that.hangingHardwareIncluded,_that.packagingConfirmed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? weightKg,  FramingState? framing,  String? format,  bool hangingHardwareIncluded,  bool packagingConfirmed)?  $default,) {final _that = this;
switch (_that) {
case _ArtworkPhysical() when $default != null:
return $default(_that.weightKg,_that.framing,_that.format,_that.hangingHardwareIncluded,_that.packagingConfirmed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtworkPhysical implements ArtworkPhysical {
  const _ArtworkPhysical({this.weightKg, this.framing, this.format, this.hangingHardwareIncluded = false, this.packagingConfirmed = false});
  factory _ArtworkPhysical.fromJson(Map<String, dynamic> json) => _$ArtworkPhysicalFromJson(json);

@override final  double? weightKg;
@override final  FramingState? framing;
/// Surface or format — canvas, paper, board, panel, bronze.
@override final  String? format;
/// MOU §12: hangers must ship with the artwork.
@override@JsonKey() final  bool hangingHardwareIncluded;
/// Artist has confirmed packing to GalleryZone's shipping standard.
@override@JsonKey() final  bool packagingConfirmed;

/// Create a copy of ArtworkPhysical
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkPhysicalCopyWith<_ArtworkPhysical> get copyWith => __$ArtworkPhysicalCopyWithImpl<_ArtworkPhysical>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkPhysicalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtworkPhysical&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.framing, framing) || other.framing == framing)&&(identical(other.format, format) || other.format == format)&&(identical(other.hangingHardwareIncluded, hangingHardwareIncluded) || other.hangingHardwareIncluded == hangingHardwareIncluded)&&(identical(other.packagingConfirmed, packagingConfirmed) || other.packagingConfirmed == packagingConfirmed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightKg,framing,format,hangingHardwareIncluded,packagingConfirmed);

@override
String toString() {
  return 'ArtworkPhysical(weightKg: $weightKg, framing: $framing, format: $format, hangingHardwareIncluded: $hangingHardwareIncluded, packagingConfirmed: $packagingConfirmed)';
}


}

/// @nodoc
abstract mixin class _$ArtworkPhysicalCopyWith<$Res> implements $ArtworkPhysicalCopyWith<$Res> {
  factory _$ArtworkPhysicalCopyWith(_ArtworkPhysical value, $Res Function(_ArtworkPhysical) _then) = __$ArtworkPhysicalCopyWithImpl;
@override @useResult
$Res call({
 double? weightKg, FramingState? framing, String? format, bool hangingHardwareIncluded, bool packagingConfirmed
});




}
/// @nodoc
class __$ArtworkPhysicalCopyWithImpl<$Res>
    implements _$ArtworkPhysicalCopyWith<$Res> {
  __$ArtworkPhysicalCopyWithImpl(this._self, this._then);

  final _ArtworkPhysical _self;
  final $Res Function(_ArtworkPhysical) _then;

/// Create a copy of ArtworkPhysical
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weightKg = freezed,Object? framing = freezed,Object? format = freezed,Object? hangingHardwareIncluded = null,Object? packagingConfirmed = null,}) {
  return _then(_ArtworkPhysical(
weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,framing: freezed == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as FramingState?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,hangingHardwareIncluded: null == hangingHardwareIncluded ? _self.hangingHardwareIncluded : hangingHardwareIncluded // ignore: cast_nullable_to_non_nullable
as bool,packagingConfirmed: null == packagingConfirmed ? _self.packagingConfirmed : packagingConfirmed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ArtworkCustody {

 CustodyParty get legalOwner;/// Named owner once a transfer has been accepted (the buyer's own name).
 String? get legalOwnerName; CustodyParty get custodian; String get locationLabel;
/// Create a copy of ArtworkCustody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtworkCustodyCopyWith<ArtworkCustody> get copyWith => _$ArtworkCustodyCopyWithImpl<ArtworkCustody>(this as ArtworkCustody, _$identity);

  /// Serializes this ArtworkCustody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtworkCustody&&(identical(other.legalOwner, legalOwner) || other.legalOwner == legalOwner)&&(identical(other.legalOwnerName, legalOwnerName) || other.legalOwnerName == legalOwnerName)&&(identical(other.custodian, custodian) || other.custodian == custodian)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,legalOwner,legalOwnerName,custodian,locationLabel);

@override
String toString() {
  return 'ArtworkCustody(legalOwner: $legalOwner, legalOwnerName: $legalOwnerName, custodian: $custodian, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class $ArtworkCustodyCopyWith<$Res>  {
  factory $ArtworkCustodyCopyWith(ArtworkCustody value, $Res Function(ArtworkCustody) _then) = _$ArtworkCustodyCopyWithImpl;
@useResult
$Res call({
 CustodyParty legalOwner, String? legalOwnerName, CustodyParty custodian, String locationLabel
});




}
/// @nodoc
class _$ArtworkCustodyCopyWithImpl<$Res>
    implements $ArtworkCustodyCopyWith<$Res> {
  _$ArtworkCustodyCopyWithImpl(this._self, this._then);

  final ArtworkCustody _self;
  final $Res Function(ArtworkCustody) _then;

/// Create a copy of ArtworkCustody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? legalOwner = null,Object? legalOwnerName = freezed,Object? custodian = null,Object? locationLabel = null,}) {
  return _then(ArtworkCustody(
legalOwner: null == legalOwner ? _self.legalOwner : legalOwner // ignore: cast_nullable_to_non_nullable
as CustodyParty,legalOwnerName: freezed == legalOwnerName ? _self.legalOwnerName : legalOwnerName // ignore: cast_nullable_to_non_nullable
as String?,custodian: null == custodian ? _self.custodian : custodian // ignore: cast_nullable_to_non_nullable
as CustodyParty,locationLabel: null == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtworkCustody].
extension ArtworkCustodyPatterns on ArtworkCustody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtworkCustody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtworkCustody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtworkCustody value)  $default,){
final _that = this;
switch (_that) {
case _ArtworkCustody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtworkCustody value)?  $default,){
final _that = this;
switch (_that) {
case _ArtworkCustody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CustodyParty legalOwner,  String? legalOwnerName,  CustodyParty custodian,  String locationLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtworkCustody() when $default != null:
return $default(_that.legalOwner,_that.legalOwnerName,_that.custodian,_that.locationLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CustodyParty legalOwner,  String? legalOwnerName,  CustodyParty custodian,  String locationLabel)  $default,) {final _that = this;
switch (_that) {
case _ArtworkCustody():
return $default(_that.legalOwner,_that.legalOwnerName,_that.custodian,_that.locationLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CustodyParty legalOwner,  String? legalOwnerName,  CustodyParty custodian,  String locationLabel)?  $default,) {final _that = this;
switch (_that) {
case _ArtworkCustody() when $default != null:
return $default(_that.legalOwner,_that.legalOwnerName,_that.custodian,_that.locationLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtworkCustody implements ArtworkCustody {
  const _ArtworkCustody({required this.legalOwner, this.legalOwnerName, required this.custodian, required this.locationLabel});
  factory _ArtworkCustody.fromJson(Map<String, dynamic> json) => _$ArtworkCustodyFromJson(json);

@override final  CustodyParty legalOwner;
/// Named owner once a transfer has been accepted (the buyer's own name).
@override final  String? legalOwnerName;
@override final  CustodyParty custodian;
@override final  String locationLabel;

/// Create a copy of ArtworkCustody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtworkCustodyCopyWith<_ArtworkCustody> get copyWith => __$ArtworkCustodyCopyWithImpl<_ArtworkCustody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtworkCustodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtworkCustody&&(identical(other.legalOwner, legalOwner) || other.legalOwner == legalOwner)&&(identical(other.legalOwnerName, legalOwnerName) || other.legalOwnerName == legalOwnerName)&&(identical(other.custodian, custodian) || other.custodian == custodian)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,legalOwner,legalOwnerName,custodian,locationLabel);

@override
String toString() {
  return 'ArtworkCustody(legalOwner: $legalOwner, legalOwnerName: $legalOwnerName, custodian: $custodian, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class _$ArtworkCustodyCopyWith<$Res> implements $ArtworkCustodyCopyWith<$Res> {
  factory _$ArtworkCustodyCopyWith(_ArtworkCustody value, $Res Function(_ArtworkCustody) _then) = __$ArtworkCustodyCopyWithImpl;
@override @useResult
$Res call({
 CustodyParty legalOwner, String? legalOwnerName, CustodyParty custodian, String locationLabel
});




}
/// @nodoc
class __$ArtworkCustodyCopyWithImpl<$Res>
    implements _$ArtworkCustodyCopyWith<$Res> {
  __$ArtworkCustodyCopyWithImpl(this._self, this._then);

  final _ArtworkCustody _self;
  final $Res Function(_ArtworkCustody) _then;

/// Create a copy of ArtworkCustody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? legalOwner = null,Object? legalOwnerName = freezed,Object? custodian = null,Object? locationLabel = null,}) {
  return _then(_ArtworkCustody(
legalOwner: null == legalOwner ? _self.legalOwner : legalOwner // ignore: cast_nullable_to_non_nullable
as CustodyParty,legalOwnerName: freezed == legalOwnerName ? _self.legalOwnerName : legalOwnerName // ignore: cast_nullable_to_non_nullable
as String?,custodian: null == custodian ? _self.custodian : custodian // ignore: cast_nullable_to_non_nullable
as CustodyParty,locationLabel: null == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PhysicalCoaRequest {

 String get id; String get artworkId; String get artworkTitle; String get coaCertificateNumber; String get requestedByName; String get requestedAt; String get deliveryAddress; PhysicalCoaStatus get status; String? get dispatchedAt; String? get courierRef;
/// Create a copy of PhysicalCoaRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhysicalCoaRequestCopyWith<PhysicalCoaRequest> get copyWith => _$PhysicalCoaRequestCopyWithImpl<PhysicalCoaRequest>(this as PhysicalCoaRequest, _$identity);

  /// Serializes this PhysicalCoaRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhysicalCoaRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.requestedByName, requestedByName) || other.requestedByName == requestedByName)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.status, status) || other.status == status)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.courierRef, courierRef) || other.courierRef == courierRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,coaCertificateNumber,requestedByName,requestedAt,deliveryAddress,status,dispatchedAt,courierRef);

@override
String toString() {
  return 'PhysicalCoaRequest(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, coaCertificateNumber: $coaCertificateNumber, requestedByName: $requestedByName, requestedAt: $requestedAt, deliveryAddress: $deliveryAddress, status: $status, dispatchedAt: $dispatchedAt, courierRef: $courierRef)';
}


}

/// @nodoc
abstract mixin class $PhysicalCoaRequestCopyWith<$Res>  {
  factory $PhysicalCoaRequestCopyWith(PhysicalCoaRequest value, $Res Function(PhysicalCoaRequest) _then) = _$PhysicalCoaRequestCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, String artworkTitle, String coaCertificateNumber, String requestedByName, String requestedAt, String deliveryAddress, PhysicalCoaStatus status, String? dispatchedAt, String? courierRef
});




}
/// @nodoc
class _$PhysicalCoaRequestCopyWithImpl<$Res>
    implements $PhysicalCoaRequestCopyWith<$Res> {
  _$PhysicalCoaRequestCopyWithImpl(this._self, this._then);

  final PhysicalCoaRequest _self;
  final $Res Function(PhysicalCoaRequest) _then;

/// Create a copy of PhysicalCoaRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? coaCertificateNumber = null,Object? requestedByName = null,Object? requestedAt = null,Object? deliveryAddress = null,Object? status = null,Object? dispatchedAt = freezed,Object? courierRef = freezed,}) {
  return _then(PhysicalCoaRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,coaCertificateNumber: null == coaCertificateNumber ? _self.coaCertificateNumber : coaCertificateNumber // ignore: cast_nullable_to_non_nullable
as String,requestedByName: null == requestedByName ? _self.requestedByName : requestedByName // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PhysicalCoaStatus,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as String?,courierRef: freezed == courierRef ? _self.courierRef : courierRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PhysicalCoaRequest].
extension PhysicalCoaRequestPatterns on PhysicalCoaRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhysicalCoaRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhysicalCoaRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhysicalCoaRequest value)  $default,){
final _that = this;
switch (_that) {
case _PhysicalCoaRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhysicalCoaRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PhysicalCoaRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  String coaCertificateNumber,  String requestedByName,  String requestedAt,  String deliveryAddress,  PhysicalCoaStatus status,  String? dispatchedAt,  String? courierRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhysicalCoaRequest() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.coaCertificateNumber,_that.requestedByName,_that.requestedAt,_that.deliveryAddress,_that.status,_that.dispatchedAt,_that.courierRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  String coaCertificateNumber,  String requestedByName,  String requestedAt,  String deliveryAddress,  PhysicalCoaStatus status,  String? dispatchedAt,  String? courierRef)  $default,) {final _that = this;
switch (_that) {
case _PhysicalCoaRequest():
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.coaCertificateNumber,_that.requestedByName,_that.requestedAt,_that.deliveryAddress,_that.status,_that.dispatchedAt,_that.courierRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  String artworkTitle,  String coaCertificateNumber,  String requestedByName,  String requestedAt,  String deliveryAddress,  PhysicalCoaStatus status,  String? dispatchedAt,  String? courierRef)?  $default,) {final _that = this;
switch (_that) {
case _PhysicalCoaRequest() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.coaCertificateNumber,_that.requestedByName,_that.requestedAt,_that.deliveryAddress,_that.status,_that.dispatchedAt,_that.courierRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhysicalCoaRequest implements PhysicalCoaRequest {
  const _PhysicalCoaRequest({required this.id, required this.artworkId, required this.artworkTitle, required this.coaCertificateNumber, required this.requestedByName, required this.requestedAt, required this.deliveryAddress, required this.status, this.dispatchedAt, this.courierRef});
  factory _PhysicalCoaRequest.fromJson(Map<String, dynamic> json) => _$PhysicalCoaRequestFromJson(json);

@override final  String id;
@override final  String artworkId;
@override final  String artworkTitle;
@override final  String coaCertificateNumber;
@override final  String requestedByName;
@override final  String requestedAt;
@override final  String deliveryAddress;
@override final  PhysicalCoaStatus status;
@override final  String? dispatchedAt;
@override final  String? courierRef;

/// Create a copy of PhysicalCoaRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhysicalCoaRequestCopyWith<_PhysicalCoaRequest> get copyWith => __$PhysicalCoaRequestCopyWithImpl<_PhysicalCoaRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhysicalCoaRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhysicalCoaRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.coaCertificateNumber, coaCertificateNumber) || other.coaCertificateNumber == coaCertificateNumber)&&(identical(other.requestedByName, requestedByName) || other.requestedByName == requestedByName)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.status, status) || other.status == status)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.courierRef, courierRef) || other.courierRef == courierRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,coaCertificateNumber,requestedByName,requestedAt,deliveryAddress,status,dispatchedAt,courierRef);

@override
String toString() {
  return 'PhysicalCoaRequest(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, coaCertificateNumber: $coaCertificateNumber, requestedByName: $requestedByName, requestedAt: $requestedAt, deliveryAddress: $deliveryAddress, status: $status, dispatchedAt: $dispatchedAt, courierRef: $courierRef)';
}


}

/// @nodoc
abstract mixin class _$PhysicalCoaRequestCopyWith<$Res> implements $PhysicalCoaRequestCopyWith<$Res> {
  factory _$PhysicalCoaRequestCopyWith(_PhysicalCoaRequest value, $Res Function(_PhysicalCoaRequest) _then) = __$PhysicalCoaRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, String artworkTitle, String coaCertificateNumber, String requestedByName, String requestedAt, String deliveryAddress, PhysicalCoaStatus status, String? dispatchedAt, String? courierRef
});




}
/// @nodoc
class __$PhysicalCoaRequestCopyWithImpl<$Res>
    implements _$PhysicalCoaRequestCopyWith<$Res> {
  __$PhysicalCoaRequestCopyWithImpl(this._self, this._then);

  final _PhysicalCoaRequest _self;
  final $Res Function(_PhysicalCoaRequest) _then;

/// Create a copy of PhysicalCoaRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? coaCertificateNumber = null,Object? requestedByName = null,Object? requestedAt = null,Object? deliveryAddress = null,Object? status = null,Object? dispatchedAt = freezed,Object? courierRef = freezed,}) {
  return _then(_PhysicalCoaRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,coaCertificateNumber: null == coaCertificateNumber ? _self.coaCertificateNumber : coaCertificateNumber // ignore: cast_nullable_to_non_nullable
as String,requestedByName: null == requestedByName ? _self.requestedByName : requestedByName // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PhysicalCoaStatus,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as String?,courierRef: freezed == courierRef ? _self.courierRef : courierRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OwnershipTransfer {

 String get id; String get artworkId; String get artworkTitle; String get fromName; String get toName; String get toEmail; String get initiatedAt; String? get acceptedAt; String? get cancelledAt; TransferStatus get status;/// Null on records written before display rights existed — those are all
/// ownership hand-overs. Read it through [transferKindOf].
 TransferKind? get kind;/// Display transfers only: the date the display period runs to.
 String? get displayEndsAt;/// Display transfers only: set when the owner pulls the piece back early.
 String? get displayEndedAt;
/// Create a copy of OwnershipTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnershipTransferCopyWith<OwnershipTransfer> get copyWith => _$OwnershipTransferCopyWithImpl<OwnershipTransfer>(this as OwnershipTransfer, _$identity);

  /// Serializes this OwnershipTransfer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnershipTransfer&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.fromName, fromName) || other.fromName == fromName)&&(identical(other.toName, toName) || other.toName == toName)&&(identical(other.toEmail, toEmail) || other.toEmail == toEmail)&&(identical(other.initiatedAt, initiatedAt) || other.initiatedAt == initiatedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.displayEndsAt, displayEndsAt) || other.displayEndsAt == displayEndsAt)&&(identical(other.displayEndedAt, displayEndedAt) || other.displayEndedAt == displayEndedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,fromName,toName,toEmail,initiatedAt,acceptedAt,cancelledAt,status,kind,displayEndsAt,displayEndedAt);

@override
String toString() {
  return 'OwnershipTransfer(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, fromName: $fromName, toName: $toName, toEmail: $toEmail, initiatedAt: $initiatedAt, acceptedAt: $acceptedAt, cancelledAt: $cancelledAt, status: $status, kind: $kind, displayEndsAt: $displayEndsAt, displayEndedAt: $displayEndedAt)';
}


}

/// @nodoc
abstract mixin class $OwnershipTransferCopyWith<$Res>  {
  factory $OwnershipTransferCopyWith(OwnershipTransfer value, $Res Function(OwnershipTransfer) _then) = _$OwnershipTransferCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, String artworkTitle, String fromName, String toName, String toEmail, String initiatedAt, String? acceptedAt, String? cancelledAt, TransferStatus status, TransferKind? kind, String? displayEndsAt, String? displayEndedAt
});




}
/// @nodoc
class _$OwnershipTransferCopyWithImpl<$Res>
    implements $OwnershipTransferCopyWith<$Res> {
  _$OwnershipTransferCopyWithImpl(this._self, this._then);

  final OwnershipTransfer _self;
  final $Res Function(OwnershipTransfer) _then;

/// Create a copy of OwnershipTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? fromName = null,Object? toName = null,Object? toEmail = null,Object? initiatedAt = null,Object? acceptedAt = freezed,Object? cancelledAt = freezed,Object? status = null,Object? kind = freezed,Object? displayEndsAt = freezed,Object? displayEndedAt = freezed,}) {
  return _then(OwnershipTransfer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,fromName: null == fromName ? _self.fromName : fromName // ignore: cast_nullable_to_non_nullable
as String,toName: null == toName ? _self.toName : toName // ignore: cast_nullable_to_non_nullable
as String,toEmail: null == toEmail ? _self.toEmail : toEmail // ignore: cast_nullable_to_non_nullable
as String,initiatedAt: null == initiatedAt ? _self.initiatedAt : initiatedAt // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TransferKind?,displayEndsAt: freezed == displayEndsAt ? _self.displayEndsAt : displayEndsAt // ignore: cast_nullable_to_non_nullable
as String?,displayEndedAt: freezed == displayEndedAt ? _self.displayEndedAt : displayEndedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OwnershipTransfer].
extension OwnershipTransferPatterns on OwnershipTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnershipTransfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnershipTransfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnershipTransfer value)  $default,){
final _that = this;
switch (_that) {
case _OwnershipTransfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnershipTransfer value)?  $default,){
final _that = this;
switch (_that) {
case _OwnershipTransfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  String fromName,  String toName,  String toEmail,  String initiatedAt,  String? acceptedAt,  String? cancelledAt,  TransferStatus status,  TransferKind? kind,  String? displayEndsAt,  String? displayEndedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnershipTransfer() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.fromName,_that.toName,_that.toEmail,_that.initiatedAt,_that.acceptedAt,_that.cancelledAt,_that.status,_that.kind,_that.displayEndsAt,_that.displayEndedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  String fromName,  String toName,  String toEmail,  String initiatedAt,  String? acceptedAt,  String? cancelledAt,  TransferStatus status,  TransferKind? kind,  String? displayEndsAt,  String? displayEndedAt)  $default,) {final _that = this;
switch (_that) {
case _OwnershipTransfer():
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.fromName,_that.toName,_that.toEmail,_that.initiatedAt,_that.acceptedAt,_that.cancelledAt,_that.status,_that.kind,_that.displayEndsAt,_that.displayEndedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  String artworkTitle,  String fromName,  String toName,  String toEmail,  String initiatedAt,  String? acceptedAt,  String? cancelledAt,  TransferStatus status,  TransferKind? kind,  String? displayEndsAt,  String? displayEndedAt)?  $default,) {final _that = this;
switch (_that) {
case _OwnershipTransfer() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.fromName,_that.toName,_that.toEmail,_that.initiatedAt,_that.acceptedAt,_that.cancelledAt,_that.status,_that.kind,_that.displayEndsAt,_that.displayEndedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OwnershipTransfer implements OwnershipTransfer {
  const _OwnershipTransfer({required this.id, required this.artworkId, required this.artworkTitle, required this.fromName, required this.toName, required this.toEmail, required this.initiatedAt, this.acceptedAt, this.cancelledAt, required this.status, this.kind, this.displayEndsAt, this.displayEndedAt});
  factory _OwnershipTransfer.fromJson(Map<String, dynamic> json) => _$OwnershipTransferFromJson(json);

@override final  String id;
@override final  String artworkId;
@override final  String artworkTitle;
@override final  String fromName;
@override final  String toName;
@override final  String toEmail;
@override final  String initiatedAt;
@override final  String? acceptedAt;
@override final  String? cancelledAt;
@override final  TransferStatus status;
/// Null on records written before display rights existed — those are all
/// ownership hand-overs. Read it through [transferKindOf].
@override final  TransferKind? kind;
/// Display transfers only: the date the display period runs to.
@override final  String? displayEndsAt;
/// Display transfers only: set when the owner pulls the piece back early.
@override final  String? displayEndedAt;

/// Create a copy of OwnershipTransfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnershipTransferCopyWith<_OwnershipTransfer> get copyWith => __$OwnershipTransferCopyWithImpl<_OwnershipTransfer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnershipTransferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnershipTransfer&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.fromName, fromName) || other.fromName == fromName)&&(identical(other.toName, toName) || other.toName == toName)&&(identical(other.toEmail, toEmail) || other.toEmail == toEmail)&&(identical(other.initiatedAt, initiatedAt) || other.initiatedAt == initiatedAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.displayEndsAt, displayEndsAt) || other.displayEndsAt == displayEndsAt)&&(identical(other.displayEndedAt, displayEndedAt) || other.displayEndedAt == displayEndedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,fromName,toName,toEmail,initiatedAt,acceptedAt,cancelledAt,status,kind,displayEndsAt,displayEndedAt);

@override
String toString() {
  return 'OwnershipTransfer(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, fromName: $fromName, toName: $toName, toEmail: $toEmail, initiatedAt: $initiatedAt, acceptedAt: $acceptedAt, cancelledAt: $cancelledAt, status: $status, kind: $kind, displayEndsAt: $displayEndsAt, displayEndedAt: $displayEndedAt)';
}


}

/// @nodoc
abstract mixin class _$OwnershipTransferCopyWith<$Res> implements $OwnershipTransferCopyWith<$Res> {
  factory _$OwnershipTransferCopyWith(_OwnershipTransfer value, $Res Function(_OwnershipTransfer) _then) = __$OwnershipTransferCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, String artworkTitle, String fromName, String toName, String toEmail, String initiatedAt, String? acceptedAt, String? cancelledAt, TransferStatus status, TransferKind? kind, String? displayEndsAt, String? displayEndedAt
});




}
/// @nodoc
class __$OwnershipTransferCopyWithImpl<$Res>
    implements _$OwnershipTransferCopyWith<$Res> {
  __$OwnershipTransferCopyWithImpl(this._self, this._then);

  final _OwnershipTransfer _self;
  final $Res Function(_OwnershipTransfer) _then;

/// Create a copy of OwnershipTransfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? fromName = null,Object? toName = null,Object? toEmail = null,Object? initiatedAt = null,Object? acceptedAt = freezed,Object? cancelledAt = freezed,Object? status = null,Object? kind = freezed,Object? displayEndsAt = freezed,Object? displayEndedAt = freezed,}) {
  return _then(_OwnershipTransfer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,fromName: null == fromName ? _self.fromName : fromName // ignore: cast_nullable_to_non_nullable
as String,toName: null == toName ? _self.toName : toName // ignore: cast_nullable_to_non_nullable
as String,toEmail: null == toEmail ? _self.toEmail : toEmail // ignore: cast_nullable_to_non_nullable
as String,initiatedAt: null == initiatedAt ? _self.initiatedAt : initiatedAt // ignore: cast_nullable_to_non_nullable
as String,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TransferKind?,displayEndsAt: freezed == displayEndsAt ? _self.displayEndsAt : displayEndsAt // ignore: cast_nullable_to_non_nullable
as String?,displayEndedAt: freezed == displayEndedAt ? _self.displayEndedAt : displayEndedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ExternalSalePenalty {

 String get id; String get artworkId; String get artworkTitle; double get amount; String get createdAt; String? get settledAt;
/// Create a copy of ExternalSalePenalty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExternalSalePenaltyCopyWith<ExternalSalePenalty> get copyWith => _$ExternalSalePenaltyCopyWithImpl<ExternalSalePenalty>(this as ExternalSalePenalty, _$identity);

  /// Serializes this ExternalSalePenalty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExternalSalePenalty&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.settledAt, settledAt) || other.settledAt == settledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,amount,createdAt,settledAt);

@override
String toString() {
  return 'ExternalSalePenalty(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, amount: $amount, createdAt: $createdAt, settledAt: $settledAt)';
}


}

/// @nodoc
abstract mixin class $ExternalSalePenaltyCopyWith<$Res>  {
  factory $ExternalSalePenaltyCopyWith(ExternalSalePenalty value, $Res Function(ExternalSalePenalty) _then) = _$ExternalSalePenaltyCopyWithImpl;
@useResult
$Res call({
 String id, String artworkId, String artworkTitle, double amount, String createdAt, String? settledAt
});




}
/// @nodoc
class _$ExternalSalePenaltyCopyWithImpl<$Res>
    implements $ExternalSalePenaltyCopyWith<$Res> {
  _$ExternalSalePenaltyCopyWithImpl(this._self, this._then);

  final ExternalSalePenalty _self;
  final $Res Function(ExternalSalePenalty) _then;

/// Create a copy of ExternalSalePenalty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? amount = null,Object? createdAt = null,Object? settledAt = freezed,}) {
  return _then(ExternalSalePenalty(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExternalSalePenalty].
extension ExternalSalePenaltyPatterns on ExternalSalePenalty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExternalSalePenalty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExternalSalePenalty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExternalSalePenalty value)  $default,){
final _that = this;
switch (_that) {
case _ExternalSalePenalty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExternalSalePenalty value)?  $default,){
final _that = this;
switch (_that) {
case _ExternalSalePenalty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  double amount,  String createdAt,  String? settledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExternalSalePenalty() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.amount,_that.createdAt,_that.settledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artworkId,  String artworkTitle,  double amount,  String createdAt,  String? settledAt)  $default,) {final _that = this;
switch (_that) {
case _ExternalSalePenalty():
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.amount,_that.createdAt,_that.settledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artworkId,  String artworkTitle,  double amount,  String createdAt,  String? settledAt)?  $default,) {final _that = this;
switch (_that) {
case _ExternalSalePenalty() when $default != null:
return $default(_that.id,_that.artworkId,_that.artworkTitle,_that.amount,_that.createdAt,_that.settledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExternalSalePenalty implements ExternalSalePenalty {
  const _ExternalSalePenalty({required this.id, required this.artworkId, required this.artworkTitle, required this.amount, required this.createdAt, this.settledAt});
  factory _ExternalSalePenalty.fromJson(Map<String, dynamic> json) => _$ExternalSalePenaltyFromJson(json);

@override final  String id;
@override final  String artworkId;
@override final  String artworkTitle;
@override final  double amount;
@override final  String createdAt;
@override final  String? settledAt;

/// Create a copy of ExternalSalePenalty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExternalSalePenaltyCopyWith<_ExternalSalePenalty> get copyWith => __$ExternalSalePenaltyCopyWithImpl<_ExternalSalePenalty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExternalSalePenaltyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExternalSalePenalty&&(identical(other.id, id) || other.id == id)&&(identical(other.artworkId, artworkId) || other.artworkId == artworkId)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.settledAt, settledAt) || other.settledAt == settledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artworkId,artworkTitle,amount,createdAt,settledAt);

@override
String toString() {
  return 'ExternalSalePenalty(id: $id, artworkId: $artworkId, artworkTitle: $artworkTitle, amount: $amount, createdAt: $createdAt, settledAt: $settledAt)';
}


}

/// @nodoc
abstract mixin class _$ExternalSalePenaltyCopyWith<$Res> implements $ExternalSalePenaltyCopyWith<$Res> {
  factory _$ExternalSalePenaltyCopyWith(_ExternalSalePenalty value, $Res Function(_ExternalSalePenalty) _then) = __$ExternalSalePenaltyCopyWithImpl;
@override @useResult
$Res call({
 String id, String artworkId, String artworkTitle, double amount, String createdAt, String? settledAt
});




}
/// @nodoc
class __$ExternalSalePenaltyCopyWithImpl<$Res>
    implements _$ExternalSalePenaltyCopyWith<$Res> {
  __$ExternalSalePenaltyCopyWithImpl(this._self, this._then);

  final _ExternalSalePenalty _self;
  final $Res Function(_ExternalSalePenalty) _then;

/// Create a copy of ExternalSalePenalty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artworkId = null,Object? artworkTitle = null,Object? amount = null,Object? createdAt = null,Object? settledAt = freezed,}) {
  return _then(_ExternalSalePenalty(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artworkId: null == artworkId ? _self.artworkId : artworkId // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
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
