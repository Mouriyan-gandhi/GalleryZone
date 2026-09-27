import { Controller, Get } from "@nestjs/common";
import { Public } from "./auth/roles.decorator.ts";

// Wired to Cloud Run's readiness/liveness probe once deployed (plan's
// Phase 0). Deliberately does no DB/Redis ping yet — that's added once
// packages/db has a real Postgres client (Phase 1), at which point this
// becomes the place a broken connection pool actually shows up as an
// unhealthy container instead of silently serving 500s.
@Controller("v1/health")
export class HealthController {
  @Public()
  @Get()
  check(): { status: "ok"; timestamp: string; emulator: boolean } {
    // True only when this process talks to the local Firebase emulators. The
    // demo seed (backend/scripts/demo) refuses to write unless it is, so it
    // can never register accounts on a real API that happens to own :8080.
    const emulator = Boolean(
      process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST,
    );
    return { status: "ok", timestamp: new Date().toISOString(), emulator };
  }
}
