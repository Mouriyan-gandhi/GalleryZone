// Puts the Amazon affiliate products from affiliate-products.seed.json on the
// shelf (/art-supplies). The links came from the client's "Affiliate" WhatsApp
// group (2-3 Oct 2026); titles, brands and photos were read off each Amazon
// page with the API's own lookup (apps/api/src/amazon-product.ts).
//
//   npm run seed:affiliate             # adds what is missing
//   npm run seed:affiliate -- --dry    # says what it would add, writes nothing
//
// Safe to re-run: a product already on the shelf (same ASIN) is left exactly
// as it is, so an admin's edits to its category or visibility survive.
//
// Reads FIREBASE_PROJECT_ID and the service-account credential the same way
// the API does, from ../.env at the repo root or apps/api/.env.

import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createDb, seedAffiliateProducts, type AffiliateProductInput } from "../packages/db/src/index.ts";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "..");

function loadDotEnv(path: string): void {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, "utf8").split(/\r?\n/)) {
    const m = /^([A-Z_]+)=(.*)$/.exec(line.trim());
    if (m && process.env[m[1]!] === undefined) process.env[m[1]!] = m[2]!.replace(/^"|"$/g, "");
  }
}
loadDotEnv(resolve(root, "..", ".env"));
loadDotEnv(resolve(root, "apps", "api", ".env"));

const products = JSON.parse(readFileSync(resolve(here, "affiliate-products.seed.json"), "utf8")) as (AffiliateProductInput & { asin: string })[];

if (process.argv.includes("--dry")) {
  const byCategory = Object.groupBy(products, (p) => p.category);
  for (const [category, items] of Object.entries(byCategory)) console.log(`${String(items!.length).padStart(3)}  ${category}`);
  console.log(`${products.length} products in the seed file. Nothing written.`);
  process.exit(0);
}

const projectId = process.env.FIREBASE_PROJECT_ID;
if (!projectId) {
  console.error("FIREBASE_PROJECT_ID must be set");
  process.exit(1);
}

const { db } = createDb(projectId);
const { created, skipped } = await seedAffiliateProducts(db, products);
console.log(`added ${created}, already on the shelf ${skipped}`);
