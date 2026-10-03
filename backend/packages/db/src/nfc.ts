// The NFC tag on an artwork: link it, lock it, let an admin undo a link, and
// the shipment gate that wants it locked (NFC_IMPLEMENTATION.md §3–§5, §9).
//
// State is two timestamps on the artwork plus the chip's UID:
//
//   unlinked          nfcLinkedAt null
//   linked, unlocked  nfcLinkedAt set, nfcLockedAt null   (rewritable: replace the chip)
//   linked, locked    both set                            (irreversible, like the chip)
//
// The UID is held in artworkNfc/{artworkId}, NOT on the artwork: firestore.rules
// lets anyone read artworks/{id}, and the plan says the UID reaches only the
// artist, the aggregator holding the piece and admins. The timestamps are not
// secret, so the public passport, the gate and the listings read them off the
// artwork without touching the private document.
//
// The rules live in small pure functions (decideLink, decideLock, ...) so every
// branch of §4 can be checked without a database; the exported async functions
// only read, call a rule, and write, in one transaction.

import { FieldValue, Timestamp, type Firestore, type Transaction } from "firebase-admin/firestore";
import { Collections, type AggregatorHoldingDoc, type ArtworkDoc, type ArtworkNfcDoc, type AuditLogDoc } from "./collections.ts";
import { FirestoreRateConfigStore } from "./firestore-rate-config-store.ts";
import { DbError } from "./errors.ts";

// --- Errors ------------------------------------------------------------------

export type NfcErrorCode =
  | "not_found"
  | "forbidden"
  | "invalid_tag_uid"
  | "reason_required"
  | "nfc_not_linked"
  | "nfc_already_locked"
  | "tag_already_bound"
  | "tag_uid_mismatch"
  | "nfc_lock_required";

const STATUS_OF: Record<NfcErrorCode, number> = {
  not_found: 404,
  forbidden: 403,
  invalid_tag_uid: 400,
  reason_required: 400,
  nfc_not_linked: 409,
  nfc_already_locked: 409,
  tag_already_bound: 409,
  tag_uid_mismatch: 409,
  nfc_lock_required: 409,
};

/**
 * A deliberate refusal, carrying the `code` the apps switch on (§4). Messages are
 * safe to show whoever asked and never contain a chip UID.
 */
export class NfcError extends DbError {
  readonly code: NfcErrorCode;
  constructor(code: NfcErrorCode, message: string) {
    super(message);
    this.name = "NfcError";
    this.code = code;
  }
  get status(): number {
    return STATUS_OF[this.code];
  }
}

// --- Rules (pure) -------------------------------------------------------------

/** An NTAG213's UID: 7 bytes, 14 lowercase hex characters (§1). */
export const TAG_UID_PATTERN = /^[0-9a-f]{14}$/;

/**
 * The stored form of a UID. Each platform hands it over differently — Android and
 * iOS as upper-case hex ("04A1B2C3D4E580"), Chrome's Web NFC as colon-separated
 * lower-case ("04:a1:b2:c3:d4:e5:80") — so case and separators are forgiven, the
 * length is not: anything but 7 bytes is some other chip.
 */
export function parseTagUid(raw: unknown): string {
  const uid = typeof raw === "string" ? raw.trim().toLowerCase().replace(/[\s:-]/g, "") : "";
  if (!TAG_UID_PATTERN.test(uid)) throw new NfcError("invalid_tag_uid", "That isn't an NTAG213 chip ID (it must be 14 hex characters).");
  return uid;
}

export interface NfcState {
  tagUid: string | null;
  linked: boolean;
  locked: boolean;
}

export type NfcStage = "unlinked" | "linked_unlocked" | "linked_locked";

export function nfcStateOf(
  artwork: Partial<Pick<ArtworkDoc, "nfcLinkedAt" | "nfcLockedAt">>,
  priv: Pick<ArtworkNfcDoc, "tagUid"> | null | undefined,
): NfcState {
  const tagUid = priv?.tagUid ?? null;
  return { tagUid, linked: Boolean(tagUid && artwork.nfcLinkedAt), locked: Boolean(artwork.nfcLockedAt) };
}

export function nfcStageOf(state: Pick<NfcState, "linked" | "locked">): NfcStage {
  return state.locked ? "linked_locked" : state.linked ? "linked_unlocked" : "unlinked";
}

export type TagHandlerRole = "artist" | "aggregator";

export type LinkDecision = { kind: "noop" } | { kind: "link" } | { kind: "replace"; previousUid: string };

/** §4.1. Same chip again is a no-op; a different chip replaces it until the lock. */
export function decideLink(state: NfcState, tagUid: string, role: TagHandlerRole): LinkDecision {
  if (state.locked) throw new NfcError("nfc_already_locked", "This artwork's tag is locked, so it can't be linked again.");
  if (state.linked && state.tagUid === tagUid) return { kind: "noop" };
  if (state.linked && state.tagUid) {
    // §2: a gallery can only lock a piece that already has a tag, never write over it.
    if (role === "aggregator") throw new NfcError("forbidden", "This piece already has a tag linked. Only the artist can replace it — you can lock it.");
    return { kind: "replace", previousUid: state.tagUid };
  }
  return { kind: "link" };
}

export type LockDecision = { kind: "noop" } | { kind: "lock" };

/** §4.2. The UID is passed again so the chip against the phone is proven to be the linked one. */
export function decideLock(state: NfcState, tagUid: string): LockDecision {
  if (!state.linked || !state.tagUid) throw new NfcError("nfc_not_linked", "Link a tag to this artwork before locking it.");
  if (state.locked) {
    if (state.tagUid === tagUid) return { kind: "noop" };
    throw new NfcError("nfc_already_locked", "This artwork's tag is already locked, and not by this chip.");
  }
  if (state.tagUid !== tagUid) throw new NfcError("tag_uid_mismatch", "This isn't the chip that was linked to this artwork. Tap the original chip.");
  return { kind: "lock" };
}

export type UnlinkDecision = { kind: "noop" } | { kind: "unlink"; previousUid: string };

/** §4.3. Only before the lock: afterwards the chip stays locked and a server unlink would just desync reality. */
export function decideUnlink(state: NfcState, reason: string): UnlinkDecision {
  if (!reason.trim()) throw new NfcError("reason_required", "Say why the tag is being unlinked.");
  if (state.locked) throw new NfcError("nfc_already_locked", "A locked tag can't be unlinked: the chip stays locked, so the record would stop matching the piece.");
  if (!state.linked || !state.tagUid) return { kind: "noop" };
  return { kind: "unlink", previousUid: state.tagUid };
}

/**
 * Where a held piece stands on the lock rule (NFC_IMPLEMENTATION.md §5.2a): waiting for the
 * artist to lock the tag, or ready to ship. The plan names these as holding statuses
 * (`reserved_awaiting_lock`, `reserved_ready_to_ship`); here they are derived from the
 * artwork, so they can never disagree with it, and the holding's own `status` stays
 * `reserved` — the web, the app and several queries filter on exactly that.
 */
export type HoldingSubStatus = "reserved_awaiting_lock" | "reserved_ready_to_ship";

export function holdingSubStatusOf(status: string, flags: { locked: boolean; overridden: boolean }): HoldingSubStatus | null {
  if (status !== "reserved") return null;
  return flags.locked || flags.overridden ? "reserved_ready_to_ship" : "reserved_awaiting_lock";
}

export type GateVerdict = "allow" | "warn" | "block";

/** §5 and §12: an unlocked dispatch is refused once the flag is on, and only logged until then. */
export function dispatchGateVerdict(input: { locked: boolean; overridden: boolean }, enforced: boolean): GateVerdict {
  if (input.locked || input.overridden) return "allow";
  return enforced ? "block" : "warn";
}

// --- Writes -------------------------------------------------------------------

export interface NfcActor {
  uid: string;
  /** The caller's role as the auth guard resolved it. Only artist and aggregator may handle a tag (§9.1). */
  role: string;
}

/** What link, lock and unlink answer with (§4.1–§4.3). */
export interface NfcStateView {
  artworkId: string;
  nfcTagUid: string | null;
  nfcLinkedAt: string | null;
  nfcLockedAt: string | null;
}

/** The state plus what the API layer needs to bust caches; `changed` is false for an idempotent repeat. */
export interface NfcWriteResult extends NfcStateView {
  artistId: string;
  changed: boolean;
}

/** The response body: the write result without the bookkeeping the API layer uses. */
export const nfcStateViewOf = ({ artworkId, nfcTagUid, nfcLinkedAt, nfcLockedAt }: NfcWriteResult): NfcStateView => ({ artworkId, nfcTagUid, nfcLinkedAt, nfcLockedAt });

const iso = (t: FirebaseFirestore.Timestamp | null | undefined) => t?.toDate().toISOString() ?? null;
const serverNow = () => FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp;

const artworkRef = (db: Firestore, id: string) => db.collection(Collections.artworks).doc(id);
const privateRef = (db: Firestore, id: string) => db.collection(Collections.artworkNfc).doc(id);

async function loadArtwork(tx: Transaction, db: Firestore, artworkId: string): Promise<ArtworkDoc> {
  const snap = await tx.get(artworkRef(db, artworkId));
  if (!snap.exists) throw new NfcError("not_found", `No artwork ${artworkId}`);
  return snap.data() as ArtworkDoc;
}

/** The artist who made the piece, or the aggregator that currently has it (reserved, or sold and not yet handed on). */
async function assertCanHandleTag(db: Firestore, tx: Transaction | null, actor: NfcActor, artworkId: string, artwork: ArtworkDoc): Promise<TagHandlerRole> {
  if (actor.role === "artist" && artwork.artistId === actor.uid) return "artist";
  if (actor.role === "aggregator") {
    // One holding per aggregator per artwork (reserveHolding refuses a second), so equality on both is enough.
    const query = db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).where("aggregatorId", "==", actor.uid).limit(1);
    const held = await (tx ? tx.get(query) : query.get());
    const holding = held.docs[0]?.data() as AggregatorHoldingDoc | undefined;
    if (holding && (holding.status === "reserved" || holding.status === "sold_pending_settlement")) return "aggregator";
  }
  throw new NfcError("forbidden", "Only the artist, or the gallery currently holding this piece, can do that.");
}

function writeAudit(
  tx: Transaction,
  db: Firestore,
  entry: { actorId: string; action: string; artworkId: string; title: string; detail: Record<string, unknown> },
): void {
  const doc: AuditLogDoc = {
    adminId: entry.actorId,
    action: entry.action,
    entityType: "artwork",
    entityId: entry.artworkId,
    entityLabel: entry.title,
    detail: entry.detail,
    createdAt: serverNow(),
  };
  tx.set(db.collection(Collections.auditLog).doc(), doc);
}

export type NfcIntent = "link" | "lock";

export interface NfcCheckResult {
  artworkId: string;
  intent: NfcIntent;
  /** What the call would do. `noop` = already so; the app can skip the write or the lock. */
  action: "link" | "replace" | "lock" | "noop";
}

/**
 * Asks, without changing anything, whether linking or locking THIS chip is allowed.
 *
 * The apps call it between reading the chip's UID and touching the chip. Without it the
 * only refusal for "this chip already belongs to another artwork" (§4.1) would come after
 * the app had written this artwork's URL over the other piece's still-unlocked chip, and
 * the only refusal for "wrong chip" at lock time (§4.2) after the lock bytes had been set —
 * which cannot be undone. Link and lock still make every one of these checks themselves.
 */
export async function checkNfcTag(db: Firestore, input: { artworkId: string; tagUid: string; intent: NfcIntent; actor: NfcActor }): Promise<NfcCheckResult> {
  const tagUid = parseTagUid(input.tagUid);
  const { artworkId, intent, actor } = input;
  const snap = await artworkRef(db, artworkId).get();
  if (!snap.exists) throw new NfcError("not_found", `No artwork ${artworkId}`);
  const artwork = snap.data() as ArtworkDoc;
  const role = await assertCanHandleTag(db, null, actor, artworkId, artwork);
  const priv = (await privateRef(db, artworkId).get()).data() as ArtworkNfcDoc | undefined;
  const state = nfcStateOf(artwork, priv);

  if (intent === "lock") return { artworkId, intent, action: decideLock(state, tagUid).kind };

  const decision = decideLink(state, tagUid, role);
  if (decision.kind !== "noop") {
    const clash = await db.collection(Collections.artworkNfc).where("tagUid", "==", tagUid).limit(2).get();
    if (clash.docs.some((d) => d.id !== artworkId)) throw new NfcError("tag_already_bound", "This chip is already linked to another artwork.");
  }
  return { artworkId, intent, action: decision.kind };
}

/** §4.1. Records that the app wrote the URL to a chip and read this UID off it. */
export async function linkNfcTag(db: Firestore, input: { artworkId: string; tagUid: string; actor: NfcActor }): Promise<NfcWriteResult> {
  const tagUid = parseTagUid(input.tagUid);
  const { artworkId, actor } = input;
  return db.runTransaction(async (tx) => {
    const artwork = await loadArtwork(tx, db, artworkId);
    const role = await assertCanHandleTag(db, tx, actor, artworkId, artwork);
    const privSnap = await tx.get(privateRef(db, artworkId));
    const priv = privSnap.data() as ArtworkNfcDoc | undefined;
    const decision = decideLink(nfcStateOf(artwork, priv), tagUid, role);
    if (decision.kind === "noop") {
      return { artworkId, artistId: artwork.artistId, nfcTagUid: tagUid, nfcLinkedAt: iso(artwork.nfcLinkedAt), nfcLockedAt: null, changed: false };
    }

    // §9.4: one physical chip belongs to one artwork. Checked inside the transaction, after the cheaper refusals.
    const clash = await tx.get(db.collection(Collections.artworkNfc).where("tagUid", "==", tagUid).limit(2));
    if (clash.docs.some((d) => d.id !== artworkId)) throw new NfcError("tag_already_bound", "This chip is already linked to another artwork.");

    const now = Timestamp.now();
    tx.update(artworkRef(db, artworkId), { nfcLinkedAt: now, nfcLockedAt: null });
    // A new link restarts the reminder clock (nfc-reminders.ts).
    tx.set(privateRef(db, artworkId), { tagUid, shipmentGateOverrideReason: priv?.shipmentGateOverrideReason ?? null, shipmentGateOverrideBy: priv?.shipmentGateOverrideBy ?? null, reminder48hAt: null, reminder7dAt: null } satisfies ArtworkNfcDoc);
    writeAudit(tx, db, {
      actorId: actor.uid,
      artworkId,
      title: artwork.title,
      ...(decision.kind === "replace"
        ? { action: "nfc.tag_replaced", detail: { artworkId, oldTagUid: decision.previousUid, newTagUid: tagUid, actorRole: role } }
        : { action: "nfc.linked", detail: { artworkId, tagUid, actorRole: role } }),
    });
    return { artworkId, artistId: artwork.artistId, nfcTagUid: tagUid, nfcLinkedAt: now.toDate().toISOString(), nfcLockedAt: null, changed: true };
  });
}

/** §4.2. Records that the app flipped the chip's lock bytes, having confirmed it is the linked chip. */
export async function lockNfcTag(db: Firestore, input: { artworkId: string; tagUid: string; actor: NfcActor }): Promise<NfcWriteResult> {
  const tagUid = parseTagUid(input.tagUid);
  const { artworkId, actor } = input;
  return db.runTransaction(async (tx) => {
    const artwork = await loadArtwork(tx, db, artworkId);
    const role = await assertCanHandleTag(db, tx, actor, artworkId, artwork);
    const priv = (await tx.get(privateRef(db, artworkId))).data() as ArtworkNfcDoc | undefined;
    const decision = decideLock(nfcStateOf(artwork, priv), tagUid);
    if (decision.kind === "noop") {
      return { artworkId, artistId: artwork.artistId, nfcTagUid: tagUid, nfcLinkedAt: iso(artwork.nfcLinkedAt), nfcLockedAt: iso(artwork.nfcLockedAt), changed: false };
    }

    const now = Timestamp.now();
    tx.update(artworkRef(db, artworkId), { nfcLockedAt: now });
    writeAudit(tx, db, { actorId: actor.uid, action: "nfc.locked", artworkId, title: artwork.title, detail: { artworkId, tagUid, actorRole: role } });
    return { artworkId, artistId: artwork.artistId, nfcTagUid: tagUid, nfcLinkedAt: iso(artwork.nfcLinkedAt), nfcLockedAt: now.toDate().toISOString(), changed: true };
  });
}

/** §4.3. An admin resets a link made to a defective chip, before it was locked. */
export async function adminUnlinkNfcTag(db: Firestore, input: { artworkId: string; reason: string; adminUid: string }): Promise<NfcWriteResult> {
  const { artworkId, adminUid } = input;
  const reason = input.reason.trim();
  return db.runTransaction(async (tx) => {
    const artwork = await loadArtwork(tx, db, artworkId);
    const priv = (await tx.get(privateRef(db, artworkId))).data() as ArtworkNfcDoc | undefined;
    const decision = decideUnlink(nfcStateOf(artwork, priv), reason);
    if (decision.kind === "noop") {
      return { artworkId, artistId: artwork.artistId, nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null, changed: false };
    }

    tx.update(artworkRef(db, artworkId), { nfcLinkedAt: null, nfcLockedAt: null });
    tx.set(privateRef(db, artworkId), { tagUid: null, shipmentGateOverrideReason: priv?.shipmentGateOverrideReason ?? null, shipmentGateOverrideBy: priv?.shipmentGateOverrideBy ?? null, reminder48hAt: null, reminder7dAt: null } satisfies ArtworkNfcDoc);
    writeAudit(tx, db, {
      actorId: adminUid,
      action: "nfc.admin_unlinked",
      artworkId,
      title: artwork.title,
      detail: { artworkId, previousTagUid: decision.previousUid, reason, adminUid },
    });
    return { artworkId, artistId: artwork.artistId, nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null, changed: true };
  });
}

export interface ShipmentGateOverride {
  artworkId: string;
  artistId: string;
  nfcShipmentGateOverrideAt: string;
  nfcShipmentGateOverrideReason: string;
}

/** §4.4. Lets one piece be dispatched without a locked tag — legacy pieces from before the feature. Needs a reason, is audit-logged. */
export async function overrideShipmentGate(db: Firestore, input: { artworkId: string; reason: string; adminUid: string }): Promise<ShipmentGateOverride> {
  const { artworkId, adminUid } = input;
  const reason = input.reason.trim();
  if (!reason) throw new NfcError("reason_required", "Say why this piece may ship without a locked tag.");
  return db.runTransaction(async (tx) => {
    const artwork = await loadArtwork(tx, db, artworkId);
    const priv = (await tx.get(privateRef(db, artworkId))).data() as ArtworkNfcDoc | undefined;
    const now = Timestamp.now();
    tx.update(artworkRef(db, artworkId), { nfcShipmentGateOverrideAt: now });
    tx.set(privateRef(db, artworkId), { tagUid: priv?.tagUid ?? null, shipmentGateOverrideReason: reason, shipmentGateOverrideBy: adminUid, reminder48hAt: priv?.reminder48hAt ?? null, reminder7dAt: priv?.reminder7dAt ?? null } satisfies ArtworkNfcDoc);
    writeAudit(tx, db, { actorId: adminUid, action: "nfc.shipment_gate_overridden", artworkId, title: artwork.title, detail: { artworkId, reason, adminUid } });
    return { artworkId, artistId: artwork.artistId, nfcShipmentGateOverrideAt: now.toDate().toISOString(), nfcShipmentGateOverrideReason: reason };
  });
}

// --- Reads ----------------------------------------------------------------------

/** The private half, for the views that may show the UID (the artist's own and the admin's). */
export async function getArtworkNfc(db: Firestore, artworkId: string): Promise<ArtworkNfcDoc | null> {
  const snap = await privateRef(db, artworkId).get();
  return snap.exists ? (snap.data() as ArtworkNfcDoc) : null;
}

/** What the artist's and admin's artwork views carry (§4.5). The UID is visible to them and to nobody else. */
export interface NfcOwnerFields {
  nfcTagUid: string | null;
  nfcLinkedAt: string | null;
  nfcLockedAt: string | null;
}

export function nfcOwnerFields(artwork: Partial<Pick<ArtworkDoc, "nfcLinkedAt" | "nfcLockedAt">>, priv: Pick<ArtworkNfcDoc, "tagUid"> | null | undefined): NfcOwnerFields {
  return { nfcTagUid: nfcStateOf(artwork, priv).linked ? (priv?.tagUid ?? null) : null, nfcLinkedAt: iso(artwork.nfcLinkedAt), nfcLockedAt: iso(artwork.nfcLockedAt) };
}

// --- Shipment gate --------------------------------------------------------------

/** Is the phase-3 flag on (§12)? Read from the active rate version like every other rate. */
export async function nfcGateEnforced(db: Firestore): Promise<boolean> {
  const version = await new FirestoreRateConfigStore(db).getActiveVersion(new Date());
  return version?.rates.nfcShipmentGateEnforced ?? false;
}

/**
 * Called before a piece is dispatched — an order moving to transit, or an
 * aggregator sale shipment moving to dispatched. Throws nfc_lock_required once
 * the gate is enforced and the tag is not locked (and not overridden). Until
 * then it only records the would-be refusal, so ops can lock or override
 * those pieces before the flag is flipped.
 */
export async function assertNfcDispatchAllowed(
  db: Firestore,
  artworkId: string,
  context: { channel: "marketplace" | "aggregator"; refId: string },
  /** For tests; production reads the flag from the active rate version. */
  opts: { enforced?: boolean } = {},
): Promise<void> {
  const artwork = (await artworkRef(db, artworkId).get()).data() as ArtworkDoc | undefined;
  if (!artwork) return; // the caller's own checks answer for a missing piece
  const flags = { locked: Boolean(artwork.nfcLockedAt), overridden: Boolean(artwork.nfcShipmentGateOverrideAt) };
  if (dispatchGateVerdict(flags, false) === "allow") return;

  if (dispatchGateVerdict(flags, opts.enforced ?? (await nfcGateEnforced(db))) === "block") {
    throw new NfcError(
      "nfc_lock_required",
      context.channel === "marketplace"
        ? "This artwork's NFC tag must be locked before it can be dispatched. Ask the artist to lock it in the GalleryZone app."
        : "This artwork's NFC tag must be locked before it can be dispatched. Lock it in the GalleryZone app, then try again.",
    );
  }

  console.warn(JSON.stringify({ event: "nfc.shipment_gate_would_block", artworkId, ...context }));
  try {
    await db.collection(Collections.auditLog).add({
      adminId: "system",
      action: "nfc.shipment_gate_warning",
      entityType: "artwork",
      entityId: artworkId,
      entityLabel: artwork.title,
      detail: { artworkId, ...context },
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`could not record the NFC gate warning for ${artworkId}: ${String(error)}`);
  }
}

// --- Lock reminders (§13) ----------------------------------------------------------

export type NfcReminderStage = "48h" | "7d";

const HOUR_MS = 3_600_000;
const REMINDER_AFTER_MS: Record<NfcReminderStage, number> = { "48h": 48 * HOUR_MS, "7d": 7 * 24 * HOUR_MS };
/** Only while the piece can still be locked: once it has sold or shipped nobody can reach the chip. */
const STILL_LOCKABLE = new Set(["pending_approval", "marketplace", "reserved", "with_aggregator"]);

export interface NfcReminderDue {
  artworkId: string;
  artistId: string;
  title: string;
  stage: NfcReminderStage;
  linkedAt: Date;
}

/** Pure: which reminder, if any, a linked-unlocked tag is due for. The 7-day one replaces the 48-hour one when both are overdue, so nobody gets two mails at once. */
export function reminderStageDue(input: { linkedAt: Date; now: Date; sent48h: boolean; sent7d: boolean }): NfcReminderStage | null {
  const age = input.now.getTime() - input.linkedAt.getTime();
  if (age >= REMINDER_AFTER_MS["7d"] && !input.sent7d) return "7d";
  if (age >= REMINDER_AFTER_MS["48h"] && age < REMINDER_AFTER_MS["7d"] && !input.sent48h) return "48h";
  return null;
}

/** Tags linked 48 hours or more ago and still unlocked whose artist has not yet been reminded at that stage. */
export async function dueNfcReminders(db: Firestore, now: Date = new Date()): Promise<NfcReminderDue[]> {
  const cutoff = Timestamp.fromMillis(now.getTime() - REMINDER_AFTER_MS["48h"]);
  const snap = await db.collection(Collections.artworks).where("nfcLinkedAt", "<=", cutoff).select("title", "artistId", "nfcLinkedAt", "nfcLockedAt", "listing.status").get();
  const open = snap.docs.filter((d) => {
    const a = d.data() as Pick<ArtworkDoc, "nfcLockedAt" | "listing">;
    return !a.nfcLockedAt && STILL_LOCKABLE.has(a.listing?.status ?? "");
  });
  if (!open.length) return [];

  const privSnaps = await db.getAll(...open.map((d) => privateRef(db, d.id)));
  const due: NfcReminderDue[] = [];
  open.forEach((d, i) => {
    const a = d.data() as Pick<ArtworkDoc, "title" | "artistId" | "nfcLinkedAt">;
    const priv = privSnaps[i]?.data() as ArtworkNfcDoc | undefined;
    if (!priv?.tagUid || !a.nfcLinkedAt) return;
    const stage = reminderStageDue({ linkedAt: a.nfcLinkedAt.toDate(), now, sent48h: Boolean(priv.reminder48hAt), sent7d: Boolean(priv.reminder7dAt) });
    if (stage) due.push({ artworkId: d.id, artistId: a.artistId, title: a.title, stage, linkedAt: a.nfcLinkedAt.toDate() });
  });
  return due;
}

/** Records that a reminder went out. The 7-day one also stands in for a 48-hour one that was never sent. */
export async function markNfcReminderSent(db: Firestore, artworkId: string, stage: NfcReminderStage): Promise<void> {
  const now = Timestamp.now();
  await privateRef(db, artworkId).update(stage === "7d" ? { reminder48hAt: now, reminder7dAt: now } : { reminder48hAt: now });
}

// --- Admin overview (§13) --------------------------------------------------------

export const NFC_WATCHED_ACTIONS = ["nfc.tag_replaced", "nfc.shipment_gate_overridden", "nfc.shipment_gate_warning"] as const;

export interface NfcOverview {
  gateEnforced: boolean;
  counts: { total: number; unlinked: number; linkedUnlocked: number; locked: number; gateOverridden: number };
  /** Linked but not locked, longest-waiting first (capped): the pieces to chase before the gate is enforced. */
  awaitingLock: { artworkId: string; title: string; artistId: string; linkedAt: string }[];
  /** Newest first. A replaced tag or an override means a chip failed or the process is being bypassed. */
  recent: { id: string; action: string; artworkId: string; title: string | null; actorId: string; at: string; detail: unknown }[];
}

const AWAITING_LOCK_CAP = 50;
const RECENT_CAP = 50;

export async function getNfcOverview(db: Firestore): Promise<NfcOverview> {
  const artworks = db.collection(Collections.artworks);
  const [gateEnforced, total, linked, locked, overridden, linkedDocs, events] = await Promise.all([
    nfcGateEnforced(db),
    artworks.count().get(),
    artworks.where("nfcLinkedAt", "!=", null).count().get(),
    artworks.where("nfcLockedAt", "!=", null).count().get(),
    artworks.where("nfcShipmentGateOverrideAt", "!=", null).count().get(),
    // Filtered in memory: a null-equality plus a not-null filter on two fields would need its own composite index.
    artworks.where("nfcLinkedAt", "!=", null).select("title", "artistId", "nfcLinkedAt", "nfcLockedAt").get(),
    db.collection(Collections.auditLog).where("action", "in", [...NFC_WATCHED_ACTIONS]).orderBy("createdAt", "desc").limit(RECENT_CAP).get(),
  ]);

  const awaitingLock = linkedDocs.docs
    .map((d) => ({ id: d.id, ...(d.data() as Pick<ArtworkDoc, "title" | "artistId" | "nfcLinkedAt" | "nfcLockedAt">) }))
    .filter((a) => !a.nfcLockedAt)
    .sort((a, b) => (a.nfcLinkedAt?.toMillis() ?? 0) - (b.nfcLinkedAt?.toMillis() ?? 0))
    .slice(0, AWAITING_LOCK_CAP)
    .map((a) => ({ artworkId: a.id, title: a.title, artistId: a.artistId, linkedAt: iso(a.nfcLinkedAt) ?? new Date(0).toISOString() }));

  const linkedCount = linked.data().count;
  const lockedCount = locked.data().count;
  return {
    gateEnforced,
    counts: {
      total: total.data().count,
      unlinked: total.data().count - linkedCount,
      linkedUnlocked: linkedCount - lockedCount,
      locked: lockedCount,
      gateOverridden: overridden.data().count,
    },
    awaitingLock,
    recent: events.docs.map((d) => {
      const e = d.data() as AuditLogDoc;
      return { id: d.id, action: e.action, artworkId: e.entityId, title: e.entityLabel, actorId: e.adminId, at: iso(e.createdAt) ?? new Date(0).toISOString(), detail: e.detail };
    }),
  };
}
