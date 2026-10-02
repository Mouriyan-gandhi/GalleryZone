// Run: node --experimental-strip-types packages/contracts/src/artwork-dto.check.ts
//
// Price-leak contract test — plan.md §8 / §17 gate. Extracts the
// CustomerArtworkDto interface's own source text (not its subtypes) and
// fails if any field name matches /artist_price|private_price|cost/i. This
// is a static source check rather than a full TS-AST inspection (no
// TypeScript compiler API dependency needed to run it), which is enough to
// catch the actual failure mode: someone adding `artistPricePaise` (or a
// same-shaped field) directly onto the customer-facing interface. It does
// NOT catch a hand-written serializer that manually copies the field in
// at runtime despite the type saying otherwise — that needs an
// integration test once apps/api exists (Phase 1/2), noted here so this
// gate isn't mistaken for the whole guarantee.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const sourcePath = fileURLToPath(new URL("./artwork-dto.ts", import.meta.url));
const source = readFileSync(sourcePath, "utf8");

function extractInterfaceBody(src: string, name: string): string {
  const start = src.indexOf(`interface ${name}`);
  assert.ok(start >= 0, `could not find "interface ${name}" in artwork-dto.ts`);
  const openBrace = src.indexOf("{", start);
  let depth = 0;
  let i = openBrace;
  for (; i < src.length; i++) {
    if (src[i] === "{") depth++;
    if (src[i] === "}") {
      depth--;
      if (depth === 0) break;
    }
  }
  return src.slice(openBrace, i + 1);
}

const FORBIDDEN = /artist_price|artistprice|private_price|privateprice|\bcost\b/i;

const customerBody = extractInterfaceBody(source, "CustomerArtworkDto");
assert.ok(
  !FORBIDDEN.test(customerBody),
  `CustomerArtworkDto contains a forbidden price-shaped field:\n${customerBody}`,
);

// Sanity check the test itself isn't vacuous: OwnerArtworkDto (which
// legitimately carries artistPricePaise) SHOULD trip the same pattern —
// if it didn't, the regex or the extraction logic would be broken.
const ownerBody = extractInterfaceBody(source, "OwnerArtworkDto");
assert.ok(
  FORBIDDEN.test(ownerBody),
  "sanity check failed: OwnerArtworkDto should contain artistPricePaise — if it doesn't, this test can't be trusted",
);

// The COA is not part of a marketplace listing: the customer shape has no
// certificate fields, the owner's does (the same sanity check as above).
assert.ok(!/coa/i.test(customerBody), `CustomerArtworkDto must not carry the COA:\n${customerBody}`);
assert.ok(/coaCertificateNumber/.test(ownerBody), "sanity check failed: OwnerArtworkDto should carry the COA");

console.log("packages/contracts/artwork-dto.ts: price-leak contract test passed (CustomerArtworkDto is clean, and has no COA)");
