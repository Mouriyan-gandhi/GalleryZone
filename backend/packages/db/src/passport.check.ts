// Run: node --experimental-strip-types packages/db/src/passport.check.ts
// The merge is the only logic in passport.ts that doesn't need Firestore:
// one entry per piece, every relation kept, the role's own list first.

import assert from "node:assert/strict";
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

console.log("packages/db/passport.ts: links merge per piece, relations kept, role-ordered, other roles' links ignored");
