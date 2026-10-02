import { Body, Controller, Get, HttpCode, Inject, Param, Post, Req } from "@nestjs/common";
import { z } from "zod";
import { NotFoundException } from "@nestjs/common";
import { FirestoreRateConfigStore, getArtworkForAdmin, listArtworksForAdmin, setArtworkRarity, delistArtwork, getAuditLog, artworkRarityValues, reindexAllListings, refreshListing, Collections, type Db } from "@galleryzone/db";
import { loadActiveRates } from "@galleryzone/config";
import { activeHoldingForArtwork, adminPullBackHolding, decideHoldingExtension, listAggregatorHoldings, AggregatorReadError, HoldingLifecycleError } from "@galleryzone/db";
import { adminUnlinkNfcTag, getNfcOverview, nfcStateViewOf, overrideShipmentGate } from "@galleryzone/db";
import { decideHoldingExtensionInputSchema, nfcReasonInputSchema, type DecideHoldingExtensionInput, type NfcReasonInput, type NfcStateDto } from "@galleryzone/contracts";
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
    private readonly emails: Emails,
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

  // --- NFC (NFC_IMPLEMENTATION.md §4.3, §4.4, §13) ------------------------------

  /** Resets a link made to a defective chip. Only before the lock: afterwards the chip stays locked whatever the server says. */
  @Roles("admin")
  @HttpCode(200)
  @Post("artworks/:id/nfc/unlink")
  async nfcUnlink(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(nfcReasonInputSchema)) body: NfcReasonInput): Promise<NfcStateDto> {
    const result = await adminUnlinkNfcTag(this.db, { artworkId: id, reason: body.reason, adminUid: req.authUser.uid });
    if (result.changed) this.cache.clear();
    return nfcStateViewOf(result);
  }

  /** Last resort: lets one piece be dispatched without a locked tag (legacy pieces from before the feature). */
  @Roles("admin")
  @HttpCode(200)
  @Post("artworks/:id/nfc/skip-shipment-gate")
  async nfcSkipShipmentGate(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(nfcReasonInputSchema)) body: NfcReasonInput) {
    const { artistId: _artistId, ...result } = await overrideShipmentGate(this.db, { artworkId: id, reason: body.reason, adminUid: req.authUser.uid });
    this.cache.clear();
    return result;
  }

  /** Counts of unlinked / linked-unlocked / locked pieces, who is still to lock, and the events that mean a chip failed or the process is being bypassed. */
  @Roles("admin")
  @Get("nfc/overview")
  nfcOverview() {
    return getNfcOverview(this.db);
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

  /** Answer an aggregator's request to keep a piece past its window. Approving moves the window's end out by one placement. */
  @Roles("admin")
  @Post("holdings/:id/extension/approve")
  approveExtension(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(decideHoldingExtensionInputSchema)) body: DecideHoldingExtensionInput) {
    return this.decideExtension(req, id, "approved", body);
  }

  @Roles("admin")
  @Post("holdings/:id/extension/decline")
  declineExtension(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(decideHoldingExtensionInputSchema)) body: DecideHoldingExtensionInput) {
    return this.decideExtension(req, id, "declined", body);
  }

  private async decideExtension(req: AuthenticatedRequest, id: string, decision: "approved" | "declined", body: DecideHoldingExtensionInput) {
    try {
      const rates = await loadActiveRates(new FirestoreRateConfigStore(this.db));
      const result = await decideHoldingExtension(this.db, { holdingId: id, adminId: req.authUser.uid, decision, note: body.note, rates });
      this.cache.clear();
      void this.emails
        .holdingExtensionDecided({ holdingId: id, artworkId: result.artworkId, aggregatorId: result.aggregatorId, approved: decision === "approved", newExpiresAt: result.newExpiresAt, note: body.note?.trim() || null })
        .catch(this.emails.swallow("holding extension decided mail"));
      return { holding: result.holding };
    } catch (error) {
      if (error instanceof HoldingLifecycleError) {
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
