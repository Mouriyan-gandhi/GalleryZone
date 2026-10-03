# GalleryZone mobile app

The Flutter app (Android and iOS) for artists, aggregators and collectors. It
talks to the same API as the website (`../backend`), and anyone can browse the
marketplace and open a piece's passport without an account.

State is Riverpod; navigation is go_router; models are `freezed`. Every screen
reads through a `Repository` interface with a real implementation (`data/remote/`)
and an offline mock (`data/mock/`), chosen once in `lib/core/backend.dart`.

## Run it

```bash
flutter pub get
flutter run                                   # the live API
flutter run --dart-define=GZ_MOCK=true        # offline demo: any email and password signs in
```

Other build-time settings (all have production defaults, see `lib/core/config.dart`):
`GZ_API_URL`, `GZ_SITE_URL`, `GZ_FIREBASE_API_KEY`.

After touching a `@freezed` model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Check it:

```bash
flutter analyze
flutter test
```

## NFC tags

An artist links a physical NTAG213 chip to a piece, then locks it for good; a
piece whose tag is not locked cannot be dispatched. The flow is in
`lib/core/nfc/` (`nfc_flow.dart` is the sequence, `ntag213.dart` the chip commands)
and the screens in `lib/features/nfc/`. The rules are in
[`../docs/NFC_IMPLEMENTATION.md`](../docs/NFC_IMPLEMENTATION.md), and the API side is
`../backend/packages/db/src/nfc.ts`.

- Simulators have no NFC. Try it on a real Android phone, with a spare chip:
  locking is permanent.
- The demo build (`GZ_MOCK=true`) runs the whole flow without the API.
- A scanned tag opens the passport in the app once the site serves a matching
  `/.well-known/assetlinks.json` (`ANDROID_APP_SHA256_FINGERPRINTS` on the web host).

## Release builds

`android/key.properties` (not committed) points at the release keystore. Without
it a release build is signed with the debug key, which is fine for testing and
not for the Play Store. Google sign-in is not available in the app yet; it needs
the app registered in the Firebase console.
