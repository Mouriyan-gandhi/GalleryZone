// Run: node --experimental-strip-types packages/db/src/passport.check.ts
// The merge is the only logic in passport.ts that doesn't need Firestore:
// one entry per piece, every relation kept, the role's own list first.
// The lifecycle builder (lifecycle.ts, NFC_IMPLEMENTATION.md section 6) is pure
// too, and carries the privacy rule: a collector's place is never public.

import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import { buildLifecycle, parseLocation, type LifecycleInputs } from "./lifecycle.ts";
import { mergePassportLinks } from "./passport.ts";

// A collector: owns two pieces, nothing else.
const collector = mergePassportLinks("customer", {
  owner: [{ artworkId: "a1" }, { artworkId: "a2" }],
  artist: [],
  holder: [],
});
assert.deepEqual(collector.map((l) => l.artworkId), ["a1", "a2"]);
assert.deepEqual(collector[0]!.relations, ["owner"]);
assert.equal(collector[0]!.nfcLinked, null);
assert.equal(collector[0]!.holdingId, null);

// An artist who bought back their own work: one entry, both relations, own works listed first.
const artist = mergePassportLinks("artist", {
  owner: [{ artworkId: "bought-back" }, { artworkId: "someone-elses" }],
  artist: [{ artworkId: "mine-1", nfcLinked: true }, { artworkId: "bought-back", nfcLinked: false }],
  holder: [],
});
assert.deepEqual(artist.map((l) => l.artworkId), ["mine-1", "bought-back", "someone-elses"]);
assert.deepEqual(artist[1]!.relations, ["artist", "owner"]);
assert.equal(artist[0]!.nfcLinked, true);
assert.equal(artist[2]!.nfcLinked, null);

// An aggregator: held pieces first, each carrying its holding to open.
const aggregator = mergePassportLinks("aggregator", {
  owner: [{ artworkId: "own" }],
  artist: [],
  holder: [{ artworkId: "held", holdingId: "h1" }],
});
assert.deepEqual(aggregator.map((l) => l.artworkId), ["held", "own"]);
assert.equal(aggregator[0]!.holdingId, "h1");
assert.equal(aggregator[1]!.holdingId, null);

// A customer never sees artist or holder links even if a caller passes them.
const stray = mergePassportLinks("customer", { owner: [], artist: [{ artworkId: "x", nfcLinked: true }], holder: [{ artworkId: "y", holdingId: "h" }] });
assert.deepEqual(stray, []);

// --- Lifecycle ---------------------------------------------------------------------

const day = (n: number) => new Date(Date.UTC(2026, 8, n, 10, 0, 0));
const ts = (n: number) => Timestamp.fromDate(day(n));
const pune = parseLocation("Pune, Maharashtra");
const delhiGallery = { city: "Delhi", state: "Delhi", country: "India" };

assert.deepEqual(pune, { city: "Pune", state: "Maharashtra", country: "India" });
assert.deepEqual(parseLocation("Paris, France"), { city: "Paris", state: "", country: "France" }, "a second part that is no Indian state is a country");
assert.deepEqual(parseLocation("Austin, Texas, USA"), { city: "Austin", state: "Texas", country: "USA" });
assert.deepEqual(parseLocation("Mumbai"), { city: "Mumbai", state: "", country: "India" });
assert.equal(parseLocation("  "), null);
assert.equal(parseLocation(null), null);

const fresh: LifecycleInputs = {
  createdAt: day(1),
  artistName: "Asha Rao",
  artistLocation: pune,
  statusEvents: [
    { status: "pending_approval", changedAt: day(1) },
    { status: "marketplace", changedAt: day(2) },
  ],
  placements: [],
  gallerySales: [],
  ownership: [],
  deliveredAt: new Map(),
};

// A fresh listing has at least the made and listed entries, with the artist's place.
const live = buildLifecycle(fresh);
assert.deepEqual(live.map((e) => e.kind), ["created", "approved", "listed"]);
assert.deepEqual(live[0]!.location, pune);
assert.equal(live[0]!.actor.kind, "artist");
assert.equal(live[1]!.location, null, "the platform has no place");
assert.deepEqual(buildLifecycle({ ...fresh, statusEvents: [{ status: "pending_approval", changedAt: day(1) }] }).map((e) => e.kind), ["created"], "not approved yet: not listed either");

// A placement at a gallery, then back: both legs appear, with the gallery's place, oldest first.
const placed = buildLifecycle({
  ...fresh,
  placements: [{ id: "h1", galleryName: "Studio Eight", galleryLocation: delhiGallery, cycleMonth: 1, status: "returned", assignedAt: day(5), returnedAt: day(20) }],
});
assert.deepEqual(placed.map((e) => e.kind), ["created", "approved", "listed", "placed_with_gallery", "returned_from_gallery"]);
assert.deepEqual(placed[3]!.location, delhiGallery);
assert.equal(placed[3]!.actor.displayName, "Studio Eight");
assert.equal(placed[3]!.note, "Month 1 of the gallery cycle");
assert.deepEqual(placed[4]!.location, delhiGallery);
const stillThere = buildLifecycle({ ...fresh, placements: [{ id: "h1", galleryName: "Studio Eight", galleryLocation: delhiGallery, cycleMonth: 1, status: "reserved", assignedAt: day(5), returnedAt: null }] });
assert.deepEqual(stillThere.map((e) => e.kind), ["created", "approved", "listed", "placed_with_gallery"], "no return entry while it is still there");

// A sale at the gallery names the gallery and never the buyer.
const soldThere = buildLifecycle({
  ...fresh,
  placements: [{ id: "h1", galleryName: "Studio Eight", galleryLocation: delhiGallery, cycleMonth: 1, status: "sold_pending_settlement", assignedAt: day(5), returnedAt: null }],
  gallerySales: [{ id: "s1", placementId: "h1", soldAt: day(9) }],
});
const galleryEntry = soldThere.find((e) => e.kind === "sold_at_gallery")!;
assert.equal(galleryEntry.actor.kind, "gallery");
assert.deepEqual(galleryEntry.location, delhiGallery);

// A marketplace sale, a hand-over, a display loan and a delivery: all about collectors or the platform, so none carries a place.
const owned = buildLifecycle({
  ...fresh,
  ownership: [
    { id: "o1", kind: "ownership", status: "accepted", toName: "Ravi K", orderId: "ord-1", acceptedAt: ts(10) },
    { id: "o2", kind: "ownership", status: "accepted", toName: "Meera S", orderId: null, acceptedAt: ts(20) },
    { id: "o3", kind: "display", status: "accepted", toName: "A Cafe", orderId: null, acceptedAt: ts(25) },
    { id: "o4", kind: "ownership", status: "pending", toName: "Someone", orderId: null, acceptedAt: null },
    { id: "o5", kind: "ownership", status: "cancelled", toName: "Nobody", orderId: null, acceptedAt: null },
  ],
  deliveredAt: new Map([["ord-1", day(14)]]),
});
assert.deepEqual(owned.map((e) => e.kind), ["created", "approved", "listed", "sold_marketplace", "delivered", "transferred", "displayed"], "pending and cancelled hand-overs never happened");
for (const e of owned) {
  if (e.actor.kind === "collector" || e.actor.kind === "platform") assert.equal(e.location, null, `${e.kind} must not carry a place`);
}
assert.equal(owned.find((e) => e.kind === "delivered")!.at, day(14).toISOString());

// The whole timeline, even when every source has a place to give: only the artist and galleries ever carry one.
const everything = buildLifecycle({
  ...fresh,
  placements: [{ id: "h1", galleryName: "Studio Eight", galleryLocation: delhiGallery, cycleMonth: 1, status: "returned", assignedAt: day(5), returnedAt: day(8) }],
  gallerySales: [],
  ownership: [{ id: "o1", kind: "ownership", status: "accepted", toName: "Ravi K", orderId: "ord-1", acceptedAt: ts(10) }],
  deliveredAt: new Map([["ord-1", day(14)]]),
});
for (const e of everything) {
  if (e.location !== null) assert.ok(e.actor.kind === "artist" || e.actor.kind === "gallery", `${e.kind} by ${e.actor.kind} carries a place`);
}
assert.deepEqual(everything.map((e) => e.at), [...everything.map((e) => e.at)].sort(), "oldest first");

// Entries at the same instant keep a sensible order: a delivery never sorts before its sale.
const sameInstant = buildLifecycle({
  ...fresh,
  ownership: [{ id: "o1", kind: "ownership", status: "accepted", toName: "Ravi K", orderId: "ord-1", acceptedAt: ts(10) }],
  deliveredAt: new Map([["ord-1", day(10)]]),
});
assert.deepEqual(sameInstant.slice(-2).map((e) => e.kind), ["sold_marketplace", "delivered"]);

// Nothing private rides along in the JSON: no contact detail, prices, buyer of a gallery sale, or chip UID.
const json = JSON.stringify(everything) + JSON.stringify(soldThere);
assert.ok(!/@|paise|price|buyer|tagUid/i.test(json), "the lifecycle carries no contact, price, buyer or chip detail");

console.log("packages/db/passport.ts: links merge per piece, relations kept, role-ordered, other roles' links ignored; lifecycle merges oldest first and never shows a collector's place");
