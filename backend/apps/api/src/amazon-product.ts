// Reads an Amazon product page so an admin adding an affiliate link gets the
// title, brand and photos filled in. Amazon sometimes answers a server with a
// captcha instead of the page; then the lookup fails and the admin types them.

const AMAZON_HOSTS = /(^|\.)(amazon\.(in|com|co\.uk)|link\.amazon|amzn\.(to|in|eu))$/i;
const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36";

/** A card shows the cover and, on hover, one more; a third photo is never seen. */
export const MAX_IMAGES = 2;

export interface AmazonProduct {
  asin: string | null;
  title: string;
  brand: string | null;
  categoryPath: string[];
  images: string[];
}

/** Only Amazon's own hosts: the API must not fetch an arbitrary URL on an admin's say-so. */
export function isAmazonUrl(raw: string): boolean {
  try {
    const url = new URL(raw);
    return url.protocol === "https:" && AMAZON_HOSTS.test(url.hostname);
  } catch {
    return false;
  }
}

export async function lookupAmazonProduct(url: string): Promise<AmazonProduct | null> {
  if (!isAmazonUrl(url)) return null;
  // Amazon answers roughly one request in three with a small captcha page
  // instead of the product; asking again usually gets the real one.
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await new Promise((r) => setTimeout(r, 1_000 * attempt));
    const res = await fetch(url, {
      headers: { "User-Agent": UA, "Accept-Language": "en-IN,en;q=0.9", Accept: "text/html" },
      redirect: "follow",
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok || !isAmazonUrl(res.url)) return null;
    const product = parseAmazonProductPage(await res.text(), res.url);
    if (product) return product;
  }
  return null;
}

export function parseAmazonProductPage(html: string, finalUrl: string): AmazonProduct | null {
  const title = clean(/\sid="productTitle"[^>]*>([^<]+)</.exec(html)?.[1]);
  if (!title) return null;

  // The gallery is a JSON string handed to A.$.parseJSON(...); colorToAsin follows it.
  const galleryAt = html.indexOf("'colorImages'");
  const galleryEnd = html.indexOf("'colorToAsin'", galleryAt);
  const gallery = galleryAt < 0 ? "" : html.slice(galleryAt, galleryEnd < 0 ? undefined : galleryEnd);
  let images = [...gallery.matchAll(/"hiRes":"(https:[^"]+)"/g)].map((m) => m[1]!);
  if (!images.length) images = [...gallery.matchAll(/"large":"(https:[^"]+)"/g)].map((m) => m[1]!);
  const landing = /data-old-hires="(https:[^"]+)"/.exec(html)?.[1];
  if (!images.length && landing) images = [landing];

  // \s before id=: data-csa-c-content-id="bylineInfo" also contains the string.
  const byline = clean(/\sid="bylineInfo"[^>]*>([^<]+)</.exec(html)?.[1]);
  const brand = byline?.replace(/^(Brand:|Visit the)\s*|\s*Store$/g, "").trim() || null;

  const crumbs = /id="wayfinding-breadcrumbs_feature_div"[\s\S]*?<\/ul>/.exec(html)?.[0] ?? "";
  const categoryPath = [...crumbs.matchAll(/<a[^>]*>([^<]+)<\/a>/g)].map((m) => clean(m[1])!).filter(Boolean);

  const asin = /\/dp\/([A-Z0-9]{10})/.exec(finalUrl)?.[1] ?? /name="ASIN" value="([A-Z0-9]{10})"/.exec(html)?.[1] ?? null;

  return { asin, title, brand, categoryPath, images: [...new Set(images)].slice(0, MAX_IMAGES) };
}

function clean(text: string | undefined): string | null {
  if (!text) return null;
  const decoded = text
    .replace(/&#(\d+);?/g, (_, code: string) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);?/gi, (_, code: string) => String.fromCodePoint(parseInt(code, 16)))
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&") // last, so "&amp;lt;" stays the text "&lt;"
    .replace(/\s+/g, " ")
    .trim();
  return decoded || null;
}
