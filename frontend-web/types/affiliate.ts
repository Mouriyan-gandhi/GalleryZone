/** An Amazon product on the Art supplies shelf. `url` is the affiliate link. */
export interface AffiliateProduct {
  id: string;
  url: string;
  asin: string | null;
  title: string;
  brand: string | null;
  category: string;
  /** Amazon CDN URLs, cover first. */
  images: string[];
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AffiliateProductInput {
  url: string;
  asin?: string | null;
  title: string;
  brand?: string | null;
  category: string;
  images: string[];
  active?: boolean;
}

/** What the API read off an Amazon page, to pre-fill the add form. */
export interface AmazonLookup {
  asin: string | null;
  title: string;
  brand: string | null;
  categoryPath: string[];
  images: string[];
}

/**
 * Amazon's CDN resizes on request: `._SL1500_.jpg` → `._AC_SL{size}_.jpg`.
 * Lets a card load a 400px image instead of the 1500px original.
 */
export function amazonImageAt(url: string, size: number): string {
  return url.replace(/\._[^/]*_\.(jpg|jpeg|png|webp)$/i, `._AC_SL${size}_.$1`);
}
