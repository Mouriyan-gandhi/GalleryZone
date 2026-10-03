import 'artwork.dart';

/// The NFC tag on a piece, in the three states the plan defines
/// (NFC_IMPLEMENTATION.md §3). The first two are not the end of the story: a
/// linked tag that is not locked can still be rewritten, and the piece cannot
/// be dispatched until it is.
enum NfcStage { unlinked, linkedUnlocked, linkedLocked }

extension ArtworkNfc on Artwork {
  NfcStage get nfcStage {
    if (nfcLinkedAt == null) return NfcStage.unlinked;
    return nfcLockedAt == null ? NfcStage.linkedUnlocked : NfcStage.linkedLocked;
  }

  /// Linked, never locked: the red "must lock before shipping" state.
  bool get nfcNeedsLock => nfcStage == NfcStage.linkedUnlocked;
}

String nfcStageLabel(NfcStage stage) => switch (stage) {
      NfcStage.unlinked => 'Not yet tagged',
      NfcStage.linkedUnlocked => 'Tag linked · unlocked',
      NfcStage.linkedLocked => 'Tag locked',
    };

/// What the app is about to do to a chip, asked of the server first.
enum NfcIntent { link, lock }

/// What the server says the call would do. [noop] means it is already so: the
/// write or the lock can be skipped.
enum NfcCheckAction { link, replace, lock, noop }

/// Where in the write/lock sequence something went wrong. The names are the
/// ones the server groups failures by when it relays them to Sentry.
enum NfcFailureStep {
  poll('poll'),
  chipType('chip_type'),
  write('write'),
  readUid('read_uid'),
  uidMismatch('uid_mismatch'),
  lockCc('lock_cc'),
  lockStatic('lock_static'),
  lockDynamic('lock_dynamic'),
  verifyLock('verify_lock'),
  confirm('confirm');

  const NfcFailureStep(this.api);

  final String api;
}

/// The tag as the server records it after a link or a lock.
class NfcState {
  const NfcState({required this.artworkId, this.tagUid, this.linkedAt, this.lockedAt});

  final String artworkId;

  /// Only the owning artist and admins are ever sent this.
  final String? tagUid;
  final String? linkedAt;
  final String? lockedAt;

  NfcStage get stage {
    if (linkedAt == null) return NfcStage.unlinked;
    return lockedAt == null ? NfcStage.linkedUnlocked : NfcStage.linkedLocked;
  }
}
