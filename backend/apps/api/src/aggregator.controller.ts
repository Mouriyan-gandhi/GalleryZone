// Aggregator (partner gallery) portal.
//   GET  /v1/aggregator/inventory              reservable pieces with this month's terms
//   GET  /v1/aggregator/holdings               what I hold (any status)
//   POST /v1/aggregator/holdings               reserve — sets the price (month 1 only), records the advance, takes the piece off the marketplace
//   GET  /v1/aggregator/holdings/:id
//   POST /v1/aggregator/holdings/:id/extension ask to keep the piece past its window, with an assurance it will sell
//   POST /v1/aggregator/holdings/:id/return    unsold return — advance refunded, piece back on the marketplace
//   POST /v1/aggregator/holdings/:id/sale      record an in-gallery sale
// The signed MOU and an approved GST number are preconditions for reserving
// (custody without an agreement is not a state this platform allows).

import { BadRequestException, Body, Controller, ConflictException, ForbiddenException, Get, Inject, NotFoundException, Param, Post, Req } from "@nestjs/common";
import {
  AggregatorFlowError,
  AggregatorReadError,
  FirestoreRateConfigStore,
  HoldingLifecycleError,
  getAggregatorHolding,
  hasApprovedGst,
  hasSignedCurrentMou,
  listAggregatorHoldings,
  listAggregatorInventory,
  recordAggregatorSale,
  requestHoldingExtension,
  reserveHolding,
  returnHolding,
  type Db,
} from "@galleryzone/db";
import { loadActiveRates } from "@galleryzone/config";
import { IllegalTransitionError } from "@galleryzone/domain";
import {
  reserveHoldingInputSchema,
  recordAggregatorSaleInputSchema,
  requestHoldingExtensionInputSchema,
  type ReserveHoldingInput,
  type RecordAggregatorSaleInput,
  type RequestHoldingExtensionInput,
} from "@galleryzone/contracts";
import { Roles } from "./auth/roles.decorator.ts";
import { Emails } from "./mail/emails.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ReadCache } from "./read-cache.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const notFound = () => new NotFoundException({ type: "about:blank", title: "Not found", status: 404, code: "not_found" });

function rethrow(error: unknown): never {
  if (error instanceof AggregatorFlowError || error instanceof AggregatorReadError || error instanceof HoldingLifecycleError) {
    if (error.message.startsWith("No ")) throw notFound();
    throw new ConflictException({ type: "about:blank", title: error.message, status: 409, code: "conflict" });
  }
  if (error instanceof IllegalTransitionError) throw new ConflictException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
  throw error;
}

@Controller("v1/aggregator")
export class AggregatorController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
    private readonly emails: Emails,
  ) {}

  private rates() {
    return loadActiveRates(new FirestoreRateConfigStore(this.db));
  }

  @Roles("aggregator")
  @Get("inventory")
  async inventory(@Req() req: AuthenticatedRequest) {
    return { artworks: await listAggregatorInventory(this.db, await this.rates(), req.authUser.uid) };
  }

  @Roles("aggregator")
  @Get("holdings")
  async holdings(@Req() req: AuthenticatedRequest) {
    return { holdings: await listAggregatorHoldings(this.db, req.authUser.uid) };
  }

  @Roles("aggregator")
  @Get("holdings/:id")
  async holding(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    const holding = await getAggregatorHolding(this.db, req.authUser.uid, id);
    if (!holding) throw notFound();
    return holding;
  }

  @Roles("aggregator")
  @Post("holdings")
  async reserve(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(reserveHoldingInputSchema)) body: ReserveHoldingInput) {
    // The version in force, not any signature: a revised MOU has to be signed again before new custody.
    if (!(await hasSignedCurrentMou(this.db, req.authUser.uid, "aggregator"))) {
      throw new BadRequestException({ type: "about:blank", title: "Sign the current Aggregator MOU in My Profile before reserving artwork", status: 403, code: "mou_required" });
    }
    // GST is required for an aggregator before they can reserve anything (client, 30 Sep 2026).
    if (!(await hasApprovedGst(this.db, req.authUser.uid))) {
      throw new ForbiddenException({ type: "about:blank", title: "Add your GST number in My Profile, and wait for GalleryZone to approve it, before reserving artwork", status: 403, code: "gst_required" });
    }
    try {
      const result = await reserveHolding({ db: this.db, aggregatorId: req.authUser.uid, artworkId: body.artworkId, sellingPricePaise: body.sellingPricePaise });
      this.cache.clear();
      // Priced far above the offer: allowed, but GalleryZone is told.
      if (result.priceWarning) {
        void this.emails
          .holdingPriceWarning({ holdingId: result.holdingId, artworkId: body.artworkId, aggregatorId: req.authUser.uid, sellingPricePaise: result.sellingPricePaise, offerSellingPricePaise: result.offerSellingPricePaise })
          .catch(this.emails.swallow("holding price warning mail"));
      }
      // The artist's work is leaving their studio — until now nobody told them.
      void this.emails
        .aggregatorReserved({
          holdingId: result.holdingId,
          artworkId: body.artworkId,
          aggregatorId: req.authUser.uid,
          advanceAmountPaise: result.advanceAmountPaise,
          displayPricePaise: result.displayPricePaise,
          expiresAt: result.expiresAt,
        })
        .catch(this.emails.swallow("holding reserved mail"));
      const holding = await getAggregatorHolding(this.db, req.authUser.uid, result.holdingId);
      return holding ?? result;
    } catch (error) {
      rethrow(error);
    }
  }

  /** Ask to keep a piece past its window. GalleryZone decides each time. */
  @Roles("aggregator")
  @Post("holdings/:id/extension")
  async requestExtension(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(requestHoldingExtensionInputSchema)) body: RequestHoldingExtensionInput) {
    try {
      const holding = await requestHoldingExtension(this.db, { aggregatorId: req.authUser.uid, holdingId: id, assurance: body.assurance, rates: await this.rates() });
      void this.emails
        .holdingExtensionRequested({ holdingId: id, artworkId: holding.artworkId, aggregatorId: req.authUser.uid, assurance: body.assurance, expiresAt: new Date(holding.expiresAt) })
        .catch(this.emails.swallow("holding extension requested mail"));
      return holding;
    } catch (error) {
      rethrow(error);
    }
  }

  @Roles("aggregator")
  @Post("holdings/:id/return")
  async returnPiece(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    try {
      await returnHolding(this.db, req.authUser.uid, id);
      this.cache.clear();
      return getAggregatorHolding(this.db, req.authUser.uid, id);
    } catch (error) {
      rethrow(error);
    }
  }

  @Roles("aggregator")
  @Post("holdings/:id/sale")
  async recordSale(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(recordAggregatorSaleInputSchema)) body: RecordAggregatorSaleInput) {
    const mine = await getAggregatorHolding(this.db, req.authUser.uid, id);
    if (!mine) throw notFound();
    try {
      const result = await recordAggregatorSale({
        db: this.db,
        holdingId: id,
        soldPricePaise: body.soldPricePaise,
        buyerName: body.buyerName,
        buyerEmail: body.buyerEmail,
        buyerPhone: body.buyerPhone,
        deliveryAddress: body.deliveryAddress,
        deliveryMode: body.deliveryMode,
        paymentRoute: body.paymentRoute,
      });
      this.cache.clear();
      return result;
    } catch (error) {
      rethrow(error);
    }
  }
}
