// GET /v1/passport/mine — the passports of the pieces the signed-in person
// owns, made or holds on display, in one round trip. Each entry is the same
// public passport /v1/verify serves (passportFor), so this route can never
// show more than a scan does; what it adds is only how the caller relates to
// the piece. The list itself is per-person, so it is never cached or shared.

import { Controller, Get, Header, Inject, NotFoundException, Req } from "@nestjs/common";
import { listPassportLinks, type Db } from "@galleryzone/db";
import type { MyPassportsDto } from "@galleryzone/contracts";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ReadCache } from "./read-cache.ts";
import { passportFor } from "./verify.controller.ts";

// ponytail: first 50 pieces, `total` says when there are more. Page it when a
// single artist or gallery actually lists more than that.
const MAX_ITEMS = 50;

@Controller("v1/passport")
export class PassportController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  @Roles("customer", "artist", "aggregator")
  @Header("Cache-Control", "private, no-store")
  @Get("mine")
  async mine(@Req() req: AuthenticatedRequest): Promise<MyPassportsDto> {
    const links = await listPassportLinks(this.db, req.authUser.uid, req.authUser.role);
    const built = await Promise.all(
      links.slice(0, MAX_ITEMS).map(async (link) => {
        // A piece deleted since the ledger was written just drops out of the list.
        const passport = await passportFor(this.db, this.cache, link.artworkId).catch((error: unknown) => {
          if (error instanceof NotFoundException) return null;
          throw error;
        });
        return passport ? { relations: link.relations, nfcLinked: link.nfcLinked, holdingId: link.holdingId, passport } : null;
      }),
    );
    return { total: links.length, items: built.filter((item) => item !== null) };
  }
}
