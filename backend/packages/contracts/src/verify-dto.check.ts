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

assert.ok(!FORBIDDEN_PRICE.test(body), `VerifyPassportDto contains a price-shaped field:
${body}`);
assert.ok(!FORBIDDEN_PII.test(body), `VerifyPassportDto contains a contact/identity field:
${body}`);

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

console.log("packages/contracts/verify-dto.ts: public passport and my-passports carry no price or contact fields");
