// Artist artwork submission/editing + the real admin moderation gate —
// closes the gap the mock frontend had (auto-approve on submit). Real work
// lives in @galleryzone/db/artist-artworks.ts.

import { BadRequestException, Body, Controller, Get, Inject, NotFoundException, Param, Patch, Post, Req } from "@nestjs/common";
import { z } from "zod";
import {
  ArtistArtworkError,
  FirestoreRateConfigStore,
  approveArtwork,
  artworkRarityValues,
  getArtistArtwork,
  listArtistOrders,
  listArtistPenalties,
  markSoldElsewhere,
  listArtistArtworksOwned,
  rejectArtwork,
  setArtworkRarity,
  submitArtwork,
  updateArtwork,
  type Db,
} from "@galleryzone/db";
import { IllegalTransitionError } from "@galleryzone/domain";
import { loadActiveRates } from "@galleryzone/config";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { CacheKeys, ReadCache } from "./read-cache.ts";
import { Emails } from "./mail/emails.ts";
import { Collections, type ArtworkDoc } from "@galleryzone/db";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const physicalSchema = z
  .object({
    weightKg: z.number().positive().max(500).nullable(),
    framing: z.string().trim().max(80).nullable(),
    format: z.string().trim().max(80).nullable(),
    hangingHardwareIncluded: z.boolean(),
    packagingConfirmed: z.boolean(),
  })
  .strict();

const artworkFields = {
  title: z.string().trim().min(1).max(160),
  description: z.string().trim().max(5000),
  category: z.string().trim().min(1).max(80),
  medium: z.string().trim().min(1).max(80),
  artistPricePaise: z.number().int().positive().max(1_000_000_000),
  listingType: z.enum(["marketplace_only", "aggregator_only", "marketplace_and_aggregator"]),
  dimensions: z.string().trim().max(80).optional(),
  yearCreated: z.number().int().min(1800).max(2100).optional(),
  mode: z.enum(["draft", "review"]).optional(),
  artworkType: z.string().trim().max(80).nullable().optional(),
  paintingStyle: z.string().trim().max(80).nullable().optional(),
  insuranceOpted: z.boolean().optional(),
  insuranceNumber: z.string().trim().max(80).nullable().optional(),
  nfcTagId: z.string().trim().max(80).nullable().optional(),
  physical: physicalSchema.nullable().optional(),
};

const submitArtworkSchema = z.object(artworkFields).strict();
type SubmitArtworkBody = z.infer<typeof submitArtworkSchema>;

const updateArtworkSchema = z.object(artworkFields).partial().strict();
type UpdateArtworkBody = z.infer<typeof updateArtworkSchema>;

const rejectSchema = z.object({ reason: z.string().min(1) }).strict();
// The rank is compulsory: an approval without one is a 400, never a live piece with no rank.
const approveSchema = z.object({ rarity: z.enum([...artworkRarityValues]) }).strict();
type ApproveBody = z.infer<typeof approveSchema>;
type RejectBody = z.infer<typeof rejectSchema>;

const notFound = () => new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });

@Controller("v1")
export class ArtistArtworksController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
    private readonly emails: Emails,
  ) {}

  private async artworkOf(id: string): Promise<(ArtworkDoc & { id: string }) | null> {
    const snap = await this.db.collection(Collections.artworks).doc(id).get();
    return snap.exists ? { id, ...(snap.data() as ArtworkDoc) } : null;
  }

  private bust(artworkId: string, artistId?: string) {
    this.cache.invalidate(CacheKeys.marketplace);
    this.cache.invalidate(CacheKeys.artwork(artworkId));
    this.cache.invalidate(CacheKeys.verify(artworkId));
    if (artistId) this.cache.invalidate(CacheKeys.artistArtworks(artistId));
  }

  private rates() {
    return loadActiveRates(new FirestoreRateConfigStore(this.db));
  }

  @Roles("artist")
  @Get("artist/artworks")
  async mine(@Req() req: AuthenticatedRequest) {
    return { artworks: await listArtistArtworksOwned(this.db, req.authUser.uid, await this.rates()) };
  }

  @Roles("artist")
  @Get("artist/orders")
  async orders(@Req() req: AuthenticatedRequest) {
    return { orders: await listArtistOrders(this.db, req.authUser.uid) };
  }

  @Roles("artist")
  @Get("artist/penalties")
  async penalties(@Req() req: AuthenticatedRequest) {
    return { penalties: await listArtistPenalties(this.db, req.authUser.uid) };
  }

  @Roles("artist")
  @Post("artist/artworks/:id/sold-elsewhere")
  async soldElsewhere(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    const rates = await this.rates();
    try {
      const result = await markSoldElsewhere(this.db, { artistId: req.authUser.uid, artworkId: id, rates });
      this.bust(id, req.authUser.uid);
      const artwork = await getArtistArtwork(this.db, req.authUser.uid, id, rates);
      return { ...result, artwork };
    } catch (error) {
      if (error instanceof ArtistArtworkError) {
        if (error.message.startsWith("No artwork")) throw notFound();
        throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "conflict" });
      }
      if (error instanceof IllegalTransitionError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
      throw error;
    }
  }

  @Roles("artist")
  @Get("artist/artworks/:id")
  async one(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    const artwork = await getArtistArtwork(this.db, req.authUser.uid, id, await this.rates());
    if (!artwork) throw notFound();
    return artwork;
  }

  @Roles("artist")
  @Post("artist/artworks")
  async submit(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(submitArtworkSchema)) body: SubmitArtworkBody) {
    const rates = await this.rates();
    const result = await submitArtwork({ db: this.db, artistId: req.authUser.uid, ...body, rates });
    this.bust(result.artworkId, req.authUser.uid);
    if (body.mode !== "draft") void this.emails.artworkSubmitted(result.artworkId, req.authUser.uid, body.title).catch(this.emails.swallow("submitted mail"));
    const artwork = await getArtistArtwork(this.db, req.authUser.uid, result.artworkId, rates);
    return artwork ?? result;
  }

  @Roles("artist")
  @Patch("artist/artworks/:id")
  async update(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(updateArtworkSchema)) body: UpdateArtworkBody) {
    const rates = await this.rates();
    try {
      await updateArtwork(this.db, { artistId: req.authUser.uid, artworkId: id, patch: body, rates });
    } catch (error) {
      if (error instanceof ArtistArtworkError) {
        if (error.message.startsWith("No artwork")) throw notFound();
        throw new BadRequestException({ type: "about:blank", title: error.message, status: 400, code: "artwork_not_editable" });
      }
      if (error instanceof IllegalTransitionError) {
        throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
      }
      throw error;
    }
    this.bust(id, req.authUser.uid);
    const artwork = await getArtistArtwork(this.db, req.authUser.uid, id, rates);
    if (!artwork) throw notFound();
    if (body.mode === "review" && artwork.status === "pending_approval") {
      void this.emails.artworkSubmitted(id, req.authUser.uid, artwork.title).catch(this.emails.swallow("submitted mail"));
    }
    return artwork;
  }

  @Roles("admin")
  @Post("admin/artworks/:id/approve")
  async approve(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(approveSchema)) body: ApproveBody) {
    const before = await this.artworkOf(id);
    if (!before) throw notFound();
    // Idempotent: a retried approval of a live piece is a no-op, not a 500.
    if (before.listing?.status === "marketplace") return { status: "marketplace" };
    try {
      await setArtworkRarity(this.db, id, body.rarity, req.authUser.uid);
      await approveArtwork(this.db, id);
    } catch (error) {
      if (error instanceof ArtistArtworkError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 400, code: "rank_required" });
      if (error instanceof IllegalTransitionError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
      throw error;
    }
    this.cache.clear();
    const artwork = await this.artworkOf(id);
    if (artwork) void this.emails.artworkApproved(id, artwork.artistId, artwork.title, artwork.coaCertificateNumber).catch(this.emails.swallow("approved mail"));
    return { status: "marketplace" };
  }

  @Roles("admin")
  @Post("admin/artworks/:id/reject")
  async reject(@Param("id") id: string, @Body(new ZodValidationPipe(rejectSchema)) body: RejectBody) {
    const before = await this.artworkOf(id);
    if (!before) throw notFound();
    if (before.listing?.status === "returned") return { status: "returned" };
    try {
      await rejectArtwork(this.db, id, body.reason);
    } catch (error) {
      if (error instanceof IllegalTransitionError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
      if (error instanceof ArtistArtworkError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 400, code: "bad_request" });
      throw error;
    }
    this.cache.clear();
    const artwork = await this.artworkOf(id);
    if (artwork) void this.emails.artworkRejected(id, artwork.artistId, artwork.title, body.reason).catch(this.emails.swallow("rejected mail"));
    return { status: "returned" };
  }
}
