import { http } from "@/lib/api";

// Linking a physical NFC chip to an artwork (NFC_IMPLEMENTATION.md §4, §8).
//
// The browser can write a chip (Web NFC, Chrome on Android) and tell the server;
// it cannot lock one, so there is no lock call here — that is the mobile app's job.
// The server keeps the chip's UID private: only the owning artist and admins see it.

/** What link, unlink and the admin calls answer with. */
export interface NfcStateResult {
  artworkId: string;
  nfcTagUid: string | null;
  nfcLinkedAt: string | null;
  nfcLockedAt: string | null;
}

export type NfcCheckAction = "link" | "replace" | "lock" | "noop";

const artworkPath = (artworkId: string) => `/v1/artist/artworks/${encodeURIComponent(artworkId)}`;
const adminArtworkPath = (artworkId: string) => `/v1/admin/artworks/${encodeURIComponent(artworkId)}`;

export interface NfcOverview {
  gateEnforced: boolean;
  counts: { total: number; unlinked: number; linkedUnlocked: number; locked: number; gateOverridden: number };
  awaitingLock: { artworkId: string; title: string; artistId: string; linkedAt: string }[];
  recent: { id: string; action: string; artworkId: string; title: string | null; actorId: string; at: string; detail: unknown }[];
}

export const nfcTagService = {
  /** Before touching the chip: would linking it be allowed? Throws the server's refusal (tag_already_bound, nfc_already_locked, ...). */
  checkLink: (artworkId: string, tagUid: string) =>
    http.post<{ artworkId: string; intent: "link"; action: NfcCheckAction }>(`${artworkPath(artworkId)}/nfc/check`, { tagUid, intent: "link" }),

  /** After the URL is written: record the chip. The same chip again is a no-op; a different one replaces it until it is locked. */
  confirmLinked: (artworkId: string, tagUid: string) => http.post<NfcStateResult>(`${artworkPath(artworkId)}/nfc/link`, { tagUid }),

  /** The app tells the server a write failed on the phone, so it reaches Sentry with the step it failed at. Never throws. */
  reportFailure: async (artworkId: string, step: string, message: string): Promise<void> => {
    try {
      await http.post(`${artworkPath(artworkId)}/nfc/failure`, { step, message: message.slice(0, 300) });
    } catch {
      // Reporting is best-effort; the artist already has their error.
    }
  },

  // --- Admin ---------------------------------------------------------------------------

  /** Reset a link made to a defective chip. Only before the lock; a reason is required. */
  adminUnlink: (artworkId: string, reason: string) => http.post<NfcStateResult>(`${adminArtworkPath(artworkId)}/nfc/unlink`, { reason }),

  /** Let one piece be dispatched without a locked tag (legacy pieces). A reason is required and audit-logged. */
  adminSkipShipmentGate: (artworkId: string, reason: string) =>
    http.post<{ artworkId: string; nfcShipmentGateOverrideAt: string; nfcShipmentGateOverrideReason: string }>(`${adminArtworkPath(artworkId)}/nfc/skip-shipment-gate`, { reason }),

  /** Email the artist to link or lock the tag. */
  adminRemind: (artworkId: string) => http.post<{ sent: boolean }>(`${adminArtworkPath(artworkId)}/nfc/remind`),

  adminOverview: () => http.get<NfcOverview>("/v1/admin/nfc/overview"),
};
