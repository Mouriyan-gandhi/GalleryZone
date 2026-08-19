# GalleryZone Mobile (Flutter) — Handoff

Continuation of the Flutter rebuild of GalleryZone mobile. Read this file
first, before re-deriving anything from scratch — most of the "figure out
the environment" work is already done and re-discovering it wastes a
session.

## Repo/workflow rules (don't re-litigate)

- Working repo: `d:\ArtGllery\GalleryZone` (personal, `Yash13606/GalleryZone`
  on GitHub) — build freely here.
- Production is a **separate** repo, `galleryzone5-alt/gallery-web`, live at
  galleryzone.in. Never push there directly from this workspace.
- `frontend-web/` here is the Next.js reference site (76 routes, fully
  mocked, no real backend) — the functional/visual source of truth for this
  app.
- `mobile/` is an **abandoned** Expo/React Native attempt — left on disk for
  reference (still untracked in git, not part of any commit), not developed
  further. Don't touch it, don't revive it, don't commit it.
- `mobile_flutter/` (this folder) is the **active** mobile app.
- Plan file: `C:\Users\yashm\.claude\plans\mellow-swimming-pixel.md` — full
  phase-by-phase plan, stack picks, architecture, open decisions. Read it in
  full before writing more screens.
- SAD (target backend spec, doesn't exist yet):
  `d:\ArtGllery\markitdown\GalleryZone_Software_Architecture_Docume.md`.

## Environment — already set up, don't reinstall

- Flutter SDK: `D:\ArtGllery\tools\flutter` (3.47.0 stable), on user PATH.
- Android SDK: `C:\Users\yashm\AppData\Local\Android\Sdk` (`ANDROID_HOME`/
  `ANDROID_SDK_ROOT` set), platforms 35/36/37 + matching build-tools + NDK +
  CMake installed, all licenses accepted.
- `JAVA_HOME` → `C:\Program Files\Android\Android Studio\jbr` (the system's
  default Temurin JDK path was broken/stale — this is the fix, don't revert
  it).
- `PUB_CACHE` → `D:\ArtGllery\tools\pub-cache`, `GRADLE_USER_HOME` →
  `D:\ArtGllery\tools\gradle-home` — **deliberately relocated off C:**. The
  project lives on D:; Kotlin's incremental compiler has a real bug where
  cross-drive relative-path resolution corrupts its cache and crashes the
  build ("this and base files have different roots"). Keep caches on D: or
  this comes back.
- Emulator: AVD `gz_pixel` (Pixel 6, Android 15 / API 35, google_apis
  x86_64), already created. Boot with:
  `emulator -avd gz_pixel -no-snapshot -gpu swiftshader_indirect`
- `mobile_flutter/android/gradle.properties` has `-Xmx1536m` (not the
  Flutter-template default `-Xmx8G`) — this machine has ~16GB RAM and only
  ~4GB free with the emulator running; 8G OOM-kills the Gradle daemon every
  time. Raise it only if building on a machine with more headroom.
- Bundle id: `in.galleryzone.app` (matches the old Expo attempt's choice,
  for continuity). `MainActivity.kt` lives at
  `android/app/src/main/kotlin/in/galleryzone/app/MainActivity.kt` — **the
  directory path must always match the package declaration inside the
  file**; this broke once already (ClassNotFoundException at runtime) when
  the applicationId was changed without moving the file.
- Verified working: `flutter doctor` clean (Android toolchain), stock
  scaffold builds and boots on `gz_pixel` (screenshotted, confirmed).

## What's actually built (code)

- `lib/core/theme/app_theme.dart` — full brand theme, light+dark, exact
  tokens ported from `frontend-web/app/globals.css` (black+brass-gold,
  Playfair Display + Inter via `google_fonts`, proportional radius scale).
- `lib/data/storage/mock_db.dart` — exact port of `lib/mock-db.ts`'s
  lazy-seed-on-first-read pattern, `shared_preferences`-backed, same
  `gz-db-v1:` prefix philosophy.
- `lib/core/storage/secure_session.dart` — role-string session storage via
  `flutter_secure_storage` (mobile equivalent of the web's `gz_session`
  cookie).
- `lib/data/models/artwork.dart`, `artist.dart`, `auth.dart`,
  `artwork_filters.dart` — freezed/json_serializable models mirroring the
  TS types field-for-field.
- `lib/data/mock/seed/artists_seed.dart`, `artworks_seed.dart` — **real**
  fixture data, ported verbatim from `frontend-web/lib/mock-data/*.ts` (7
  artists, 18 artworks) — not placeholders.
- `lib/data/repositories/artwork_repository.dart` +
  `lib/data/mock/mock_artwork_repository.dart` — done.
- `lib/data/repositories/auth_repository.dart` +
  `lib/data/mock/mock_auth_repository.dart` — done.
- `lib/data/mock/mock_utils.dart` — `mockDelay`/`mockError`, port of
  `lib/mock-utils.ts`.

Run `dart run build_runner build` after touching any `@freezed`/
`@JsonSerializable` model — codegen output (`.freezed.dart`/`.g.dart`) isn't
committed source, it's generated.

## What's NOT built yet (Phase 0 gaps + everything after)

- go_router not wired up — app is still the stock Flutter counter demo.
- 7 of 9 repository interfaces missing: Marketplace (partly folded into
  Artwork already — check before adding a duplicate), Aggregator, Order &
  Wallet, Settlement, Customer, Messages, Support.
- 23 of ~25 mock collections not seeded (only artworks/artists exist).
- Zero actual screens. No login, no marketplace browse, no dashboards —
  nothing past the default template.

## Recommended next step

Don't batch-build the remaining 7 repositories/23 collections up front —
that contradicts the plan's own philosophy (vertical slices, not a
shell-everything-first milestone; see "Phase breakdown" in the plan file).

**Do Phase 1 next**: wire `go_router` + build the 5 auth screens
(login/register/forgot-password/reset-password/verify-email) against the
already-built `AuthRepository`, with role-based shell mounting
(`CustomerShell`/`ArtistShell`/`AggregatorShell` stubs are fine to start
empty). Then Phase 2 (marketplace) reuses the already-built
`ArtworkRepository`. Build each later repository/collection only when the
phase that needs it actually needs it.

## Open decisions — still unresolved, don't guess

1. Payment gateway (recommend Razorpay, not decided).
2. Aggregator commission/settlement formula — genuine 3-way conflict between
   mocked code, a business requirement, and the SAD's schema. See plan file
   for detail. Blocks Phase 6 settlement screens being *correct*, not
   Phase 6 existing.
3. Public marketing pages (Phase 7) — full native rebuild vs. minimal/
   link-out to galleryzone.in.
4. iOS — no Mac on this dev machine. Recommend Android-first, revisit once
   there's a real app to test.
