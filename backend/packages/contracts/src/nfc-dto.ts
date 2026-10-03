// Request and response shapes for the NFC routes (NFC_IMPLEMENTATION.md §4):
// the artist's and gallery's link/lock calls, the admin's unlink and shipment
// override, and the app's failure report. The web and the Flutter app mirror
// these by hand, so this file is the one place the contract is written down.

import { z } from "zod";

/**
 * The chip's UID as the phone read it. Upper or lower case and ":" separators are
 * accepted and normalised by packages/db's parseTagUid (Android and iOS hand it
 * over as upper-case hex, Chrome's Web NFC as colon-separated); the length is not
 * negotiable — an NTAG213 has a 7-byte UID, 14 hex characters. A wrong one is
 * answered 400 invalid_tag_uid.
 */
export const tagUidInputSchema = z.object({ tagUid: z.string().min(1).max(40) }).strict();
export type TagUidInput = z.infer<typeof tagUidInputSchema>;

/** Ask, before touching the chip, whether linking or locking it is allowed. Nothing is changed. */
export const checkNfcInputSchema = z.object({ tagUid: z.string().min(1).max(40), intent: z.enum(["link", "lock"]) }).strict();
export type CheckNfcInput = z.infer<typeof checkNfcInputSchema>;

/** What `check` answers: what the call would do (`noop` = already so, so the write or lock can be skipped). */
export interface NfcCheckDto {
  artworkId: string;
  intent: "link" | "lock";
  action: "link" | "replace" | "lock" | "noop";
}

/** Admin unlink and shipment override: a reason is always required, and is audit-logged. */
export const nfcReasonInputSchema = z.object({ reason: z.string().trim().min(1).max(500) }).strict();
export type NfcReasonInput = z.infer<typeof nfcReasonInputSchema>;

/** Where in the write/lock sequence the app gave up (§7.4, §7.5), so a Sentry search can group failures by step. */
export const nfcFailureStepValues = ["poll", "chip_type", "write", "read_uid", "uid_mismatch", "lock_cc", "lock_static", "lock_dynamic", "verify_lock", "confirm"] as const;
export type NfcFailureStep = (typeof nfcFailureStepValues)[number];

/** The app telling the server a link or lock attempt failed on the device; the server relays it to Sentry (§13). */
export const reportNfcFailureInputSchema = z
  .object({
    step: z.enum(nfcFailureStepValues),
    message: z.string().trim().max(300),
    tagUid: z.string().max(40).optional(),
  })
  .strict();
export type ReportNfcFailureInput = z.infer<typeof reportNfcFailureInputSchema>;

/** What link, lock and admin unlink answer with (§4.1–§4.3). */
export interface NfcStateDto {
  artworkId: string;
  nfcTagUid: string | null;
  nfcLinkedAt: string | null;
  nfcLockedAt: string | null;
}
