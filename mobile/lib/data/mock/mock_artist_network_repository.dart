import '../models/artist_network.dart';
import '../repositories/artist_network_repository.dart';
import '../storage/mock_db.dart';
import 'mock_utils.dart';
import 'seed/artist_network_seed.dart';
import 'seed/artist_seed.dart' show currentArtistId, currentArtistName;
import 'seed/artists_seed.dart';

const _reviewsKey = 'artistReviews';
const _connectionsKey = 'artistConnections';
const _deactivationKey = 'deactivationRequests';

/// Port of `services/artistNetworkService.ts`. The rules live here, not in the
/// widgets, so a screen that forgets to hide a button still cannot get around
/// them.
class MockArtistNetworkRepository implements ArtistNetworkRepository {
  List<ArtistReview> _reviews() => MockDb.getCollection(
    _reviewsKey,
    seedArtistReviews,
    ArtistReview.fromJson,
    (r) => r.toJson(),
  );

  List<ArtistConnection> _connections() => MockDb.getCollection(
    _connectionsKey,
    seedArtistConnections,
    ArtistConnection.fromJson,
    (c) => c.toJson(),
  );

  void _writeConnections(List<ArtistConnection> value) =>
      MockDb.setCollection(_connectionsKey, value, (c) => c.toJson());

  List<DeactivationRequest> _deactivations() => MockDb.getCollection(
    _deactivationKey,
    () => const <DeactivationRequest>[],
    DeactivationRequest.fromJson,
    (r) => r.toJson(),
  );

  void _writeDeactivations(List<DeactivationRequest> value) =>
      MockDb.setCollection(_deactivationKey, value, (r) => r.toJson());

  ({String name, String avatar}) _display(String artistId) {
    if (artistId == currentArtistId) {
      return (name: currentArtistName, avatar: currentArtistAvatar);
    }
    final artist = seedArtists().where((a) => a.id == artistId).firstOrNull;
    return (
      name: artist?.name ?? artistId,
      avatar: artist?.profileImageUrl ?? currentArtistAvatar,
    );
  }

  /// A connection exists for a pair regardless of who asked — checking only
  /// one direction is how you end up with two pending rows for the same two
  /// people.
  ArtistConnection? _between(String a, String b) => _connections()
      .where(
        (c) =>
            (c.requesterId == a && c.recipientId == b) ||
            (c.requesterId == b && c.recipientId == a),
      )
      .firstOrNull;

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  // --- Ratings ---------------------------------------------------------------

  @override
  Future<ArtistRating> getRating(String artistId) =>
      mockDelay(() => summarizeRating(artistId, _reviews()));

  @override
  Future<List<ArtistReview>> listReviews(String artistId) => mockDelay(() {
    final mine = _reviews().where((r) => r.artistId == artistId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  });

  // --- Connections -----------------------------------------------------------

  @override
  Future<List<ArtistConnection>> listConnections(String artistId) =>
      mockDelay(() {
        final mine = _connections()
            .where((c) => involvesArtist(c, artistId))
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        return mine;
      });

  @override
  Future<ArtistConnection?> getConnectionWith(String viewerId, String peerId) =>
      mockDelay(() => _between(viewerId, peerId));

  @override
  Future<ArtistConnection> sendConnectionRequest({
    required String requesterId,
    required String recipientId,
    String message = '',
  }) {
    if (requesterId == recipientId) {
      return mockError('You cannot connect with yourself');
    }
    final existing = _between(requesterId, recipientId);
    // A declined request can be sent again; a pending or accepted one cannot.
    if (existing != null && existing.status != ConnectionStatus.declined) {
      return mockError(
        existing.status == ConnectionStatus.accepted
            ? 'You are already connected'
            : 'There is already a request open with this artist',
      );
    }

    return mockDelay(() {
      final requester = _display(requesterId);
      final recipient = _display(recipientId);
      final connection = ArtistConnection(
        id: _id('conn'),
        requesterId: requesterId,
        requesterName: requester.name,
        requesterAvatar: requester.avatar,
        recipientId: recipientId,
        recipientName: recipient.name,
        recipientAvatar: recipient.avatar,
        status: ConnectionStatus.pending,
        message: message.trim(),
        requestedAt: DateTime.now().toIso8601String(),
      );
      _writeConnections([
        ..._connections().where((c) => c.id != existing?.id),
        connection,
      ]);
      return connection;
    });
  }

  @override
  Future<ArtistConnection> respondToConnection({
    required String connectionId,
    required String viewerId,
    required bool accept,
  }) {
    final all = _connections();
    final connection = all.where((c) => c.id == connectionId).firstOrNull;
    if (connection == null) return mockError('Request not found');
    if (connection.recipientId != viewerId) {
      return mockError('Only the person who received a request can answer it');
    }
    if (connection.status != ConnectionStatus.pending) {
      return mockError('That request has already been answered');
    }

    return mockDelay(() {
      final updated = connection.copyWith(
        status: accept ? ConnectionStatus.accepted : ConnectionStatus.declined,
        respondedAt: DateTime.now().toIso8601String(),
      );
      _writeConnections([
        for (final c in all) c.id == connectionId ? updated : c,
      ]);
      return updated;
    });
  }

  // --- Account deactivation --------------------------------------------------

  @override
  Future<DeactivationRequest?> getDeactivationRequest() => mockDelay(() {
    final mine =
        _deactivations().where((r) => r.userId == currentArtistId).toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return mine.firstOrNull;
  });

  @override
  Future<DeactivationRequest> requestDeactivation({required String reason}) {
    if (reason.trim().isEmpty) {
      return mockError('Tell us why you are closing the account');
    }
    if (_deactivations().any(
      (r) =>
          r.userId == currentArtistId && r.status == DeactivationStatus.pending,
    )) {
      return mockError('You already have a request under review');
    }

    return mockDelay(() {
      final request = DeactivationRequest(
        id: _id('deact'),
        userId: currentArtistId,
        userName: currentArtistName,
        reason: reason.trim(),
        status: DeactivationStatus.pending,
        requestedAt: DateTime.now().toIso8601String(),
      );
      _writeDeactivations([request, ..._deactivations()]);
      return request;
    });
  }

  @override
  Future<void> withdrawDeactivation(String requestId) {
    final request = _deactivations()
        .where((r) => r.id == requestId)
        .firstOrNull;
    if (request == null) return mockError('Request not found');
    if (request.status != DeactivationStatus.pending) {
      return mockError('That request has already been decided');
    }

    return mockDelay(() {
      _writeDeactivations(
        _deactivations().where((r) => r.id != requestId).toList(),
      );
    });
  }
}
