import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/theme/app_theme.dart';
import 'package:gallery_zone/core/verify_url.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/nfc.dart';
import 'package:gallery_zone/data/repositories/artist_repository.dart';
import 'package:gallery_zone/data/repositories/nfc_repository.dart';
import 'package:gallery_zone/features/artist/providers/artist_providers.dart';
import 'package:gallery_zone/features/artist/screens/coa_nfc_screen.dart';
import 'package:gallery_zone/features/nfc/providers/nfc_providers.dart';

import 'support/catalog_fixtures.dart';
import 'support/fake_nfc.dart';

/// The artist's COA & NFC board (NFC_IMPLEMENTATION.md §2, §7.7): three states,
/// the red flag on an unlocked one, and the link and lock sheets, run end to end
/// on a chip in memory. The rules themselves are checked in nfc_test.dart.

const _uid = '04a1b2c3d4e580';

/// One artist's pieces, and the server's side of their tags in the same object,
/// so a confirmed link changes what the board reads next.
class _World implements ArtistRepository, NfcRepository {
  _World(this.artworks);

  List<Artwork> artworks;
  String? refusal;
  final calls = <String>[];

  @override
  Future<List<ArtistArtwork>> listArtworks() async => [for (final a in artworks) ArtistArtwork(artwork: a, artistPrice: 10000)];

  @override
  Future<List<PhysicalCoaRequest>> listPhysicalCoaRequests() async => const [];

  Artwork _update(String id, Artwork Function(Artwork) change) {
    final updated = change(artworks.firstWhere((a) => a.id == id));
    artworks = [for (final a in artworks) a.id == id ? updated : a];
    return updated;
  }

  @override
  Future<NfcCheckAction> check(String artworkId, String tagUid, NfcIntent intent) async {
    calls.add('check:${intent.name}');
    if (refusal != null) throw Exception(refusal);
    return intent == NfcIntent.link ? NfcCheckAction.link : NfcCheckAction.lock;
  }

  @override
  Future<NfcState> confirmLinked(String artworkId, String tagUid) async {
    calls.add('link');
    final a = _update(artworkId, (a) => a.copyWith(nfcTagUid: tagUid, nfcLinkedAt: '2026-10-02T12:00:00.000Z', nfcLockedAt: null));
    return NfcState(artworkId: artworkId, tagUid: tagUid, linkedAt: a.nfcLinkedAt);
  }

  @override
  Future<NfcState> confirmLocked(String artworkId, String tagUid) async {
    calls.add('lock');
    final a = _update(artworkId, (a) => a.copyWith(nfcLockedAt: '2026-10-02T12:05:00.000Z'));
    return NfcState(artworkId: artworkId, tagUid: tagUid, linkedAt: a.nfcLinkedAt, lockedAt: a.nfcLockedAt);
  }

  @override
  Future<void> reportFailure(String artworkId, NfcFailureStep step, String message, {String? tagUid}) async {
    calls.add('failure:${step.api}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Artwork _piece(String id, {String? linked, String? locked}) => fixtureArtwork(
  id: id,
  title: 'Piece $id',
  nfcTagUid: linked == null ? null : _uid,
  nfcLinkedAt: linked,
  nfcLockedAt: locked,
);

const _linkedAt = '2026-09-28T10:00:00.000Z';
const _lockedAt = '2026-09-28T10:05:00.000Z';

Future<FakeNtagDevice> _open(WidgetTester tester, _World world, {FakeNtagDevice? device}) async {
  tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final chip = device ?? FakeNtagDevice();
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        artistRepositoryProvider.overrideWithValue(world),
        nfcRepositoryProvider.overrideWithValue(world),
        nfcDeviceProvider.overrideWithValue(chip),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const CoaNfcScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return chip;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('the board', () {
    testWidgets('shows three states, flags what cannot ship, and offers each piece the right action', (tester) async {
      final world = _World([_piece('a1'), _piece('a2', linked: _linkedAt), _piece('a3', linked: _linkedAt, locked: _lockedAt)]);
      await _open(tester, world);

      expect(find.text('Not yet tagged'), findsOneWidget);
      expect(find.text('Tag linked · unlocked'), findsOneWidget);
      expect(find.text('Tag locked'), findsOneWidget);

      // Red only on the linked-but-unlocked piece, and a banner that counts them.
      expect(find.text('Must lock before shipping'), findsOneWidget);
      expect(find.byKey(const Key('nfc-must-lock-a2')), findsOneWidget);
      expect(find.byKey(const Key('nfc-lock-warning')), findsOneWidget);
      expect(find.textContaining('1 piece has a tag that isn’t locked'), findsOneWidget);

      expect(find.byKey(const Key('link-nfc-a1')), findsOneWidget);
      expect(find.text('Link tag'), findsOneWidget);
      expect(find.byKey(const Key('lock-nfc-a2')), findsOneWidget, reason: 'the unlocked piece can be locked');
      expect(find.text('Replace tag'), findsOneWidget, reason: 'and replaced, until it is');
      expect(find.byKey(const Key('link-nfc-a3')), findsNothing, reason: 'a locked tag offers neither');
      expect(find.byKey(const Key('lock-nfc-a3')), findsNothing);
    });

    testWidgets('no warning when every linked tag is locked', (tester) async {
      await _open(tester, _World([_piece('a1'), _piece('a3', linked: _linkedAt, locked: _lockedAt)]));
      expect(find.byKey(const Key('nfc-lock-warning')), findsNothing);
      expect(find.text('Must lock before shipping'), findsNothing);
    });

    testWidgets('a phone without NFC says so and shows no Link or Lock buttons', (tester) async {
      final world = _World([_piece('a1'), _piece('a2', linked: _linkedAt)]);
      await _open(tester, world, device: FakeNtagDevice(available: false));

      expect(find.byKey(const Key('nfc-unavailable')), findsOneWidget);
      expect(find.byKey(const Key('link-nfc-a1')), findsNothing);
      expect(find.byKey(const Key('lock-nfc-a2')), findsNothing);
      expect(find.text('Preview certificate'), findsWidgets, reason: 'the rest of the board still works');
    });
  });

  group('linking a tag', () {
    testWidgets('writes the address, records the link, and does not call it done: it must still be locked', (tester) async {
      final world = _World([_piece('a1')]);
      final chip = await _open(tester, world);

      await _tap(tester, find.byKey(const Key('link-nfc-a1')));
      expect(find.text('Link NFC tag'), findsOneWidget);
      expect(find.text(verifyUrlFor('a1')), findsOneWidget, reason: 'the exact address that will be written');

      await _tap(tester, find.byKey(const Key('nfc-start')));

      expect(chip.url, verifyUrlFor('a1'));
      expect(world.calls, ['check:link', 'link']);
      expect(find.text('Tag linked'), findsOneWidget);
      expect(find.text('Not locked yet — must lock before shipping'), findsOneWidget);
      expect(chip.fullyLocked, isFalse);
    });

    testWidgets('"Lock later" leaves the piece flagged in red on the board', (tester) async {
      final world = _World([_piece('a1')]);
      await _open(tester, world);
      await _tap(tester, find.byKey(const Key('link-nfc-a1')));
      await _tap(tester, find.byKey(const Key('nfc-start')));
      await _tap(tester, find.byKey(const Key('nfc-lock-later')));

      expect(find.text('Link NFC tag'), findsNothing, reason: 'the sheet closed');
      expect(find.text('Tag linked · unlocked'), findsOneWidget);
      expect(find.text('Must lock before shipping'), findsOneWidget);
      expect(find.byKey(const Key('nfc-lock-warning')), findsOneWidget);
    });

    testWidgets('"Lock now" asks for a second, deliberate tap, then locks for good', (tester) async {
      final world = _World([_piece('a1')]);
      final chip = await _open(tester, world);
      await _tap(tester, find.byKey(const Key('link-nfc-a1')));
      await _tap(tester, find.byKey(const Key('nfc-start')));
      await _tap(tester, find.byKey(const Key('nfc-lock-now')));

      expect(find.text('Locking is permanent'), findsOneWidget);
      expect(chip.fullyLocked, isFalse, reason: 'nothing is locked by getting to the question');

      await _tap(tester, find.byKey(const Key('nfc-start')));

      expect(chip.fullyLocked, isTrue);
      expect(world.calls, ['check:link', 'link', 'check:lock', 'lock']);
      expect(find.text('Tag locked'), findsWidgets);
      expect(find.text('The chip is read-only for good. The piece can now be dispatched.'), findsOneWidget);

      await _tap(tester, find.text('Done'));
      expect(find.text('Tag locked'), findsOneWidget, reason: 'the board reads Locked now');
      expect(find.text('Must lock before shipping'), findsNothing);
      expect(find.byKey(const Key('nfc-lock-warning')), findsNothing);
    });

    testWidgets('a chip the server refuses is explained, untouched, and can be tried again', (tester) async {
      final world = _World([_piece('a1')])..refusal = 'This chip is already linked to another artwork.';
      final chip = await _open(tester, world);
      await _tap(tester, find.byKey(const Key('link-nfc-a1')));
      await _tap(tester, find.byKey(const Key('nfc-start')));

      expect(find.text("The tag wasn't linked"), findsOneWidget);
      expect(find.text('This chip is already linked to another artwork.'), findsOneWidget);
      expect(chip.url, isNull, reason: 'refused before it was written');
      expect(world.calls, contains('failure:uid_mismatch'));

      world.refusal = null;
      await _tap(tester, find.byKey(const Key('nfc-try-again')));
      expect(find.text('Tag linked'), findsOneWidget);
      expect(chip.url, verifyUrlFor('a1'));
    });

    testWidgets('replacing says what it replaces', (tester) async {
      await _open(tester, _World([_piece('a2', linked: _linkedAt)]));
      await _tap(tester, find.byKey(const Key('link-nfc-a2')));

      expect(find.text('Replace NFC tag'), findsOneWidget);
      expect(find.text('This replaces the linked chip'), findsOneWidget);
      expect(find.text('Write a new tag'), findsOneWidget);
    });
  });

  group('locking a tag', () {
    testWidgets('from the board: a chip that does not point at this piece is refused, nothing locked', (tester) async {
      final world = _World([_piece('a2', linked: _linkedAt)]);
      final chip = await _open(tester, world, device: FakeNtagDevice()..url = 'https://www.galleryzone.art/verify/other');
      await _tap(tester, find.byKey(const Key('lock-nfc-a2')));
      await _tap(tester, find.byKey(const Key('nfc-start')));

      expect(find.text("The tag wasn't locked"), findsOneWidget);
      expect(find.textContaining("doesn't hold this artwork's link"), findsOneWidget);
      expect(chip.writtenPages, isEmpty);
      expect(world.calls, ['check:lock', 'failure:uid_mismatch']);
    });

    testWidgets('from the board: locks the chip it was linked to', (tester) async {
      final world = _World([_piece('a2', linked: _linkedAt)]);
      final chip = await _open(tester, world, device: FakeNtagDevice()..url = verifyUrlFor('a2'));
      await _tap(tester, find.byKey(const Key('lock-nfc-a2')));
      expect(find.text('Lock NFC tag'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('nfc-start')));

      expect(chip.fullyLocked, isTrue);
      expect(find.text('Tag locked'), findsWidgets);
    });
  });
}
