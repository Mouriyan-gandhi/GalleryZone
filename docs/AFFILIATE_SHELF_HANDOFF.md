# Affiliate shelf (Amazon "Art supplies") — backend handoff

Read this before touching it. State as of **4 Oct 2026**, on top of `main` at `e304ff0`.
**None of this is committed or deployed yet**; it sits in the working tree of whoever built it.

## What it is

A public page, `/art-supplies`, listing 118 Amazon products GalleryZone recommends to artists. Every
button is an Amazon affiliate link, so a sale earns GalleryZone a commission. An admin screen,
`/admin/art-supplies`, adds, edits, hides and removes products. The products came from the client's
"Affiliate" WhatsApp group (128 `https://link.amazon/…` links; 10 were duplicates of another link's
product, leaving 118). When a short link is followed, Amazon redirects to amazon.in with the client's
Associates tag `tag=galleryzone27-21`, which is how a purchase is credited. **Never rewrite or expand
these links.**

## Where things stand

| | Status |
|---|---|
| API routes (public list, admin CRUD, Amazon lookup) | Written. Compiles, built, `npm run check` green (158 routes). **Never called over HTTP.** |
| DB layer (`affiliate-products.ts`) | Ran green against the real Firestore emulator (seed, edit-survival, duplicate ASIN, update, delete, a 1,200-product batch). The check now lives at `packages/db/src/affiliate-products.check.ts`; only its import path changed when it moved, so **re-run it**. |
| Amazon page parser + host allow-list | Unit-checked in `npm run check` (`apps/api/src/amazon-product.check.ts`). Also ran against all 128 real links. |
| Website (public page, admin screen) | Built. 10 Playwright tests pass **with the API stubbed**; production `next build --webpack` passes. |
| `seed:affiliate` script | **Never run**, not even `--dry`. Its data file was validated separately (118 products, 233 photos, every photo URL returned an image). |
| `scripts/affiliate-e2e.sh` | Written, **never run**. See "Do these first". |
| Flutter app | **Not built.** Only the website has this. `GET /v1/affiliate-products` is ready for it. |

## Do these first (in order)

1. `cd backend && npm ci && npm run check` — must be green.
2. `npm run check:affiliate-db` — needs Java (Temurin 25 worked). Re-confirms the DB layer after the move.
3. `npm run e2e:affiliate` — the unrun script. It starts the Firestore + Auth emulators, seeds, boots the
   built API, then drives every route as an admin, a customer and no one. It asserts what we *expect*:
   `401` with no token, `403` for a customer, `400` for a bad body, `409` for a duplicate ASIN, `404` for an
   unknown id, and that the public list changes the moment an admin writes. Those statuses are expectations,
   not verified facts. Fix the script if it is the thing that is wrong, and the API if the API is.
4. Deploy the **API first**, then the website. The page shows "The shelf didn't load" if the route is missing.
5. Seed production: `npm run seed:affiliate -- --dry`, then `npm run seed:affiliate`. It writes to the live
   Firestore, so use the same `../.env` the API uses (`FIREBASE_PROJECT_ID` + the service-account credential,
   see the root README). It is safe to re-run: products already on the shelf are left exactly as they are.
6. Smoke test in production: open `/art-supplies`; click a card; confirm the Amazon URL you land on carries
   `tag=galleryzone27-21`. If it does not, stop and tell Yash. That tag is the whole point.

## Code map

Backend (`backend/`)
- `apps/api/src/affiliate-products.controller.ts` — two controllers: `AffiliateProductsController` (public) and `AdminAffiliateProductsController`. Zod-validated, `.strict()`.
- `apps/api/src/amazon-product.ts` — fetches and parses an Amazon product page; `MAX_IMAGES = 2`; the `isAmazonUrl` allow-list.
- `packages/db/src/affiliate-products.ts` — list / create / update / delete / seed. `AffiliateError extends DbError`, so messages starting `No ` answer 404 and others 409 (see `errors.ts`).
- `packages/db/src/collections.ts` — `Collections.affiliateProducts` and `AffiliateProductDoc`.
- `packages/contracts/src/api-routes.ts` — six new rows.
- `scripts/seed-affiliate-products.ts` + `scripts/affiliate-products.seed.json` — the 118 products.
- `apps/api/src/app.module.ts` — both controllers registered.

Website (`frontend-web/`)
- `app/art-supplies/page.tsx`, `features/art-supplies/*` — public page, card, quick-view popup.
- `app/admin/art-supplies/page.tsx`, `features/admin/catalog/affiliate-manager.tsx` — admin.
- `services/affiliateService.ts`, `hooks/useAffiliateProducts.ts`, `types/affiliate.ts`.
- `tests/functional/art-supplies.spec.ts` — the 10 browser tests.
- Header and footer links; a nav entry in `features/admin/admin-shell.tsx`.

## API

| Method and path | Who | Notes |
|---|---|---|
| `GET /v1/affiliate-products` | public | Active products only, oldest first. Cached (see Gotchas). → `{ products }` |
| `GET /v1/admin/affiliate-products` | admin | All products, hidden ones too. |
| `POST /v1/admin/affiliate-products/lookup` | admin | `{ url }` → `{ asin, title, brand, categoryPath, images }`. Saves nothing. `422 amazon_lookup_failed` when Amazon won't answer. |
| `POST /v1/admin/affiliate-products` | admin | `url` (https, Amazon host), `asin?` (10 chars `A-Z0-9`), `title` 2–300, `brand?` ≤80, `category` 2–60, `images` **1–2** https URLs, `active?`. → `201` the row. |
| `PATCH /v1/admin/affiliate-products/:id` | admin | Any of the above except `asin` (the id; sending it is a `400`). |
| `DELETE /v1/admin/affiliate-products/:id` | admin | → `{ id }` |

A row is `{ id, url, asin, title, brand, category, images, active, createdAt, updatedAt }`, dates as ISO strings.
Collection `affiliateProducts`; the document id **is** the ASIN, which is what stops a product being listed twice.
There is no `firestore.rules` entry on purpose: the catch-all denies clients and the API (Admin SDK) is the only reader and writer.

## Settled — don't re-open without asking Yash

- **No price, rating or review count, stored or shown.** Amazon's Associates agreement allows those only from their
  official product API, refreshed daily; a scraped price goes stale and breaks it. Cards link out for the price.
  Showing prices means Amazon's Product Advertising API, which needs approved access first. A product decision, not a bug.
- **One or two photos per product** (Yash's call). Three products have one because Amazon has one.
- Photos are **hotlinked** from `m.media-amazon.com` (resized by changing the URL suffix), not re-hosted.
  Whether that satisfies the client's Associates terms has not been confirmed with the client.
- The page carries "As an Amazon Associate, GalleryZone earns from qualifying purchases", and affiliate links use
  `rel="sponsored nofollow noopener"`. Keep both.
- The product URL and the lookup fetch accept **only https Amazon hosts** (a guard against making the server fetch
  arbitrary URLs). `amazon.in.evil.com` and the cloud metadata IP are refused; this is tested.

## Gotchas

- **Amazon answers about one request in three with a captcha page** instead of the product. The lookup retries up to
  three times, then returns `422`, and the admin form falls back to typing by hand. It was tested from a home connection;
  **from a cloud host expect more failures**. If it is bad in production, that is the lookup, not the rest.
- **Caching:** the public list is cached in-process for 5 minutes (`TTL.artist`) and sent with
  `Cache-Control: public, max-age=60, s-maxage=300`. A write clears the cache on the instance that handled it only,
  so a hidden product can stay visible for up to about 5 minutes. Fine on one instance; revisit if the API scales out.
- A product typed in by hand (lookup failed) has no ASIN, gets a random id, and so has **no duplicate protection**.
- The list reads the whole collection and filters in memory (118 docs; a comment in the file marks the ceiling).
- Admin edits are **not** written to `auditLog` (category edits aren't either).
- Nothing checks that a product is still on sale. Amazon delists things, so some links will go dead.
- The throwaway scraper that produced the seed file is not in the repo. The JSON is the source of truth; add products in the admin.
- `check:affiliate-db` and `e2e:affiliate` run `npx firebase-tools` (downloaded on first use) and need Java.

## Possible follow-ups (none asked for)

A link-health job in `apps/jobs`; audit-log entries for admin changes; prices and ratings via Amazon's API;
a Flutter screen; real pagination if the shelf grows past a few hundred.

## Rolling back

Hide everything from the admin screen, or delete the `affiliateProducts` collection. The page then reads
"The shelf is being stocked". Nothing else in the system depends on it.
