import '../models/artwork.dart';
import '../models/nfc.dart';
import '../repositories/nfc_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show promoteApprovedSubmissions, seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/artist_seed.dart' show seedPendingArtworks;

const _artworksKey = 'artworks';
const _pendingArtworksKey = 'pendingArtworks';

/// The offline demo of the NFC rules (NFC_IMPLEMENTATION.md §4): the same
/// answers the server gives, kept on the mock artworks. Roles are not modelled
/// here — the demo has one artist.
class MockNfcRepository implements NfcRepository {
  List<Artwork> _live() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(_artworksKey, seedArtworksCollection, Artwork.fromJson, (a) => a.toJson());
  }

  List<Artwork> _pending() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(_pendingArtworksKey, seedPendingArtworks, Artwork.fromJson, (a) => a.toJson());
  }

  Artwork? _find(String artworkId) =>
      _live().where((a) => a.id == artworkId).firstOrNull ?? _pending().where((a) => a.id == artworkId).firstOrNull;

  void _write(Artwork updated) {
    final live = _live();
    if (live.any((a) => a.id == updated.id)) {
      MockDb.setCollection(_artworksKey, [for (final a in live) a.id == updated.id ? updated : a], (a) => a.toJson());
      return;
    }
    MockDb.setCollection(
      _pendingArtworksKey,
      [for (final a in _pending()) a.id == updated.id ? updated : a],
      (a) => a.toJson(),
    );
  }

  Artwork _required(String artworkId) {
    final artwork = _find(artworkId);
    if (artwork == null) throw Exception('Artwork not found');
    return artwork;
  }

  /// One chip belongs to one artwork.
  bool _boundElsewhere(String artworkId, String uid) =>
      [..._live(), ..._pending()].any((a) => a.id != artworkId && a.nfcTagUid == uid);

  NfcCheckAction _decide(Artwork artwork, String uid, NfcIntent intent) {
    switch (intent) {
      case NfcIntent.link:
        if (artwork.nfcLockedAt != null) throw Exception("This artwork's tag is locked, so it can't be linked again.");
        if (artwork.nfcLinkedAt != null && artwork.nfcTagUid == uid) return NfcCheckAction.noop;
        if (_boundElsewhere(artwork.id, uid)) throw Exception('This chip is already linked to another artwork.');
        return artwork.nfcLinkedAt != null ? NfcCheckAction.replace : NfcCheckAction.link;
      case NfcIntent.lock:
        if (artwork.nfcLinkedAt == null) throw Exception('Link a tag to this artwork before locking it.');
        if (artwork.nfcLockedAt != null) {
          if (artwork.nfcTagUid == uid) return NfcCheckAction.noop;
          throw Exception("This artwork's tag is already locked, and not by this chip.");
        }
        if (artwork.nfcTagUid != uid) {
          throw Exception("This isn't the chip that was linked to this artwork. Tap the original chip.");
        }
        return NfcCheckAction.lock;
    }
  }

  NfcState _stateOf(Artwork a) =>
      NfcState(artworkId: a.id, tagUid: a.nfcTagUid, linkedAt: a.nfcLinkedAt, lockedAt: a.nfcLockedAt);

  @override
  Future<NfcCheckAction> check(String artworkId, String tagUid, NfcIntent intent) =>
      mockDelay(() => _decide(_required(artworkId), tagUid.toLowerCase(), intent), duration: const Duration(milliseconds: 150));

  @override
  Future<NfcState> confirmLinked(String artworkId, String tagUid) => mockDelay(() {
    final uid = tagUid.toLowerCase();
    final artwork = _required(artworkId);
    if (_decide(artwork, uid, NfcIntent.link) == NfcCheckAction.noop) return _stateOf(artwork);
    final updated = artwork.copyWith(
      nfcTagUid: uid,
      nfcLinkedAt: DateTime.now().toUtc().toIso8601String(),
      nfcLockedAt: null,
    );
    _write(updated);
    return _stateOf(updated);
  }, duration: const Duration(milliseconds: 150));

  @override
  Future<NfcState> confirmLocked(String artworkId, String tagUid) => mockDelay(() {
    final uid = tagUid.toLowerCase();
    final artwork = _required(artworkId);
    if (_decide(artwork, uid, NfcIntent.lock) == NfcCheckAction.noop) return _stateOf(artwork);
    final updated = artwork.copyWith(nfcLockedAt: DateTime.now().toUtc().toIso8601String());
    _write(updated);
    return _stateOf(updated);
  }, duration: const Duration(milliseconds: 150));

  @override
  Future<void> reportFailure(String artworkId, NfcFailureStep step, String message, {String? tagUid}) async {}
}
