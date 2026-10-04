import { Body, Controller, Delete, Get, Header, Inject, Param, Patch, Post, UnprocessableEntityException } from "@nestjs/common";
import { z } from "zod";
import { createAffiliateProduct, deleteAffiliateProduct, listAffiliateProducts, updateAffiliateProduct, type Db } from "@galleryzone/db";
import { isAmazonUrl, lookupAmazonProduct, MAX_IMAGES } from "./amazon-product.ts";
import { Public, Roles } from "./auth/roles.decorator.ts";
import { DB } from "./db.module.ts";
import { ReadCache, TTL } from "./read-cache.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const CACHE_KEY = "affiliate-products";

const amazonUrl = z.string().trim().url().refine(isAmazonUrl, "Must be an https Amazon link");
const imageUrl = z.string().trim().url().refine((u) => u.startsWith("https://"), "Must be an https image URL");

const productSchema = z
  .object({
    url: amazonUrl,
    asin: z.string().regex(/^[A-Z0-9]{10}$/).nullable().optional(),
    title: z.string().trim().min(2).max(300),
    brand: z.string().trim().max(80).nullable().optional(),
    category: z.string().trim().min(2).max(60),
    images: z.array(imageUrl).min(1).max(MAX_IMAGES),
    active: z.boolean().optional(),
  })
  .strict();
type ProductBody = z.infer<typeof productSchema>;

const patchSchema = productSchema.omit({ asin: true }).partial().strict();
type PatchBody = z.infer<typeof patchSchema>;

const lookupSchema = z.object({ url: amazonUrl }).strict();
type LookupBody = z.infer<typeof lookupSchema>;

@Controller("v1/affiliate-products")
export class AffiliateProductsController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  /** The public shelf: active products, in the order they were added. */
  @Public()
  @Get()
  @Header("Cache-Control", "public, max-age=60, s-maxage=300")
  async list() {
    const products = await this.cache.getOrFill(CACHE_KEY, TTL.artist, () => listAffiliateProducts(this.db, { activeOnly: true }));
    return { products };
  }
}

@Controller("v1/admin/affiliate-products")
export class AdminAffiliateProductsController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
  ) {}

  @Roles("admin")
  @Get()
  async list() {
    return { products: await listAffiliateProducts(this.db, { activeOnly: false }) };
  }

  /** Reads the Amazon page so the add form can fill itself in. Saves nothing. */
  @Roles("admin")
  @Post("lookup")
  async lookup(@Body(new ZodValidationPipe(lookupSchema)) body: LookupBody) {
    const product = await lookupAmazonProduct(body.url).catch(() => null);
    if (!product) {
      throw new UnprocessableEntityException({
        type: "about:blank",
        title: "Amazon didn't return the product page. Fill in the title and image by hand.",
        status: 422,
        code: "amazon_lookup_failed",
      });
    }
    return product;
  }

  @Roles("admin")
  @Post()
  async create(@Body(new ZodValidationPipe(productSchema)) body: ProductBody) {
    const product = await createAffiliateProduct(this.db, body);
    this.cache.invalidate(CACHE_KEY);
    return product;
  }

  @Roles("admin")
  @Patch(":id")
  async update(@Param("id") id: string, @Body(new ZodValidationPipe(patchSchema)) body: PatchBody) {
    const product = await updateAffiliateProduct(this.db, id, body);
    this.cache.invalidate(CACHE_KEY);
    return product;
  }

  @Roles("admin")
  @Delete(":id")
  async remove(@Param("id") id: string) {
    await deleteAffiliateProduct(this.db, id);
    this.cache.invalidate(CACHE_KEY);
    return { id };
  }
}
