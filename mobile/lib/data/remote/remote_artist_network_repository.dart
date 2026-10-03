import '../../core/api/api_client.dart';
import '../../core/api/json_utils.dart';
import '../models/artist_network.dart';
import '../repositories/artist_network_repository.dart';
import 'mappers/portal_mappers.dart';

/// What the API offers of the artist "network" — which is, today, only the
/// closing of an account. The website matches this exactly:
///
///  * collector reviews aren't collected yet, so every artist has an honest
///    zero, never a made-up score;
///  * artist-to-artist connections have no routes ("coming soon");
///  * collaborations were removed from the product (27 Aug 2026) - and so
///    from this app;
///  * deactivation is a real request that an admin decides.
class RemoteArtistNetworkRepository implements ArtistNetworkRepository {
  RemoteArtistNetworkRepository(this.api);

  final ApiClient api;

  static const _connectionsSoon = 'Artist connections are coming soon.';

  @override
  Future<ArtistRating> getRating(String artistId) async => summarizeRating(artistId, const []);

  @override
  Future<List<ArtistReview>> listReviews(String artistId) async => const [];

  @override
  Future<List<ArtistConnection>> listConnections(String artistId) async => const [];

  @override
  Future<ArtistConnection?> getConnectionWith(String viewerId, String peerId) async => null;

  @override
  Future<ArtistConnection> sendConnectionRequest({
    required String requesterId,
    required String recipientId,
    String message = '',
  }) =>
      Future.error(Exception(_connectionsSoon));

  @override
  Future<ArtistConnection> respondToConnection({
    required String connectionId,
    required String viewerId,
    required bool accept,
  }) =>
      Future.error(Exception(_connectionsSoon));

  // --- Closing an account --------------------------------------------------------------

  /// Asking is all the artist can do. An admin decides, because a closing
  /// account may still owe a settlement, hold a piece with an aggregator, or
  /// have a transfer someone is waiting to accept.
  @override
  Future<DeactivationRequest?> getDeactivationRequest() async {
    final json = await api.getMap('/v1/artist/deactivation');
    final request = json['request'];
    return request is Map ? deactivationFromApi(asMap(request)) : null;
  }

  @override
  Future<DeactivationRequest> requestDeactivation({required String reason}) async {
    if (reason.trim().isEmpty) {
      throw Exception("Tell us why you're leaving so an admin can review it");
    }
    await api.post('/v1/artist/deactivation', body: {'reason': reason.trim()});
    final request = await getDeactivationRequest();
    if (request == null) throw Exception('The request was not recorded');
    return request;
  }

  /// Withdrawing a pending request isn't a server operation. Surfaced as a
  /// plain message, not a silent no-op.
  @override
  Future<void> withdrawDeactivation(String requestId) =>
      Future.error(Exception('Contact support to withdraw a pending deactivation request'));
}
