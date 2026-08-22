import '../models/artwork.dart';
import '../repositories/ownership_repository.dart';
import '../storage/mock_db.dart';
import 'mock_artwork_repository.dart' show promoteApprovedSubmissions, seedArtworksCollection;
import 'mock_utils.dart';
import 'seed/artist_seed.dart' show seedPendingArtworks;

const _transfersKey = 'ownershipTransfers';
const _artworksKey = 'artworks';
const _pendingArtworksKey = 'pendingArtworks';

/// Port of `services/ownershipService.ts`. No seeded transfers: provenance
/// starts empty and is written by the app, which is the honest state for a
/// record that only exists once someone hands a piece over.
class MockOwnershipRepository implements OwnershipRepository {
  List<OwnershipTransfer> _read() => MockDb.getCollection(
    _transfersKey,
    () => const <OwnershipTransfer>[],
    OwnershipTransfer.fromJson,
    (t) => t.toJson(),
  );

  void _write(List<OwnershipTransfer> transfers) =>
      MockDb.setCollection(_transfersKey, transfers, (t) => t.toJson());

  List<Artwork> _live() {
    promoteApprovedSubmissions();
    return MockDb.getCollection(
      _artworksKey,
      seedArtworksCollection,
      Artwork.fromJson,
      (a) => a.toJson(),
    );
  }

  List<Artwork> _pending() => MockDb.getCollection(
    _pendingArtworksKey,
    seedPendingArtworks,
    Artwork.fromJson,
    (a) => a.toJson(),
  );

  Artwork? _findArtwork(String artworkId) =>
      _live().where((a) => a.id == artworkId).firstOrNull ??
      _pending().where((a) => a.id == artworkId).firstOrNull;

  void _writeArtwork(Artwork updated) {
    final live = _live();
    if (live.any((a) => a.id == updated.id)) {
      MockDb.setCollection(
        _artworksKey,
        [for (final a in live) a.id == updated.id ? updated : a],
        (a) => a.toJson(),
      );
      return;
    }
    MockDb.setCollection(
      _pendingArtworksKey,
      [for (final a in _pending()) a.id == updated.id ? updated : a],
      (a) => a.toJson(),
    );
  }

  @override
  Future<List<OwnershipTransfer>> listForArtwork(String artworkId) => mockDelay(() {
    final matches = _read().where((t) => t.artworkId == artworkId).toList()
      ..sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return matches;
  });

  @override
  Future<OwnershipTransfer?> get(String transferId) =>
      mockDelay(() => _read().where((t) => t.id == transferId).firstOrNull);

  @override
  Future<OwnershipTransfer> initiate({
    required String artworkId,
    required String fromName,
    required String toName,
    required String toEmail,
    TransferKind kind = TransferKind.ownership,
    String? displayEndsAt,
  }) {
    final artwork = _findArtwork(artworkId);
    if (artwork == null) return mockError('Artwork not found');
    if (toName.trim().isEmpty) return mockError("Enter the new owner's name");
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(toEmail.trim())) {
      return mockError('Enter a valid email address');
    }
    if (kind == TransferKind.display) {
      if (displayEndsAt == null) {
        return mockError('Pick the date the display runs to');
      }
      if (!DateTime.parse(displayEndsAt).isAfter(DateTime.now())) {
        return mockError('The display end date has to be in the future');
      }
    }
    // One open transfer per artwork: two pending ones would let two people
    // each claim the same piece.
    if (_read().any((t) => t.artworkId == artworkId && t.status == TransferStatus.pending)) {
      return mockError('A transfer for this artwork is already waiting to be accepted');
    }
    // A piece cannot be lent twice over. The active loan has to end — by its
    // own date or by the owner ending it — before another one starts.
    if (_read().any((t) => t.artworkId == artworkId && isDisplayActive(t))) {
      return mockError(
        'This artwork is already on display somewhere. End that display first.',
      );
    }

    return mockDelay(() {
      final transfer = OwnershipTransfer(
        id: 'tr-${DateTime.now().microsecondsSinceEpoch}',
        artworkId: artwork.id,
        artworkTitle: artwork.title,
        fromName: fromName,
        toName: toName.trim(),
        toEmail: toEmail.trim(),
        initiatedAt: DateTime.now().toIso8601String(),
        status: TransferStatus.pending,
        kind: kind,
        displayEndsAt: kind == TransferKind.display ? displayEndsAt : null,
      );
      _write([transfer, ..._read()]);
      return transfer;
    });
  }

  @override
  Future<OwnershipTransfer> accept(String transferId) {
    final transfers = _read();
    final transfer = transfers.where((t) => t.id == transferId).firstOrNull;
    if (transfer == null) return mockError('This transfer link is not valid');
    if (transfer.status == TransferStatus.accepted) {
      return mockError('This transfer has already been accepted');
    }
    if (transfer.status == TransferStatus.cancelled) {
      return mockError('This transfer was cancelled by the sender');
    }
    final artwork = _findArtwork(transfer.artworkId);
    if (artwork == null) return mockError('Artwork not found');

    return mockDelay(() {
      final now = DateTime.now().toIso8601String();
      final accepted = transfer.copyWith(status: TransferStatus.accepted, acceptedAt: now);
      _write([for (final t in transfers) t.id == transferId ? accepted : t]);

      // Ownership moves; custody only follows if the artist was still
      // holding it. A piece sitting with an aggregator stays there. A display
      // transfer writes nothing: it is derived from the record and the date.
      if (transferKindOf(accepted) == TransferKind.ownership) {
        final current = resolveCustody(artwork);
        _writeArtwork(
          artwork.copyWith(
            custody: current.copyWith(
              legalOwner: CustodyParty.customer,
              legalOwnerName: accepted.toName,
              custodian: current.custodian == CustodyParty.artist
                  ? CustodyParty.customer
                  : current.custodian,
              locationLabel: 'With ${accepted.toName}',
            ),
          ),
        );
      }
      return accepted;
    });
  }

  @override
  Future<OwnershipTransfer> endDisplay(String transferId) {
    final transfers = _read();
    final transfer = transfers.where((t) => t.id == transferId).firstOrNull;
    if (transfer == null) return mockError('Display record not found');
    if (!isDisplayActive(transfer)) {
      return mockError('This display has already ended');
    }

    return mockDelay(() {
      final ended = transfer.copyWith(
        displayEndedAt: DateTime.now().toIso8601String(),
      );
      _write([for (final t in transfers) t.id == transferId ? ended : t]);
      return ended;
    });
  }

  @override
  Future<OwnershipTransfer> cancel(String transferId) {
    final transfers = _read();
    final transfer = transfers.where((t) => t.id == transferId).firstOrNull;
    if (transfer == null) return mockError('Transfer not found');
    if (transfer.status != TransferStatus.pending) {
      return mockError('Only a pending transfer can be cancelled');
    }

    return mockDelay(() {
      final cancelled = transfer.copyWith(
        status: TransferStatus.cancelled,
        cancelledAt: DateTime.now().toIso8601String(),
      );
      _write([for (final t in transfers) t.id == transferId ? cancelled : t]);
      return cancelled;
    });
  }
}
