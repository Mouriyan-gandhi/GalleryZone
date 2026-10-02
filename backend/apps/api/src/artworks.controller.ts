// The marketplace listing/detail endpoints — the highest-traffic read path
// in the whole system. Public: no auth required, but SECURITY-CRITICAL
// regardless — see packages/db/public-artworks.ts, which owns the DTO
// construction and the price-leak discipline. This controller is thin:
// parse the query, serve from the read cache, set cache headers.

import { Controller, Get, Header, Inject, NotFoundException, Param, Query } from "@nestjs/common";
import { z } from "zod";
import { FirestoreRateConfigStore, getPublicArtwork, loadMarketplace, queryMarketplace, toMarketplaceView, type Db, type MarketplacePage } from "@galleryzone/db";
import { checkoutTotal } from "@galleryzone/domain";
import type { CustomerArtworkDto } from "@galleryzone/contracts";
import { Public } from "./auth/roles.decorator.ts";
import { DB } from "./db.module.ts";
import { CacheKeys, ReadCache, TTL } from "./read-cache.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

// "Painting,Sculpture" -> ["Painting", "Sculpture"] — lets the marketplace
// filter sidebar's multi-select combobox pick more than one value per facet
// without a second query param shape.
const csvList = (maxLen: number) =>
  z
    .string()
    .trim()
    .max(maxLen)
    .optional()
    .transform((v) => (v ? v.split(",").map((s) => s.trim()).filter(Boolean) : undefined));

const listQuerySchema = z.object({
    category: csvList(400),
    medium: csvList(400),
    rarity: z.string().trim().min(1).max(20).optional(),
    artistId: z.string().trim().min(1).max(200).optional(),
    location: z.string().trim().min(1).max(80).optional(),
    size: z.enum(["small", "medium", "large"]).optional(),
    minPricePaise: z.coerce.number().int().min(0).optional(),
    maxPricePaise: z.coerce.number().int().min(0).optional(),
    q: z.string().trim().max(120).optional(),
    sort: z.enum(["newest", "price_asc", "price_desc"]).optional(),
    page: z.coerce.number().int().min(1).max(10_000).optional(),
    pageSize: z.coerce.number().int().min(1).max(60).optional(),
  });
  // Deliberately not .strict(): unknown params (utm_*, fbclid) are stripped, never a 400 on a public page.
type ListQuery = z.infer<typeof listQuerySchema>;

// Browsers and Vercel's edge may hold a listing for 30s and serve it stale
// for a minute while revalidating; the API's own cache is the real
// backstop, this just shaves round-trips on the busiest pages.
const PUBLIC_CACHE = "public, max-age=30, s-maxage=60, stale-while-revalidate=60";

@Controller("v1/artworks")
export class ArtworksController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  /** Live marketplace only, filtered/sorted/paged server-side. Facets describe the whole live marketplace. */
  @Public()
  @Get()
  @Header("Cache-Control", PUBLIC_CACHE)
  async list(@Query(new ZodValidationPipe(listQuerySchema)) query: ListQuery): Promise<MarketplacePage> {
    const all = await this.cache.getOrFill(CacheKeys.marketplace, TTL.marketplace, () => loadMarketplace(this.db));
    return queryMarketplace(all, query);
  }

  /**
   * What this artwork would actually cost at checkout, line by line, from
   * the rates in force right now. The checkout screens render this rather
   * than recomputing the ladder client-side, so a preview can never quote a
   * different number from the order the API then creates.
   */
  @Public()
  @Get(":id/quote")
  @Header("Cache-Control", PUBLIC_CACHE)
  async quote(@Param("id") id: string) {
    const artwork = await this.cache.getOrFill(CacheKeys.artwork(id), TTL.artwork, () => getPublicArtwork(this.db, id));
    if (!artwork) throw new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });
    const version = await new FirestoreRateConfigStore(this.db).getActiveVersion(new Date());
    if (!version) {
      throw new NotFoundException({ type: "about:blank", title: "Pricing rules are not configured yet", status: 404, code: "no_active_rates" });
    }
    const total = checkoutTotal(artwork.displayPricePaise, version.rates);
    return {
      artworkId: id,
      displayPricePaise: total.displayPrice,
      gstPaise: total.gstIncluded,
      gstRate: version.rates.gstRate,
      convenienceFeePaise: total.convenienceFee,
      convenienceGstPaise: total.convenienceGst,
      deliveryChargePaise: total.deliveryCharge,
      totalPaise: total.total,
      rateConfigVersionId: version.id,
    };
  }

  /** Any status — a passport link must still resolve after a sale. No COA: that isn't part of the marketplace listing. */
  @Public()
  @Get(":id")
  @Header("Cache-Control", PUBLIC_CACHE)
  async get(@Param("id") id: string): Promise<CustomerArtworkDto> {
    const artwork = await this.cache.getOrFill(CacheKeys.artwork(id), TTL.artwork, () => getPublicArtwork(this.db, id));
    if (!artwork) throw new NotFoundException({ type: "about:blank", title: "Artwork not found", status: 404, code: "not_found" });
    return toMarketplaceView(artwork);
  }
}
