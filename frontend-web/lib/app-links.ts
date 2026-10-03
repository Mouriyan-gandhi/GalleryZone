// The two files that let a phone hand a scanned tag's URL to the GalleryZone app instead
// of the browser (NFC_IMPLEMENTATION.md §7.6, §9.5): Android's assetlinks.json and iOS's
// apple-app-site-association. They are the only thing standing between "the app opens the
// passport" and "some other app registers for /verify/* and intercepts scans", so they
// carry the app's real identity and nothing is invented here: with no fingerprint or team
// configured the files are served EMPTY (valid, and verifying nothing), never with a guess.
//
// Configure on the web host (Vercel project env), all server-side:
//   ANDROID_APP_PACKAGE                 default in.galleryzone.app
//   ANDROID_APP_SHA256_FINGERPRINTS     comma-separated SHA-256 cert fingerprints of the signing key(s)
//   IOS_APP_ID                          "<TeamID>.<bundle id>", e.g. ABCDE12345.in.galleryzone.galleryZone
//
// The paths are /verify/* only: the app has no business claiming the rest of the site.

export const APP_LINK_PATHS = ["/verify/*"] as const;

const DEFAULT_ANDROID_PACKAGE = "in.galleryzone.app";

/** The part of the environment these files read, as plain values so the builders stay pure. */
export interface AppLinkEnv {
  ANDROID_APP_PACKAGE?: string | undefined;
  ANDROID_APP_SHA256_FINGERPRINTS?: string | undefined;
  IOS_APP_ID?: string | undefined;
  /** So `process.env` itself can be passed in. */
  [other: string]: string | undefined;
}

/** "AA:BB:..." (32 colon-separated hex bytes), as Android's tooling prints it. Anything else is dropped, not guessed at. */
const FINGERPRINT = /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/;

export function androidFingerprints(raw: string | undefined): string[] {
  return (raw ?? "")
    .split(",")
    .map((f) => f.trim().toUpperCase())
    .filter((f) => FINGERPRINT.test(f));
}

export function buildAssetLinks(env: AppLinkEnv): unknown[] {
  const fingerprints = androidFingerprints(env.ANDROID_APP_SHA256_FINGERPRINTS);
  if (fingerprints.length === 0) return [];
  return [
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: env.ANDROID_APP_PACKAGE?.trim() || DEFAULT_ANDROID_PACKAGE,
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];
}

/** "<TeamID>.<bundle id>": ten letters or digits, a dot, then a reverse-DNS bundle id. */
const IOS_APP_ID = /^[A-Z0-9]{10}\.[A-Za-z0-9.-]+$/;

export function buildAppleAppSiteAssociation(env: AppLinkEnv): { applinks: { details: unknown[] } } {
  const appID = env.IOS_APP_ID?.trim() ?? "";
  if (!IOS_APP_ID.test(appID)) return { applinks: { details: [] } };
  return {
    applinks: {
      details: [{ appIDs: [appID], components: APP_LINK_PATHS.map((path) => ({ "/": path })) }],
    },
  };
}

/** Both files are fetched by the OS at install time and rarely change; an hour matches the plan (§9.5). */
export const APP_LINK_HEADERS = { "Content-Type": "application/json", "Cache-Control": "public, max-age=3600" } as const;
