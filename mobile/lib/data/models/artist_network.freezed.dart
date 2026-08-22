// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_network.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistReview {

 String get id; String get artistId; String get reviewerName;/// 1–5. Kept as an int rather than an enum so it can be summed.
 int get rating; String get comment;/// The piece the review is about — a rating is always earned on a sale.
 String get artworkTitle; String get createdAt;
/// Create a copy of ArtistReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistReviewCopyWith<ArtistReview> get copyWith => _$ArtistReviewCopyWithImpl<ArtistReview>(this as ArtistReview, _$identity);

  /// Serializes this ArtistReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistReview&&(identical(other.id, id) || other.id == id)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artistId,reviewerName,rating,comment,artworkTitle,createdAt);

@override
String toString() {
  return 'ArtistReview(id: $id, artistId: $artistId, reviewerName: $reviewerName, rating: $rating, comment: $comment, artworkTitle: $artworkTitle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ArtistReviewCopyWith<$Res>  {
  factory $ArtistReviewCopyWith(ArtistReview value, $Res Function(ArtistReview) _then) = _$ArtistReviewCopyWithImpl;
@useResult
$Res call({
 String id, String artistId, String reviewerName, int rating, String comment, String artworkTitle, String createdAt
});




}
/// @nodoc
class _$ArtistReviewCopyWithImpl<$Res>
    implements $ArtistReviewCopyWith<$Res> {
  _$ArtistReviewCopyWithImpl(this._self, this._then);

  final ArtistReview _self;
  final $Res Function(ArtistReview) _then;

/// Create a copy of ArtistReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? artistId = null,Object? reviewerName = null,Object? rating = null,Object? comment = null,Object? artworkTitle = null,Object? createdAt = null,}) {
  return _then(ArtistReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistReview].
extension ArtistReviewPatterns on ArtistReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistReview value)  $default,){
final _that = this;
switch (_that) {
case _ArtistReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistReview value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String artistId,  String reviewerName,  int rating,  String comment,  String artworkTitle,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistReview() when $default != null:
return $default(_that.id,_that.artistId,_that.reviewerName,_that.rating,_that.comment,_that.artworkTitle,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String artistId,  String reviewerName,  int rating,  String comment,  String artworkTitle,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _ArtistReview():
return $default(_that.id,_that.artistId,_that.reviewerName,_that.rating,_that.comment,_that.artworkTitle,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String artistId,  String reviewerName,  int rating,  String comment,  String artworkTitle,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ArtistReview() when $default != null:
return $default(_that.id,_that.artistId,_that.reviewerName,_that.rating,_that.comment,_that.artworkTitle,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistReview implements ArtistReview {
  const _ArtistReview({required this.id, required this.artistId, required this.reviewerName, required this.rating, required this.comment, required this.artworkTitle, required this.createdAt});
  factory _ArtistReview.fromJson(Map<String, dynamic> json) => _$ArtistReviewFromJson(json);

@override final  String id;
@override final  String artistId;
@override final  String reviewerName;
/// 1–5. Kept as an int rather than an enum so it can be summed.
@override final  int rating;
@override final  String comment;
/// The piece the review is about — a rating is always earned on a sale.
@override final  String artworkTitle;
@override final  String createdAt;

/// Create a copy of ArtistReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistReviewCopyWith<_ArtistReview> get copyWith => __$ArtistReviewCopyWithImpl<_ArtistReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistReview&&(identical(other.id, id) || other.id == id)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.artworkTitle, artworkTitle) || other.artworkTitle == artworkTitle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,artistId,reviewerName,rating,comment,artworkTitle,createdAt);

@override
String toString() {
  return 'ArtistReview(id: $id, artistId: $artistId, reviewerName: $reviewerName, rating: $rating, comment: $comment, artworkTitle: $artworkTitle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ArtistReviewCopyWith<$Res> implements $ArtistReviewCopyWith<$Res> {
  factory _$ArtistReviewCopyWith(_ArtistReview value, $Res Function(_ArtistReview) _then) = __$ArtistReviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String artistId, String reviewerName, int rating, String comment, String artworkTitle, String createdAt
});




}
/// @nodoc
class __$ArtistReviewCopyWithImpl<$Res>
    implements _$ArtistReviewCopyWith<$Res> {
  __$ArtistReviewCopyWithImpl(this._self, this._then);

  final _ArtistReview _self;
  final $Res Function(_ArtistReview) _then;

/// Create a copy of ArtistReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? artistId = null,Object? reviewerName = null,Object? rating = null,Object? comment = null,Object? artworkTitle = null,Object? createdAt = null,}) {
  return _then(_ArtistReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,artworkTitle: null == artworkTitle ? _self.artworkTitle : artworkTitle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ArtistRating {

 String get artistId;/// Mean of every review, to one decimal. 0 when there are none.
 double get average; int get count;/// How many reviews sat at each star, keyed 1–5.
 Map<int, int> get breakdown;
/// Create a copy of ArtistRating
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistRatingCopyWith<ArtistRating> get copyWith => _$ArtistRatingCopyWithImpl<ArtistRating>(this as ArtistRating, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistRating&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.average, average) || other.average == average)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.breakdown, breakdown));
}


@override
int get hashCode => Object.hash(runtimeType,artistId,average,count,const DeepCollectionEquality().hash(breakdown));

@override
String toString() {
  return 'ArtistRating(artistId: $artistId, average: $average, count: $count, breakdown: $breakdown)';
}


}

/// @nodoc
abstract mixin class $ArtistRatingCopyWith<$Res>  {
  factory $ArtistRatingCopyWith(ArtistRating value, $Res Function(ArtistRating) _then) = _$ArtistRatingCopyWithImpl;
@useResult
$Res call({
 String artistId, double average, int count, Map<int, int> breakdown
});




}
/// @nodoc
class _$ArtistRatingCopyWithImpl<$Res>
    implements $ArtistRatingCopyWith<$Res> {
  _$ArtistRatingCopyWithImpl(this._self, this._then);

  final ArtistRating _self;
  final $Res Function(ArtistRating) _then;

/// Create a copy of ArtistRating
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistId = null,Object? average = null,Object? count = null,Object? breakdown = null,}) {
  return _then(ArtistRating(
artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,average: null == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistRating].
extension ArtistRatingPatterns on ArtistRating {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistRating value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistRating() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistRating value)  $default,){
final _that = this;
switch (_that) {
case _ArtistRating():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistRating value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistRating() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String artistId,  double average,  int count,  Map<int, int> breakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistRating() when $default != null:
return $default(_that.artistId,_that.average,_that.count,_that.breakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String artistId,  double average,  int count,  Map<int, int> breakdown)  $default,) {final _that = this;
switch (_that) {
case _ArtistRating():
return $default(_that.artistId,_that.average,_that.count,_that.breakdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String artistId,  double average,  int count,  Map<int, int> breakdown)?  $default,) {final _that = this;
switch (_that) {
case _ArtistRating() when $default != null:
return $default(_that.artistId,_that.average,_that.count,_that.breakdown);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistRating implements ArtistRating {
  const _ArtistRating({required this.artistId, required this.average, required this.count, required  Map<int, int> breakdown}): _breakdown = breakdown;
  

@override final  String artistId;
/// Mean of every review, to one decimal. 0 when there are none.
@override final  double average;
@override final  int count;
/// How many reviews sat at each star, keyed 1–5.
 final  Map<int, int> _breakdown;
/// How many reviews sat at each star, keyed 1–5.
@override Map<int, int> get breakdown {
  if (_breakdown is EqualUnmodifiableMapView) return _breakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_breakdown);
}


/// Create a copy of ArtistRating
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistRatingCopyWith<_ArtistRating> get copyWith => __$ArtistRatingCopyWithImpl<_ArtistRating>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistRating&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.average, average) || other.average == average)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._breakdown, _breakdown));
}


@override
int get hashCode => Object.hash(runtimeType,artistId,average,count,const DeepCollectionEquality().hash(_breakdown));

@override
String toString() {
  return 'ArtistRating(artistId: $artistId, average: $average, count: $count, breakdown: $breakdown)';
}


}

/// @nodoc
abstract mixin class _$ArtistRatingCopyWith<$Res> implements $ArtistRatingCopyWith<$Res> {
  factory _$ArtistRatingCopyWith(_ArtistRating value, $Res Function(_ArtistRating) _then) = __$ArtistRatingCopyWithImpl;
@override @useResult
$Res call({
 String artistId, double average, int count, Map<int, int> breakdown
});




}
/// @nodoc
class __$ArtistRatingCopyWithImpl<$Res>
    implements _$ArtistRatingCopyWith<$Res> {
  __$ArtistRatingCopyWithImpl(this._self, this._then);

  final _ArtistRating _self;
  final $Res Function(_ArtistRating) _then;

/// Create a copy of ArtistRating
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artistId = null,Object? average = null,Object? count = null,Object? breakdown = null,}) {
  return _then(_ArtistRating(
artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,average: null == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,breakdown: null == breakdown ? _self._breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}


}


/// @nodoc
mixin _$ArtistConnection {

 String get id; String get requesterId; String get requesterName; String get requesterAvatar; String get recipientId; String get recipientName; String get recipientAvatar; ConnectionStatus get status;/// Optional note the requester attached.
 String get message; String get requestedAt; String? get respondedAt;
/// Create a copy of ArtistConnection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistConnectionCopyWith<ArtistConnection> get copyWith => _$ArtistConnectionCopyWithImpl<ArtistConnection>(this as ArtistConnection, _$identity);

  /// Serializes this ArtistConnection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.requesterName, requesterName) || other.requesterName == requesterName)&&(identical(other.requesterAvatar, requesterAvatar) || other.requesterAvatar == requesterAvatar)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientAvatar, recipientAvatar) || other.recipientAvatar == recipientAvatar)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,requesterId,requesterName,requesterAvatar,recipientId,recipientName,recipientAvatar,status,message,requestedAt,respondedAt);

@override
String toString() {
  return 'ArtistConnection(id: $id, requesterId: $requesterId, requesterName: $requesterName, requesterAvatar: $requesterAvatar, recipientId: $recipientId, recipientName: $recipientName, recipientAvatar: $recipientAvatar, status: $status, message: $message, requestedAt: $requestedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $ArtistConnectionCopyWith<$Res>  {
  factory $ArtistConnectionCopyWith(ArtistConnection value, $Res Function(ArtistConnection) _then) = _$ArtistConnectionCopyWithImpl;
@useResult
$Res call({
 String id, String requesterId, String requesterName, String requesterAvatar, String recipientId, String recipientName, String recipientAvatar, ConnectionStatus status, String message, String requestedAt, String? respondedAt
});




}
/// @nodoc
class _$ArtistConnectionCopyWithImpl<$Res>
    implements $ArtistConnectionCopyWith<$Res> {
  _$ArtistConnectionCopyWithImpl(this._self, this._then);

  final ArtistConnection _self;
  final $Res Function(ArtistConnection) _then;

/// Create a copy of ArtistConnection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requesterId = null,Object? requesterName = null,Object? requesterAvatar = null,Object? recipientId = null,Object? recipientName = null,Object? recipientAvatar = null,Object? status = null,Object? message = null,Object? requestedAt = null,Object? respondedAt = freezed,}) {
  return _then(ArtistConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String,requesterName: null == requesterName ? _self.requesterName : requesterName // ignore: cast_nullable_to_non_nullable
as String,requesterAvatar: null == requesterAvatar ? _self.requesterAvatar : requesterAvatar // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,recipientAvatar: null == recipientAvatar ? _self.recipientAvatar : recipientAvatar // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistConnection].
extension ArtistConnectionPatterns on ArtistConnection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistConnection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistConnection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistConnection value)  $default,){
final _that = this;
switch (_that) {
case _ArtistConnection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistConnection value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistConnection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String requesterId,  String requesterName,  String requesterAvatar,  String recipientId,  String recipientName,  String recipientAvatar,  ConnectionStatus status,  String message,  String requestedAt,  String? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistConnection() when $default != null:
return $default(_that.id,_that.requesterId,_that.requesterName,_that.requesterAvatar,_that.recipientId,_that.recipientName,_that.recipientAvatar,_that.status,_that.message,_that.requestedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String requesterId,  String requesterName,  String requesterAvatar,  String recipientId,  String recipientName,  String recipientAvatar,  ConnectionStatus status,  String message,  String requestedAt,  String? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _ArtistConnection():
return $default(_that.id,_that.requesterId,_that.requesterName,_that.requesterAvatar,_that.recipientId,_that.recipientName,_that.recipientAvatar,_that.status,_that.message,_that.requestedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String requesterId,  String requesterName,  String requesterAvatar,  String recipientId,  String recipientName,  String recipientAvatar,  ConnectionStatus status,  String message,  String requestedAt,  String? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _ArtistConnection() when $default != null:
return $default(_that.id,_that.requesterId,_that.requesterName,_that.requesterAvatar,_that.recipientId,_that.recipientName,_that.recipientAvatar,_that.status,_that.message,_that.requestedAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistConnection implements ArtistConnection {
  const _ArtistConnection({required this.id, required this.requesterId, required this.requesterName, required this.requesterAvatar, required this.recipientId, required this.recipientName, required this.recipientAvatar, required this.status, required this.message, required this.requestedAt, this.respondedAt});
  factory _ArtistConnection.fromJson(Map<String, dynamic> json) => _$ArtistConnectionFromJson(json);

@override final  String id;
@override final  String requesterId;
@override final  String requesterName;
@override final  String requesterAvatar;
@override final  String recipientId;
@override final  String recipientName;
@override final  String recipientAvatar;
@override final  ConnectionStatus status;
/// Optional note the requester attached.
@override final  String message;
@override final  String requestedAt;
@override final  String? respondedAt;

/// Create a copy of ArtistConnection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistConnectionCopyWith<_ArtistConnection> get copyWith => __$ArtistConnectionCopyWithImpl<_ArtistConnection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistConnection&&(identical(other.id, id) || other.id == id)&&(identical(other.requesterId, requesterId) || other.requesterId == requesterId)&&(identical(other.requesterName, requesterName) || other.requesterName == requesterName)&&(identical(other.requesterAvatar, requesterAvatar) || other.requesterAvatar == requesterAvatar)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientAvatar, recipientAvatar) || other.recipientAvatar == recipientAvatar)&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,requesterId,requesterName,requesterAvatar,recipientId,recipientName,recipientAvatar,status,message,requestedAt,respondedAt);

@override
String toString() {
  return 'ArtistConnection(id: $id, requesterId: $requesterId, requesterName: $requesterName, requesterAvatar: $requesterAvatar, recipientId: $recipientId, recipientName: $recipientName, recipientAvatar: $recipientAvatar, status: $status, message: $message, requestedAt: $requestedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$ArtistConnectionCopyWith<$Res> implements $ArtistConnectionCopyWith<$Res> {
  factory _$ArtistConnectionCopyWith(_ArtistConnection value, $Res Function(_ArtistConnection) _then) = __$ArtistConnectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String requesterId, String requesterName, String requesterAvatar, String recipientId, String recipientName, String recipientAvatar, ConnectionStatus status, String message, String requestedAt, String? respondedAt
});




}
/// @nodoc
class __$ArtistConnectionCopyWithImpl<$Res>
    implements _$ArtistConnectionCopyWith<$Res> {
  __$ArtistConnectionCopyWithImpl(this._self, this._then);

  final _ArtistConnection _self;
  final $Res Function(_ArtistConnection) _then;

/// Create a copy of ArtistConnection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requesterId = null,Object? requesterName = null,Object? requesterAvatar = null,Object? recipientId = null,Object? recipientName = null,Object? recipientAvatar = null,Object? status = null,Object? message = null,Object? requestedAt = null,Object? respondedAt = freezed,}) {
  return _then(_ArtistConnection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requesterId: null == requesterId ? _self.requesterId : requesterId // ignore: cast_nullable_to_non_nullable
as String,requesterName: null == requesterName ? _self.requesterName : requesterName // ignore: cast_nullable_to_non_nullable
as String,requesterAvatar: null == requesterAvatar ? _self.requesterAvatar : requesterAvatar // ignore: cast_nullable_to_non_nullable
as String,recipientId: null == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as String,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,recipientAvatar: null == recipientAvatar ? _self.recipientAvatar : recipientAvatar // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ArtistCollaboration {

 String get id; String get proposerId; String get proposerName; String get partnerId; String get partnerName; String get title; String get brief; CollaborationStatus get status; String get proposedAt; String? get respondedAt;
/// Create a copy of ArtistCollaboration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistCollaborationCopyWith<ArtistCollaboration> get copyWith => _$ArtistCollaborationCopyWithImpl<ArtistCollaboration>(this as ArtistCollaboration, _$identity);

  /// Serializes this ArtistCollaboration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistCollaboration&&(identical(other.id, id) || other.id == id)&&(identical(other.proposerId, proposerId) || other.proposerId == proposerId)&&(identical(other.proposerName, proposerName) || other.proposerName == proposerName)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.partnerName, partnerName) || other.partnerName == partnerName)&&(identical(other.title, title) || other.title == title)&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.status, status) || other.status == status)&&(identical(other.proposedAt, proposedAt) || other.proposedAt == proposedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,proposerId,proposerName,partnerId,partnerName,title,brief,status,proposedAt,respondedAt);

@override
String toString() {
  return 'ArtistCollaboration(id: $id, proposerId: $proposerId, proposerName: $proposerName, partnerId: $partnerId, partnerName: $partnerName, title: $title, brief: $brief, status: $status, proposedAt: $proposedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $ArtistCollaborationCopyWith<$Res>  {
  factory $ArtistCollaborationCopyWith(ArtistCollaboration value, $Res Function(ArtistCollaboration) _then) = _$ArtistCollaborationCopyWithImpl;
@useResult
$Res call({
 String id, String proposerId, String proposerName, String partnerId, String partnerName, String title, String brief, CollaborationStatus status, String proposedAt, String? respondedAt
});




}
/// @nodoc
class _$ArtistCollaborationCopyWithImpl<$Res>
    implements $ArtistCollaborationCopyWith<$Res> {
  _$ArtistCollaborationCopyWithImpl(this._self, this._then);

  final ArtistCollaboration _self;
  final $Res Function(ArtistCollaboration) _then;

/// Create a copy of ArtistCollaboration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? proposerId = null,Object? proposerName = null,Object? partnerId = null,Object? partnerName = null,Object? title = null,Object? brief = null,Object? status = null,Object? proposedAt = null,Object? respondedAt = freezed,}) {
  return _then(ArtistCollaboration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,proposerId: null == proposerId ? _self.proposerId : proposerId // ignore: cast_nullable_to_non_nullable
as String,proposerName: null == proposerName ? _self.proposerName : proposerName // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,partnerName: null == partnerName ? _self.partnerName : partnerName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CollaborationStatus,proposedAt: null == proposedAt ? _self.proposedAt : proposedAt // ignore: cast_nullable_to_non_nullable
as String,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistCollaboration].
extension ArtistCollaborationPatterns on ArtistCollaboration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistCollaboration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistCollaboration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistCollaboration value)  $default,){
final _that = this;
switch (_that) {
case _ArtistCollaboration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistCollaboration value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistCollaboration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String proposerId,  String proposerName,  String partnerId,  String partnerName,  String title,  String brief,  CollaborationStatus status,  String proposedAt,  String? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistCollaboration() when $default != null:
return $default(_that.id,_that.proposerId,_that.proposerName,_that.partnerId,_that.partnerName,_that.title,_that.brief,_that.status,_that.proposedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String proposerId,  String proposerName,  String partnerId,  String partnerName,  String title,  String brief,  CollaborationStatus status,  String proposedAt,  String? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _ArtistCollaboration():
return $default(_that.id,_that.proposerId,_that.proposerName,_that.partnerId,_that.partnerName,_that.title,_that.brief,_that.status,_that.proposedAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String proposerId,  String proposerName,  String partnerId,  String partnerName,  String title,  String brief,  CollaborationStatus status,  String proposedAt,  String? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _ArtistCollaboration() when $default != null:
return $default(_that.id,_that.proposerId,_that.proposerName,_that.partnerId,_that.partnerName,_that.title,_that.brief,_that.status,_that.proposedAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistCollaboration implements ArtistCollaboration {
  const _ArtistCollaboration({required this.id, required this.proposerId, required this.proposerName, required this.partnerId, required this.partnerName, required this.title, required this.brief, required this.status, required this.proposedAt, this.respondedAt});
  factory _ArtistCollaboration.fromJson(Map<String, dynamic> json) => _$ArtistCollaborationFromJson(json);

@override final  String id;
@override final  String proposerId;
@override final  String proposerName;
@override final  String partnerId;
@override final  String partnerName;
@override final  String title;
@override final  String brief;
@override final  CollaborationStatus status;
@override final  String proposedAt;
@override final  String? respondedAt;

/// Create a copy of ArtistCollaboration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistCollaborationCopyWith<_ArtistCollaboration> get copyWith => __$ArtistCollaborationCopyWithImpl<_ArtistCollaboration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistCollaborationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistCollaboration&&(identical(other.id, id) || other.id == id)&&(identical(other.proposerId, proposerId) || other.proposerId == proposerId)&&(identical(other.proposerName, proposerName) || other.proposerName == proposerName)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.partnerName, partnerName) || other.partnerName == partnerName)&&(identical(other.title, title) || other.title == title)&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.status, status) || other.status == status)&&(identical(other.proposedAt, proposedAt) || other.proposedAt == proposedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,proposerId,proposerName,partnerId,partnerName,title,brief,status,proposedAt,respondedAt);

@override
String toString() {
  return 'ArtistCollaboration(id: $id, proposerId: $proposerId, proposerName: $proposerName, partnerId: $partnerId, partnerName: $partnerName, title: $title, brief: $brief, status: $status, proposedAt: $proposedAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$ArtistCollaborationCopyWith<$Res> implements $ArtistCollaborationCopyWith<$Res> {
  factory _$ArtistCollaborationCopyWith(_ArtistCollaboration value, $Res Function(_ArtistCollaboration) _then) = __$ArtistCollaborationCopyWithImpl;
@override @useResult
$Res call({
 String id, String proposerId, String proposerName, String partnerId, String partnerName, String title, String brief, CollaborationStatus status, String proposedAt, String? respondedAt
});




}
/// @nodoc
class __$ArtistCollaborationCopyWithImpl<$Res>
    implements _$ArtistCollaborationCopyWith<$Res> {
  __$ArtistCollaborationCopyWithImpl(this._self, this._then);

  final _ArtistCollaboration _self;
  final $Res Function(_ArtistCollaboration) _then;

/// Create a copy of ArtistCollaboration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? proposerId = null,Object? proposerName = null,Object? partnerId = null,Object? partnerName = null,Object? title = null,Object? brief = null,Object? status = null,Object? proposedAt = null,Object? respondedAt = freezed,}) {
  return _then(_ArtistCollaboration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,proposerId: null == proposerId ? _self.proposerId : proposerId // ignore: cast_nullable_to_non_nullable
as String,proposerName: null == proposerName ? _self.proposerName : proposerName // ignore: cast_nullable_to_non_nullable
as String,partnerId: null == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String,partnerName: null == partnerName ? _self.partnerName : partnerName // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CollaborationStatus,proposedAt: null == proposedAt ? _self.proposedAt : proposedAt // ignore: cast_nullable_to_non_nullable
as String,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DeactivationRequest {

 String get id; String get userId; String get userName; String get reason; DeactivationStatus get status; String get requestedAt; String? get decidedAt;/// Why an admin refused, shown back to the artist.
 String? get decisionNote;
/// Create a copy of DeactivationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeactivationRequestCopyWith<DeactivationRequest> get copyWith => _$DeactivationRequestCopyWithImpl<DeactivationRequest>(this as DeactivationRequest, _$identity);

  /// Serializes this DeactivationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeactivationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,reason,status,requestedAt,decidedAt,decisionNote);

@override
String toString() {
  return 'DeactivationRequest(id: $id, userId: $userId, userName: $userName, reason: $reason, status: $status, requestedAt: $requestedAt, decidedAt: $decidedAt, decisionNote: $decisionNote)';
}


}

/// @nodoc
abstract mixin class $DeactivationRequestCopyWith<$Res>  {
  factory $DeactivationRequestCopyWith(DeactivationRequest value, $Res Function(DeactivationRequest) _then) = _$DeactivationRequestCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String userName, String reason, DeactivationStatus status, String requestedAt, String? decidedAt, String? decisionNote
});




}
/// @nodoc
class _$DeactivationRequestCopyWithImpl<$Res>
    implements $DeactivationRequestCopyWith<$Res> {
  _$DeactivationRequestCopyWithImpl(this._self, this._then);

  final DeactivationRequest _self;
  final $Res Function(DeactivationRequest) _then;

/// Create a copy of DeactivationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? reason = null,Object? status = null,Object? requestedAt = null,Object? decidedAt = freezed,Object? decisionNote = freezed,}) {
  return _then(DeactivationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeactivationStatus,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeactivationRequest].
extension DeactivationRequestPatterns on DeactivationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeactivationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeactivationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeactivationRequest value)  $default,){
final _that = this;
switch (_that) {
case _DeactivationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeactivationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _DeactivationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String userName,  String reason,  DeactivationStatus status,  String requestedAt,  String? decidedAt,  String? decisionNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeactivationRequest() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.reason,_that.status,_that.requestedAt,_that.decidedAt,_that.decisionNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String userName,  String reason,  DeactivationStatus status,  String requestedAt,  String? decidedAt,  String? decisionNote)  $default,) {final _that = this;
switch (_that) {
case _DeactivationRequest():
return $default(_that.id,_that.userId,_that.userName,_that.reason,_that.status,_that.requestedAt,_that.decidedAt,_that.decisionNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String userName,  String reason,  DeactivationStatus status,  String requestedAt,  String? decidedAt,  String? decisionNote)?  $default,) {final _that = this;
switch (_that) {
case _DeactivationRequest() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.reason,_that.status,_that.requestedAt,_that.decidedAt,_that.decisionNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeactivationRequest implements DeactivationRequest {
  const _DeactivationRequest({required this.id, required this.userId, required this.userName, required this.reason, required this.status, required this.requestedAt, this.decidedAt, this.decisionNote});
  factory _DeactivationRequest.fromJson(Map<String, dynamic> json) => _$DeactivationRequestFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String userName;
@override final  String reason;
@override final  DeactivationStatus status;
@override final  String requestedAt;
@override final  String? decidedAt;
/// Why an admin refused, shown back to the artist.
@override final  String? decisionNote;

/// Create a copy of DeactivationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeactivationRequestCopyWith<_DeactivationRequest> get copyWith => __$DeactivationRequestCopyWithImpl<_DeactivationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeactivationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeactivationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.decisionNote, decisionNote) || other.decisionNote == decisionNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,reason,status,requestedAt,decidedAt,decisionNote);

@override
String toString() {
  return 'DeactivationRequest(id: $id, userId: $userId, userName: $userName, reason: $reason, status: $status, requestedAt: $requestedAt, decidedAt: $decidedAt, decisionNote: $decisionNote)';
}


}

/// @nodoc
abstract mixin class _$DeactivationRequestCopyWith<$Res> implements $DeactivationRequestCopyWith<$Res> {
  factory _$DeactivationRequestCopyWith(_DeactivationRequest value, $Res Function(_DeactivationRequest) _then) = __$DeactivationRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String userName, String reason, DeactivationStatus status, String requestedAt, String? decidedAt, String? decisionNote
});




}
/// @nodoc
class __$DeactivationRequestCopyWithImpl<$Res>
    implements _$DeactivationRequestCopyWith<$Res> {
  __$DeactivationRequestCopyWithImpl(this._self, this._then);

  final _DeactivationRequest _self;
  final $Res Function(_DeactivationRequest) _then;

/// Create a copy of DeactivationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? reason = null,Object? status = null,Object? requestedAt = null,Object? decidedAt = freezed,Object? decisionNote = freezed,}) {
  return _then(_DeactivationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DeactivationStatus,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as String?,decisionNote: freezed == decisionNote ? _self.decisionNote : decisionNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
