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
- Verified working: `flutter doctor` clean (Android toolchain), the app
  builds and boots on `gz_pixel` (screenshotted, confirmed).
- **Shells don't always inherit the user-level env vars.** `PUB_CACHE` and
  `GRADLE_USER_HOME` are set at user scope, but a shell started before that
  (or a non-login shell) sees them empty, and `flutter pub add` then writes
  to the default cache on C: instead of D:. Export both explicitly at the
  top of any build/pub command, then run `flutter pub get` to repoint
  `.dart_tool/package_config.json` back at D:.
- `lucide_icons` (0.257.0) is **dead** — its `LucideIconData extends
  IconData` no longer compiles now that Flutter 3.47 made `IconData` final.
  Replaced by `lucide_icons_flutter` (3.1.15), same `LucideIcons.<name>`
  API. Lucide ships no brand glyphs, so the 4 social marks are hand-drawn
  SVG in `lib/features/marketplace/widgets/social_glyphs.dart`, ported from
  the web's `components/social-icons.tsx`.

## Commands (copy these — the env vars matter, see above)

```powershell
$env:PUB_CACHE="D:\ArtGllery\tools\pub-cache"
$env:GRADLE_USER_HOME="D:\ArtGllery\tools\gradle-home"
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME="C:\Users\yashm\AppData\Local\Android\Sdk"
cd d:\ArtGllery\GalleryZone\mobile_flutter

flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # after touching a @freezed model
flutter build apk --debug
flutter build appbundle --release                          # store build; R8 on

# Only after editing assets/icon/generate_icons.py or the generator config
# at the bottom of pubspec.yaml:
python assets/icon/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

On-device check (the emulator dies under memory pressure — restart it rather
than debugging the crash):

```powershell
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd gz_pixel -no-snapshot -gpu swiftshader_indirect
$adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
& $adb install -r build\app\outputs\flutter-apk\app-debug.apk
& $adb shell am start -n in.galleryzone.app/.MainActivity
& $adb shell screencap -p /sdcard/s.png; & $adb pull /sdcard/s.png .
```

Screenshots must go through `adb shell screencap` + `adb pull` — piping
`adb exec-out screencap -p > file.png` through PowerShell corrupts the bytes.
Run these from PowerShell, not Git Bash: Git Bash rewrites the device path
`/sdcard/s.png` into `C:/Program Files/Git/sdcard/s.png` and both commands
fail confusingly. (`MSYS_NO_PATHCONV=1` works if you must use bash.)

To reach a portal without signing in each time: Login has a role toggle
("sign in as"), and Register has three one-tap Demo buttons that write the
session and jump straight to that role's home.

Writing widget tests: never `await` a repository call inside a `testWidgets`
body. Everything there runs in fake async, so `mockDelay`'s timer never fires
and the test hangs until the harness kills it ten minutes later — read the
seed fixture directly instead. And if a screen starts a future without
animating while it waits, `pumpAndSettle` returns with the timer still
pending and teardown fails on "A Timer is still pending"; add an explicit
`pump(Duration(seconds: 1))` after it.

**Don't drive the emulator.** The user runs the app and reports back. Finish
at `flutter analyze` + `flutter test` + (if useful) the APK build, and say
plainly which checks ran and that runtime behaviour is unverified. The
emulator also dies under memory pressure on this machine, so agent-driven
tap-and-screenshot loops cost a lot of session for little signal.

## What's actually built (code)

**All eight phases are built**, plus two post-phase features (follow-an-artist
and account deletion). `flutter analyze` is clean, `flutter test` is 74 green, the debug APK builds, and `flutter build appbundle --release`
succeeds with R8 on. Phase 6 was verified on `gz_pixel` (all four aggregator
tabs screenshotted); Phases 7 and 8 are **not** runtime-verified — see their
sections. What remains is not a phase: the open decisions below, the unwired
artist settlement, and deep links.

**Foundation (Phase 0)**
- `lib/core/theme/app_theme.dart` — brand theme, light+dark, tokens ported
  from `frontend-web/app/globals.css` (black+brass-gold, Playfair Display +
  Inter via `google_fonts`, proportional radius scale).
  `colorScheme.tertiary` carries the brand's gold-bright accent (Material
  has no slot for a second gold); `inputDecorationTheme`/`checkboxTheme`
  match the web's Input primitive.
- `lib/core/format.dart` — `formatInr` (en_IN lakh grouping via `intl`),
  long/short dates, `titleCase`.
- `lib/core/adaptive.dart` — `WindowSize` (Material's compact/medium/expanded
  breakpoints: 600/840) and `ContentWidth`. **Every layout branch keys off
  available width** — never `Platform.*`, a device name, or orientation, all
  of which lie in split-screen, foldables and resizable windows. Reading
  content (forms, stacked detail screens) is capped and centred rather than
  stretched; grids reflow via `SliverGridDelegateWithMaxCrossAxisExtent`.
- `lib/data/storage/mock_db.dart` — `shared_preferences`-backed port of
  `lib/mock-db.ts`, same lazy-seed-on-first-read and `gz-db-v1:` prefix.
  **`MockDb.init()` is awaited in `main()`** — every mock repository reads
  collections synchronously.
- `lib/core/storage/secure_session.dart` — role string in the OS keystore
  (mobile equivalent of the web's `gz_session` cookie).
- Models: `artwork`, `artist`, `auth`, `artwork_filters`, `order` (Order +
  Address). `ArtworkFilters` has `copyWith`/`==` because it is a Riverpod
  family key — without equality every rebuild would refetch.
- Seeds: `artists_seed` (7), `artworks_seed` (18), `addresses_seed` (3),
  all ported verbatim from `frontend-web/lib/mock-data/*.ts`.
- `assets/images/**` — the artwork/avatar images the seeds reference, copied
  from `frontend-web/public/` and re-encoded to JPEG at 1200px (24MB of PNGs
  became 3.4MB). Seeds keep the web paths; `ArtworkImageView` maps
  `/artworks/bird.png` to `assets/images/artworks/bird.jpg`.

**Phase 1 — auth + shell**
- `lib/core/router/app_router.dart` — go_router, `refreshListenable` bridged
  off the session provider, `errorBuilder`, and `redirectFor()` (exported for
  tests) reimplementing `proxy.ts`: unauthenticated to `/login?next=...`,
  wrong-role to that role's own home, admin absent by design.
- `lib/features/auth/` — all 5 screens (login, register, forgot, reset,
  verify-email), `validators.dart` (Zod rules ported one-for-one),
  `role_options.dart` (role copy + `ROLE_HOME`), `auth_widgets.dart` (crest,
  header, text field, role toggle, DEV panel, strength meter, result panel,
  social row).
- `lib/features/shell/role_shell.dart` — a parameterized stub role home.
  Customer and artist now have real shells (Phases 4 and 5); **only
  `/aggregator/dashboard` still lands here**, until Phase 6 replaces it.

**Phase 2 — marketplace core loop**
- `marketplace_screen.dart` — search (300ms debounce, same as web) + a
  filter bottom sheet (the web's inline filter bar is a desktop affordance;
  the filter model and reset semantics are identical) + result grid.
- `artwork_detail_screen.dart` — gallery with full-screen zoom, info panel,
  authenticity card, social proof, wishlist, related rail.
- `artist_profile_screen.dart`, `passport_screen.dart` (the NFC/QR artwork
  passport + provenance timeline).
- `marketplace_providers.dart` — repository provider, four `autoDispose`
  reads, facets, and the wishlist notifier (persisted under the web's
  `gz-wishlist` key).

**Phase 3 — checkout**
- `checkout_screen.dart` — address / review / confirm on one route, **no
  payment step** (same as the web; blocked on the gateway decision below).
- `checkout_repository.dart` + `mock_checkout_repository.dart` — addresses
  and order placement. GST 5% + Rs.250 delivery pinned in one place; placing
  an order marks the artwork `sold` and appends to its status history.

Run `dart run build_runner build` after touching any `@freezed`/
`@JsonSerializable` model — codegen output (`.freezed.dart`/`.g.dart`) isn't
committed source, it's generated.

**Phase 4 — customer account**
- `customer_shell.dart` — `StatefulShellRoute.indexedStack` over four
  branches (Account / Orders / Collection / Wishlist), each with its own
  navigator so tab state and scroll position survive both tab switches and
  resize. The navigation *surface* adapts: bottom `NavigationBar` under
  600, `NavigationRail` from 600, extended rail from 840 — one shared
  destination list, not two hand-maintained navs. The web's nine-item
  grouped sidebar collapses to four tabs; wallet/resale/addresses/profile/
  support are pushed from the dashboard's "Manage" list.
- Screens: dashboard (stats + recent orders), orders + order detail (status
  timeline, price breakdown, delivery address), wishlist, collection (owned
  = delivered orders, with a certificate/provenance sheet), wallet (no
  withdrawal — this is refund credit, not earnings), resale (seller-side
  listing/withdraw only), addresses (add/edit/delete), profile, support.
- `customer_repository.dart` + `mock_customer_repository.dart` — profile,
  address book, wallet, collection, resale, support. The **address book
  moved here from `CheckoutRepository`**, so reads and writes of the same
  records live together; checkout is a caller, not the owner.
- Unlike the web mock, `updateProfile` writes through instead of resolving
  an un-persisted object that every call site has to patch into its query
  cache by hand.

**Phase 5 — artist portal**
- `artist_shell.dart` — same adaptive structure as `CustomerShell`, four
  branches (Dashboard / Artworks / Orders / Wallet). Deliberately a separate
  file, not a `RoleShell<T>`: the two shells share no state, no destinations
  and no behavior beyond Material's navigation pattern.
- 15 screens: dashboard (KPIs, verification ladder, activity feed, Manage
  list), artworks board, **artwork upload with `image_picker`** (camera and
  gallery), orders, wallet (with the ₹1,000-floor withdrawal the collector
  wallet doesn't have), analytics (`fl_chart` revenue line + category bars),
  COA/NFC, gallery spaces, portfolio, settlements, verification, messages,
  profile & KYC, settings, support.
- `artist_repository.dart` + `mock_artist_repository.dart` + `artist_seed.dart`
  — the full portal, including the `artistPrices` map kept **out** of the
  `Artwork` shape. `ArtistArtwork` (artwork + artistPrice) is the only type
  carrying that figure, and only artist-scoped methods construct it.
- **The `artworks` collection now has one shared seed**,
  `seedArtworksCollection()` in `mock_artwork_repository.dart`: the public
  fixtures plus the artist's approved work. Every repository that reads that
  collection must seed it through that function — an earlier version had the
  artist repo seeding it with `[]`, which persisted an empty marketplace for
  whichever repository touched it first.
- Drafts and in-review submissions live in a separate `pendingArtworks`
  collection, so a submission can never appear on the public marketplace.
- `MockDb.resetForTesting()` exists because `SharedPreferences.setMockInitialValues({})`
  alone doesn't clear the cached handle — without it, state leaks between
  tests. Every test file's `setUp` calls it.

**Phase 6 — aggregator portal**
- `aggregator_shell.dart` — four branches (Dashboard / Browse / Inventory /
  Wallet), same adaptive structure as the other two shells. The web's
  fifteen-item grouped sidebar collapses to those four; the other ten pages
  are pushed from the dashboard's "Manage" list. "Browse" and "Inventory" are
  the web's "Browse GalleryZone" and "My Inventory".
- 14 screens across 6 files: dashboard (KPIs, commission explainer, activity
  rail, Manage list), browse/reservable grid with the reserve sheet,
  inventory/collection with edit-display-price and record-sale sheets,
  wallet, orders & sales, customers, shipping (inbound + outbound), gallery
  spaces, settlements, analytics (`fl_chart` sell-through area + category
  bars), messages, company profile, settings, support.
- `aggregator_repository.dart` + `mock_aggregator_repository.dart` +
  `aggregator_seed.dart` — one interface, not six. The web splits
  aggregatorService / SalesService / MessagesService / ProfileService /
  SettingsService / SupportService one-file-per-service out of TypeScript
  module habit; they are not separate seams, so they are not separate
  interfaces here.
- `aggregator.dart` models `AggregatorSale`, `DeliveryAddress`,
  `GallerySpace`, `AggregatorProfile`, `AggregatorSettings` and the derived
  (never-persisted) view types. `AggregatorHolding` stays in
  `artist_portal.dart` where it already lived.
- **The `holdings` collection now has one shared seed**,
  `seedHoldingsCollection()` in `aggregator_seed.dart` — the six public
  fixtures plus the artist's own placed piece. Exactly the trap
  `seedArtworksCollection()` closes: the artist repo previously seeded
  `holdings` with only its own row, so whichever repository read it first
  persisted a six-piece-short collection for both. A test asserts every
  seeded holding resolves to a real `marketplaceAndAggregator` artwork (the
  web does this with a throw at module load; Dart has no equivalent).
- **Reserving and recording a sale never mutate the shared `artworks`
  collection.** That collection belongs to the marketplace and the artist
  portal too. So an artwork's own `status` stays `marketplace` after this
  portal reserves it, and every eligibility check reads `holdings` instead —
  there is a test pinning this.
- Commission is `aggregatorCommissionFor()` in the repository file, one
  place: 20% of the display price's markup over the customer-price floor,
  ported verbatim from the web. **It is provisional** — every screen showing
  it renders `ProvisionalCommissionNotice`, and a sale at exactly the floor
  earns ₹0, which is the honest output of the formula rather than a bug.
- Money moves only when pressed. A sale credits *pending* commission;
  "Simulate settlement" on the Settlements screen moves it to the withdrawable
  balance and writes the settlement row. No timer, and the pending wallet row
  is rewritten into the settlement row rather than a second line appearing
  beside it.
- `PortalCard` / `PortalDetailRow` / `ShellDestination` moved to
  `lib/features/shell/portal_widgets.dart` when the aggregator became their
  third consumer (they were `ArtistCard`/`ArtistDetailRow` in
  `artist_widgets.dart`, and `ShellDestination` was in `customer_shell.dart`).
  `artist_widgets.dart` re-exports the shared file, so no artist screen's
  import list changed. `role_shell.dart` is **deleted** — all three portals
  have real shells now.
- `fixtureToday` (in `aggregator_seed.dart`, was `MOCK_TODAY` on the web) is
  the fixed clock every holding countdown reads. The artist Gallery Spaces
  screen was using the real wall clock against the same fixtures and would
  have started showing its one holding as expired on 2026-08-24; it now reads
  the same anchor.

**Phase 7 — public marketing (link-out form)**
- Open decision 3 was answered: **link out, don't rebuild.** The eight public
  pages (`/`, `/about`, `/contact`, `/faq`, `/privacy`, `/terms`, `/cookies`,
  `/artist-survey`) stay on galleryzone.in. They are marketing and legal copy
  with no interaction; rebuilding them natively would put the same paragraphs
  in two repos and drift the first time legal changes a sentence.
- `lib/features/marketing/screens/about_screen.dart` — one native screen at
  `/about` (unguarded: someone who never signed in still needs the terms).
  Brand header, a Company group and a Legal group of link rows, tappable
  contact points, and a "Visit galleryzone.in" button. `companyLinks` /
  `legalLinks` are `@visibleForTesting` so the path set can be asserted.
- `lib/core/launch.dart` — `openExternal()`, plus `galleryZoneSite`,
  `galleryZoneEmail`, `galleryZonePhone`. Every external tap in the app goes
  through that one function so the "no browser / no mail client" failure path
  is handled once instead of per call site. `launchUrl` signals that case by
  returning false *or* throwing depending on platform; both are caught.
- **`url_launcher` needs `<queries>` entries in `AndroidManifest.xml`.**
  Android 11+ hides other packages, and without the `https` / `mailto` / `tel`
  intents declared there `launchUrl` fails silently. They are added — don't
  remove them when doing the Phase 8 manifest work.
- Entry points to `/about`: the marketplace app bar (the public one, reachable
  signed-out via login's "Browse the marketplace"), plus an "About & legal"
  row at the bottom of all three portals' Manage lists.
- **The dead external links are now live**, which was the other half of this
  decision: the three support screens' contact address/phone were plain
  selectable text, and the artwork-detail and artist-profile social-proof
  chips were inert `Chip`s. All now open. `ContactLinkRow` in
  `portal_widgets.dart` is the shared row.
- Runtime behaviour of the link-outs is **unverified** — analyze, tests and
  the APK build all pass, but nobody has tapped a row on a device. First thing
  to check if something looks wrong: whether galleryzone.in actually serves
  all seven paths (they exist in `frontend-web/app/`, which is not proof the
  deployed site matches).

**Phase 8 — polish & store prep**
- App identity: `android:label` is now `GalleryZone` (was the scaffold's
  `gallery_zone`), and the launcher icon + splash are generated from
  `assets/icon/`.
- The icon is a gold `GZ` monogram on brand black — the same mark the login
  crest shows, so the icon and the first screen agree.
  `frontend-web/public/brand/gz-logo-mark.png` was **not** used: it is a wide
  wordmark on white with a finely-detailed India map inside the `G`, which is
  an unreadable smudge at 48dp and fights a dark-first brand. Swap it if the
  brand owner disagrees — that's a taste call, not a technical one.
- `assets/icon/generate_icons.py` regenerates all four PNGs (needs Pillow).
  They are generated output, not hand-drawn artwork, so edit the script rather
  than the images, then re-run `dart run flutter_launcher_icons` and
  `dart run flutter_native_splash:create`. Both generators' config lives at
  the bottom of `pubspec.yaml`.
- **No camera or photo permission is declared, on purpose.** `image_picker`
  works through ACTION_IMAGE_CAPTURE and the system photo picker, which return
  a result without the app holding anything. Declaring `CAMERA` would make it
  *worse*, not more explicit: Android requires a declared CAMERA permission to
  also be granted before it serves ACTION_IMAGE_CAPTURE, so adding it turns a
  working upload into a SecurityException unless a runtime request is added
  too. Only `uses-feature ... required="false"` is declared, which keeps the
  Play listing reachable on camera-less devices. Don't "fix" this.
- Release signing is opt-in and outside the repo: create `android/key.properties`
  (already gitignored) with `storeFile` / `storePassword` / `keyAlias` /
  `keyPassword` and release builds use it. With no such file the build still
  succeeds and still signs with the debug key — installable for testing,
  rejected by Play, which is the right failure mode.
- R8 + resource shrinking are on for release. `android/app/proguard-rules.pro`
  is deliberately empty: `fl_chart` and `intl` are pure Dart, and
  `image_picker` / `url_launcher` ship their own consumer rules that R8
  merges. If a release build throws a ClassNotFoundException a debug build
  doesn't, add the keep rule there rather than switching minification off.
- **Size: the 60MB `.aab` is not a problem.** 79MB of that file is
  `BUNDLE-METADATA` — native debug symbols for three ABIs plus the ProGuard
  map, which Play uses for crash symbolication and never ships. The actual
  per-device download is ~14.5MB (arm64) / ~14.1MB (armeabi-v7a).
- Still `version: 1.0.0+1` in `pubspec.yaml`. Bump before the first upload;
  Play rejects a re-used versionCode.
- Not runtime-verified: nobody has yet seen the new icon on a launcher or the
  splash on a cold start, and no release build has been run on a device.

**Post-phase — follow an artist, and delete an account**
Both came out of a review against four competitor apps (Artsy, Artlusive,
Masterpiece Fine Art, and an artist-business app), screenshots of which the
user supplied on 20 Aug 2026.
- `followsProvider` in `marketplace_providers.dart` — a persisted set of
  artist ids, deliberately the same shape as `wishlistProvider`, because it is
  the same problem and both swap to a query-backed hook the same way.
- The artist profile gains a Follow / Following button (filled while not
  following, outlined once followed).
- The collector's fourth tab is relabelled **Saved** and now carries two
  segments, **Artworks** and **Artists**, rather than the app growing a fifth
  bottom tab. The route stays `/account/wishlist` — the path is the web's and
  worth keeping stable; only the label changed.
- `ArtworkRepository.listArtists()` is new: the Following list joins ids
  against it instead of fanning out one `getArtistProfile` per followed id.
- **A follow is invisible to the artist, on purpose.** Nothing in the artist
  portal shows a follower count, because a number derived from one device's
  local storage would be fiction. That is the first thing to wire when a real
  backend exists.
- `DeleteAccountTile` / `showDeleteAccountSheet` in
  `features/account/widgets/delete_account.dart`, wired into all three
  portals' settings screens. **Google Play requires an in-app deletion path
  for any app with accounts** — this is a submission requirement, not a
  nicety. Two steps: a sheet listing exactly what goes, then a confirm dialog.
- `MockDb.clearAll()` removes only the `gz-db-v1:` keys, never the whole
  preference store — other plugins keep keys in there and an account deletion
  has no business clearing them. It wipes data *before* signing out; the other
  order would bounce to `/login` with the records still on disk.

## What's NOT built yet

- The artist wallet/settlement **side effect of a sale** is still not wired:
  placing an order marks the artwork sold but doesn't credit the artist's
  wallet or create a settlement (the web's `settleIntoArtistWallet`). The
  collections now exist, so this is a small addition — it was left out
  because the payout formula is one of the open decisions below.
- Alerts / saved searches. Artsy splits Saves, Follows and Alerts; this app
  has the first two. Alerts need push, which does not exist — see below.
- No Play Store listing copy, screenshots, feature graphic or privacy-policy
  URL have been prepared. The privacy policy itself exists at
  galleryzone.in/privacy, which is what the listing field wants.
- All four repository interfaces now exist (Artwork, Checkout, Customer,
  Artist, Aggregator). Messages, Support and Settlement remain methods on the
  portal interfaces rather than separate interfaces — the aggregator side
  confirmed they aren't separate seams.
- The aggregator's inbound-shipping section is illustrative and says so on
  screen: the data model has no "in transit to the aggregator" state distinct
  from a holding being reserved (SAD §2.7), so it surfaces reserved holdings
  rather than inventing a tracking state machine nothing writes to.
- Deep links aren't configured natively (no `AndroidManifest` intent filter,
  no domain association) — every route works in-app, but a real NFC tag URL
  won't open the app yet. Phase 8 item, and it needs the galleryzone.in
  domain decision.
- `X` and `LinkedIn` social marks are deliberately absent from the About
  screen. The web footer renders them, but both point at `#` there — no
  account exists yet, and a tap that goes nowhere is worse than no icon.

## Recommended next step

The phase plan is finished, so the next session picks from these rather than
following a sequence:

1. **Answer the open decisions below.** Three of the four now gate real work
   rather than hypothetical work: payment blocks a real checkout, the payout
   formula blocks the settlement, the domain blocks deep links.
2. **Wire the sale → artist-wallet settlement.** Placing an order still marks
   the artwork sold and credits nobody. The aggregator portal built exactly
   the mechanic to copy — pending credit on the sale, a manual settlement step
   moves it to the withdrawable balance, one ledger row rewritten rather than
   two appearing. Only the payout formula is missing; ship it provisional
   behind the same notice if that stays undecided.
3. **Deep links**, once the domain is settled: an `intent-filter` with
   `autoVerify="true"` plus an `assetlinks.json` on the domain. Every route
   already works in-app, so this is configuration, not screens — but a real
   NFC tag URL won't open the app until it's done.
4. **Play Console groundwork**: listing copy, screenshots, feature graphic,
   data-safety form, and a versionCode bump.
5. **Follower counts on the artist side**, once follows live on a server
   rather than one device. The collector half is built and waiting.

Shell/screen patterns to copy: `aggregator_shell.dart` is the newest of the
three and the cleanest. Skills used for the adaptive shells, worth reloading:
`flutter-adaptive-ui` (madteacher/mad-agents-skills) and
`flutter-build-responsive-layout` (flutter/agent-plugins).

## Open decisions — still unresolved, don't guess

1. Payment gateway (recommend Razorpay, not decided).
2. Aggregator commission/settlement formula — genuine 3-way conflict between
   mocked code, a business requirement, and the SAD's schema. See plan file
   for detail. Phase 6 shipped against the web's formula (20% of the
   aggregator's markup over the customer price) with a provisional notice on
   every screen that shows the number. When this is decided, the only code
   that changes is `aggregatorCommissionFor()` in
   `aggregator_repository.dart` and the notice widget — deliberately one
   function, not a formula sprinkled through the screens.
3. ~~Public marketing pages (Phase 7)~~ — **decided 2026-08-20: link out to
   galleryzone.in.** Shipped. Reopen only if the marketing team wants the
   pages readable offline.
4. iOS — no Mac on this dev machine. Recommend Android-first, revisit once
   there's a real app to test. `flutter_launcher_icons` has `ios: false` for
   this reason; flip it and re-run the generator when that changes.
5. Deep-link domain — which host serves the NFC/QR tag URLs that resolve to
   `/verify/<artworkId>`. Needed for the `intent-filter` and the
   `assetlinks.json` that verifies it. Presumably galleryzone.in, but that
   domain is served by the production repo, so publishing `assetlinks.json`
   there is a cross-repo change someone has to approve.
