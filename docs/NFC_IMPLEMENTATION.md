# GalleryZone — NFC Implementation Plan

**Audience:** two engineering sessions / teams.
1. **Mobile (Flutter)** — building the GalleryZone phone app that reads/writes/locks NFC tags.
2. **Backend + web** — this repo (`GZ-web`), where the API routes and the artist dashboard dialog live.

Both sides must stay in agreement on the state model (§3) and the API contract (§4). Everything else can change independently.

---

## 0. Why NFC exists on GalleryZone

Every artwork already has a public **passport** at `https://<site>/verify/{artworkId}` (QR codes already point here). The NFC tag is a second physical anchor to the same URL, with two properties the QR doesn't give you:

- **Harder to replace silently.** A sticker can be peeled and reprinted. A tag embedded behind a signature can't be swapped without visibly damaging the piece.
- **Zero-friction scan.** No camera, no app required to read — the OS opens the URL the moment the phone touches the tag.

NFC does **not** replace the ownership ledger — the ledger is still the source of truth. The tag only resolves to a URL; what that URL *says* comes from Firestore.

---

## 1. Hardware — NTAG213 facts (what we're actually using)

- **Chip:** NXP NTAG213.
- **User memory:** 144 bytes (36 pages × 4 bytes). Of that, roughly **~137 bytes** are usable for an NDEF message once the CC byte and TLV headers are accounted for.
- **Our payload:** one NDEF URI record, `https://galleryzone.art/verify/<artworkId>` ≈ 40–55 bytes. Well under budget.
- **Protocol family:** ISO/IEC 14443 Type A, NFC Forum Type 2 tag. On iOS this is reached through `NFCMiFareTag` (NTAG213 shares the command set with MIFARE Ultralight). On Android: `android.nfc.tech.MifareUltralight` and `Ndef`.
- **UID:** every chip has an immutable 7-byte UID (hex, 14 chars) burned in at manufacture. **We store this as the chip identity.** It cannot be rewritten, which is exactly what we need for "did someone swap this tag for a cloned one" forensics later.
- **Locking:** NTAG213 has **static lock bytes** (page 2, bytes 2–3) and a **CC (Capability Container) byte** (page 3, byte 2). Flipping these makes the chip read-only forever. Irreversible. This is what we use for the "lock before shipping" step.
- **Known trade-off:** NTAG213 has **no cryptographic authentication**. An attacker with a blank NTAG213 can clone the UID and the URL. We accept this for v1. Migration path to NTAG 424 DNA (SUN message, dynamic signed URLs) is in §15.

---

## 2. End-to-end story (what the user sees)

### Artist (on their phone, in the GalleryZone app)
1. Opens **Dashboard → COA & NFC**, picks an artwork that doesn't yet have a linked tag.
2. Taps **Link NFC tag**. App shows the exact URL that will be written and a big blue "Hold tag to the back of your phone" prompt.
3. Taps a blank NTAG213 chip to the phone.
4. The app writes the URL + the chip's UID is read back. Server records the link.
5. Artist sees a success screen with two options:
   - **"Lock now"** — recommended, irreversible.
   - **"Lock later"** — artist can walk away. The artwork is flagged **"Unlocked — must lock before shipment"** in red on their dashboard.
6. If the artist taps **Lock now** (or returns later and taps **Lock tag**), the app runs the lock command. Server records `nfcLockedAt`.

### Aggregator (same app, on their phone)
Same flow, but only for pieces they received for display:
- They can see the lock status on each holding.
- If a piece arrives from the artist unlocked (shouldn't happen if the shipment gate holds, but possible for pieces that moved before this feature), the aggregator is nudged to lock before putting the piece on display.
- Aggregators cannot **write** a new URL to a piece that already has one — they can only **lock**. (Secure logic: tagUid stored at link time must match the chip they're about to lock.)

### Collector (anyone, on any phone)
Taps the tag → OS reads the NDEF URI → opens the URL.
- If the GalleryZone app is installed and registered as a handler for `galleryzone.art/verify/*` (Android App Links / iOS Universal Links), the **app** opens the passport inside its own screen.
- If not installed, the **mobile browser** opens the public web passport page.
Either way they see the same provenance timeline.

### Admin
- Can view the lock state of every artwork.
- Can **unlink** a tag only before `nfcLockedAt` (e.g. artist wrote to a defective chip and wants a fresh one).
- Cannot override "must be locked before shipment" — the only path to shipment of an unlocked piece is through an admin override action that is audit-logged with a reason.

---

## 3. State model

An artwork's NFC state is three fields on the `ArtworkDoc` (the user-facing "link/lock" state is derived from them):

```ts
interface ArtworkDoc {
  // ...existing fields

  /** 7-byte chip UID in lowercase hex, no separators. Null = never linked. */
  nfcTagUid: string | null;

  /** When the URL + UID were recorded on the server (write confirmed by the app). */
  nfcLinkedAt: FirebaseFirestore.Timestamp | null;

  /** When the chip's lock bytes were set, recorded by the app after it ran the lock command. Irreversible. */
  nfcLockedAt: FirebaseFirestore.Timestamp | null;
}
```

Derived states (what the dashboard renders):

| nfcTagUid | nfcLinkedAt | nfcLockedAt | State | Admin unlink? | Rewrite allowed? |
|---|---|---|---|---|---|
| null | null | null | **Unlinked** | — | — |
| set | set | null | **Linked, unlocked** | ✓ (reason required) | ✓ (artist can replace with a new chip, resetting all three fields) |
| set | set | set | **Linked, locked** | ✗ | ✗ |

**Legacy data cleanup**: today an `nfcTagId: "NFC-abc12345"` is written for any artwork that went through the simulated dialog. Those are not real chips. On deploy of the real system, these legacy strings are migrated to `nfcTagUid: null, nfcLinkedAt: null, nfcLockedAt: null` (one-shot script, logged — see §13).

**The old `nfcTagId` field is removed.** All reads switch to `nfcTagUid`. The passport exposes only `nfcLinked: boolean` publicly; the UID itself is never shown to anyone except the owning artist/aggregator and admins. (A clone defence that leaks the real UID is self-defeating.)

---

## 4. API contract (backend ↔ app ↔ web)

All routes are under `/v1`, bearer token = Firebase ID token, same guard as every other route (`backend/apps/api/src/auth/roles.guard.ts`).

### 4.1 Link write (called by the app after it successfully writes the URL)

```
POST /v1/artist/artworks/:artworkId/nfc/link
Role: artist (must own the artwork)

Body:
{
  "tagUid": "04a1b2c3d4e580"   // lowercase hex, length 14, from Android/iOS NFC read
}

Response 200:
{
  "artworkId": "<id>",
  "nfcTagUid": "04a1b2c3d4e580",
  "nfcLinkedAt": "2026-10-02T12:34:56.789Z",
  "nfcLockedAt": null
}

Errors (RFC 7807, same shape as every other endpoint):
409 nfc_already_locked      — artwork already has nfcLockedAt; can't relink
409 tag_already_bound       — this tagUid is already linked to a DIFFERENT artwork (prevents one physical chip being re-pointed at a different piece via the app)
403 forbidden               — not the owning artist
400 invalid_tag_uid         — tagUid is not 14 hex chars
```

**Idempotency**: calling the same route twice with the same tagUid for the same artwork is a no-op success. Calling it with a *different* tagUid when the artwork is unlocked **replaces** the UID and emits an audit event `nfc.tag_replaced` (see §13). This is how "artist wrote to a bad chip, redoing" works — allowed until lock.

The aggregator can also hit this route **only if** the artwork is in a holding they own (role grant check: `role === "aggregator" && holding.aggregatorId === authUser.uid && holding.artworkId === artworkId`). This covers the "piece arrived unlocked, aggregator links one now" edge case, though the shipment gate (§5) is meant to prevent it.

### 4.2 Lock confirm (called by the app after it successfully flips the lock bytes)

```
POST /v1/artist/artworks/:artworkId/nfc/lock
Role: artist OR aggregator-currently-holding

Body:
{
  "tagUid": "04a1b2c3d4e580"   // must match the UID currently on file for this artwork
}

Response 200:
{
  "artworkId": "<id>",
  "nfcTagUid": "04a1b2c3d4e580",
  "nfcLinkedAt": "...",
  "nfcLockedAt": "2026-10-02T13:00:00.123Z"
}

Errors:
409 nfc_not_linked          — artwork has no nfcTagUid yet; nothing to lock
409 nfc_already_locked      — nfcLockedAt is already set; idempotent no-op is 200 if same tagUid, 409 if different (someone's trying to lock a swapped chip)
409 tag_uid_mismatch        — the UID the app read does not match what's on file; probably a different chip against the phone
403 forbidden               — not the artist and not the current holder
```

**Why we require the app to pass the UID again at lock time:** it's the only check we have that the chip against the phone right now is the same one that was linked. If an attacker tries to lock a cloned replica, the UIDs will not match (UIDs are immutable per chip).

### 4.3 Admin unlink (reset before lock)

```
POST /v1/admin/artworks/:artworkId/nfc/unlink
Role: admin

Body:
{
  "reason": "artist reported chip failed to lock"   // required, non-empty
}

Response 200:
{
  "artworkId": "<id>",
  "nfcTagUid": null,
  "nfcLinkedAt": null,
  "nfcLockedAt": null   // must have been null to be allowed
}

Errors:
409 nfc_already_locked      — once locked, admin cannot unlink from the server (the physical chip remains locked anyway — a server unlink would just desync reality)
```

### 4.4 Admin shipment override (last resort escape)

```
POST /v1/admin/artworks/:artworkId/nfc/skip-shipment-gate
Role: admin

Body:
{
  "reason": "shipped to collector 2025-09-01 before lock requirement; grandfathering"
}

Response 200: records nfcShipmentGateOverrideAt + nfcShipmentGateOverrideReason + nfcShipmentGateOverrideBy on the artwork. Audit-logged.
```

Not used in day-to-day flow. Exists so admins can unblock legacy pieces that pre-date this feature.

### 4.5 Read: the artist's own view

The existing `GET /v1/artist/artworks/:id` and `GET /v1/artist/artworks` already return the artwork. Add three fields to `OwnerArtworkDto` (already in `backend/packages/db/src/artist-artworks.ts`):

```ts
interface OwnerArtworkDto {
  // ...existing

  nfcTagUid: string | null;    // visible to the owning artist and admin only
  nfcLinkedAt: string | null;  // ISO
  nfcLockedAt: string | null;  // ISO
}
```

### 4.6 Read: the public passport

`GET /v1/verify/:artworkId` continues to never leak the UID. It just carries two flags so the public page can show a "Verified via NFC + locked" badge:

```ts
interface VerifyPassportDto {
  // ...existing

  nfcLinked: boolean;   // true when nfcLinkedAt is set
  nfcLocked: boolean;   // true when nfcLockedAt is set
  // nfcTagUid NEVER appears here — enforced by backend/packages/contracts/src/verify-dto.check.ts
}
```

Add the new fields to the forbidden-list check in `verify-dto.check.ts` to make sure `nfcTagUid` never accidentally sneaks in.

### 4.7 Read: aggregator holding view

`GET /v1/aggregator/holdings/:id` already returns the artwork. The artwork DTO in that response needs `nfcLinkedAt` and `nfcLockedAt` so the aggregator sees "this piece is locked" or "this piece is not locked — you cannot ship until it is."

The aggregator does **not** see the tagUid value.

---

## 5. Shipment gate — "compulsory before customer receives it"

Two channels, two gates. Both reject the dispatch with 409 `nfc_lock_required` if `nfcLockedAt` is null, unless the admin override at §4.4 is set.

### 5.1 Marketplace channel

File: `backend/packages/db/src/admin-orders.ts` → `advanceOrderStatus(db, orderId, to)`.

Current flow: `paid → packed → dispatched → delivered`. Add a check **on the transition to `dispatched`**:

```ts
if (to === "dispatched") {
  const artwork = await db.collection(Collections.artworks).doc(order.artworkId).get();
  const a = artwork.data() as ArtworkDoc;
  const overridden = a.nfcShipmentGateOverrideAt;
  if (!a.nfcLockedAt && !overridden) {
    throw new OrderStateError(
      "This artwork's NFC tag must be locked before it can be dispatched. " +
      "Ask the artist to lock it in the GalleryZone app."
    );
  }
}
```

Why `dispatched` and not `packed`: packing happens on the artist's premises; the artist can still lock during packing. Dispatch is the point of no return — once the courier has it, nobody can lock any more.

### 5.2 Aggregator channel

Two sub-cases:

**(a) Artist → aggregator transit.** The artist ships the piece to the aggregator for display. This is a shipment from the artist's hands, but the recipient is a partner, not a customer. Do we need the lock here?

**Decision: yes, before artist→aggregator transit too.** Rationale: the artist is the only person with easy physical access to pre-attach phase. Once the piece is with the aggregator, locking becomes somebody else's problem and often doesn't happen. So the gate goes on the earliest practical point.

File: `backend/packages/db/src/aggregator-flow.ts` → `reserveHolding(...)`. After the aggregator confirms reservation, the backend asks the artist to prepare the piece. Add a status transition:

```
holding.status: reserved_awaiting_lock  →  reserved_ready_to_ship  →  in_transit  →  on_display
```

Transition `reserved_awaiting_lock → reserved_ready_to_ship` is gated on `nfcLockedAt`. The artist's dashboard shows a "Lock the tag — gallery is waiting" prompt. If the artwork is already locked at reservation time (lock-first workflow), the holding is created directly in `reserved_ready_to_ship`.

**(b) Aggregator → customer sale.** When an aggregator records a sale and ships to the end customer, same gate as §5.1. Already locked by the time the piece reached the aggregator, so this is a sanity check.

File: `backend/packages/db/src/aggregator-sales.ts` → the transition that advances a sale's `shipmentStatus` to `dispatched`.

### 5.3 Admin UI changes

Admin orders queue + aggregator sales list show a red **"Unlocked"** chip next to any item whose dispatch is blocked. Admin can click into the artwork detail and (a) nag the artist by email, (b) use the override at §4.4 with a reason.

---

## 6. Passport contents — adding history / location

The user flagged "we have only owner details and location, not the history in the link." Here's the current state and what to add.

### 6.1 What's there today

`GET /v1/verify/:artworkId` already returns an `events` array of ownership transfers (`backend/apps/api/src/verify.controller.ts:73`). The web passport view (`features/verify/nfc-artwork-passport-view.tsx:100-155`) renders this as a "Provenance" timeline (from → to, date, display vs ownership).

**So the ownership history IS exposed.** What's missing:

- **Aggregator placements don't appear.** When an aggregator reserves a piece, no `OwnershipEventDoc` is written (the artist retains title; the aggregator is a bailee). So a piece that spent 60 days on display at a gallery leaves no public trace of that leg.
- **Location** — currently nothing on the passport says *where* a piece was displayed. The artist's `location` is a profile field but the passport doesn't carry it. Aggregators have `addressCity/State` on their profile but the passport doesn't ask for them.
- **Lifecycle milestones** — created / approved / listed / sold / delivered are internal statuses with timestamps in `statusHistory` on the owner's view, but the public passport only shows the current `status`.

### 6.2 What to add

Extend the passport with a new field `lifecycle` that merges three streams, oldest first, with explicit location on each entry where it exists:

```ts
interface VerifyPassportDto {
  // ...existing

  lifecycle: LifecycleEntry[];
}

interface LifecycleEntry {
  id: string;
  kind:
    | "created"           // artist submitted
    | "approved"          // admin approved for marketplace
    | "listed"            // appeared on marketplace
    | "placed_with_gallery"   // aggregator reserved for display (NEW event)
    | "returned_from_gallery" // placement ended, piece back with artist (NEW)
    | "sold_marketplace"
    | "sold_at_gallery"
    | "transferred"       // manual hand-over, kind=ownership, accepted
    | "displayed"         // manual hand-over, kind=display, accepted
    | "delivered";        // courier delivered to buyer
  at: string;             // ISO
  actor: {                // whoever did the thing, as a display-name snapshot
    kind: "artist" | "gallery" | "collector" | "platform";
    displayName: string;
  };
  location: {             // null when unknown or private (e.g. collector's home — never shown)
    city: string;
    state: string;
    country: string;
  } | null;
  note: string | null;    // short freeform (e.g. "Winter show, 60 days")
}
```

**Privacy rule — unchanged from plan.md §12:**
- Artist location: shown.
- Aggregator / gallery location: shown (galleries are commercial venues, public).
- Collector location: **never shown**. For a `transferred` or `delivered` event, `location` is `null` even though internally we know the address.

The `backend/packages/contracts/src/verify-dto.check.ts` guard already blocks price / email / phone / addresses. Add a check that `lifecycle[].location` is never non-null for a collector-side entry.

### 6.3 Data sources for each lifecycle entry

| Entry | Where it comes from |
|---|---|
| `created` | `ArtworkDoc.createdAt`, artist profile |
| `approved` | artwork statusHistory, admin audit log |
| `listed` | artwork statusHistory first `marketplace` entry |
| `placed_with_gallery` | `HoldingDoc.assignedAt` + aggregator profile city/state |
| `returned_from_gallery` | `HoldingDoc.returnedAt` |
| `sold_marketplace` | order record |
| `sold_at_gallery` | aggregator sale record |
| `transferred` / `displayed` | `OwnershipEventDoc` (as today) |
| `delivered` | order statusHistory `delivered` entry |

Build this projection in `backend/packages/db/src/passport.ts` or a new `backend/packages/db/src/lifecycle.ts` — same read-cache (`CacheKeys.verify(artworkId)`) as the rest of the passport.

### 6.4 Where to render in the apps

**Web** — `frontend-web/features/verify/nfc-artwork-passport-view.tsx`. The existing `NfcProvenanceTimeline` becomes a generic `NfcLifecycleTimeline`, iterating `passport.lifecycle` instead of the narrower `passport.events`. Icon per `kind`, location shown as a muted sub-line.

**Mobile (Flutter)** — the passport screen in the app mirrors the same structure. See §8.

---

## 7. Mobile app (Flutter) — spec for the other session

### 7.1 Dependencies

- Android/iOS NFC: use `flutter_nfc_kit` ([pub.dev/packages/flutter_nfc_kit](https://pub.dev/packages/flutter_nfc_kit)) — it exposes both NDEF read/write **and** low-level APDU, which is what we need for the lock step on NTAG213. Alternatives considered: `nfc_manager` (NDEF only, no raw command access — rejected).
- Auth: `firebase_auth` — same ID tokens the web uses.
- HTTP: `dio` or `http` — attach `Authorization: Bearer <idToken>` on every call.
- Deep linking: `app_links` (replaces deprecated `uni_links`) for Android App Links + iOS Universal Links.

### 7.2 iOS entitlements

Needs the **"Near Field Communication Tag Reading"** entitlement in `GalleryZone.entitlements` and `com.apple.developer.nfc.readersession.formats = TAG` in `Info.plist`, plus the standard NFC usage description. Apple grants this automatically for apps that read tags — no human review.

### 7.3 Android manifest

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

Not setting `required="true"` means phones without NFC can still install the app (they just won't see the Link/Lock buttons).

### 7.4 Write flow (Flutter pseudocode)

```dart
Future<void> writeAndLink({required String artworkId, required String verifyUrl}) async {
  // 1. Open a tag session (platform-specific prompt appears).
  final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));

  // 2. Sanity check the chip is an NTAG213 (or compatible NTAG21x).
  if (tag.type != NFCTagType.mifare_ultralight) {
    throw Exception("This chip isn't an NTAG213. Please use a GalleryZone-supplied tag.");
  }

  // 3. Write a single NDEF URI record.
  await FlutterNfcKit.writeNDEFRecords([
    ndef.UriRecord.fromString(verifyUrl),
  ]);

  // 4. Confirm with the backend. Pass the UID the OS read.
  final response = await api.post(
    '/v1/artist/artworks/$artworkId/nfc/link',
    body: { 'tagUid': tag.id.toLowerCase() },
  );

  await FlutterNfcKit.finish();

  // 5. UI: show "Linked. Lock now or later?"
}
```

### 7.5 Lock flow (NTAG213 raw commands)

NTAG213 locks happen two places:
- **Static lock bytes** — page 2, bytes 2 and 3. Setting these to 0xFF marks pages 3–15 as read-only.
- **Dynamic lock bytes** — page 40. For pages 16–39.
- **CC byte** — page 3, byte 2 — set the read/write access half-byte to 0x0F to make the whole chip read-only at the NDEF level.

The sequence (via `transceive` with raw ISO/IEC 14443 WRITE commands, opcode `0xA2`):

```dart
Future<void> lockTag({required String artworkId, required String tagUid}) async {
  final tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));

  // 1. Re-read UID and refuse if it doesn't match what we told the server.
  if (tag.id.toLowerCase() != tagUid) {
    throw Exception("Different chip detected. Please tap the chip that was originally linked.");
  }

  // 2. Set the CC byte to make the NDEF area read-only.
  //    Page 3 = [0xE1, 0x10, 0x12, 0x00] on an NTAG213 with NDEF.
  //    We change the 4th byte (RW access) from 0x00 to 0x0F.
  //    WRITE command: 0xA2 <page> <4 bytes>
  await FlutterNfcKit.transceive("A203E11012 0F".replaceAll(' ',''));

  // 3. Set static lock bytes (page 2 bytes 2 & 3) to 0xFF 0xFF.
  //    Page 2 is the first 4 bytes = [UID3, BCC1, lock0, lock1]; we must
  //    preserve the first two bytes. Read page 2 first (0x30 <page>), then
  //    write back with lock0/lock1 forced to 0xFF.
  final page2 = await FlutterNfcKit.transceive("3002");  // read 4 pages starting at 2
  final preserved = page2.substring(0, 4); // first 2 bytes = UID3 + BCC1 as hex
  await FlutterNfcKit.transceive("A202$preserved" + "FFFF");

  // 4. Dynamic lock bytes (page 40 on NTAG213) — set to 0xFF 0xFF 0xFF
  //    across the lock region to cover pages 16–39.
  await FlutterNfcKit.transceive("A228FFFFFFBD");  // last byte 0xBD = reserved/do-not-change

  // 5. Confirm lock with the server.
  await api.post(
    '/v1/artist/artworks/$artworkId/nfc/lock',
    body: { 'tagUid': tagUid },
  );

  await FlutterNfcKit.finish();
}
```

**Verify the lock actually took:** before the server call, attempt a dummy WRITE to a locked page. If it succeeds, the lock failed and we must not report success. (Device-specific: iOS may surface this as an error from `transceive`; Android returns a non-ACK response byte.)

### 7.6 Deep-link reader (opening a scanned tag inside the app)

When any phone taps a locked tag, the OS reads the URL. On Android (API 30+) with App Links, and on iOS with Universal Links, a URL matching our pattern opens our app:

- **Pattern to register:** `https://galleryzone.art/verify/*` (and the staging host if separate).
- **Android:** add an `<intent-filter>` with `android:autoVerify="true"` and host these in `android/app/src/main/AndroidManifest.xml`. Serve `/.well-known/assetlinks.json` from the website.
- **iOS:** `Associated Domains` entitlement with `applinks:galleryzone.art`. Serve `/.well-known/apple-app-site-association` from the website.

Website serving the association files: add two static route handlers in `frontend-web/app/.well-known/`. Both files contain the app's bundle id / fingerprint pair.

**Fallback:** on a phone without the app, the URL opens in the mobile browser and the web passport renders. Nothing to do here — this already works because `/verify/:artworkId` is a public server-rendered page.

### 7.7 Which screens the app needs

Mobile scope for v1:
- Sign in (Firebase, same credentials as web).
- Dashboard with the subset of the artist's artworks that need NFC action (unlinked, or linked-but-unlocked). Not the full web dashboard.
- "Link tag" flow (§7.4).
- "Lock tag" flow (§7.5).
- Passport screen that opens when the app is launched from a scanned tag (§7.6). Renders the same data the web passport does, including the new `lifecycle` array.
- (Nice-to-have) An artwork-list view that shows every piece the signed-in user owns / made, so a collector can scan a tag at a gallery and see the piece they bought appear in a sensible "my collection" context.

Everything else — browsing marketplace, buying art, aggregator sales workflow — stays web-only for now.

---

## 8. Web browser fallback (write only, Android Chrome)

Not required but nice to have, for an artist without the app installed.

In `frontend-web/features/dashboard/link-nfc-dialog.tsx`:
1. Feature-detect `"NDEFReader" in window`. If absent → show a QR code to install the mobile app, no simulate button.
2. If present → `const writer = new NDEFReader(); await writer.write({ records: [{ recordType: "url", data: verifyUrl }] });` on button press.
3. Call `POST /v1/artist/artworks/:id/nfc/link` with the tagUid Chrome exposes via `writer.onreading`.
4. **No lock step from the browser.** Web NFC can write but cannot flip NTAG lock bytes. Show "Open the mobile app to lock" with a deep link into the app.

The current `services/nfcTagService.ts` + `hooks/useLinkNfcTag.ts` are rewritten:

```ts
// services/nfcTagService.ts
export const nfcTagService = {
  async confirmLinked(artworkId: string, tagUid: string) {
    return http.post<{ artworkId: string; nfcTagUid: string; nfcLinkedAt: string }>(
      `/v1/artist/artworks/${encodeURIComponent(artworkId)}/nfc/link`,
      { tagUid },
    );
  },
  async confirmLocked(artworkId: string, tagUid: string) {
    return http.post<{ artworkId: string; nfcLockedAt: string }>(
      `/v1/artist/artworks/${encodeURIComponent(artworkId)}/nfc/lock`,
      { tagUid },
    );
  },
  async adminUnlink(artworkId: string, reason: string) {
    return http.post(`/v1/admin/artworks/${encodeURIComponent(artworkId)}/nfc/unlink`, { reason });
  },
};
```

`generateNfcTagId` and the fake-write path are removed.

---

## 9. Security logic (because we're allowing re-link until lock)

### 9.1 Who can hit each route

| Route | artist (owner) | aggregator (current holder) | admin |
|---|---|---|---|
| `POST /v1/artist/artworks/:id/nfc/link` | ✓ | ✓ (only if a holding exists) | ✗ (admins shouldn't write to physical chips) |
| `POST /v1/artist/artworks/:id/nfc/lock` | ✓ | ✓ (only if a holding exists) | ✗ |
| `POST /v1/admin/artworks/:id/nfc/unlink` | ✗ | ✗ | ✓ |
| `POST /v1/admin/artworks/:id/nfc/skip-shipment-gate` | ✗ | ✗ | ✓ |

Enforced by `@Roles(...)` plus an explicit `assertOwnership` or `assertCurrentHolding` check inside each handler.

### 9.2 Rate limit on the link write

A buggy app or a hostile client could spam `POST /nfc/link` with different `tagUid` values. Each call is one Firestore write, cheap, but the `tagUid` global uniqueness check (§4.1 `tag_already_bound`) is a query across every artwork. Rate-limit this specific route to **10 req/min per user** on top of the global throttle. Add a `@Throttle({ sustained: { limit: 10, ttl: 60_000 } })` decorator.

### 9.3 Audit log

Every link / replace / lock / unlink / override emits an entry in the admin audit log (same store the existing moderation entries live in — `AuditLogDoc` collection, see `admin.controller.ts` and the `useAdminAuditStore` for the UI side):

| Action | Detail payload |
|---|---|
| `nfc.linked` | `{ artworkId, tagUid, actorRole }` |
| `nfc.tag_replaced` | `{ artworkId, oldTagUid, newTagUid, actorRole }` |
| `nfc.locked` | `{ artworkId, tagUid, actorRole }` |
| `nfc.admin_unlinked` | `{ artworkId, previousTagUid, reason, adminUid }` |
| `nfc.shipment_gate_overridden` | `{ artworkId, reason, adminUid }` |

### 9.4 Tag UID uniqueness

A physical chip can only be bound to one artwork at a time. Enforce by a Firestore uniqueness check inside `linkTag`:

```ts
const existing = await db.collection(Collections.artworks)
  .where('nfcTagUid', '==', tagUid)
  .limit(1)
  .get();

if (!existing.empty && existing.docs[0].id !== artworkId) {
  throw new NfcError('tag_already_bound', 'This chip is already linked to another artwork.');
}
```

Add an index on `nfcTagUid` in `backend/firestore.indexes.json`.

Secondary benefit: if an attacker tries to clone a chip, our system refuses to re-bind it to anything else. (It cannot stop a passport URL from being read off a cloned chip — nothing can without NTAG 424 DNA — but the ledger says "this UID belongs to artwork X" and if the attacker tries to pretend it belongs to artwork Y, the backend rejects.)

### 9.5 iOS Universal Links / Android App Links verification

The `.well-known/assetlinks.json` + `apple-app-site-association` files are the only thing standing between "GalleryZone app opens the passport" and "a random app registers for `galleryzone.art/verify/*` and intercepts scans." Both files must be served:

- `assetlinks.json`: contains the app's SHA-256 cert fingerprints. Serve as `Content-Type: application/json` with `Cache-Control: public, max-age=3600`.
- `apple-app-site-association`: no file extension, same content type.

Rotate these files whenever the app's signing key rotates (never, in practice, except after an incident).

### 9.6 Legacy data migration

A one-off script at `backend/scripts/migrate-legacy-nfc-ids.ts`:

```ts
// Finds every artwork with the legacy nfcTagId field (format "NFC-xxxxxxxx")
// and clears it. These are not real chips. Logs each one.
const snap = await db.collection(Collections.artworks).where('nfcTagId', '!=', null).get();
for (const doc of snap.docs) {
  console.log(`clearing legacy nfcTagId=${doc.data().nfcTagId} on ${doc.id}`);
  await doc.ref.update({
    nfcTagId: FieldValue.delete(),
    nfcTagUid: null,
    nfcLinkedAt: null,
    nfcLockedAt: null,
  });
}
```

Run once per environment before switching the UI over.

---

## 10. Where every change lands in the repo

### 10.1 Backend (`backend/`)

| File | Change |
|---|---|
| `packages/db/src/collections.ts` | Replace `nfcTagId: string \| null` on `ArtworkDoc` with `nfcTagUid`, `nfcLinkedAt`, `nfcLockedAt`, `nfcShipmentGateOverrideAt`, `nfcShipmentGateOverrideReason`, `nfcShipmentGateOverrideBy` |
| `packages/db/src/artist-artworks.ts` | Remove `nfcTagId` from `SubmitArtworkInput` and the owner view; expose new three fields. Remove the PATCH path that writes `nfcTagId` directly. |
| `packages/db/src/nfc.ts` (new) | `linkNfcTag()`, `lockNfcTag()`, `adminUnlinkNfcTag()`, `overrideShipmentGate()` — all with their own `NfcError` class and idempotency rules per §4. |
| `apps/api/src/artist-artworks.controller.ts` | Add `POST /nfc/link`, `POST /nfc/lock` endpoints. |
| `apps/api/src/admin-artworks.controller.ts` | Add `POST /nfc/unlink`, `POST /nfc/skip-shipment-gate`. |
| `apps/api/src/aggregator.controller.ts` | Allow the aggregator-currently-holding to call the same `/nfc/link` and `/nfc/lock` under their own guard (reuse the artist controller logic or mirror it). |
| `packages/db/src/admin-orders.ts` → `advanceOrderStatus` | Lock gate on transition to `dispatched`. |
| `packages/db/src/aggregator-sales.ts` | Same gate on aggregator → customer dispatch. |
| `packages/db/src/aggregator-flow.ts` → `reserveHolding` | Hold the holding in `reserved_awaiting_lock` until the lock is confirmed (introduce the new sub-status). |
| `packages/db/src/passport.ts` (or new `lifecycle.ts`) | Build the `lifecycle: LifecycleEntry[]` from orders, holdings, ownership events, status history. |
| `packages/contracts/src/verify-dto.ts` | Add `nfcLinked`, `nfcLocked`, `lifecycle` fields. |
| `packages/contracts/src/verify-dto.check.ts` | Add `nfcTagUid` to the forbidden-field regex. Add `lifecycle[].location` must-be-null-for-collector-entries check. |
| `firestore.indexes.json` | Composite index on `artworks` for `nfcTagUid`. |
| `firestore.rules` | No change — all writes still through the API. |
| `scripts/migrate-legacy-nfc-ids.ts` (new) | One-shot migration (§9.6). |

### 10.2 Frontend web (`frontend-web/`)

| File | Change |
|---|---|
| `services/nfcTagService.ts` | Rewrite per §8 — `confirmLinked`, `confirmLocked`, `adminUnlink`. Remove `generateNfcTagId`. |
| `hooks/useLinkNfcTag.ts` | Replace mock mutation with the two real mutations. |
| `features/dashboard/link-nfc-dialog.tsx` | Feature-detect Web NFC; show the mobile-app-install QR when unsupported; wire the write path; two-step UI (write → lock prompt). |
| `features/dashboard/coa-nfc-board.tsx` | Status pill shows three states (Unlinked / Linked, unlocked / Linked, locked). Red "Must lock before shipping" warning when linked-but-unlocked. |
| `features/verify/nfc-artwork-passport-view.tsx` | Rename `NfcProvenanceTimeline` → `NfcLifecycleTimeline`; iterate `passport.lifecycle` instead of `passport.events`; icon per `kind`, location sub-line. Add "Verified via NFC + locked" chip when `passport.nfcLocked`. |
| `features/aggregator/holding-detail.tsx` | Lock-state banner on holdings that arrived unlocked; link out to the mobile app. |
| `lib/api-mappers.ts` | Remove the `verifiedArtist: false` hardcode is unrelated; just add the three new owner-view fields on `OwnerArtworkDto`. |
| `app/.well-known/assetlinks.json/route.ts` (new) | Static JSON serving. |
| `app/.well-known/apple-app-site-association/route.ts` (new) | Static JSON serving (no extension; set `Content-Type: application/json`). |

### 10.3 Mobile Flutter (sister repo)

See §7. The MD plan file to drop into that repo:
- Base URL + Firebase config.
- The four API routes from §4 as a Dart client.
- The write + lock flows from §7.4 and §7.5.
- Deep-link registration from §7.6.
- Testing on a real device + a real NTAG213 — simulators have no NFC.

---

## 11. Testing

### 11.1 Unit (backend)

Add check scripts in `backend/packages/db/` matching the existing `*.check.ts` pattern. All run under `npm run check`.

- `nfc.check.ts`:
  - Link an unlinked artwork — succeeds, sets `nfcTagUid` and `nfcLinkedAt`.
  - Link again with the same UID — idempotent, no-op.
  - Link again with a different UID — replaces, emits `nfc.tag_replaced` audit.
  - Lock a linked artwork — succeeds.
  - Lock an unlinked artwork — rejects with `nfc_not_linked`.
  - Lock a locked artwork with the same UID — idempotent success.
  - Lock with a mismatched UID — rejects with `tag_uid_mismatch`.
  - Lock → attempt to re-link — rejects with `nfc_already_locked`.
  - Bind the same UID to two different artworks — rejects with `tag_already_bound`.
  - Admin unlink of a locked artwork — rejects.
  - Admin unlink of an unlocked artwork with no reason — rejects.
- Extend `admin-orders.check.ts` and `aggregator-sales.check.ts`:
  - Dispatch an order whose artwork is unlocked — rejects.
  - Dispatch after lock — succeeds.
  - Dispatch after override — succeeds, override is audit-logged.
- Extend `passport.check.ts`:
  - `lifecycle` contains at least the `created` and `listed` entries for a fresh listing.
  - Aggregator placement produces `placed_with_gallery` and `returned_from_gallery` entries.
  - `nfcTagUid` NEVER appears in the passport JSON (regex check in `verify-dto.check.ts`).
  - Collector-side `transferred` / `delivered` entries never carry a location.

### 11.2 Integration (manual, with a real NTAG213)

With a real chip in hand:

1. On an Android phone with the Flutter app: open the artist dashboard, pick an unlinked artwork, tap "Link tag", bring the chip to the phone's NFC antenna, confirm success. Verify `nfcTagUid` on the backend matches `tag.id`.
2. Tap "Lock later", go back to the dashboard, verify the "Unlocked — must lock before shipping" red warning is present.
3. Return to the artwork, tap "Lock tag", bring the same chip, confirm success. Verify `nfcLockedAt` is set.
4. Try to scan the chip with a third-party NFC writer app (e.g., NXP TagWriter) — it should refuse to write or report the chip as read-only.
5. From the admin console, try to advance an order whose artwork is unlocked to `dispatched` — expect a 409.
6. Scan the chip with a browser (not the app) — the mobile browser opens the public `/verify/:artworkId` page.
7. Install the app, scan the chip again — the app opens the passport screen directly.

### 11.3 Browser fallback (Android Chrome)

Same artwork, Chrome on Android, use the dashboard dialog's web write path:
- Permission prompt appears.
- Write succeeds.
- Server records the link.
- Lock button is disabled with "Open mobile app to lock."

---

## 12. Rollout order

Three phases so neither side blocks the other.

**Phase 1 — backend ships without a client.** All new routes, new fields, migration script, passport lifecycle extension, shipment gate. The old `nfcTagId` field goes away. No UI change yet. The dashboard dialog continues to simulate; the simulate call ends up at a 404 (the old route is gone) and surfaces a loud error.

**Phase 2 — web dashboard rewrite + mobile app.** Both can proceed in parallel because they consume the same API. The dashboard switches to the browser-write-only flow (lock disabled, prompting for app). The mobile app ships with full write + lock. The web passport renders the extended lifecycle.

**Phase 3 — enforce the gate.** Flip a feature flag so the shipment gate becomes a hard rejection. Before this flip it logs the would-be rejection as a warning but still allows the dispatch, so operations get a chance to see which pieces would be blocked and lock them (via the artist) or override (if legacy).

Feature flag mechanism: a boolean in the active `rate_configs` doc, `nfcShipmentGateEnforced`. Add it to `packages/domain/src/pricing.ts`'s `PricingRates` the same way other config lives. Default `false`; admin flips it when ready.

---

## 13. Observability

- Sentry events on every lock failure (both server-side and app-reported). Tag with `artworkId`, `tagUid`, `step`.
- A tiny `/admin/nfc` dashboard page: counts of (unlinked, linked-unlocked, locked) across the whole catalogue, plus a table of recent `nfc.tag_replaced` and `nfc.shipment_gate_overridden` events — these are the signals that something is physically wrong with chips or that the process is being bypassed.
- Email the artist on first lock-later → mark the status at every dashboard load; nag email after 48h unlinked-unlocked, another at 7d. Hook into the existing `Emails` service in `backend/apps/api/src/mail/emails.ts`.

---

## 14. Known limitations we're accepting for v1

| Limitation | Why we accept it | When we'd fix it |
|---|---|---|
| **Clonable chips.** NTAG213 has no cryptography; a copy of the UID + URL is indistinguishable from the original at the NDEF layer. | Cost. NTAG 424 DNA is ~3-5× the per-unit price. We get tamper-evidence from the lock (clone a chip → have to reach the original and swap it) + the server's "this UID belongs to artwork X" check. | When we migrate to NTAG 424 DNA. See §15. |
| **Lock from browser impossible.** Web NFC can't flip lock bytes. | Platform limitation, not fixable. | Native app covers it. |
| **iOS write requires the native app.** iOS Safari has no Web NFC at all. | Apple restriction. | Native app covers it. |
| **"Lock before shipment" relies on operations enforcing the status machine.** A dishonest artist could lie that the chip is locked, then not actually lock it, and the piece could physically ship unlocked. | The lock command is run from the artist's device; the server has no way to physically verify. We rely on the irreversibility of the hardware lock + the audit trail. | If misuse surfaces: require a photo of the chip in-situ + lock verification step, or move write/lock to a staff-controlled station. |
| **No image on the passport proves the chip is attached to _this_ piece.** The chip could be stuck to a different canvas by someone with access. | A photo-at-lock-time step would help but is out of v1 scope. | Add a photo field to the lock confirmation API in v2. |

---

## 15. Migration path to NTAG 424 DNA (future)

NTAG 424 DNA supports **SUN** (Secure Unique NFC) — each tap produces a URL with `?picc_data=...&cmac=...` parameters cryptographically signed by a key inside the chip. The server (GCP KMS or an in-process library) verifies the CMAC and confirms the tag is genuine and the tap counter advanced.

To migrate without re-tagging everything:

- Add `nfcChipFamily: 'ntag213' | 'ntag424'` on `ArtworkDoc`.
- Verify endpoint accepts both plain URLs and SUN URLs. For a plain URL from an NTAG213-era tag, verify unchanged. For a SUN URL, verify the CMAC first; reject if invalid.
- New artworks ship on NTAG 424. Old artworks keep their NTAG213 unless the piece is re-tagged (a new link flow that replaces the chip + bumps the chip family).

This is intentionally forward-compatible with everything in §1–§13. No API changes except the chip-family field and a new verify path.

---

## 16. Checklist (what "done" looks like)

Backend
- [ ] `nfcTagId` removed from `ArtworkDoc`; three new fields added.
- [ ] `POST /v1/artist/artworks/:id/nfc/link` and `/nfc/lock` landed, idempotent, with the five documented error codes.
- [ ] Admin unlink + shipment-gate override endpoints landed and audit-logged.
- [ ] Shipment gate on both marketplace dispatch and aggregator dispatch.
- [ ] Passport lifecycle array returns ownership events + holdings + status milestones.
- [ ] `verify-dto.check.ts` guarantees `nfcTagUid` never appears publicly.
- [ ] Firestore index on `nfcTagUid`.
- [ ] One-shot migration script run on prod data.

Web
- [ ] Dashboard "Link tag" dialog does a real browser write where supported.
- [ ] Red "Must lock before shipping" warning on unlocked-but-linked artworks.
- [ ] Passport renders the extended lifecycle.
- [ ] `.well-known` association files served.

Mobile (Flutter repo)
- [ ] Sign-in reuses Firebase ID tokens.
- [ ] Link flow writes the URL + confirms with the server.
- [ ] Lock flow runs the raw APDU sequence + confirms with the server.
- [ ] Deep link opens the passport screen in the app.
- [ ] Verified on at least one real NTAG213 end-to-end.

Rollout
- [ ] Phase 1 deployed, no UI yet.
- [ ] Phase 2 deployed to staging; artist + aggregator can link and lock from the app.
- [ ] Phase 3 feature flag flipped after ops has caught up every unlocked piece.

---

## 17. Who to ask when

- **"How does the backend expose field X?"** — this file (§4), then `backend/apps/api/src/artist-artworks.controller.ts` and `backend/packages/db/src/nfc.ts`.
- **"What's the current state of artwork Y?"** — admin console → artwork detail → NFC pane (after Phase 1).
- **"The lock command failed on this chip, what do I do?"** — Sentry event (§13), then admin unlink (§4.3), hand the artist a fresh chip, repeat the link flow.
- **"We need to change the URL format."** — don't, if any locked chips exist in the wild. The URL on a locked chip is permanent. The server-side `/verify/:artworkId` route is stable forever; only the hostname can migrate, and only if the old hostname 301s to the new one.
