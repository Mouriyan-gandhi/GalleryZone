# GalleryZone

A marketplace for original artwork, built around one idea: every piece carries a
verifiable identity — who made it, who owns it now, and everywhere it has been.
Three portals run on the same catalogue: **artists** list and price their work,
**aggregators** take pieces on display in real galleries, and **collectors** buy,
own and resell them. A QR code on each piece resolves to its public passport.

This repository is all of it: the website, its API and the mobile app.

| Folder | What it is |
|---|---|
| `frontend-web/` | Next.js 16 site (App Router). Deployed on Vercel. |
| `backend/` | NestJS API on Firestore (Firebase Admin SDK is the only writer). npm-workspaces monorepo: `apps/api`, `packages/{domain,db,contracts,config}`. |
| `mobile/` | Flutter app (Android and iOS) for artists, aggregators and collectors. Talks to the same API. See [`mobile/README.md`](mobile/README.md). |
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
