import 'dart:typed_data';

/// The NXP NTAG213 commands this app sends, and what a locked chip looks like
/// (NFC_IMPLEMENTATION.md §1, §7.5). Pure: bytes in, bytes out, so every
/// command and every judgement about a chip's lock state can be tested without
/// a chip. Everything irreversible the app ever does to a tag is built here.
///
/// Layout of the pages that matter (4 bytes each):
///
///   page 2   BCC1, internal, LOCK0, LOCK1      static lock bytes
///   page 3   E1, 10, 12, RW                    capability container (RW 00 = writable, 0F = read-only)
///   pages 4–39                                 user memory, the NDEF message
///   page 40  LOCK2, LOCK3, LOCK4, RFUI         dynamic lock bytes (pages 16–39)
///
/// Lock bits and the capability container's write access are one-time
/// programmable: once set they cannot be cleared by anyone.
class Ntag213 {
  Ntag213._();

  static const readCommand = 0x30;
  static const writeCommand = 0xA2;

  static const staticLockPage = 2;
  static const capabilityContainerPage = 3;
  static const firstUserPage = 4;
  static const dynamicLockPage = 40;

  /// The capability container's size byte: 0x12 × 8 = 144 bytes, the NTAG213.
  /// (NTAG215 is 0x3E, NTAG216 0x6D.)
  static const capabilitySizeByte = 0x12;
  static const capabilityMagic = 0xE1;

  /// CC byte 3 with write access refused: the NDEF area is read-only.
  static const readOnlyAccess = 0x0F;

  /// READ returns four pages (16 bytes) starting at [page].
  static Uint8List read(int page) => Uint8List.fromList([readCommand, page]);

  /// WRITE puts exactly one page (4 bytes).
  static Uint8List write(int page, List<int> data) {
    if (data.length != 4) throw ArgumentError('A page is 4 bytes, got ${data.length}');
    return Uint8List.fromList([writeCommand, page, ...data]);
  }

  /// The first page of a READ response.
  static Uint8List firstPage(Uint8List response) {
    if (response.length < 4) throw StateError('A READ answers 16 bytes, got ${response.length}');
    return Uint8List.sublistView(response, 0, 4);
  }

  /// Is this the capability container of an NTAG213? Anything else (a different
  /// chip, or one never formatted) is refused before it is written or locked.
  static bool isNtag213(Uint8List capabilityContainer) =>
      capabilityContainer.length >= 4 &&
      capabilityContainer[0] == capabilityMagic &&
      capabilityContainer[2] == capabilitySizeByte;

  /// CC with the read-only access byte set. The first three bytes are kept as
  /// read, not assumed.
  static Uint8List lockedCapabilityContainer(Uint8List current) =>
      Uint8List.fromList([current[0], current[1], current[2], current[3] | readOnlyAccess]);

  /// Static lock bytes: pages 3–15 read-only and the lock bits themselves
  /// frozen. The two internal bytes are kept as read (the chip ignores them).
  static Uint8List lockedStaticPage(Uint8List current) =>
      Uint8List.fromList([current[0], current[1], 0xFF, 0xFF]);

  /// Dynamic lock bytes: pages 16–39 read-only. The fourth byte is reserved and
  /// kept as the chip reported it (0xBD from the factory).
  static Uint8List lockedDynamicPage(Uint8List current) =>
      Uint8List.fromList([0xFF, 0xFF, 0xFF, current[3]]);

  /// Has the whole chip been locked? The three regions, read back, are the proof
  /// — not a status code from a write, which the OS does not always surface.
  static bool isFullyLocked({
    required Uint8List capabilityContainer,
    required Uint8List staticPage,
    required Uint8List dynamicPage,
  }) =>
      capabilityContainer.length >= 4 &&
      (capabilityContainer[3] & readOnlyAccess) == readOnlyAccess &&
      staticPage.length >= 4 &&
      staticPage[2] == 0xFF &&
      staticPage[3] == 0xFF &&
      dynamicPage.length >= 4 &&
      dynamicPage[0] == 0xFF &&
      dynamicPage[1] == 0xFF &&
      dynamicPage[2] == 0xFF;
}

/// Hex <-> bytes, as the OS hands a chip's id over as hex text.
String toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// A chip's UID in the one form the server stores: 7 bytes, 14 lowercase hex
/// characters, no separators. Android and iOS report it upper-case.
String normalizeTagUid(String raw) => raw.trim().toLowerCase().replaceAll(RegExp(r'[\s:\-]'), '');

bool isNtagUid(String uid) => RegExp(r'^[0-9a-f]{14}$').hasMatch(uid);
