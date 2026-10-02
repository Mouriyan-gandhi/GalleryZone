import { existsSync } from "node:fs";
import { resolve } from "node:path";
import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs/config";

// One .env for the whole repo, at the root (see /.env.example). Next only
// reads env files from its own directory, so load the root one here — this
// runs before NEXT_PUBLIC_* values are inlined at build time. Absent on
// Vercel (env vars come from the project settings there), hence the guard.
const rootEnv = resolve(__dirname, "..", ".env");
if (existsSync(rootEnv)) process.loadEnvFile(rootEnv);


// Artwork images are served by the API (GET /v1/images/...) from the
// private storage bucket; next/image must be told it may optimise them.
const apiUrl = process.env.NEXT_PUBLIC_API_URL ? new URL(process.env.NEXT_PUBLIC_API_URL) : null;

const nextConfig: NextConfig = {
  images: {
    remotePatterns: apiUrl
      ? [{ protocol: apiUrl.protocol.replace(":", "") as "http" | "https", hostname: apiUrl.hostname, pathname: "/v1/images/**" }]
      : [],
    // Object keys are immutable, so optimised variants can live for a long time.
    minimumCacheTTL: 60 * 60 * 24 * 30,
  },
  // Playwright's baseURL is 127.0.0.1 (more reliable than localhost for this
  // environment's curl/Playwright connectivity — see docs/TESTING_VERIFICATION_REPORT.md),
  // but `next dev`'s default cross-origin dev-asset protection only allows
  // "localhost" by default. Without this, every async chunk request (any
  // client component using next/dynamic, or split out by Turbopack — this
  // hit framer-motion and @base-ui/react in practice) 403s in the browser
  // even though curl on the same URL returns 200, because curl sends no
  // Origin header and skips the check entirely. Effect: pages render (SSR
  // HTML is unaffected) but are inert — no click/keyboard interaction works.
  // Requires a dev server restart to take effect (next.config.ts is not
  // hot-reloaded).
  allowedDevOrigins: ["127.0.0.1"],
};

// Source maps upload only when SENTRY_AUTH_TOKEN is present (Vercel env);
// otherwise this is a pass-through and the build never talks to Sentry.
export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  silent: !process.env.CI,
  widenClientFileUpload: true,
  disableLogger: true,
  sourcemaps: { disable: !process.env.SENTRY_AUTH_TOKEN },
});
