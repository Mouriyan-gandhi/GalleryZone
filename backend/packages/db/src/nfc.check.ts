// Run: node --experimental-strip-types packages/db/src/nfc.check.ts
// NFC_IMPLEMENTATION.md §11.1. The pure rules are checked directly; the
// transactional functions run against a just-big-enough in-memory Firestore
// (below) so refusals, audit entries, idempotence and the one-chip-one-artwork
// rule are exercised for real, not assumed.

import assert from "node:assert/strict";
import { Timestamp, type Firestore } from "firebase-admin/firestore";
import {
  NfcError,
  adminUnlinkNfcTag,
  assertNfcDispatchAllowed,
  decideLink,
  decideLock,
  decideUnlink,
  dispatchGateVerdict,
  linkNfcTag,
  lockNfcTag,
  nfcOwnerFields,
  nfcStageOf,
  nfcStateOf,
  overrideShipmentGate,
  parseTagUid,
  type NfcState,
} from "./nfc.ts";

// --- An in-memory Firestore: collections, equality queries, transactions --------

type Data = Record<string, unknown>;

class FakeDb {
  readonly docs = new Map<string, Data>();
  auto = 0;
  collection(name: string) {
    return new Coll(this, name);
  }
  async runTransaction<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
    return fn(new Tx(this));
  }
}

class Ref {
  readonly db: FakeDb;
  readonly col: string;
  readonly id: string;
  constructor(db: FakeDb, col: string, id: string) {
    this.db = db;
    this.col = col;
    this.id = id;
  }
  get path() {
    return `${this.col}/${this.id}`;
  }
  async get() {
    const data = this.db.docs.get(this.path);
    return { id: this.id, exists: data !== undefined, data: () => (data === undefined ? undefined : { ...data }) };
  }
}

class Query {
  readonly db: FakeDb;
  readonly col: string;
  readonly filters: [string, unknown][];
  readonly max: number;
  constructor(db: FakeDb, col: string, filters: [string, unknown][] = [], max = Infinity) {
    this.db = db;
    this.col = col;
    this.filters = filters;
    this.max = max;
  }
  where(field: string, op: string, value: unknown) {
    assert.equal(op, "==", "the fake only supports equality filters");
    return new Query(this.db, this.col, [...this.filters, [field, value]], this.max);
  }
  limit(n: number) {
    return new Query(this.db, this.col, this.filters, n);
  }
  async get() {
    const hits = [...this.db.docs].filter(([path, data]) => path.startsWith(`${this.col}/`) && this.filters.every(([f, v]) => data[f] === v)).slice(0, this.max);
    const docs = await Promise.all(hits.map(([path]) => new Ref(this.db, this.col, path.slice(this.col.length + 1)).get()));
    return { docs, empty: docs.length === 0 };
  }
}

class Coll extends Query {
  constructor(db: FakeDb, col: string) {
    super(db, col);
  }
  doc(id?: string) {
    return new Ref(this.db, this.col, id ?? `auto${++this.db.auto}`);
  }
  async add(data: Data) {
    const ref = this.doc();
    this.db.docs.set(ref.path, { ...data });
    return ref;
  }
}

class Tx {
  private wrote = false;
  readonly db: FakeDb;
  constructor(db: FakeDb) {
    this.db = db;
  }
  async get(target: Ref | Query) {
    assert.ok(!this.wrote, "a Firestore transaction must finish all its reads before its first write");
    return target.get();
  }
  set(ref: Ref, data: Data) {
    this.wrote = true;
    this.db.docs.set(ref.path, { ...data });
    return this;
  }
  update(ref: Ref, data: Data) {
    this.wrote = true;
    const current = this.db.docs.get(ref.path);
    assert.ok(current, `update of a missing document: ${ref.path}`);
    this.db.docs.set(ref.path, { ...current, ...data });
    return this;
  }
}

// --- Pure rules ----------------------------------------------------------------

const UID = "04a1b2c3d4e580";
const OTHER = "04ffeeddccbbaa";

assert.equal(parseTagUid("04A1B2C3D4E580"), UID, "Android/iOS give upper-case hex");
assert.equal(parseTagUid("04:a1:b2:c3:d4:e5:80"), UID, "Chrome Web NFC gives colon-separated hex");
assert.equal(parseTagUid("  04a1b2c3d4e580 "), UID);
for (const bad of ["", "04a1b2c3", "04a1b2c3d4e58", "04a1b2c3d4e5800", "zz a1b2c3d4e580", "04a1b2c3d4e58g", 42, null, undefined]) {
  assert.throws(() => parseTagUid(bad), (e) => e instanceof NfcError && e.code === "invalid_tag_uid" && e.status === 400, `rejects ${String(bad)}`);
}

const unlinked: NfcState = { tagUid: null, linked: false, locked: false };
const linkedUnlocked: NfcState = { tagUid: UID, linked: true, locked: false };
const locked: NfcState = { tagUid: UID, linked: true, locked: true };
const refuses = (code: string, status: number) => (e: unknown) => e instanceof NfcError && e.code === code && e.status === status;

assert.deepEqual(decideLink(unlinked, UID, "artist"), { kind: "link" });
assert.deepEqual(decideLink(linkedUnlocked, UID, "artist"), { kind: "noop" });
assert.deepEqual(decideLink(linkedUnlocked, OTHER, "artist"), { kind: "replace", previousUid: UID });
assert.throws(() => decideLink(locked, UID, "artist"), refuses("nfc_already_locked", 409), "a locked tag can't be linked again, even with its own chip");
assert.throws(() => decideLink(locked, OTHER, "artist"), refuses("nfc_already_locked", 409));
assert.deepEqual(decideLink(unlinked, UID, "aggregator"), { kind: "link" }, "a gallery may link a piece that has no tag");
assert.deepEqual(decideLink(linkedUnlocked, UID, "aggregator"), { kind: "noop" });
assert.throws(() => decideLink(linkedUnlocked, OTHER, "aggregator"), refuses("forbidden", 403), "a gallery can lock a linked tag but not write over it");

assert.deepEqual(decideLock(linkedUnlocked, UID), { kind: "lock" });
assert.throws(() => decideLock(unlinked, UID), refuses("nfc_not_linked", 409));
assert.deepEqual(decideLock(locked, UID), { kind: "noop" });
assert.throws(() => decideLock(locked, OTHER), refuses("nfc_already_locked", 409));
assert.throws(() => decideLock(linkedUnlocked, OTHER), refuses("tag_uid_mismatch", 409));

assert.deepEqual(decideUnlink(linkedUnlocked, "chip failed to lock"), { kind: "unlink", previousUid: UID });
assert.deepEqual(decideUnlink(unlinked, "chip failed to lock"), { kind: "noop" });
assert.throws(() => decideUnlink(locked, "chip failed to lock"), refuses("nfc_already_locked", 409));
assert.throws(() => decideUnlink(linkedUnlocked, "   "), refuses("reason_required", 400));

assert.equal(dispatchGateVerdict({ locked: true, overridden: false }, true), "allow");
assert.equal(dispatchGateVerdict({ locked: false, overridden: true }, true), "allow");
assert.equal(dispatchGateVerdict({ locked: false, overridden: false }, true), "block");
assert.equal(dispatchGateVerdict({ locked: false, overridden: false }, false), "warn");

const stamp = Timestamp.fromDate(new Date("2026-10-02T12:00:00Z"));
assert.equal(nfcStageOf(nfcStateOf({}, null)), "unlinked");
assert.equal(nfcStageOf(nfcStateOf({ nfcLinkedAt: stamp, nfcLockedAt: null }, { tagUid: UID })), "linked_unlocked");
assert.equal(nfcStageOf(nfcStateOf({ nfcLinkedAt: stamp, nfcLockedAt: stamp }, { tagUid: UID })), "linked_locked");
assert.equal(nfcStageOf(nfcStateOf({ nfcLinkedAt: stamp }, null)), "unlinked", "a link with no chip on record is not a link");
assert.deepEqual(nfcOwnerFields({}, null), { nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null }, "a piece from before the feature reads as unlinked");
assert.equal(nfcOwnerFields({ nfcLinkedAt: stamp }, { tagUid: UID }).nfcTagUid, UID);

// --- Transactional functions ----------------------------------------------------

function world() {
  const db = new FakeDb();
  db.docs.set("artworks/a1", { artistId: "artist-1", title: "Dusk", nfcLinkedAt: null, nfcLockedAt: null });
  db.docs.set("artworks/a2", { artistId: "artist-2", title: "Dawn", nfcLinkedAt: null, nfcLockedAt: null });
  db.docs.set("aggregatorHoldings/h1", { artworkId: "a1", aggregatorId: "agg-1", status: "reserved" });
  return db;
}
const asFirestore = (db: FakeDb) => db as unknown as Firestore;
const artist1 = { uid: "artist-1", role: "artist" };
const audits = (db: FakeDb) => [...db.docs].filter(([p]) => p.startsWith("auditLog/")).map(([, d]) => d);
const priv = (db: FakeDb, id: string) => db.docs.get(`artworkNfc/${id}`);
const refusal = (code: string) => (e: unknown) => e instanceof NfcError && e.code === code;

{
  // Link, repeat, replace.
  const db = world();
  const linked = await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: "04A1B2C3D4E580", actor: artist1 });
  assert.equal(linked.changed, true);
  assert.equal(linked.nfcTagUid, UID);
  assert.ok(linked.nfcLinkedAt && linked.nfcLockedAt === null);
  assert.equal(db.docs.get("artworks/a1")?.nfcLockedAt, null);
  assert.ok(db.docs.get("artworks/a1")?.nfcLinkedAt instanceof Timestamp);
  assert.equal(priv(db, "a1")?.tagUid, UID);
  assert.equal("nfcTagUid" in (db.docs.get("artworks/a1") ?? {}), false, "the UID never sits on the world-readable artwork document");
  assert.deepEqual(audits(db).map((a) => a.action), ["nfc.linked"]);
  assert.deepEqual(audits(db)[0]?.detail, { artworkId: "a1", tagUid: UID, actorRole: "artist" });

  const again = await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  assert.equal(again.changed, false, "the same chip again is a no-op success");
  assert.equal(audits(db).length, 1, "and writes no second audit entry");

  const replaced = await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 });
  assert.equal(replaced.changed, true);
  assert.equal(priv(db, "a1")?.tagUid, OTHER);
  assert.equal(audits(db)[1]?.action, "nfc.tag_replaced");
  assert.deepEqual(audits(db)[1]?.detail, { artworkId: "a1", oldTagUid: UID, newTagUid: OTHER, actorRole: "artist" });

  await assert.rejects(linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: "nope", actor: artist1 }), refusal("invalid_tag_uid"));
}

{
  // Lock.
  const db = world();
  await assert.rejects(lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 }), refusal("nfc_not_linked"));
  await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  await assert.rejects(lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 }), refusal("tag_uid_mismatch"));
  assert.equal(db.docs.get("artworks/a1")?.nfcLockedAt, null, "a refused lock changes nothing");

  const done = await lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  assert.equal(done.changed, true);
  assert.ok(done.nfcLockedAt);
  assert.ok(db.docs.get("artworks/a1")?.nfcLockedAt instanceof Timestamp);
  assert.equal(audits(db).at(-1)?.action, "nfc.locked");

  const repeat = await lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  assert.equal(repeat.changed, false, "locking a locked artwork with the same chip is an idempotent success");
  assert.equal(repeat.nfcLockedAt, done.nfcLockedAt);
  await assert.rejects(lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 }), refusal("nfc_already_locked"));
  await assert.rejects(linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 }), refusal("nfc_already_locked"));
  await assert.rejects(linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 }), refusal("nfc_already_locked"));
}

{
  // One chip, one artwork.
  const db = world();
  await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  await assert.rejects(linkNfcTag(asFirestore(db), { artworkId: "a2", tagUid: UID, actor: { uid: "artist-2", role: "artist" } }), refusal("tag_already_bound"));
  assert.equal(db.docs.get("artworks/a2")?.nfcLinkedAt, null);
  assert.equal(priv(db, "a2"), undefined);
}

{
  // Who may handle a tag (§9.1).
  const db = world();
  const link = (artworkId: string, actor: { uid: string; role: string }) => linkNfcTag(asFirestore(db), { artworkId, tagUid: UID, actor });
  await assert.rejects(link("a1", { uid: "artist-2", role: "artist" }), refusal("forbidden"), "an artist who didn't make it");
  await assert.rejects(link("a1", { uid: "admin-1", role: "admin" }), refusal("forbidden"), "admins don't write to chips");
  await assert.rejects(link("a1", { uid: "agg-2", role: "aggregator" }), refusal("forbidden"), "a gallery with no holding on it");
  await assert.rejects(link("nope", artist1), refusal("not_found"));

  const agg1 = { uid: "agg-1", role: "aggregator" };
  await link("a1", agg1); // the holding gallery may link a piece that has none
  assert.equal((audits(db)[0]?.detail as Data).actorRole, "aggregator");
  await assert.rejects(linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: agg1 }), refusal("forbidden"), "but not write over a linked tag");
  await lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: agg1 });
  assert.ok(db.docs.get("artworks/a1")?.nfcLockedAt, "and may lock it");

  const db2 = world();
  db2.docs.set("aggregatorHoldings/h1", { artworkId: "a1", aggregatorId: "agg-1", status: "returned" });
  await assert.rejects(linkNfcTag(asFirestore(db2), { artworkId: "a1", tagUid: UID, actor: agg1 }), refusal("forbidden"), "once the piece is back with the artist");
  db2.docs.set("aggregatorHoldings/h1", { artworkId: "a1", aggregatorId: "agg-1", status: "sold_pending_settlement" });
  await linkNfcTag(asFirestore(db2), { artworkId: "a1", tagUid: UID, actor: agg1 }); // sold but not yet handed on: still in its hands
}

{
  // Admin unlink.
  const db = world();
  const admin = (reason: string, artworkId = "a1") => adminUnlinkNfcTag(asFirestore(db), { artworkId, reason, adminUid: "admin-1" });
  assert.equal((await admin("chip failed to lock")).changed, false, "nothing linked: a no-op");
  await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: UID, actor: artist1 });
  await assert.rejects(admin("   "), refusal("reason_required"));
  assert.equal(priv(db, "a1")?.tagUid, UID, "a refused unlink changes nothing");

  const result = await admin("  artist reported chip failed to lock  ");
  assert.deepEqual({ ...result, artistId: undefined }, { artworkId: "a1", artistId: undefined, nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null, changed: true });
  assert.equal(db.docs.get("artworks/a1")?.nfcLinkedAt, null);
  assert.equal(priv(db, "a1")?.tagUid, null);
  assert.deepEqual(audits(db).at(-1)?.detail, { artworkId: "a1", previousTagUid: UID, reason: "artist reported chip failed to lock", adminUid: "admin-1" });
  assert.equal(audits(db).at(-1)?.action, "nfc.admin_unlinked");
  await linkNfcTag(asFirestore(db), { artworkId: "a2", tagUid: UID, actor: { uid: "artist-2", role: "artist" } }); // the freed chip can be used elsewhere

  await linkNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 });
  await lockNfcTag(asFirestore(db), { artworkId: "a1", tagUid: OTHER, actor: artist1 });
  await assert.rejects(admin("too late"), refusal("nfc_already_locked"));
  await assert.rejects(admin("x", "nope"), refusal("not_found"));
}

{
  // Shipment gate and its override.
  const db = world();
  const context = { channel: "marketplace", refId: "order-1" } as const;
  await assert.rejects(assertNfcDispatchAllowed(asFirestore(db), "a1", context, { enforced: true }), (e) => e instanceof NfcError && e.code === "nfc_lock_required" && e.status === 409);
  await assertNfcDispatchAllowed(asFirestore(db), "a1", context, { enforced: false }); // phase 2: warn only
  assert.equal(audits(db).at(-1)?.action, "nfc.shipment_gate_warning");
  await assertNfcDispatchAllowed(asFirestore(db), "gone", context, { enforced: true });

  await assert.rejects(overrideShipmentGate(asFirestore(db), { artworkId: "a1", reason: " ", adminUid: "admin-1" }), refusal("reason_required"));
  const override = await overrideShipmentGate(asFirestore(db), { artworkId: "a1", reason: "shipped before the lock requirement", adminUid: "admin-1" });
  assert.equal(override.nfcShipmentGateOverrideReason, "shipped before the lock requirement");
  assert.ok(db.docs.get("artworks/a1")?.nfcShipmentGateOverrideAt instanceof Timestamp);
  assert.deepEqual({ reason: priv(db, "a1")?.shipmentGateOverrideReason, by: priv(db, "a1")?.shipmentGateOverrideBy }, { reason: "shipped before the lock requirement", by: "admin-1" });
  assert.equal(audits(db).at(-1)?.action, "nfc.shipment_gate_overridden");
  const before = audits(db).length;
  await assertNfcDispatchAllowed(asFirestore(db), "a1", context, { enforced: true });
  assert.equal(audits(db).length, before, "an overridden piece ships silently");

  await linkNfcTag(asFirestore(db), { artworkId: "a2", tagUid: UID, actor: { uid: "artist-2", role: "artist" } });
  await lockNfcTag(asFirestore(db), { artworkId: "a2", tagUid: UID, actor: { uid: "artist-2", role: "artist" } });
  await assertNfcDispatchAllowed(asFirestore(db), "a2", { channel: "aggregator", refId: "sale-1" }, { enforced: true });
}

console.log("packages/db/nfc.ts: link, replace, lock, unlink, one-chip-one-artwork, roles, shipment gate and override all hold");
