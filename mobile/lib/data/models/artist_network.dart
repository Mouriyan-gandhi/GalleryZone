import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_network.freezed.dart';
part 'artist_network.g.dart';

/// Artist ratings, artist-to-artist connections, and the collaborations that
/// grow out of them — the Dart side of the web's `types/artist-network.ts`.
/// One file because they are one story: a collector rates an artist, artists
/// connect with each other, and a connection is what makes a collaboration
/// possible.

@freezed
abstract class ArtistReview with _$ArtistReview {
  const factory ArtistReview({
    required String id,
    required String artistId,
    required String reviewerName,

    /// 1–5. Kept as an int rather than an enum so it can be summed.
    required int rating,
    required String comment,

    /// The piece the review is about — a rating is always earned on a sale.
    required String artworkTitle,
    required String createdAt,
  }) = _ArtistReview;

  factory ArtistReview.fromJson(Map<String, dynamic> json) =>
      _$ArtistReviewFromJson(json);
}

@freezed
abstract class ArtistRating with _$ArtistRating {
  const factory ArtistRating({
    required String artistId,

    /// Mean of every review, to one decimal. 0 when there are none.
    required double average,
    required int count,

    /// How many reviews sat at each star, keyed 1–5.
    required Map<int, int> breakdown,
  }) = _ArtistRating;
}

const starValues = [5, 4, 3, 2, 1];

/// The one place that turns reviews into a score. The dashboard card and any
/// future public badge both call this, so they cannot disagree about what
/// "4.6" means.
ArtistRating summarizeRating(String artistId, List<ArtistReview> reviews) {
  final mine = reviews.where((r) => r.artistId == artistId).toList();
  final breakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  for (final review in mine) {
    breakdown[review.rating] = (breakdown[review.rating] ?? 0) + 1;
  }

  if (mine.isEmpty) {
    return ArtistRating(
      artistId: artistId,
      average: 0,
      count: 0,
      breakdown: breakdown,
    );
  }

  final total = mine.fold<int>(0, (sum, r) => sum + r.rating);
  return ArtistRating(
    artistId: artistId,
    average: (total / mine.length * 10).round() / 10,
    count: mine.length,
    breakdown: breakdown,
  );
}

enum ConnectionStatus { pending, accepted, declined }

/// Stored once per pair, from the sender's point of view. Whether it reads as
/// incoming or outgoing depends on who is looking — see [connectionDirection].
@freezed
abstract class ArtistConnection with _$ArtistConnection {
  const factory ArtistConnection({
    required String id,
    required String requesterId,
    required String requesterName,
    required String requesterAvatar,
    required String recipientId,
    required String recipientName,
    required String recipientAvatar,
    required ConnectionStatus status,

    /// Optional note the requester attached.
    required String message,
    required String requestedAt,
    String? respondedAt,
  }) = _ArtistConnection;

  factory ArtistConnection.fromJson(Map<String, dynamic> json) =>
      _$ArtistConnectionFromJson(json);
}

enum ConnectionDirection { incoming, outgoing }

ConnectionDirection connectionDirection(
  ArtistConnection connection,
  String viewerId,
) => connection.recipientId == viewerId
    ? ConnectionDirection.incoming
    : ConnectionDirection.outgoing;

/// The other person, whichever end of the request the viewer is on.
({String id, String name, String avatar}) connectionPeer(
  ArtistConnection connection,
  String viewerId,
) => connection.recipientId == viewerId
    ? (
        id: connection.requesterId,
        name: connection.requesterName,
        avatar: connection.requesterAvatar,
      )
    : (
        id: connection.recipientId,
        name: connection.recipientName,
        avatar: connection.recipientAvatar,
      );

bool involvesArtist(ArtistConnection connection, String artistId) =>
    connection.requesterId == artistId || connection.recipientId == artistId;

enum CollaborationStatus { proposed, active, completed, declined }

const collaborationStatusLabel = {
  CollaborationStatus.proposed: 'Proposed',
  CollaborationStatus.active: 'Active',
  CollaborationStatus.completed: 'Completed',
  CollaborationStatus.declined: 'Declined',
};

/// A joint piece or show between two artists who are already connected. Same
/// two-sided storage as a connection: one record, read from either end.
@freezed
abstract class ArtistCollaboration with _$ArtistCollaboration {
  const factory ArtistCollaboration({
    required String id,
    required String proposerId,
    required String proposerName,
    required String partnerId,
    required String partnerName,
    required String title,
    required String brief,
    required CollaborationStatus status,
    required String proposedAt,
    String? respondedAt,
  }) = _ArtistCollaboration;

  factory ArtistCollaboration.fromJson(Map<String, dynamic> json) =>
      _$ArtistCollaborationFromJson(json);
}

String collaborationPeerName(
  ArtistCollaboration collaboration,
  String viewerId,
) => collaboration.proposerId == viewerId
    ? collaboration.partnerName
    : collaboration.proposerName;

/// Closing an account is not self-service: the artist asks, an admin decides.
/// This app has no admin portal, so a request made here waits to be decided in
/// the web console — the artist side is all that exists on the phone.
enum DeactivationStatus { pending, approved, rejected }

@freezed
abstract class DeactivationRequest with _$DeactivationRequest {
  const factory DeactivationRequest({
    required String id,
    required String userId,
    required String userName,
    required String reason,
    required DeactivationStatus status,
    required String requestedAt,
    String? decidedAt,

    /// Why an admin refused, shown back to the artist.
    String? decisionNote,
  }) = _DeactivationRequest;

  factory DeactivationRequest.fromJson(Map<String, dynamic> json) =>
      _$DeactivationRequestFromJson(json);
}
