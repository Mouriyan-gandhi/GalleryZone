import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/nfc/nfc_flow.dart';
import 'package:gallery_zone/core/verify_url.dart';
import 'package:gallery_zone/data/mock/mock_artist_repository.dart';
import 'package:gallery_zone/data/mock/mock_nfc_repository.dart';
import 'package:gallery_zone/data/models/nfc.dart';
import 'package:gallery_zone/data/storage/mock_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_nfc.dart';

/// The offline demo (`--dart-define=GZ_MOCK=true`) is how the app is tried with a real
/// chip before the API has the NFC routes. This runs the real flow against the demo's own
/// artist and artworks, so what a person taps through there is what is tested here.

Future<List<String>> _stages(MockArtistRepository artist) async =>
    [for (final a in await artist.listArtworks()) '${a.artwork.id}:${a.artwork.nfcStage.name}'];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockDb.resetForTesting();
    await MockDb.init();
  });

  test('the demo artist has pieces to tag, and linking then locking moves them through the three states', () async {
    final artist = MockArtistRepository();
    final first = (await artist.listArtworks()).first.artwork;
    expect(first.nfcStage, NfcStage.unlinked);

    final chip = FakeNtagDevice();
    final flow = NfcFlow(device: chip, repository: MockNfcRepository());

    await flow.link(first.id);
    var now = (await artist.listArtworks()).firstWhere((a) => a.artwork.id == first.id).artwork;
    expect(now.nfcStage, NfcStage.linkedUnlocked);
    expect(now.nfcTagUid, '04a1b2c3d4e580');
    expect(chip.url, verifyUrlFor(first.id));

    await flow.lock(first.id);
    now = (await artist.listArtworks()).firstWhere((a) => a.artwork.id == first.id).artwork;
    expect(now.nfcStage, NfcStage.linkedLocked);
    expect(chip.fullyLocked, isTrue);
  });

  test('one chip cannot be linked to two pieces, and a locked tag cannot be linked again', () async {
    final artist = MockArtistRepository();
    final pieces = (await artist.listArtworks()).map((a) => a.artwork).toList();
    expect(pieces.length, greaterThan(1));
    final repository = MockNfcRepository();

    final chip = FakeNtagDevice();
    await NfcFlow(device: chip, repository: repository).link(pieces[0].id);

    final second = FakeNtagDevice(); // the very same chip id
    await expectLater(
      NfcFlow(device: second, repository: repository).link(pieces[1].id),
      throwsA(isA<NfcFlowException>().having((e) => e.message, 'message', 'This chip is already linked to another artwork.')),
    );
    expect(second.url, isNull, reason: 'the first piece\'s chip was not overwritten');

    await NfcFlow(device: chip, repository: repository).lock(pieces[0].id);
    await expectLater(
      NfcFlow(device: FakeNtagDevice(uid: '04ffeeddccbbaa'), repository: repository).link(pieces[0].id),
      throwsA(isA<NfcFlowException>().having((e) => e.message, 'message', contains('locked'))),
    );
    expect(await _stages(artist), contains('${pieces[0].id}:linkedLocked'));
  });

  test('the passport in the demo reads the same state', () async {
    final artist = MockArtistRepository();
    final piece = (await artist.listArtworks()).first.artwork;
    final repository = MockNfcRepository();
    await NfcFlow(device: FakeNtagDevice(), repository: repository).link(piece.id);
    final stored = (await artist.listArtworks()).firstWhere((a) => a.artwork.id == piece.id).artwork;
    expect(stored.nfcLinkedAt, isNotNull);
    expect(stored.nfcLockedAt, isNull);
  });
}
