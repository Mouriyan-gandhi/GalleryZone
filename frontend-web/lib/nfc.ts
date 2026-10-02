// The NFC tag on an artwork, as the dashboard and the admin console see it
// (NFC_IMPLEMENTATION.md §3), and the browser's own tag writer (§8).
//
// The tag has three states, and the first two are not the end of the story:
//
//   unlinked          no chip recorded
//   linked, unlocked  a chip was written and recorded, but anyone with a phone could rewrite it,
//                     and the piece can't be dispatched until it is locked
//   linked, locked    the chip is read-only for good
//
// A browser can write a chip but cannot lock one (Web NFC has no raw commands), so the
// lock is always finished in the mobile app. Kept dependency-free: no React, no http.

export type NfcStage = "unlinked" | "linked_unlocked" | "linked_locked";

export interface NfcFields {
  nfcLinkedAt?: string | null;
  nfcLockedAt?: string | null;
}

export function nfcStageOf(artwork: NfcFields): NfcStage {
  if (!artwork.nfcLinkedAt) return "unlinked";
  return artwork.nfcLockedAt ? "linked_locked" : "linked_unlocked";
}

export const NFC_STAGE_LABEL: Record<NfcStage, string> = {
  unlinked: "Not yet tagged",
  linked_unlocked: "Tag linked · unlocked",
  linked_locked: "Tag locked",
};

/** Where the mobile app is installed from. Unset until the app is on a store: the dialog then just says "open the app". */
export const MOBILE_APP_URL = process.env.NEXT_PUBLIC_MOBILE_APP_URL ?? "";

// --- Web NFC (Chrome on Android, secure context only) ------------------------------------

/** The slice of the Web NFC API this app uses; lib.dom has no types for it. */
interface NdefReadingEventLike extends Event {
  /** Colon-separated hex, e.g. "04:a1:b2:c3:d4:e5:80". */
  serialNumber: string;
}

interface NdefReaderLike extends EventTarget {
  scan(options?: { signal?: AbortSignal }): Promise<void>;
  write(message: { records: { recordType: string; data: string }[] }, options?: { overwrite?: boolean; signal?: AbortSignal }): Promise<void>;
}

type NdefReaderConstructor = new () => NdefReaderLike;

function readerConstructor(): NdefReaderConstructor | null {
  if (typeof window === "undefined" || !window.isSecureContext) return null;
  const ctor = (window as unknown as { NDEFReader?: NdefReaderConstructor }).NDEFReader;
  return ctor ?? null;
}

export function webNfcSupported(): boolean {
  return readerConstructor() !== null;
}

/** An NTAG213's UID is 7 bytes: 14 hex characters once the separators are gone. */
export function isNtagUid(serialNumber: string): boolean {
  return /^[0-9a-f]{14}$/.test(serialNumber.replace(/[:\s-]/g, "").toLowerCase());
}

/**
 * A write that did not happen, with the step it stopped at. The step names are the ones the
 * server groups failures by (reportNfcFailureInputSchema), so they can be forwarded as they are.
 */
export class NfcWriteError extends Error {
  constructor(
    message: string,
    readonly step: "poll" | "chip_type" | "uid_mismatch" | "write",
  ) {
    super(message);
    this.name = "NfcWriteError";
  }
}

const TAP_TIMEOUT_MS = 25_000;

/**
 * Waits for a chip to be tapped, hands its UID to `beforeWrite` (which may refuse it — the
 * server's check runs there, so a chip that belongs to another piece is never overwritten),
 * then writes the URL as one NDEF record. Resolves with the UID Chrome read.
 */
export async function tapAndWriteUrl(url: string, beforeWrite: (serialNumber: string) => Promise<void>): Promise<string> {
  const Reader = readerConstructor();
  if (!Reader) throw new NfcWriteError("This browser can't write NFC tags. Use the GalleryZone app, or Chrome on an Android phone.", "poll");

  const reader = new Reader();
  const signal = AbortSignal.timeout(TAP_TIMEOUT_MS);

  let serialNumber: string;
  try {
    serialNumber = await new Promise<string>((resolve, reject) => {
      signal.addEventListener("abort", () => reject(new NfcWriteError("No tag was tapped in time. Hold it to the back of your phone and try again.", "poll")), { once: true });
      reader.addEventListener("reading", (event) => resolve((event as NdefReadingEventLike).serialNumber), { once: true });
      reader.addEventListener("readingerror", () => reject(new NfcWriteError("That tag couldn't be read. Try again, or use a different tag.", "poll")), { once: true });
      reader.scan({ signal }).catch((error: unknown) => reject(new NfcWriteError(describe(error, "NFC permission was refused. Allow NFC for this site and try again."), "poll")));
    });
  } catch (error) {
    if (error instanceof NfcWriteError) throw error;
    throw new NfcWriteError("The tag couldn't be read.", "poll");
  }

  if (!isNtagUid(serialNumber)) {
    throw new NfcWriteError("This isn't an NTAG213 chip. Please use a GalleryZone-supplied tag.", "chip_type");
  }
  try {
    await beforeWrite(serialNumber);
  } catch (error) {
    throw new NfcWriteError(error instanceof Error ? error.message : "That tag can't be used for this piece.", "uid_mismatch");
  }

  try {
    await reader.write({ records: [{ recordType: "url", data: url }] }, { overwrite: true, signal });
  } catch (error) {
    throw new NfcWriteError(describe(error, "The tag couldn't be written. If it was already locked it can't be changed — use a new one."), "write");
  }
  return serialNumber;
}

function describe(error: unknown, fallback: string): string {
  // DOMException names are the only stable signal Web NFC gives.
  const name = error instanceof DOMException ? error.name : "";
  if (name === "NotAllowedError") return "NFC permission was refused. Allow NFC for this site and try again.";
  if (name === "AbortError") return "No tag was tapped in time. Hold it to the back of your phone and try again.";
  return fallback;
}
