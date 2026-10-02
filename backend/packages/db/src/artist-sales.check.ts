// Run: node --experimental-strip-types packages/db/src/artist-sales.check.ts
// The financial-year key is the one part of artist-sales.ts that needs no
// Firestore: every sale is filed under it, so a wrong key at the 1 April
// boundary would start the ₹5 lakh count in the wrong year.

import assert from "node:assert/strict";
import { financialYearKey } from "./artist-sales.ts";

const at = (iso: string) => financialYearKey(new Date(iso));

assert.equal(at("2026-09-30T10:00:00.000Z"), "2026-27");
assert.equal(at("2027-02-14T10:00:00.000Z"), "2026-27", "February belongs to the year that began the April before");
assert.equal(at("2026-03-31T18:29:59.000Z"), "2025-26", "the last second of 31 March, India time");
assert.equal(at("2026-03-31T18:30:00.000Z"), "2026-27", "1 April 00:00 India time is the first moment of the new year");
assert.equal(at("2099-05-01T00:00:00.000Z"), "2099-00", "the century rolls over as two digits");
assert.equal(at("2026-04-01T00:00:00.000Z"), "2026-27");

console.log("packages/db/artist-sales.ts: financial-year keys hold at the 1 April boundary");
