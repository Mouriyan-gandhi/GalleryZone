import '../models/artist_network.dart';

/// Artist ratings and artist-to-artist connections - the Dart side of
/// `services/artistNetworkService.ts`.
///
/// Also carries the account-deactivation request, which is the artist's half
/// of a decision an admin makes. This app has no admin portal, so the request
/// is made here and waits; only the web console can decide it.
abstract class ArtistNetworkRepository {
  Future<ArtistRating> getRating(String artistId);

  Future<List<ArtistReview>> listReviews(String artistId);

  /// Every connection the artist is either end of, newest first.
  Future<List<ArtistConnection>> listConnections(String artistId);

  /// The viewer's connection with one other artist, if any.
  Future<ArtistConnection?> getConnectionWith(String viewerId, String peerId);

  Future<ArtistConnection> sendConnectionRequest({
    required String requesterId,
    required String recipientId,
    String message,
  });

  /// Only the recipient answers a request.
  Future<ArtistConnection> respondToConnection({
    required String connectionId,
    required String viewerId,
    required bool accept,
  });

  /// The artist's latest deactivation request, or null if they never asked.
  Future<DeactivationRequest?> getDeactivationRequest();

  Future<DeactivationRequest> requestDeactivation({required String reason});

  Future<void> withdrawDeactivation(String requestId);
}
