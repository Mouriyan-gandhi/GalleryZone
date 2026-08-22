import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_artist_network_repository.dart';
import '../../../data/mock/seed/artist_seed.dart' show currentArtistId;
import '../../../data/models/artist_network.dart';
import '../../../data/repositories/artist_network_repository.dart';

final artistNetworkRepositoryProvider = Provider<ArtistNetworkRepository>((
  ref,
) {
  return MockArtistNetworkRepository();
});

/// Bumped after any write. Riverpod has no query cache to invalidate the way
/// TanStack Query does on the web, so one counter every network read watches
/// is the smallest thing that keeps the rating card, the connections panel and
/// the public profile button from disagreeing after an accept.
class ArtistNetworkRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final artistNetworkRevisionProvider =
    NotifierProvider<ArtistNetworkRevision, int>(ArtistNetworkRevision.new);

final artistRatingProvider = FutureProvider.autoDispose
    .family<ArtistRating, String>((ref, artistId) {
      ref.watch(artistNetworkRevisionProvider);
      return ref.watch(artistNetworkRepositoryProvider).getRating(artistId);
    });

final artistReviewsProvider = FutureProvider.autoDispose
    .family<List<ArtistReview>, String>((ref, artistId) {
      ref.watch(artistNetworkRevisionProvider);
      return ref.watch(artistNetworkRepositoryProvider).listReviews(artistId);
    });

final artistConnectionsProvider =
    FutureProvider.autoDispose<List<ArtistConnection>>((ref) {
      ref.watch(artistNetworkRevisionProvider);
      return ref
          .watch(artistNetworkRepositoryProvider)
          .listConnections(currentArtistId);
    });

/// The viewer's connection with one other artist — what the Connect button on
/// a public profile reads.
final connectionWithProvider = FutureProvider.autoDispose
    .family<ArtistConnection?, String>((ref, peerId) {
      ref.watch(artistNetworkRevisionProvider);
      return ref
          .watch(artistNetworkRepositoryProvider)
          .getConnectionWith(currentArtistId, peerId);
    });

final artistCollaborationsProvider =
    FutureProvider.autoDispose<List<ArtistCollaboration>>((ref) {
      ref.watch(artistNetworkRevisionProvider);
      return ref
          .watch(artistNetworkRepositoryProvider)
          .listCollaborations(currentArtistId);
    });

final deactivationRequestProvider =
    FutureProvider.autoDispose<DeactivationRequest?>((ref) {
      ref.watch(artistNetworkRevisionProvider);
      return ref
          .watch(artistNetworkRepositoryProvider)
          .getDeactivationRequest();
    });
