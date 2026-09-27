# GalleryZone

A marketplace for original artwork, built around one idea: every piece carries a
verifiable identity — who made it, who owns it now, and everywhere it has been.
Three portals run on the same catalogue: **artists** list and price their work,
**aggregators** take pieces on display in real galleries, and **collectors** buy,
own and resell them. A QR code on each piece resolves to its public passport.

This repository is the website and its API.

| Folder | What it is |
|---|---|
| `frontend-web/` | Next.js 16 site (App Router). Deployed on Vercel. |
| `backend/` | NestJS API on Firestore (Firebase Admin SDK is the only writer). npm-workspaces monorepo: `apps/api`, `packages/{domain,db,contracts,config}`. |
| `docs/` | Design notes, the backend master plan, audits. |

## Running it locally

One env file for everything: copy `.env.example` to `.env` at the repo root and
fill it in (Firebase web config, the Admin SDK key path). Both apps read it.

```bash
# API  → http://localhost:8080
cd backend && npm ci && npm run dev

# website → http://localhost:3000
cd frontend-web && npm ci && npm run dev
```

`npm run check` in `backend/` runs the verification suite (contract tests,
state machines, pricing replay, type-check, build). `npm run build` in
`frontend-web/` must pass before a push; `npm run test:smoke` drives it with
Playwright.

## Local demo world

A full local copy of the site with demo accounts and realistic data: Firebase
emulators, a fake S3 bucket, and nothing that can reach production.
`.env.demo` (committed) uses the offline-only project `demo-galleryzone`, and
its mail, payment and monitoring keys are empty. Needs Java 11+ for the
Firestore emulator. Start each in its own terminal:

```bash
cd backend && npm run demo:emulators   # Auth :9099, Firestore :8085, UI :4000
cd backend && npm run demo:s3          # artwork images on :4568
cd backend && npm run demo:api         # API :8080, against the emulators (the seed refuses any other API)
cd frontend-web && npm run demo        # site :3000, signs in against the emulator
cd backend && npm run demo:seed        # wipes the emulators, then seeds; safe to re-run
```

Every demo password is `Demo@12345`:

| Account | Role | Shows |
|---|---|---|
| `admin@demo.galleryzone.test`, `admin2@…` | Admin | moderation queues, two-admin pricing approval |
| `artist@demo.galleryzone.test` | Artist | every artwork state, wallet, certificates |
| `artist2@demo.galleryzone.test` | Artist | very long names and titles |
| `aggregator@demo.galleryzone.test` | Aggregator | holdings, sales, cash owed, remittance |
| `collector@demo.galleryzone.test` | Collector | orders, collection, resale, a pending transfer |
| `artist-new@`, `aggregator-new@`, `collector-new@` | each role | empty states |

The wishlist is browser-local, so it starts empty. The data lives only in the
emulators: stop them and it's gone.

## Deploying

- **Website**: Vercel, *Import from GitHub* with **Root Directory = `frontend-web`**.
  Set the `NEXT_PUBLIC_*` variables from `.env.example` in the project's
  Environment Variables (`NEXT_PUBLIC_SITE_URL` = the production domain — it is
  baked into QR codes; `NEXT_PUBLIC_API_URL` = where the API is hosted).
- **API**: any Node 22+ host (Railway, Render, Cloud Run). Set the backend
  variables from `.env.example`, provide the service-account JSON as a file,
  and put the Vercel domain in `CORS_ORIGINS`. Build with `npm run build`, run
  with `node --experimental-strip-types apps/api/dist/main.js`.
- **Firestore rules/indexes**: `cd backend && npx firebase-tools deploy --only firestore`.

## Conventions

Money is integer paise. Every API error is RFC 7807 (`{type,title,status,code}`).
Every route carries `@Roles()` or `@Public()`. Authorization is always re-read
from `users/{uid}` in Firestore, never from the ID token's claims. Small,
verified commits, pushed to `main`.
