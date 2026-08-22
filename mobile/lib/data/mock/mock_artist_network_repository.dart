import '../models/artist_network.dart';
import '../models/artist_portal.dart';
import '../repositories/artist_network_repository.dart';
import '../storage/mock_db.dart';
import 'mock_utils.dart';
import 'seed/artist_network_seed.dart';
import 'seed/artist_seed.dart' show currentArtistId, currentArtistName;
import 'seed/artists_seed.dart';

const _reviewsKey = 'artistReviews';
const _connectionsKey = 'artistConnections';
const _collaborationsKey = 'artistCollaborations';
const _deactivationKey = 'deactivationRequests';
const _mouKey = 'artistMou';

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

  List<ArtistCollaboration> _collaborations() => MockDb.getCollection(
    _collaborationsKey,
    seedArtistCollaborations,
    ArtistCollaboration.fromJson,
    (c) => c.toJson(),
  );

  void _writeCollaborations(List<ArtistCollaboration> value) =>
      MockDb.setCollection(_collaborationsKey, value, (c) => c.toJson());

  List<DeactivationRequest> _deactivations() => MockDb.getCollection(
    _deactivationKey,
    () => const <DeactivationRequest>[],
    DeactivationRequest.fromJson,
    (r) => r.toJson(),
  );

  void _writeDeactivations(List<DeactivationRequest> value) =>
      MockDb.setCollection(_deactivationKey, value, (r) => r.toJson());

  bool _mouSigned() => MockDb.getCollection(
    _mouKey,
    () => const <MouAcceptance>[],
    MouAcceptance.fromJson,
    (a) => a.toJson(),
  ).isNotEmpty;

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

  bool _isConnected(String a, String b) =>
      _between(a, b)?.status == ConnectionStatus.accepted;

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

  // --- Collaborations --------------------------------------------------------

  @override
  Future<List<ArtistCollaboration>> listCollaborations(String artistId) =>
      mockDelay(() {
        final mine = _collaborations()
            .where((c) => c.proposerId == artistId || c.partnerId == artistId)
            .toList()
          ..sort((a, b) => b.proposedAt.compareTo(a.proposedAt));
        return mine;
      });

  @override
  Future<ArtistCollaboration> proposeCollaboration({
    required String proposerId,
    required String partnerId,
    required String title,
    required String brief,
  }) {
    // Both gates are enforced here as well as in the UI: the MOU is the
    // agreement that makes joint work possible at all, and a collaboration
    // with someone you are not connected to is not a collaboration.
    if (proposerId == currentArtistId && !_mouSigned()) {
      return mockError('Sign your MOU before proposing a collaboration');
    }
    if (!_isConnected(proposerId, partnerId)) {
      return mockError('Connect with this artist first');
    }
    if (title.trim().isEmpty) {
      return mockError('Give the collaboration a title');
    }
    if (brief.trim().isEmpty) {
      return mockError('Describe what you have in mind');
    }

    return mockDelay(() {
      final collaboration = ArtistCollaboration(
        id: _id('collab'),
        proposerId: proposerId,
        proposerName: _display(proposerId).name,
        partnerId: partnerId,
        partnerName: _display(partnerId).name,
        title: title.trim(),
        brief: brief.trim(),
        status: CollaborationStatus.proposed,
        proposedAt: DateTime.now().toIso8601String(),
      );
      _writeCollaborations([..._collaborations(), collaboration]);
      return collaboration;
    });
  }

  @override
  Future<ArtistCollaboration> respondToCollaboration({
    required String collaborationId,
    required String viewerId,
    required bool accept,
  }) {
    final all = _collaborations();
    final collaboration = all.where((c) => c.id == collaborationId).firstOrNull;
    if (collaboration == null) return mockError('Collaboration not found');
    if (collaboration.partnerId != viewerId) {
      return mockError('Only the invited artist can answer this');
    }
    if (collaboration.status != CollaborationStatus.proposed) {
      return mockError('That proposal has already been answered');
    }

    return mockDelay(() {
      final updated = collaboration.copyWith(
        status: accept
            ? CollaborationStatus.active
            : CollaborationStatus.declined,
        respondedAt: DateTime.now().toIso8601String(),
      );
      _writeCollaborations([
        for (final c in all) c.id == collaborationId ? updated : c,
      ]);
      return updated;
    });
  }

  @override
  Future<ArtistCollaboration> completeCollaboration({
    required String collaborationId,
    required String viewerId,
  }) {
    final all = _collaborations();
    final collaboration = all.where((c) => c.id == collaborationId).firstOrNull;
    if (collaboration == null) return mockError('Collaboration not found');
    if (collaboration.proposerId != viewerId &&
        collaboration.partnerId != viewerId) {
      return mockError('You are not part of this collaboration');
    }
    if (collaboration.status != CollaborationStatus.active) {
      return mockError('Only an active collaboration can be completed');
    }

    return mockDelay(() {
      final updated = collaboration.copyWith(
        status: CollaborationStatus.completed,
        respondedAt: DateTime.now().toIso8601String(),
      );
      _writeCollaborations([
        for (final c in all) c.id == collaborationId ? updated : c,
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
