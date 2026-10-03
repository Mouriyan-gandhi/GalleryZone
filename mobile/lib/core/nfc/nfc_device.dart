import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

import 'ntag213.dart';

/// A chip held against the phone, as the OS read it.
class NfcChip {
  const NfcChip({required this.uid, required this.isMifareUltralight});

  /// Lower-case hex, no separators (see [normalizeTagUid]).
  final String uid;

  /// NTAG213 is an NFC Forum Type 2 tag that the OS reports as MIFARE
  /// Ultralight. Anything else is not one of ours.
  final bool isMifareUltralight;
}

/// What the phone's NFC reader can do, behind a seam so the write and lock
/// flows run in tests with no hardware (simulators have no NFC).
abstract class NfcDevice {
  /// False on a phone with no NFC, or with it switched off.
  Future<bool> isAvailable();

  /// Waits for a chip to be held to the phone and opens a session on it.
  /// Throws if none arrives in [timeout].
  Future<NfcChip> poll({Duration timeout = const Duration(seconds: 20)});

  /// Sends one raw command to the chip and returns its answer.
  Future<Uint8List> transceive(Uint8List command);

  /// Replaces the chip's NDEF message with a single URI record.
  Future<void> writeUrl(String url);

  /// The URI the chip's first NDEF record holds, or null when it holds none.
  Future<String?> readUrl();

  /// Ends the session. [error] shows the failure in the iOS reader sheet.
  Future<void> finish({String? message, String? error});
}

/// The real reader, over `flutter_nfc_kit`: NDEF read/write and raw commands in
/// one package, which is what the lock step needs.
class FlutterNfcKitDevice implements NfcDevice {
  const FlutterNfcKitDevice();

  @override
  Future<bool> isAvailable() async {
    try {
      return await FlutterNfcKit.nfcAvailability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<NfcChip> poll({Duration timeout = const Duration(seconds: 20)}) async {
    final tag = await FlutterNfcKit.poll(
      timeout: timeout,
      iosAlertMessage: 'Hold the tag to the back of your phone',
      iosMultipleTagMessage: 'More than one tag found. Hold just one.',
    );
    return NfcChip(uid: normalizeTagUid(tag.id), isMifareUltralight: tag.type == NFCTagType.mifare_ultralight);
  }

  @override
  Future<Uint8List> transceive(Uint8List command) => FlutterNfcKit.transceive(command);

  @override
  Future<void> writeUrl(String url) => FlutterNfcKit.writeNDEFRecords([ndef.UriRecord.fromString(url)]);

  @override
  Future<String?> readUrl() async {
    final records = await FlutterNfcKit.readNDEFRecords();
    for (final record in records) {
      if (record is ndef.UriRecord) return record.uri?.toString();
    }
    return null;
  }

  @override
  Future<void> finish({String? message, String? error}) async {
    try {
      await FlutterNfcKit.finish(iosAlertMessage: message, iosErrorMessage: error);
    } catch (_) {
      // Closing a session that is already gone is not worth telling anyone about.
    }
  }
}
