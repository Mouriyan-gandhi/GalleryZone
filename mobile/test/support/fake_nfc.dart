import 'dart:typed_data';

import 'package:gallery_zone/core/nfc/nfc_device.dart';
import 'package:gallery_zone/data/models/nfc.dart';
import 'package:gallery_zone/data/repositories/nfc_repository.dart';

/// An NTAG213 in memory, faithful in the ways the lock sequence depends on:
/// pages of four bytes, the capability container and the lock bytes are
/// one-time programmable (bits only ever go 0 -> 1), the static lock bytes lock
/// page 3 itself, and a write to a locked page is refused (a NAK, which the
/// phone's NFC stack raises as an error).
///
/// Simulators have no NFC, so this is what the write and lock flows run against.
class FakeNtagDevice implements NfcDevice {
  FakeNtagDevice({
    this.uid = '04a1b2c3d4e580',
    this.available = true,
    this.mifareUltralight = true,
    List<int>? capabilityContainer,
  }) : pages = List.generate(45, (_) => Uint8List(4)) {
    pages[2].setAll(0, [0xA1, 0x48, 0x00, 0x00]); // BCC1, internal, LOCK0, LOCK1
    pages[3].setAll(0, capabilityContainer ?? [0xE1, 0x10, 0x12, 0x00]);
    pages[40].setAll(0, [0x00, 0x00, 0x00, 0xBD]); // dynamic lock bytes + reserved
  }

  String uid;
  bool available;
  bool mifareUltralight;
  final List<Uint8List> pages;

  /// No chip arrives within the timeout.
  bool noTag = false;

  /// The chip stores a different address from the one it was given.
  bool corruptWrites = false;

  /// Writes to the capability container are accepted but do nothing: a lock that
  /// reports success and did not happen.
  bool ignoreCapabilityWrites = false;

  String? url;
  final writtenPages = <int>[];
  final events = <String>[];
  String? finishedWith;
  String? finishedError;

  bool get capabilityLocked => (pages[3][3] & 0x0F) == 0x0F;
  bool get staticLocked => pages[2][2] == 0xFF && pages[2][3] == 0xFF;
  bool get dynamicLocked => pages[40][0] == 0xFF && pages[40][1] == 0xFF && pages[40][2] == 0xFF;
  bool get fullyLocked => capabilityLocked && staticLocked && dynamicLocked;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<NfcChip> poll({Duration timeout = const Duration(seconds: 20)}) async {
    events.add('poll');
    if (noTag) throw Exception('Polling tag timeout');
    return NfcChip(uid: uid, isMifareUltralight: mifareUltralight);
  }

  bool _userPageLocked(int page) {
    if (page <= 7) return (pages[2][2] & (1 << page)) != 0;
    if (page <= 15) return (pages[2][3] & (1 << (page - 8))) != 0;
    return pages[40][0] == 0xFF && pages[40][1] == 0xFF;
  }

  @override
  Future<Uint8List> transceive(Uint8List command) async {
    final page = command[1];
    if (command[0] == 0x30) {
      events.add('read:$page');
      return Uint8List.fromList([for (var i = 0; i < 4; i++) ...pages[(page + i) % pages.length]]);
    }
    assert(command[0] == 0xA2 && command.length == 6, 'a WRITE is A2, page, four bytes');
    events.add('write:$page');
    writtenPages.add(page);
    final data = command.sublist(2);
    final old = pages[page];
    switch (page) {
      case 2:
        old[2] |= data[2];
        old[3] |= data[3];
      case 3:
        if ((pages[2][2] & 0x08) != 0) throw Exception('NAK: page 3 is locked');
        if (ignoreCapabilityWrites) return Uint8List(0);
        for (var i = 0; i < 4; i++) {
          old[i] |= data[i];
        }
      case 40:
        for (var i = 0; i < 3; i++) {
          old[i] |= data[i];
        }
      default:
        if (page < 4 || page > 39) throw Exception('NAK: page $page is not writable');
        if (_userPageLocked(page)) throw Exception('NAK: page $page is locked');
        old.setAll(0, data);
    }
    return Uint8List(0);
  }

  @override
  Future<void> writeUrl(String address) async {
    events.add('writeUrl');
    if (capabilityLocked || _userPageLocked(4)) throw Exception('The tag is read-only');
    url = corruptWrites ? '${address}x' : address;
  }

  @override
  Future<String?> readUrl() async {
    events.add('readUrl');
    return url;
  }

  @override
  Future<void> finish({String? message, String? error}) async {
    events.add('finish');
    finishedWith = message;
    finishedError = error;
  }
}

/// The server's side, scripted. Records every call so a test can assert the
/// ORDER things happened in.
class FakeNfcRepository implements NfcRepository {
  FakeNfcRepository({this.linkAction = NfcCheckAction.link, this.lockAction = NfcCheckAction.lock});

  NfcCheckAction linkAction;
  NfcCheckAction lockAction;

  /// Throws this from `check`, as the server's refusal.
  String? checkRefusal;

  /// Throws this from `confirmLinked` / `confirmLocked`.
  String? confirmFailure;

  /// Every call, in order.
  final calls = <String>[];

  final failures = <(NfcFailureStep, String)>[];

  NfcState state = const NfcState(artworkId: 'aw-1');

  @override
  Future<NfcCheckAction> check(String artworkId, String tagUid, NfcIntent intent) async {
    calls.add('check:${intent.name}:$tagUid');
    if (checkRefusal != null) throw Exception(checkRefusal);
    return intent == NfcIntent.link ? linkAction : lockAction;
  }

  @override
  Future<NfcState> confirmLinked(String artworkId, String tagUid) async {
    calls.add('confirmLinked:$tagUid');
    if (confirmFailure != null) throw Exception(confirmFailure);
    return state = NfcState(artworkId: artworkId, tagUid: tagUid, linkedAt: '2026-10-02T12:00:00.000Z');
  }

  @override
  Future<NfcState> confirmLocked(String artworkId, String tagUid) async {
    calls.add('confirmLocked:$tagUid');
    if (confirmFailure != null) throw Exception(confirmFailure);
    return state = NfcState(
      artworkId: artworkId,
      tagUid: tagUid,
      linkedAt: '2026-10-02T12:00:00.000Z',
      lockedAt: '2026-10-02T12:05:00.000Z',
    );
  }

  @override
  Future<void> reportFailure(String artworkId, NfcFailureStep step, String message, {String? tagUid}) async {
    failures.add((step, message));
    calls.add('failure:${step.api}');
  }

}
