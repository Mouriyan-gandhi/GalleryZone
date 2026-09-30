// Run: node --experimental-strip-types lib/similar-artworks.check.ts

import assert from "node:assert/strict";
import { similarTo, similarityScore } from "./similar-artworks.ts";

const piece = (id: string, category: string, customerPrice: number, sizeBand: "small" | "medium" | "large" | null = null) =>
  ({ id, category, customerPrice, sizeBand }) as Parameters<typeof similarityScore>[0];

const reference = piece("ref", "Abstract", 100_000, "medium");

// Category is the anchor; price and size add to it.
assert.equal(similarityScore(reference, piece("a", "Abstract", 500_000, "large")), 3, "category alone");
assert.equal(similarityScore(reference, piece("a", "Abstract", 90_000, "medium")), 6, "category, price and size");
assert.equal(similarityScore(reference, piece("a", "Portrait", 90_000, "medium")), 3, "price and size without category still qualifies");
assert.equal(similarityScore(reference, piece("a", "Portrait", 90_000, "large")), 2, "price alone does not");
assert.equal(similarityScore(reference, piece("a", "Portrait", 74_999, "medium")), 1, "more than a quarter apart is not similar in price");
assert.equal(similarityScore(reference, piece("a", "Abstract", 75_000, "medium")), 6, "exactly a quarter apart is similar");
assert.equal(similarityScore(reference, piece("a", "", 0, null)), 0, "nothing known, nothing matched");

// Ranking: best first, never itself, capped, and nothing below the bar.
const candidates = [
  piece("weak", "Portrait", 90_000, "large"),
  piece("best", "Abstract", 95_000, "medium"),
  piece("mid", "Abstract", 400_000, "small"),
  piece("self", "Abstract", 100_000, "medium"),
  piece("none", "Landscape", 10_000, "small"),
];
assert.deepEqual(similarTo([reference, piece("self", "Abstract", 100_000, "medium")], candidates).map((c) => c.id), ["best", "mid"]);
assert.deepEqual(similarTo([reference], candidates, 1).map((c) => c.id), ["best"], "the limit applies");
assert.deepEqual(similarTo([], candidates), [], "no references, no suggestions");

// With several references, a candidate counts by the one it matches best: the
// Landscape piece qualifies through r1's category, the Abstract ones through r2.
assert.deepEqual(
  similarTo([piece("r1", "Landscape", 999_999, null), piece("r2", "Abstract", 95_000, "medium")], candidates).map((c) => c.id),
  ["best", "self", "mid", "none"],
);

console.log("lib/similar-artworks.ts checks passed");
