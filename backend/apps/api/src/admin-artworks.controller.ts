import { Body, Controller, Get, Inject, Param, Post, Req } from "@nestjs/common";
import { z } from "zod";
import { NotFoundException } from "@nestjs/common";
import { FirestoreRateConfigStore, getArtworkForAdmin, listArtworksForAdmin, setArtworkRarity, delistArtwork, getAuditLog, artworkRarityValues, reindexAllListings, refreshListing, Collections, type Db } from "@galleryzone/db";
import { loadActiveRates } from "@galleryzone/config";
import { activeHoldingForArtwork, adminPullBackHolding, listAggregatorHoldings, AggregatorReadError } from "@galleryzone/db";
import { BadRequestException } from "@nestjs/common";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";
import { CacheKeys, ReadCache } from "./read-cache.ts";
import { Emails } from "./mail/emails.ts";

const raritySchema = z.object({ rarity: z.enum([...artworkRarityValues]) }).strict();
type RarityBody = z.infer<typeof raritySchema>;

@Controller("v1/admin")
export class AdminArtworksController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  @Roles("admin")
  @Get("artworks")
  async list() {
    const rates = await loadActiveRates(new FirestoreRateConfigStore(this.db));
    return { artworks: await listArtworksForAdmin(this.db, rates) };
  }

  @Roles("admin")
  @Get("artworks/:id")
  async one(@Param("id") id: string) {
    const rates = await loadActiveRates(new FirestoreRateConfigStore(this.db));
    const artwork = await getArtworkForAdmin(this.db, id, rates);
    if (!artwork) throw new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });
    return artwork;
  }

  @Roles("admin")
  @Post("artworks/:id/rarity")
  async setRarity(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(raritySchema)) body: RarityBody) {
    await setArtworkRarity(this.db, id, body.rarity, req.authUser.uid);
    this.cache.clear();
    return { rarity: body.rarity };
  }

  @Roles("admin")
  @Post("artworks/:id/delist")
  async delist(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    await delistArtwork(this.db, id, req.authUser.uid);
    this.cache.clear();
    return { status: "returned" };
  }

  /** Rebuild every artwork's denormalised listing projection (after a rate change, a migration, or on suspicion). */
  @Roles("admin")
  @Post("artworks/reindex")
  async reindex() {
    const count = await reindexAllListings(this.db);
    this.cache.clear();
    return { reindexed: count };
  }

  @Roles("admin")
  @Post("artworks/:id/reindex")
  async reindexOne(@Param("id") id: string) {
    const listing = await refreshListing(this.db, id);
    this.cache.clear();
    return { reindexed: listing ? 1 : 0 };
  }

  @Roles("admin")
  @Get("aggregators/:id/holdings")
  async aggregatorHoldings(@Param("id") id: string) {
    return { holdings: await listAggregatorHoldings(this.db, id) };
  }

  @Roles("admin")
  @Get("artworks/:id/holding")
  async activeHolding(@Param("id") id: string) {
    return { holding: await activeHoldingForArtwork(this.db, id) };
  }

  @Roles("admin")
  @Post("holdings/:id/pull-back")
  async pullBack(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    try {
      const holding = await adminPullBackHolding(this.db, id, req.authUser.uid);
      this.cache.clear();
      return { holding };
    } catch (error) {
      if (error instanceof AggregatorReadError) {
        if (error.message.startsWith("No ")) throw new NotFoundException({ type: "about:blank", title: "Holding not found", status: 404, code: "not_found" });
        throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "conflict" });
      }
      throw error;
    }
  }

  @Roles("admin")
  @Get("audit-log")
  auditLog() {
    return getAuditLog(this.db);
  }
}
