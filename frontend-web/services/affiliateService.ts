import { http } from "@/lib/api";
import type { AffiliateProduct, AffiliateProductInput, AmazonLookup } from "@/types/affiliate";

export const affiliateService = {
  async list(): Promise<AffiliateProduct[]> {
    return (await http.get<{ products: AffiliateProduct[] }>("/v1/affiliate-products")).products;
  },

  async listForAdmin(): Promise<AffiliateProduct[]> {
    return (await http.get<{ products: AffiliateProduct[] }>("/v1/admin/affiliate-products")).products;
  },

  lookup(url: string): Promise<AmazonLookup> {
    return http.post<AmazonLookup>("/v1/admin/affiliate-products/lookup", { url });
  },

  create(input: AffiliateProductInput): Promise<AffiliateProduct> {
    return http.post<AffiliateProduct>("/v1/admin/affiliate-products", input);
  },

  update(id: string, patch: Partial<Omit<AffiliateProductInput, "asin">>): Promise<AffiliateProduct> {
    return http.patch<AffiliateProduct>(`/v1/admin/affiliate-products/${encodeURIComponent(id)}`, patch);
  },

  async remove(id: string): Promise<void> {
    await http.delete(`/v1/admin/affiliate-products/${encodeURIComponent(id)}`);
  },
};
