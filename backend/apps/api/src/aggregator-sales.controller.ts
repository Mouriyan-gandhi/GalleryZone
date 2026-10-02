import { BadRequestException, Body, ConflictException, Controller, Get, Inject, NotFoundException, Param, Patch, Post, Req } from "@nestjs/common";
import { z } from "zod";
import { IllegalTransitionError } from "@galleryzone/domain";
import { remitSaleInputSchema, type RemitSaleInput } from "@galleryzone/contracts";
import { listAggregatorSales, advanceShipment, markRemitted, listRemittancesDue, AggregatorSalesError, type Db } from "@galleryzone/db";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const advanceSchema = z.object({ to: z.enum(["dispatched", "delivered"]), courierRef: z.string().optional() }).strict();
type AdvanceBody = z.infer<typeof advanceSchema>;

// Without this the db layer's errors fell through as 500s, so "already
// remitted" and "that isn't your sale" both reached the aggregator as a
// generic failure. A sale that isn't theirs is a 404 for the same reason it
// is on the order routes — the id must not be confirmed to a stranger.
function rethrow(error: unknown): never {
  if (error instanceof AggregatorSalesError) {
    if (error.message.startsWith("No sale")) {
      throw new NotFoundException({ type: "about:blank", title: "Not found", status: 404, code: "not_found" });
    }
    throw new ConflictException({ type: "about:blank", title: error.message, status: 409, code: "conflict" });
  }
  if (error instanceof IllegalTransitionError) {
    throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "illegal_transition" });
  }
  throw error;
}

@Controller("v1/aggregator/sales")
export class AggregatorSalesController {
  constructor(@Inject(DB) private readonly db: Db) {}

  @Roles("aggregator")
  @Get()
  list(@Req() req: AuthenticatedRequest) {
    return listAggregatorSales(this.db, req.authUser.uid);
  }

  @Roles("aggregator")
  @Patch(":id/shipment")
  async shipment(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(advanceSchema)) body: AdvanceBody) {
    try {
      return await advanceShipment(this.db, req.authUser.uid, id, body.to, body.courierRef);
    } catch (error) {
      rethrow(error);
    }
  }

  @Roles("aggregator")
  @Post(":id/remit")
  async remit(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(remitSaleInputSchema)) body: RemitSaleInput) {
    try {
      return await markRemitted(this.db, req.authUser.uid, id, body.via);
    } catch (error) {
      rethrow(error);
    }
  }

  @Roles("aggregator")
  @Get("remittances-due")
  remittancesDue(@Req() req: AuthenticatedRequest) {
    return listRemittancesDue(this.db, req.authUser.uid);
  }
}
