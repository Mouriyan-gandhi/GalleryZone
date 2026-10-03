// Run: node --experimental-strip-types packages/contracts/src/verify-dto.check.ts
// Same static gate as artwork-dto.check.ts, applied to the fully public
// passport: no price-shaped field, and no contact-detail-shaped field
// either (this page is reachable by anyone who scans a QR).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const source = readFileSync(fileURLToPath(new URL("./verify-dto.ts", import.meta.url)), "utf8");
const start = source.indexOf("interface VerifyPassportDto");
assert.ok(start >= 0);
const body = source.slice(source.indexOf("{", start));

const FORBIDDEN_PRICE = /price|paise|cost/i;
const FORBIDDEN_PII = /email|phone|address|pincode|toUserId|fromUserId|customerId|buyerId/i;
// The chip's UID is for the artist, the gallery holding the piece and admins. A clone
// defence that leaks the real UID defeats itself (NFC_IMPLEMENTATION.md section 3).
const FORBIDDEN_CHIP = /tagUid|nfcTag|chipUid|chipId/i;

assert.ok(!FORBIDDEN_PRICE.test(body), `VerifyPassportDto contains a price-shaped field:
${body}`);
assert.ok(!FORBIDDEN_PII.test(body), `VerifyPassportDto contains a contact/identity field:
${body}`);
assert.ok(!FORBIDDEN_CHIP.test(body), `VerifyPassportDto exposes the NFC chip's UID:
${body}`);
// The two public flags and the lifecycle are the whole NFC surface: make sure they are still there.
for (const field of ["nfcLinked: boolean", "nfcLocked: boolean", "lifecycle: LifecycleEntry[]"]) {
  assert.ok(body.includes(field), `VerifyPassportDto lost ${field}`);
}

// A collector's place is never public (plan.md section 12): an entry about a collector or the
// platform has `location: null` and nothing else. The runtime half of this rule is checked,
// on real entries, by passport.check.ts.
const typeBody = (name: string): string => {
  const at = source.indexOf(`type ${name}`);
  assert.ok(at >= 0, `${name} is missing`);
  // Up to the type's own closing brace (the one at the start of a line), not the one of its `actor`.
  const rest = source.slice(at);
  return rest.slice(0, rest.search(/^};/m) + 2);
};
const privateBody = typeBody("PrivateLifecycleEntry");
assert.ok(/location: null;/.test(privateBody) && !/LifecycleLocation/.test(privateBody), `a collector-side lifecycle entry may not carry a place:
${privateBody}`);
assert.ok(/kind: "collector" \| "platform"/.test(privateBody), "PrivateLifecycleEntry must be the collector/platform side");
const venueBody = typeBody("VenueLifecycleEntry");
assert.ok(!/collector/.test(venueBody), `a venue lifecycle entry (the only kind that may carry a place) must not be about a collector:
${venueBody}`);

// GET /v1/passport/mine wraps the same passport plus the viewer's relation to
// it, so it gets the same gate on its own fields (the passport inside is
// already covered above).
const mineStart = source.indexOf("interface MyPassportsDto");
assert.ok(mineStart >= 0);
const mineBody = source.slice(source.indexOf("{", mineStart));
assert.ok(!FORBIDDEN_PRICE.test(mineBody), `MyPassportsDto contains a price-shaped field:
${mineBody}`);
assert.ok(!FORBIDDEN_PII.test(mineBody), `MyPassportsDto contains a contact/identity field:
${mineBody}`);

console.log("packages/contracts/verify-dto.ts: public passport and my-passports carry no price, contact or chip-UID fields, and no collector place");
