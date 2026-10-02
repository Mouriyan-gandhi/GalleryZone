import '../models/nfc.dart';

/// The server's side of the NFC tag (NFC_IMPLEMENTATION.md §4). The artist who
/// made a piece, or the aggregator holding it, may use all of this; the server
/// decides which.
abstract class NfcRepository {
  /// Before the chip is touched: would linking or locking THIS chip be allowed?
  /// Changes nothing. A refusal (the chip belongs to another piece, the wrong
  /// chip for a lock, a locked tag...) throws with the server's own wording.
  Future<NfcCheckAction> check(String artworkId, String tagUid, NfcIntent intent);

  /// The URL has been written and the UID read back. The same chip again is a
  /// no-op; a different one replaces it until the lock.
  Future<NfcState> confirmLinked(String artworkId, String tagUid);

  /// The lock bytes have been set and read back. Irreversible.
  Future<NfcState> confirmLocked(String artworkId, String tagUid);

  /// A link or lock that failed on the phone, relayed to Sentry. Best-effort:
  /// never throws.
  Future<void> reportFailure(String artworkId, NfcFailureStep step, String message, {String? tagUid});
}
