// Artist artwork submission/editing + the real admin moderation gate —
// closes the gap the mock frontend had (auto-approve on submit). Real work
// lives in @galleryzone/db/artist-artworks.ts.

import { BadRequestException, Body, Controller, Get, HttpCode, Inject, NotFoundException, Param, Patch, Post, Req } from "@nestjs/common";
import { Throttle } from "@nestjs/throttler";
import * as Sentry from "@sentry/node";
import { z } from "zod";
import {
  ArtistArtworkError,
  FirestoreRateConfigStore,
  NfcError,
  approveArtwork,
  artworkRarityValues,
  getArtistArtwork,
  linkNfcTag,
  listArtistOrders,
  listArtistPenalties,
  lockNfcTag,
  markSoldElsewhere,
  listArtistArtworksOwned,
  nfcStateViewOf,
  rejectArtwork,
  setArtworkRarity,
  submitArtwork,
  updateArtwork,
  type Db,
} from "@galleryzone/db";
import { reportNfcFailureInputSchema, tagUidInputSchema, type NfcStateDto, type ReportNfcFailureInput, type TagUidInput } from "@galleryzone/contracts";
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
  physical: physicalSchema.nullable().optional(),
};

// Retired: a chip is linked from the app through /nfc/link, after it has been
// written (NFC_IMPLEMENTATION.md §3). Web builds from before that still send the
// field, empty, with every submit — so empty is accepted and dropped, while a
// value (the old "simulate a tag" button) is refused out loud instead of being
// silently swallowed.
const retiredNfcTagId = z
  .string()
  .max(80)
  .nullable()
  .optional()
  .refine((value) => !value?.trim(), { message: "NFC tags are linked from the GalleryZone app now: write the chip there, and it is recorded on this artwork" });
const dropRetired = <T extends { nfcTagId?: unknown }>({ nfcTagId: _retired, ...rest }: T): Omit<T, "nfcTagId"> => rest;

const submitArtworkSchema = z.object({ ...artworkFields, nfcTagId: retiredNfcTagId }).strict().transform(dropRetired);
type SubmitArtworkBody = z.infer<typeof submitArtworkSchema>;

const updateArtworkSchema = z.object({ ...artworkFields, nfcTagId: retiredNfcTagId }).partial().strict().transform(dropRetired);
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

  // --- NFC tag (NFC_IMPLEMENTATION.md §4.1, §4.2) ---------------------------------
  // The artist who made the piece, or the aggregator currently holding it, may
  // call these; nfc.ts checks which (a bare @Roles can't say "this artwork").

  /** The app wrote the URL to a chip and read this UID off it. Same chip again is a no-op; a different one replaces it until the lock. */
  @Roles("artist", "aggregator")
  @Throttle({ sustained: { limit: 10, ttl: 60_000 } }) // §9.2: the one-chip-one-artwork check is a query
  @HttpCode(200)
  @Post("artist/artworks/:id/nfc/link")
  async nfcLink(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(tagUidInputSchema)) body: TagUidInput): Promise<NfcStateDto> {
    const result = await linkNfcTag(this.db, { artworkId: id, tagUid: body.tagUid, actor: { uid: req.authUser.uid, role: req.authUser.role } });
    if (result.changed) this.bust(id, result.artistId);
    return nfcStateViewOf(result);
  }

  /** The app flipped the chip's lock bytes, having re-read the UID. Irreversible. */
  @Roles("artist", "aggregator")
  @HttpCode(200)
  @Post("artist/artworks/:id/nfc/lock")
  async nfcLock(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(tagUidInputSchema)) body: TagUidInput): Promise<NfcStateDto> {
    try {
      const result = await lockNfcTag(this.db, { artworkId: id, tagUid: body.tagUid, actor: { uid: req.authUser.uid, role: req.authUser.role } });
      if (result.changed) this.bust(id, result.artistId);
      return nfcStateViewOf(result);
    } catch (error) {
      // §13: a lock that fails is worth a look, whichever side it fails on.
      if (error instanceof NfcError) Sentry.captureException(error, { level: "warning", tags: { artworkId: id, tagUid: body.tagUid, step: error.code } });
      throw error;
    }
  }

  /** The app reporting a link or lock that failed on the phone, so it reaches Sentry with the same tags as a server-side failure (§13). */
  @Roles("artist", "aggregator")
  @Throttle({ sustained: { limit: 10, ttl: 60_000 } })
  @HttpCode(204)
  @Post("artist/artworks/:id/nfc/failure")
  nfcFailure(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(reportNfcFailureInputSchema)) body: ReportNfcFailureInput): void {
    Sentry.captureMessage(`NFC ${body.step} failed: ${body.message || "no detail"}`, {
      level: "error",
      tags: { artworkId: id, step: body.step, source: "app", ...(body.tagUid ? { tagUid: body.tagUid } : {}) },
      user: { id: req.authUser.uid },
    });
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
