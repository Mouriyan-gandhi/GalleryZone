// Typed env loader. Every required variable is listed here once; a missing
// one fails fast at boot instead of surfacing as an undefined-is-not-a-
// function error three layers down in a webhook handler.

export interface AppEnv {
  nodeEnv: "development" | "staging" | "production" | "test";
  port: number;
  // Optional — nothing in this codebase actually uses Redis yet (it's
  // reserved for rate limiting/caching per the plan); required only once
  // something really connects to it.
  redisUrl: string | null;
  firebaseProjectId: string;
  // Optional for now — Razorpay is explicitly deferred (test-mode setup
  // comes later); confirmSimulatedPayment() doesn't call out to Razorpay
  // at all yet, so the app can boot and be exercised without these. They
  // become required the moment Phase 2 wires in a real webhook handler.
  razorpayKeyId: string | null;
  razorpayKeySecret: string | null;
  razorpayWebhookSecret: string | null;
  sentryDsn: string | null;
  gcpProjectId: string;
  /** Browser origins allowed by CORS. Comma-separated in env; defaults to the local Next dev server. */
  corsOrigins: string[];
  /**
   * "simulated" lets the order's own customer call POST /v1/orders/:id/simulate-payment
   * (stand-in for the Razorpay webhook while Razorpay is deferred). Anything else
   * refuses that route for customers, so a deploy can't accidentally ship free checkout.
   */
  paymentsMode: "simulated" | "razorpay";
  /** S3-compatible object storage for artwork images (Railway bucket). Null until configured — image routes then 503. */
  /** Where this API is reachable by browsers — baked into image URLs. */
  publicApiUrl: string;
  s3: { bucket: string; accessKeyId: string; secretAccessKey: string; endpoint: string; region: string } | null;
  /** Who signs the MOUs for Galleryzone. Unset leaves the company's name/designation blanks empty on every MOU. */
  mouSignatory: { name: string | null; designation: string | null };
}

function required(name: string, value: string | undefined): string {
  if (!value || value.length === 0) {
    throw new Error(
      `Missing required environment variable ${name}. Set it in .env (see .env.example) — ` +
        `this backend never falls back to a hardcoded default for infra config.`,
    );
  }
  return value;
}

function optional(value: string | undefined): string | null {
  return value && value.length > 0 ? value : null;
}

const NODE_ENVS: readonly AppEnv["nodeEnv"][] = ["development", "staging", "production", "test"];

function nodeEnvOf(value: string | undefined): AppEnv["nodeEnv"] {
  if (value && (NODE_ENVS as readonly string[]).includes(value)) {
    return value as AppEnv["nodeEnv"];
  }
  return "development";
}

/** Reads process.env once at boot. Call this exactly once per process. */
export function loadEnv(source: NodeJS.ProcessEnv = process.env): AppEnv {
  return {
    nodeEnv: nodeEnvOf(source.NODE_ENV),
    port: Number(source.PORT ?? 8080),
    redisUrl: optional(source.REDIS_URL),
    firebaseProjectId: required("FIREBASE_PROJECT_ID", source.FIREBASE_PROJECT_ID),
    razorpayKeyId: optional(source.RAZORPAY_KEY_ID),
    razorpayKeySecret: optional(source.RAZORPAY_KEY_SECRET),
    razorpayWebhookSecret: optional(source.RAZORPAY_WEBHOOK_SECRET),
    sentryDsn: optional(source.SENTRY_DSN),
    gcpProjectId: required("GCP_PROJECT_ID", source.GCP_PROJECT_ID),
    corsOrigins: (source.CORS_ORIGINS ?? "http://localhost:3000").split(",").map((o) => o.trim()).filter(Boolean),
    paymentsMode: source.PAYMENTS_MODE === "razorpay" ? "razorpay" : "simulated",
    publicApiUrl:
      optional(source.PUBLIC_API_URL) ??
      (source.RAILWAY_PUBLIC_DOMAIN ? `https://${source.RAILWAY_PUBLIC_DOMAIN}` : `http://localhost:${Number(source.PORT ?? 8080)}`),
    s3:
      source.S3_BUCKET && source.S3_ACCESS_KEY_ID && source.S3_SECRET_ACCESS_KEY && source.S3_ENDPOINT
        ? {
            bucket: source.S3_BUCKET,
            accessKeyId: source.S3_ACCESS_KEY_ID,
            secretAccessKey: source.S3_SECRET_ACCESS_KEY,
            endpoint: source.S3_ENDPOINT,
            region: source.S3_REGION || "auto",
          }
        : null,
    mouSignatory: { name: optional(source.MOU_SIGNATORY_NAME?.trim()), designation: optional(source.MOU_SIGNATORY_DESIGNATION?.trim()) },
  };
}
