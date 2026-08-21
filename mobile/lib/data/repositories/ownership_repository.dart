import '../models/artwork.dart';

/// Digital ownership hand-over for an artwork's passport, mirroring
/// `services/ownershipService.ts`.
///
/// Its own interface rather than methods bolted onto [ArtworkRepository] or
/// [CustomerRepository]: the reads are public (anyone scanning a tag sees the
/// chain of custody), the writes are owner-scoped, and splitting one concept
/// across two interfaces to honour that would be worse than a small third one.
abstract class OwnershipRepository {
  /// Every transfer recorded against an artwork, newest first.
  Future<List<OwnershipTransfer>> listForArtwork(String artworkId);

  /// The transfer behind an accept link. Null when the link is not valid.
  Future<OwnershipTransfer?> get(String transferId);

  /// Starts a hand-over. Only one can be open per artwork — two pending
  /// transfers would let two people each claim the same piece.
  Future<OwnershipTransfer> initiate({
    required String artworkId,
    required String fromName,
    required String toName,
    required String toEmail,
  });

  /// The buyer accepting is what actually moves ownership: nothing changes on
  /// the artwork until this runs.
  Future<OwnershipTransfer> accept(String transferId);

  Future<OwnershipTransfer> cancel(String transferId);
}
