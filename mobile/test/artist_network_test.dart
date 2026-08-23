import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/data/mock/mock_artist_network_repository.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_artwork_repository.dart';
import 'package:gallery_zone/data/mock/mock_ownership_repository.dart';
import 'package:gallery_zone/data/mock/seed/artist_network_seed.dart';
import 'package:gallery_zone/data/mock/seed/artist_seed.dart'
    show currentArtistId;
import 'package:gallery_zone/data/models/artist_network.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `a2fdb9b` and `c5108c4` features ported from the web: artist ratings,
/// artist-to-artist connections, MOU-gated collaborations, the deactivation
/// request, and display-rights transfers.

void main() {
  late MockArtistNetworkRepository network;
  late MockArtistRepository artist;
  late MockOwnershipRepository ownership;
  late MockArtworkRepository artworks;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
    network = MockArtistNetworkRepository();
    artist = MockArtistRepository();
    ownership = MockOwnershipRepository();
    artworks = MockArtworkRepository();
  });

  group('ratings', () {
    test('the average and the breakdown agree with the reviews', () async {
      final rating = await network.getRating(currentArtistId);
      final reviews = await network.listReviews(currentArtistId);

      expect(rating.count, reviews.length);
      expect(
        rating.breakdown.values.fold<int>(0, (sum, n) => sum + n),
        reviews.length,
      );
      final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      expect(rating.average, (total / reviews.length * 10).round() / 10);
    });

    test('an artist nobody has reviewed reads as zero, not as one star', () async {
      final rating = await network.getRating('nobody-has-bought-from-me');
      expect(rating.count, 0);
      expect(rating.average, 0);
    });

    test('reviews come back newest first', () async {
      final reviews = await network.listReviews(currentArtistId);
      for (var i = 1; i < reviews.length; i++) {
        expect(
          reviews[i - 1].createdAt.compareTo(reviews[i].createdAt) >= 0,
          isTrue,
        );
      }
    });
  });

  group('connections', () {
    test('only the recipient can answer a request', () async {
      final connections = await network.listConnections(currentArtistId);
      final incoming = connections.firstWhere(
        (c) =>
            c.status == ConnectionStatus.pending &&
            c.recipientId == currentArtistId,
      );

      // The person who sent it cannot accept on the other side's behalf.
      expect(
        () => network.respondToConnection(
          connectionId: incoming.id,
          viewerId: incoming.requesterId,
          accept: true,
        ),
        throwsA(isA<Exception>()),
      );

      final accepted = await network.respondToConnection(
        connectionId: incoming.id,
        viewerId: currentArtistId,
        accept: true,
      );
      expect(accepted.status, ConnectionStatus.accepted);
    });

    test('an answered request cannot be answered again', () async {
      final connections = await network.listConnections(currentArtistId);
      final incoming = connections.firstWhere(
        (c) => c.status == ConnectionStatus.pending,
      );
      await network.respondToConnection(
        connectionId: incoming.id,
        viewerId: currentArtistId,
        accept: false,
      );

      expect(
        () => network.respondToConnection(
          connectionId: incoming.id,
          viewerId: currentArtistId,
          accept: true,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a pair can only have one open request, whoever asked', () async {
      // meera-nair is already connected in the seed, from this artist's side.
      expect(
        () => network.sendConnectionRequest(
          requesterId: 'meera-nair',
          recipientId: currentArtistId,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a declined request can be sent again', () async {
      final connections = await network.listConnections(currentArtistId);
      final incoming = connections.firstWhere(
        (c) => c.status == ConnectionStatus.pending,
      );
      await network.respondToConnection(
        connectionId: incoming.id,
        viewerId: currentArtistId,
        accept: false,
      );

      final resent = await network.sendConnectionRequest(
        requesterId: currentArtistId,
        recipientId: incoming.requesterId,
      );
      expect(resent.status, ConnectionStatus.pending);

      // And not as a second row beside the declined one.
      final after = await network.listConnections(currentArtistId);
      expect(
        after.where((c) => involvesArtist(c, incoming.requesterId)).length,
        1,
      );
    });

    test('nobody connects with themselves', () async {
      expect(
        () => network.sendConnectionRequest(
          requesterId: currentArtistId,
          recipientId: currentArtistId,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('collaborations', () {
    test('proposing is refused until the MOU is signed', () async {
      expect(
        () => network.proposeCollaboration(
          proposerId: currentArtistId,
          partnerId: 'meera-nair',
          title: 'Two Coasts',
          brief: 'A paired series.',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a signed MOU opens it, but only with a connection', () async {
      await artist.acceptMou('2026.1');

      final proposed = await network.proposeCollaboration(
        proposerId: currentArtistId,
        partnerId: 'meera-nair',
        title: 'Two Coasts',
        brief: 'A paired series.',
      );
      expect(proposed.status, CollaborationStatus.proposed);

      // kavya-iyer is nobody this artist has connected with.
      expect(
        () => network.proposeCollaboration(
          proposerId: currentArtistId,
          partnerId: 'kavya-iyer',
          title: 'Anything',
          brief: 'Anything.',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('only the invited artist answers, and only once', () async {
      final seeded = (await network.listCollaborations(currentArtistId))
          .firstWhere((c) => c.status == CollaborationStatus.proposed);

      expect(
        () => network.respondToCollaboration(
          collaborationId: seeded.id,
          viewerId: seeded.proposerId,
          accept: true,
        ),
        throwsA(isA<Exception>()),
      );

      final active = await network.respondToCollaboration(
        collaborationId: seeded.id,
        viewerId: currentArtistId,
        accept: true,
      );
      expect(active.status, CollaborationStatus.active);

      expect(
        () => network.respondToCollaboration(
          collaborationId: seeded.id,
          viewerId: currentArtistId,
          accept: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('only an active collaboration can be completed', () async {
      final seeded = (await network.listCollaborations(currentArtistId))
          .firstWhere((c) => c.status == CollaborationStatus.proposed);

      expect(
        () => network.completeCollaboration(
          collaborationId: seeded.id,
          viewerId: currentArtistId,
        ),
        throwsA(isA<Exception>()),
      );

      await network.respondToCollaboration(
        collaborationId: seeded.id,
        viewerId: currentArtistId,
        accept: true,
      );
      final done = await network.completeCollaboration(
        collaborationId: seeded.id,
        viewerId: currentArtistId,
      );
      expect(done.status, CollaborationStatus.completed);
    });
  });

  group('account deactivation', () {
    test('a request waits on a decision and can be withdrawn', () async {
      expect(await network.getDeactivationRequest(), isNull);

      final request = await network.requestDeactivation(reason: 'Moving abroad');
      expect(request.status, DeactivationStatus.pending);

      // Asking twice while one is open is refused — a queue of identical
      // requests helps nobody.
      expect(
        () => network.requestDeactivation(reason: 'Moving abroad'),
        throwsA(isA<Exception>()),
      );

      await network.withdrawDeactivation(request.id);
      expect(await network.getDeactivationRequest(), isNull);
    });

    test('a reason is required', () async {
      expect(
        () => network.requestDeactivation(reason: '   '),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('display rights', () {
    String inDays(int days) =>
        DateTime.now().add(Duration(days: days)).toIso8601String();

    test('accepting a display transfer does not change the owner', () async {
      final before = resolveCustody(
        (await artworks.get('aw-1'))!,
      );

      final transfer = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Devika Rao',
        toName: 'Verandah Art House',
        toEmail: 'hello@verandaharthouse.in',
        kind: TransferKind.display,
        displayEndsAt: inDays(30),
      );
      final accepted = await ownership.accept(transfer.id);

      expect(accepted.status, TransferStatus.accepted);
      expect(isDisplayActive(accepted), isTrue);

      final after = resolveCustody(
        (await artworks.get('aw-1'))!,
      );
      expect(after.legalOwner, before.legalOwner);
      expect(after.legalOwnerName, before.legalOwnerName);
    });

    test('a display without an end date, or with a past one, is refused', () async {
      expect(
        () => ownership.initiate(
          artworkId: 'aw-1',
          fromName: 'Devika Rao',
          toName: 'Verandah Art House',
          toEmail: 'hello@verandaharthouse.in',
          kind: TransferKind.display,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => ownership.initiate(
          artworkId: 'aw-1',
          fromName: 'Devika Rao',
          toName: 'Verandah Art House',
          toEmail: 'hello@verandaharthouse.in',
          kind: TransferKind.display,
          displayEndsAt: inDays(-1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a piece cannot be lent twice over', () async {
      final first = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Devika Rao',
        toName: 'Verandah Art House',
        toEmail: 'hello@verandaharthouse.in',
        kind: TransferKind.display,
        displayEndsAt: inDays(30),
      );
      await ownership.accept(first.id);

      expect(
        () => ownership.initiate(
          artworkId: 'aw-1',
          fromName: 'Devika Rao',
          toName: 'Another Gallery',
          toEmail: 'hello@another.in',
          kind: TransferKind.display,
          displayEndsAt: inDays(10),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('ending early beats an end date that has not arrived', () async {
      final transfer = await ownership.initiate(
        artworkId: 'aw-1',
        fromName: 'Devika Rao',
        toName: 'Verandah Art House',
        toEmail: 'hello@verandaharthouse.in',
        kind: TransferKind.display,
        displayEndsAt: inDays(30),
      );
      await ownership.accept(transfer.id);

      final ended = await ownership.endDisplay(transfer.id);
      expect(isDisplayActive(ended), isFalse);

      // And ending it twice is refused rather than silently accepted.
      expect(
        () => ownership.endDisplay(transfer.id),
        throwsA(isA<Exception>()),
      );
    });

    test('the date passing ends it with nothing having run', () {
      final lapsed = OwnershipTransfer(
        id: 'tr-lapsed',
        artworkId: 'aw-1',
        artworkTitle: 'Monsoon Reverie',
        fromName: 'Devika Rao',
        toName: 'Verandah Art House',
        toEmail: 'hello@verandaharthouse.in',
        initiatedAt: DateTime.now().toIso8601String(),
        acceptedAt: DateTime.now().toIso8601String(),
        status: TransferStatus.accepted,
        kind: TransferKind.display,
        displayEndsAt: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      );
      expect(isDisplayActive(lapsed), isFalse);
      expect(activeDisplayTransfer([lapsed]), isNull);
    });

    test('a record with no kind is an ownership hand-over', () {
      final legacy = OwnershipTransfer(
        id: 'tr-legacy',
        artworkId: 'aw-1',
        artworkTitle: 'Monsoon Reverie',
        fromName: 'Devika Rao',
        toName: 'Anil Kumar',
        toEmail: 'anil@example.com',
        initiatedAt: DateTime.now().toIso8601String(),
        status: TransferStatus.pending,
      );
      expect(transferKindOf(legacy), TransferKind.ownership);
      expect(isDisplayActive(legacy), isFalse);
    });
  });

  group('off-platform sale fee', () {
    // Raising a fee is not charging one: an admin decides, and until they do
    // nothing comes out of the artist's wallet.
    ExternalSalePenalty fee({PenaltyStatus? status, String? settledAt}) =>
        ExternalSalePenalty(
          id: 'pen-1',
          artworkId: 'aw-1',
          artworkTitle: 'Monsoon Reverie',
          amount: 1300,
          createdAt: DateTime.now().toIso8601String(),
          settledAt: settledAt,
          status: status,
        );

    test('only an approved, uncollected fee is collectable', () {
      expect(isPenaltyCollectable(fee(status: PenaltyStatus.pendingReview)), isFalse);
      expect(isPenaltyCollectable(fee(status: PenaltyStatus.waived)), isFalse);
      expect(isPenaltyCollectable(fee(status: PenaltyStatus.approved)), isTrue);
      expect(
        isPenaltyCollectable(
          fee(
            status: PenaltyStatus.approved,
            settledAt: DateTime.now().toIso8601String(),
          ),
        ),
        isFalse,
      );
    });

    test('a record with no status reads as approved, not as unreviewed', () {
      // Those were charged automatically before the fee became reviewable;
      // flipping them back to pending would collect them a second time.
      expect(penaltyStatusOf(fee()), PenaltyStatus.approved);
    });

    test('marking sold elsewhere raises the fee for review, not for payment', () async {
      final walletBefore = await artist.getWallet();

      await artist.markSoldElsewhere('aw-1');
      final penalties = await artist.listPenalties();
      final raised = penalties.firstWhere((p) => p.artworkId == 'aw-1');

      expect(penaltyStatusOf(raised), PenaltyStatus.pendingReview);
      expect(raised.settledAt, isNull);

      final walletAfter = await artist.getWallet();
      expect(walletAfter.balance, walletBefore.balance);
    });
  });

  test('the demo artist has an avatar the seeds agree on', () {
    expect(currentArtistAvatar, isNotEmpty);
    final connections = seedArtistConnections();
    expect(
      connections.where((c) => c.requesterId == currentArtistId).first.requesterAvatar,
      currentArtistAvatar,
    );
  });
}
