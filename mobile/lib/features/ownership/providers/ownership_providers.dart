import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_ownership_repository.dart';
import '../../../data/models/artwork.dart';
import '../../../data/repositories/ownership_repository.dart';

final ownershipRepositoryProvider = Provider<OwnershipRepository>((ref) {
  return MockOwnershipRepository();
});

/// The chain of custody on one artwork's passport. Public: someone scanning a
/// physical tag reads this without an account.
final artworkTransfersProvider =
    FutureProvider.autoDispose.family<List<OwnershipTransfer>, String>((ref, artworkId) {
      return ref.watch(ownershipRepositoryProvider).listForArtwork(artworkId);
    });

/// One transfer, behind its accept link.
final transferProvider = FutureProvider.autoDispose.family<OwnershipTransfer?, String>((
  ref,
  transferId,
) {
  return ref.watch(ownershipRepositoryProvider).get(transferId);
});
