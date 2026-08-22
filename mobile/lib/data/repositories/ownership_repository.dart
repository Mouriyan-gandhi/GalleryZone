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
  ///
  /// [kind] picks what is being handed over. A display transfer needs
  /// [displayEndsAt] and leaves the owner unchanged.
  Future<OwnershipTransfer> initiate({
    required String artworkId,
    required String fromName,
    required String toName,
    required String toEmail,
    TransferKind kind,
    String? displayEndsAt,
  });

  /// The buyer accepting is what actually moves ownership: nothing changes on
  /// the artwork until this runs. A display transfer accepted here moves
  /// nothing at all — custody on display is derived from the record and the
  /// date, so there is no state to write and none to unwind at expiry.
  Future<OwnershipTransfer> accept(String transferId);

  /// The owner pulling a piece back before the end date. The alternative —
  /// the date passing — needs no call at all.
  Future<OwnershipTransfer> endDisplay(String transferId);

  Future<OwnershipTransfer> cancel(String transferId);
}
