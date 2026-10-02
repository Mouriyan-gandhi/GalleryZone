import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_zone/core/nfc/nfc_flow.dart';
import 'package:gallery_zone/core/nfc/ntag213.dart';
import 'package:gallery_zone/core/verify_url.dart';
import 'package:gallery_zone/data/models/nfc.dart';
import 'package:gallery_zone/data/models/passport.dart';
import 'package:gallery_zone/data/remote/mappers/catalog_mappers.dart';
import 'package:gallery_zone/data/remote/mappers/portal_mappers.dart';
import 'package:gallery_zone/data/remote/remote_nfc_repository.dart';

import 'support/catalog_fixtures.dart';
import 'support/fake_api.dart';
import 'support/fake_nfc.dart';

/// NFC_IMPLEMENTATION.md §7 and §11.3, run against an NTAG213 in memory and a
/// scripted server. The point of most of these is ORDER: the server is asked
/// before a chip is touched, and nothing is locked that doesn't point here.

const _uid = '04a1b2c3d4e580';

({FakeNtagDevice device, FakeNfcRepository repository, NfcFlow flow}) _rig({
  FakeNtagDevice? device,
  FakeNfcRepository? repository,
}) {
  final d = device ?? FakeNtagDevice();
  final r = repository ?? FakeNfcRepository();
  return (device: d, repository: r, flow: NfcFlow(device: d, repository: r));
}

String get _url => verifyUrlFor('aw-1');

Future<NfcFlowException> _failure(Future<Object?> run) async {
  try {
    await run;
  } on NfcFlowException catch (failure) {
    return failure;
  }
  fail('expected the flow to fail');
}

void main() {
  group('the NTAG213 commands', () {
    test('READ and WRITE are the two-byte and six-byte frames the chip expects', () {
      expect(Ntag213.read(3), [0x30, 0x03]);
      expect(Ntag213.write(3, [0xE1, 0x10, 0x12, 0x0F]), [0xA2, 0x03, 0xE1, 0x10, 0x12, 0x0F]);
      expect(() => Ntag213.write(3, [1, 2, 3]), throwsArgumentError, reason: 'a page is exactly four bytes');
    });

    test('the capability container keeps what the chip said and only closes write access', () {
      final cc = Uint8List.fromList([0xE1, 0x10, 0x12, 0x00]);
      expect(Ntag213.lockedCapabilityContainer(cc), [0xE1, 0x10, 0x12, 0x0F]);
      expect(Ntag213.lockedCapabilityContainer(Uint8List.fromList([0xE1, 0x10, 0x12, 0x0F])), [0xE1, 0x10, 0x12, 0x0F]);
    });

    test('the static lock keeps the two internal bytes, the dynamic lock keeps the reserved one', () {
      expect(Ntag213.lockedStaticPage(Uint8List.fromList([0xA1, 0x48, 0x00, 0x00])), [0xA1, 0x48, 0xFF, 0xFF]);
      expect(Ntag213.lockedDynamicPage(Uint8List.fromList([0x00, 0x00, 0x00, 0xBD])), [0xFF, 0xFF, 0xFF, 0xBD]);
    });

    test('only an NTAG213 passes: the size byte names it', () {
      expect(Ntag213.isNtag213(Uint8List.fromList([0xE1, 0x10, 0x12, 0x00])), isTrue);
      expect(Ntag213.isNtag213(Uint8List.fromList([0xE1, 0x10, 0x3E, 0x00])), isFalse, reason: 'an NTAG215');
      expect(Ntag213.isNtag213(Uint8List.fromList([0x00, 0x00, 0x00, 0x00])), isFalse, reason: 'never formatted');
    });

    test('"locked" needs all three regions, read back', () {
      Uint8List b(List<int> v) => Uint8List.fromList(v);
      final cc = b([0xE1, 0x10, 0x12, 0x0F]);
      final staticOk = b([0xA1, 0x48, 0xFF, 0xFF]);
      final dynamicOk = b([0xFF, 0xFF, 0xFF, 0xBD]);
      expect(Ntag213.isFullyLocked(capabilityContainer: cc, staticPage: staticOk, dynamicPage: dynamicOk), isTrue);
      expect(Ntag213.isFullyLocked(capabilityContainer: b([0xE1, 0x10, 0x12, 0x00]), staticPage: staticOk, dynamicPage: dynamicOk), isFalse);
      expect(Ntag213.isFullyLocked(capabilityContainer: cc, staticPage: b([0xA1, 0x48, 0xFF, 0x00]), dynamicPage: dynamicOk), isFalse);
      expect(Ntag213.isFullyLocked(capabilityContainer: cc, staticPage: staticOk, dynamicPage: b([0xFF, 0xFF, 0x00, 0xBD])), isFalse);
    });

    test('ids are stored the way the server stores them', () {
      expect(normalizeTagUid('04A1B2C3D4E580'), _uid, reason: 'Android and iOS report upper case');
      expect(normalizeTagUid('04:a1:b2:c3:d4:e5:80'), _uid);
      expect(isNtagUid(_uid), isTrue);
      expect(isNtagUid('04a1b2c3'), isFalse, reason: 'a 4-byte id is some other kind of card');
    });
  });

  group('linking a tag', () {
    test('asks the server first, then writes, checks what was written, then records the link', () async {
      final rig = _rig();
      final progress = <NfcProgress>[];
      final state = await rig.flow.link('aw-1', onProgress: progress.add);

      expect(rig.repository.calls, ['check:link:$_uid', 'confirmLinked:$_uid']);
      // The write sits between the two server calls: the server was asked before the chip was touched.
      final events = rig.device.events;
      expect(events.indexOf('writeUrl'), greaterThan(events.indexOf('poll')));
      expect(rig.device.url, _url, reason: 'the very address the QR carries');
      expect(state.linkedAt, isNotNull);
      expect(state.lockedAt, isNull, reason: 'linking never locks');
      expect(rig.device.fullyLocked, isFalse);
      expect(rig.device.finishedWith, 'Tag linked');
      expect(progress, [
        NfcProgress.waitingForTag,
        NfcProgress.checking,
        NfcProgress.writing,
        NfcProgress.verifyingWrite,
        NfcProgress.recording,
      ]);
    });

    test('a chip the server refuses is never written to', () async {
      final repository = FakeNfcRepository()..checkRefusal = 'This chip is already linked to another artwork.';
      final rig = _rig(repository: repository);
      rig.device.url = 'https://www.galleryzone.art/verify/someone-elses-piece';

      final failure = await _failure(rig.flow.link('aw-1'));

      expect(failure.message, 'This chip is already linked to another artwork.');
      expect(failure.step, NfcFailureStep.uidMismatch);
      expect(rig.device.url, 'https://www.galleryzone.art/verify/someone-elses-piece', reason: 'the other piece\'s chip is untouched');
      expect(rig.device.events, isNot(contains('writeUrl')));
      expect(rig.repository.calls, contains('failure:uid_mismatch'), reason: 'reported to Sentry via the API');
      expect(rig.device.finishedError, failure.message);
    });

    test('a chip that is not an NTAG213 is refused before the server is even asked', () async {
      final unformatted = FakeNtagDevice(capabilityContainer: [0x00, 0x00, 0x00, 0x00]);
      final rig = _rig(device: unformatted);
      final failure = await _failure(rig.flow.link('aw-1'));

      expect(failure.step, NfcFailureStep.chipType);
      expect(failure.message, "This isn't an NTAG213 chip. Please use a GalleryZone-supplied tag.");
      expect(rig.repository.calls.where((c) => c.startsWith('check')), isEmpty);
      expect(unformatted.events, isNot(contains('writeUrl')));

      final other = FakeNtagDevice(mifareUltralight: false);
      expect((await _failure(_rig(device: other).flow.link('aw-1'))).step, NfcFailureStep.chipType);
      final shortId = FakeNtagDevice(uid: '04a1b2c3');
      expect((await _failure(_rig(device: shortId).flow.link('aw-1'))).step, NfcFailureStep.chipType);
    });

    test('a write that does not read back is not recorded', () async {
      final device = FakeNtagDevice()..corruptWrites = true;
      final rig = _rig(device: device);
      final failure = await _failure(rig.flow.link('aw-1'));

      expect(failure.step, NfcFailureStep.write);
      expect(rig.repository.calls, isNot(contains('confirmLinked:$_uid')));
    });

    test('the same chip again is left alone when it already carries the address', () async {
      final device = FakeNtagDevice()..url = _url;
      final rig = _rig(device: device, repository: FakeNfcRepository(linkAction: NfcCheckAction.noop));
      await rig.flow.link('aw-1');

      expect(device.events, isNot(contains('writeUrl')));
      expect(rig.repository.calls, ['check:link:$_uid', 'confirmLinked:$_uid'], reason: 'recording is idempotent');
    });

    test('...but is rewritten if the address on it is not this piece\'s', () async {
      final device = FakeNtagDevice()..url = 'https://www.galleryzone.art/verify/other';
      final rig = _rig(device: device, repository: FakeNfcRepository(linkAction: NfcCheckAction.noop));
      await rig.flow.link('aw-1');
      expect(device.url, _url);
    });

    test('a lost connection after a good write says so, and how to finish', () async {
      final repository = FakeNfcRepository()..confirmFailure = "Can't reach GalleryZone.";
      final rig = _rig(repository: repository);
      final failure = await _failure(rig.flow.link('aw-1'));

      expect(failure.step, NfcFailureStep.confirm);
      expect(failure.message, contains('The tag was written, but GalleryZone could not record it'));
      expect(failure.message, contains('Tap Link tag again'));
      expect(rig.device.url, _url);
    });

    test('no tap in time is not reported as a failure', () async {
      final device = FakeNtagDevice()..noTag = true;
      final rig = _rig(device: device);
      final failure = await _failure(rig.flow.link('aw-1'));

      expect(failure.step, NfcFailureStep.poll);
      expect(failure.message, contains('No tag was found'));
      expect(rig.repository.calls, isEmpty, reason: 'nothing asked, nothing reported');
    });
  });

  group('locking a tag', () {
    FakeNtagDevice linkedChip() => FakeNtagDevice()..url = _url;

    test('sets the capability container, then the static lock, then the dynamic lock, and checks they took', () async {
      final device = linkedChip();
      final rig = _rig(device: device);
      final progress = <NfcProgress>[];
      final state = await rig.flow.lock('aw-1', onProgress: progress.add);

      // Page 3 first: the static lock bytes lock page 3 itself. The fake refuses a CC write after
      // that, so this passing is the proof of the order.
      expect(device.writtenPages, [3, 2, 40]);
      expect(device.fullyLocked, isTrue);
      expect(device.pages[3], [0xE1, 0x10, 0x12, 0x0F]);
      expect(device.pages[2], [0xA1, 0x48, 0xFF, 0xFF], reason: 'the chip\'s own bytes are kept');
      expect(device.pages[40], [0xFF, 0xFF, 0xFF, 0xBD]);
      expect(rig.repository.calls, ['check:lock:$_uid', 'confirmLocked:$_uid']);
      expect(state.lockedAt, isNotNull);
      expect(device.url, _url, reason: 'locking never changes the address');
      expect(progress, [
        NfcProgress.waitingForTag,
        NfcProgress.checking,
        NfcProgress.locking,
        NfcProgress.verifyingLock,
        NfcProgress.recording,
      ]);
    });

    test('the server is asked before a single lock byte is written', () async {
      final rig = _rig(device: linkedChip());
      await rig.flow.lock('aw-1');
      // check is the first thing the repository saw; the device's first write came after the poll.
      expect(rig.repository.calls.first, 'check:lock:$_uid');
    });

    test('the wrong chip is refused with no lock byte written', () async {
      final repository = FakeNfcRepository()..checkRefusal = "This isn't the chip that was linked to this artwork. Tap the original chip.";
      final device = linkedChip();
      final rig = _rig(device: device, repository: repository);
      final failure = await _failure(rig.flow.lock('aw-1'));

      expect(failure.message, contains('Tap the original chip'));
      expect(device.writtenPages, isEmpty);
      expect(device.fullyLocked, isFalse);
    });

    test('a chip that does not carry this artwork\'s address is never locked: the address is permanent', () async {
      final device = FakeNtagDevice()..url = 'https://www.galleryzone.art/verify/some-other-piece';
      final rig = _rig(device: device);
      final failure = await _failure(rig.flow.lock('aw-1'));

      expect(failure.message, contains("doesn't hold this artwork's link"));
      expect(device.writtenPages, isEmpty);

      final blank = FakeNtagDevice();
      expect((await _failure(_rig(device: blank).flow.lock('aw-1'))).message, contains("doesn't hold this artwork's link"));
      expect(blank.writtenPages, isEmpty);
    });

    test('a lock that only looks like it worked is caught by reading the lock bytes back', () async {
      final device = linkedChip()..ignoreCapabilityWrites = true;
      final rig = _rig(device: device);
      final failure = await _failure(rig.flow.lock('aw-1'));

      expect(failure.step, NfcFailureStep.verifyLock);
      expect(failure.message, contains("didn't lock completely"));
      expect(rig.repository.calls, isNot(contains('confirmLocked:$_uid')), reason: 'nothing recorded for a lock that did not take');
    });

    test('running it again on a chip that is already locked only records it', () async {
      final device = linkedChip();
      await _rig(device: device).flow.lock('aw-1');
      expect(device.fullyLocked, isTrue);
      device.writtenPages.clear();

      // The first run locked the chip but lost its connection before the record.
      final rig = _rig(device: device);
      final state = await rig.flow.lock('aw-1');
      expect(device.writtenPages, isEmpty, reason: 'every step already shows done, so none is repeated');
      expect(rig.repository.calls, ['check:lock:$_uid', 'confirmLocked:$_uid']);
      expect(state.lockedAt, isNotNull);
    });

    test('...and a half-locked chip gets only the steps it is missing', () async {
      final device = linkedChip();
      device.pages[3][3] = 0x0F; // an earlier attempt got as far as the capability container
      await _rig(device: device).flow.lock('aw-1');
      expect(device.writtenPages, [2, 40]);
      expect(device.fullyLocked, isTrue);
    });

    test('the server saying it is already locked skips the chip entirely', () async {
      final device = linkedChip();
      final rig = _rig(device: device, repository: FakeNfcRepository(lockAction: NfcCheckAction.noop));
      await rig.flow.lock('aw-1');
      expect(device.writtenPages, isEmpty);
      expect(rig.repository.calls, ['check:lock:$_uid', 'confirmLocked:$_uid']);
    });

    test('a connection lost after the lock says the chip IS locked and how to finish', () async {
      final repository = FakeNfcRepository()..confirmFailure = "Can't reach GalleryZone.";
      final device = linkedChip();
      final rig = _rig(device: device, repository: repository);
      final failure = await _failure(rig.flow.lock('aw-1'));

      expect(device.fullyLocked, isTrue);
      expect(failure.step, NfcFailureStep.confirm);
      expect(failure.message, startsWith('The tag is locked, but GalleryZone could not record it'));
      expect(failure.message, contains('Tap Lock tag again'));
    });

    test('a tag that cannot be locked any more because it was locked first by something else fails on its step', () async {
      final device = linkedChip();
      device.pages[2][2] = 0xFF; // L-CC set but the capability container never closed
      device.pages[2][3] = 0xFF;
      final rig = _rig(device: device);
      final failure = await _failure(rig.flow.lock('aw-1'));
      expect(failure.step, NfcFailureStep.lockCc);
      expect(rig.repository.failures.single.$1, NfcFailureStep.lockCc);
    });
  });

  group('what the API sends', () {
    test('an artwork carries the tag as three fields, none of them required', () {
      final base = {
        'id': 'a1',
        'title': 'Dusk',
        'artistId': 'u1',
        'artistName': 'Ananya Rao',
        'category': 'painting',
        'medium': 'oil',
        'displayPricePaise': 100000,
        'images': <Object>[],
        'status': 'marketplace',
        'listingType': 'marketplace_only',
      };
      expect(artworkFromApi(base).nfcStage, NfcStage.unlinked, reason: 'a public listing carries none of it');

      final linked = artworkFromApi({...base, 'nfcTagUid': _uid, 'nfcLinkedAt': '2026-09-28T10:00:00.000Z', 'nfcLockedAt': null});
      expect(linked.nfcStage, NfcStage.linkedUnlocked);
      expect(linked.nfcNeedsLock, isTrue);
      expect(linked.nfcTagUid, _uid);

      final locked = artworkFromApi({...base, 'nfcTagUid': _uid, 'nfcLinkedAt': '2026-09-28T10:00:00.000Z', 'nfcLockedAt': '2026-09-28T10:05:00.000Z'});
      expect(locked.nfcStage, NfcStage.linkedLocked);
      expect(locked.nfcNeedsLock, isFalse);

      // The retired field means nothing any more.
      expect(artworkFromApi({...base, 'nfcTagId': 'NFC-OLD12345'}).nfcStage, NfcStage.unlinked);
    });

    test('the passport carries the two public flags and the lifecycle, and drops a collector\'s place', () {
      final passport = passportFromApi({
        'artworkId': 'a1',
        'title': 'Dusk',
        'owner': {'kind': 'collector', 'displayName': 'Ravi K'},
        'listedAt': '2026-03-02T00:00:00.000Z',
        'events': <Object>[],
        'nfcLinked': true,
        'nfcLocked': true,
        'lifecycle': [
          {
            'id': 'created',
            'kind': 'created',
            'at': '2026-03-01T10:00:00.000Z',
            'actor': {'kind': 'artist', 'displayName': 'Ananya Rao'},
            'location': {'city': 'Pune', 'state': 'Maharashtra', 'country': 'India'},
            'note': null,
          },
          {
            'id': 'sale:o1',
            'kind': 'sold_marketplace',
            'at': '2026-06-10T10:00:00.000Z',
            'actor': {'kind': 'collector', 'displayName': 'Ravi K'},
            // Never sent by the server; if it ever were, it is not kept.
            'location': {'city': 'Mumbai', 'state': 'Maharashtra', 'country': 'India'},
            'note': null,
          },
        ],
      });
      expect(passport.nfcLinked, isTrue);
      expect(passport.nfcLocked, isTrue);
      expect(passport.lifecycle.map((e) => e.kind), [LifecycleKind.created, LifecycleKind.soldMarketplace]);
      expect(passport.lifecycle.first.place?.label, 'Pune, Maharashtra, India');
      expect(passport.lifecycle.last.place, isNull);
    });

    test('a locked flag without a linked one is not believed', () {
      final passport = passportFromApi({'artworkId': 'a1', 'owner': {'kind': 'artist'}, 'nfcLinked': false, 'nfcLocked': true});
      expect(passport.nfcLocked, isFalse);
    });

    test('an older API says nothing about tags, and the passport reads as untagged', () {
      final passport = passportFromApi({'artworkId': 'a1', 'owner': {'kind': 'artist'}});
      expect(passport.nfcLinked, isFalse);
      expect(passport.lifecycle, isEmpty);
    });

    test('a sale is "ready" unless the API says its piece is unlocked and not waved through', () {
      Map<String, dynamic> sale(Map<String, dynamic> extra) => {'id': 's1', 'holdingId': 'h1', 'artworkId': 'a1', 'shipmentStatus': 'preparing', ...extra};
      expect(saleFromApi(sale({})).nfcReady, isTrue, reason: 'older API: say nothing rather than guess');
      expect(saleFromApi(sale({'nfcLocked': true})).nfcReady, isTrue);
      expect(saleFromApi(sale({'nfcLocked': false})).nfcReady, isFalse);
      expect(saleFromApi(sale({'nfcLocked': false, 'nfcGateOverridden': true})).nfcReady, isTrue);
    });
  });

  group('the NFC routes', () {
    test('check, link, lock and failure go where the server expects them', () async {
      final api = FakeApi()
        ..json('POST /v1/artist/artworks/aw-1/nfc/check', {'artworkId': 'aw-1', 'intent': 'link', 'action': 'replace'})
        ..json('POST /v1/artist/artworks/aw-1/nfc/link', {'artworkId': 'aw-1', 'nfcTagUid': _uid, 'nfcLinkedAt': '2026-10-02T12:00:00.000Z', 'nfcLockedAt': null})
        ..json('POST /v1/artist/artworks/aw-1/nfc/lock', {'artworkId': 'aw-1', 'nfcTagUid': _uid, 'nfcLinkedAt': '2026-10-02T12:00:00.000Z', 'nfcLockedAt': '2026-10-02T12:05:00.000Z'})
        ..json('POST /v1/artist/artworks/aw-1/nfc/failure', null, status: 204);
      final repository = RemoteNfcRepository(api.client());

      expect(await repository.check('aw-1', _uid, NfcIntent.link), NfcCheckAction.replace);
      final linked = await repository.confirmLinked('aw-1', _uid);
      expect(linked.stage, NfcStage.linkedUnlocked);
      final locked = await repository.confirmLocked('aw-1', _uid);
      expect(locked.stage, NfcStage.linkedLocked);
      await repository.reportFailure('aw-1', NfcFailureStep.lockStatic, 'x' * 500, tagUid: _uid);

      expect(api.bodiesOf('POST /v1/artist/artworks/aw-1/nfc/check'), [
        {'tagUid': _uid, 'intent': 'link'},
      ]);
      expect(api.bodiesOf('POST /v1/artist/artworks/aw-1/nfc/link'), [
        {'tagUid': _uid},
      ]);
      final failure = api.bodiesOf('POST /v1/artist/artworks/aw-1/nfc/failure').single! as Map;
      expect(failure['step'], 'lock_static');
      expect((failure['message'] as String).length, 300, reason: 'the server caps it at 300');
    });

    test('a refusal arrives with the server\'s own words', () async {
      final api = FakeApi()
        ..problem('POST /v1/artist/artworks/aw-1/nfc/check', 409, 'tag_already_bound', 'This chip is already linked to another artwork.');
      final failure = await _failure(
        NfcFlow(device: FakeNtagDevice()..url = null, repository: RemoteNfcRepository(api.client())).link('aw-1'),
      );
      expect(failure.message, 'This chip is already linked to another artwork.');
    });

    test('reporting a failure never throws, even offline', () async {
      final api = FakeApi();
      await RemoteNfcRepository(api.client()).reportFailure('aw-1', NfcFailureStep.write, 'x');
    });
  });

  test('the artwork fixture helper builds all three states', () {
    expect(fixtureArtwork().nfcStage, NfcStage.unlinked);
    expect(fixtureArtwork(nfcLinkedAt: '2026-10-01T00:00:00.000Z').nfcStage, NfcStage.linkedUnlocked);
    expect(fixtureArtwork(nfcLinkedAt: '2026-10-01T00:00:00.000Z', nfcLockedAt: '2026-10-02T00:00:00.000Z').nfcStage, NfcStage.linkedLocked);
  });
}
