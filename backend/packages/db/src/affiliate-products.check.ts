// Run (needs Java for the emulator):  npm run check:affiliate-db
//
// Real-Firestore-emulator check of affiliate-products.ts. Not part of `npm run check`
// because that suite has no emulator. The repo's other db checks use a hand-rolled fake;
// this one needs the real thing for create() failing on a duplicate id, ordering, and
// the 500-writes-per-batch limit.

import assert from "node:assert/strict";
import { createDb, listAffiliateProducts, createAffiliateProduct, updateAffiliateProduct, deleteAffiliateProduct, seedAffiliateProducts, AffiliateError } from "./index.ts";

const { db } = createDb("demo-gz");
const base = { url: "https://link.amazon/x", title: "Brush set", brand: "ECLET", category: "Brushes", images: ["https://m.media-amazon.com/images/I/a._SL1500_.jpg"] };

// seed: order kept, duplicate ASIN in the input counted once, re-run changes nothing
const seed = ["B000000001", "B000000002", "B000000003", "B000000002"].map((asin, i) => ({ ...base, asin, title: `Item ${i}` }));
assert.deepEqual(await seedAffiliateProducts(db, seed), { created: 3, skipped: 0 });
assert.deepEqual((await listAffiliateProducts(db, { activeOnly: true })).map((p) => p.id), ["B000000001", "B000000002", "B000000003"]);

// an admin edit survives a re-seed
await updateAffiliateProduct(db, "B000000001", { category: "Easels", active: false });
assert.deepEqual(await seedAffiliateProducts(db, seed), { created: 0, skipped: 3 });
const all = await listAffiliateProducts(db, { activeOnly: false });
assert.equal(all.find((p) => p.id === "B000000001")!.category, "Easels");
assert.equal((await listAffiliateProducts(db, { activeOnly: true })).length, 2, "hidden products are not on the public list");

// update: unspecified fields kept, null clears the brand, createdAt fixed, updatedAt moves
const before = all.find((p) => p.id === "B000000002")!;
const after = await updateAffiliateProduct(db, "B000000002", { brand: null });
assert.equal(after.brand, null);
assert.equal(after.title, before.title);
assert.equal(after.createdAt, before.createdAt);
assert.ok(after.updatedAt >= before.updatedAt);

// create: ASIN is the id, a second add of the same ASIN is refused in words, no-ASIN gets a generated id
const created = await createAffiliateProduct(db, { ...base, asin: "B000000009" });
assert.equal(created.id, "B000000009");
await assert.rejects(() => createAffiliateProduct(db, { ...base, asin: "B000000009" }), (e) => e instanceof AffiliateError && /already on the shelf/.test(e.message));
const manual = await createAffiliateProduct(db, base);
assert.ok(manual.id.length >= 10 && manual.asin === null);

// unknown ids are "No ..." errors (the API answers those as 404)
await assert.rejects(() => updateAffiliateProduct(db, "nope", { title: "x" }), (e) => e instanceof AffiliateError && e.message.startsWith("No "));
await assert.rejects(() => deleteAffiliateProduct(db, "nope"), (e) => e instanceof AffiliateError && e.message.startsWith("No "));

await deleteAffiliateProduct(db, "B000000009");
assert.equal((await listAffiliateProducts(db, { activeOnly: false })).some((p) => p.id === "B000000009"), false);

// 1,200 products cross the 500-per-batch limit
const many = Array.from({ length: 1200 }, (_, i) => ({ ...base, asin: `M${String(i).padStart(9, "0")}` }));
assert.deepEqual(await seedAffiliateProducts(db, many), { created: 1200, skipped: 0 });

console.log("affiliate-products against the Firestore emulator: seed, edit-survival, create/dup, update, delete, 1200-batch all hold");
