// The admin rules console's API surface — see the plan's "Admin rules
// console" section. Backed by the real FirestoreRateConfigStore.
//
// SECURITY: gated by RolesGuard (auth/roles.guard.ts) — a real Firebase
// ID token is now verified and the caller's role re-derived from
// Firestore on every request, not the 501 stub from before.

import { Body, ConflictException, Controller, Get, Header, Inject, NotFoundException, Param, Post, Req, UsePipes } from "@nestjs/common";
import { loadActiveRates } from "@galleryzone/config";
import { Collections, FirestoreRateConfigStore, RateConfigError, reindexAllListings, type Db, type RateConfigVersionDoc } from "@galleryzone/db";
import { DEFAULT_RATE_SEED } from "@galleryzone/domain";
import { proposeRateChangeSchema, type ProposeRateChangeInput } from "@galleryzone/contracts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";
import { Public, Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ReadCache } from "./read-cache.ts";


// The same rates, readable by anyone. The artist's upload form quotes the
// markup, GST and listing fee from here rather than from constants compiled
// into the bundle, so an approved rate change moves every screen at once.
// Nothing in PricingRates is confidential — it is the published commercial
// terms, and no artist-specific or customer-specific figure appears in it.
@Controller("v1/pricing-rules")
export class PublicPricingRulesController {
  constructor(@Inject(DB) private readonly db: Db) {}

  @Public()
  @Get()
  @Header("Cache-Control", "public, max-age=60, s-maxage=300, stale-while-revalidate=600")
  async active() {
    const store = new FirestoreRateConfigStore(this.db);
    const version = await store.getActiveVersion(new Date());
    return { rates: version?.rates ?? null, rateConfigVersionId: version?.id ?? null };
  }
}

@Controller("v1/admin/rate-config")
export class RateConfigController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  @Roles("admin", "platform_admin")
  @Get()
  async getActive() {
    const rates = await loadActiveRates(new FirestoreRateConfigStore(this.db));
    return { rates };
  }

  /** Every proposed version, newest first — the second admin sees what is waiting for approval. */
  @Roles("admin", "platform_admin")
  @Get("versions")
  async versions() {
    const snap = await this.db.collection(Collections.rateConfigVersions).orderBy("proposedAt", "desc").limit(20).get();
    return {
      versions: snap.docs.map((d) => {
        const v = d.data() as RateConfigVersionDoc;
        return {
          id: d.id,
          rates: v.rates,
          effectiveFrom: v.effectiveFrom?.toDate().toISOString() ?? null,
          proposedBy: v.proposedBy,
          proposedAt: v.proposedAt?.toDate().toISOString() ?? null,
          approvedBy: v.approvedBy,
          approvedAt: v.approvedAt?.toDate().toISOString() ?? null,
          approved: v.approved,
          reason: v.reason ?? null,
        };
      }),
    };
  }

  /** The seed every deployment starts from — a proposal form can pre-fill from it. */
  @Roles("admin", "platform_admin")
  @Get("defaults")
  defaults() {
    return { rates: DEFAULT_RATE_SEED };
  }

  @Roles("platform_admin")
  @Post("propose")
  @UsePipes(new ZodValidationPipe(proposeRateChangeSchema))
  async propose(@Req() req: AuthenticatedRequest, @Body() body: ProposeRateChangeInput) {
    const store = new FirestoreRateConfigStore(this.db);
    // A console that predates the NFC flag sends none: keep it as it is in force
    // rather than let an unrelated rate change quietly switch the gate off.
    const nfcShipmentGateEnforced = body.rates.nfcShipmentGateEnforced ?? (await loadActiveRates(store)).nfcShipmentGateEnforced;
    const versionId = await store.propose({
      rates: { ...body.rates, nfcShipmentGateEnforced },
      effectiveFrom: new Date(body.effectiveFrom),
      proposedBy: req.authUser.uid,
      reason: body.reason,
    });
    return { versionId, status: "pending_approval" };
  }

  @Roles("platform_admin")
  @Post(":versionId/approve")
  async approve(@Req() req: AuthenticatedRequest, @Param("versionId") versionId: string) {
    // The store itself refuses a self-approval when proposedBy === approvedBy.
    try {
      await new FirestoreRateConfigStore(this.db).approve({ versionId, approvedBy: req.authUser.uid });
    } catch (error) {
      if (error instanceof RateConfigError) {
        if (error.message.startsWith("No rate_config version")) {
          throw new NotFoundException({ type: "about:blank", title: "Not found", status: 404, code: "not_found" });
        }
        throw new ConflictException({ type: "about:blank", title: error.message, status: 409, code: "rate_change_rejected" });
      }
      throw error;
    }
    // Every display price just moved: rebuild the projections, then drop the caches.
    await reindexAllListings(this.db);
    this.cache.clear();
    return { versionId, status: "approved" };
  }
}
