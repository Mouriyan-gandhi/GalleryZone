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
  check(): { status: "ok"; timestamp: string } {
    return { status: "ok", timestamp: new Date().toISOString() };
  }
}
