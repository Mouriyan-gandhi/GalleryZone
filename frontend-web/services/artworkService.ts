import type { Artwork, ArtworkFilters, ArtworkSummary, MarketplacePage } from "@/types/artwork";
import type { ArtistProfile } from "@/types/artist";
import { http, isApiError } from "@/lib/api";
// Gate only — never the catalogue itself. The demo data is loaded with a
// dynamic import inside each gated branch so it stays out of the production
// bundle; see lib/demo-artworks-flag.ts.
import { DEMO_ARTWORKS_ENABLED, isDemoId } from "@/lib/demo-artworks-flag";
import {
  toArtistProfile,
  toArtwork,
  toArtworkSummary,
  toMarketplacePage,
  type ArtistDto,
  type ArtworkDto,
  type MarketplacePageDto,
} from "@/lib/api-mappers";

// Real implementation of the SAD §5.3 Page -> Hook -> Service -> API
// pattern. Filtering, sorting, search and pagination all happen on the
// server (GET /v1/artworks?...): the browser never downloads the whole
// catalogue, and the filter options come back as facets computed from
// what is actually live.
export const PAGE_SIZE = 20;
/** The API's max page size (artworks.controller.ts). */
export const MAX_PAGE_SIZE = 60;

function toQuery(filters: ArtworkFilters, pageSize: number): Record<string, string> {
  const q: Record<string, string> = { pageSize: String(pageSize) };
  if (filters.category?.length) q.category = filters.category.join(",");
  if (filters.medium?.length) q.medium = filters.medium.join(",");
  if (filters.rarity) q.rarity = filters.rarity;
  if (filters.artistId) q.artistId = filters.artistId;
  if (filters.location) q.location = filters.location;
  if (filters.size) q.size = filters.size;
  if (typeof filters.minPrice === "number") q.minPricePaise = String(Math.round(filters.minPrice * 100));
  if (typeof filters.maxPrice === "number") q.maxPricePaise = String(Math.round(filters.maxPrice * 100));
  if (filters.query?.trim()) q.q = filters.query.trim();
  if (filters.sortBy) q.sort = filters.sortBy;
  if (filters.page && filters.page > 1) q.page = String(filters.page);
  return q;
}

export const artworkService = {
  async list(filters: ArtworkFilters, pageSize = PAGE_SIZE): Promise<MarketplacePage> {
    if (DEMO_ARTWORKS_ENABLED) {
      const { withDemoArtworks } = await import("@/lib/demo-artworks");
      const real = await http.get<MarketplacePageDto>("/v1/artworks", {
        params: toQuery({ ...filters, page: undefined }, MAX_PAGE_SIZE),
      });
      return withDemoArtworks(toMarketplacePage(real), filters, pageSize);
    }
    const dto = await http.get<MarketplacePageDto>("/v1/artworks", { params: toQuery(filters, pageSize) });
    return toMarketplacePage(dto);
  },

  // Full Artwork for the detail page; undefined when no artwork matches,
  // which callers (the Artwork Detail page) turn into notFound().
  async get(id: string): Promise<Artwork | undefined> {
    if (DEMO_ARTWORKS_ENABLED && isDemoId(id)) {
      return (await import("@/lib/demo-artworks")).demoArtwork(id);
    }
    try {
      return toArtwork(await http.get<ArtworkDto>(`/v1/artworks/${encodeURIComponent(id)}`));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  // "More from this artist" rail + the Artist Public Profile's listings
  // grid — the public summary shape, never full Artwork records.
  async listByArtist(artistId: string): Promise<ArtworkSummary[]> {
    if (DEMO_ARTWORKS_ENABLED && isDemoId(artistId)) {
      return (await import("@/lib/demo-artworks")).demoArtworksByArtist(artistId);
    }
    const { artworks } = await http.get<{ artworks: ArtworkDto[] }>(
      `/v1/artists/${encodeURIComponent(artistId)}/artworks`,
    );
    return artworks.map(toArtworkSummary);
  },
};

/** Mirrors backend PublicArtistCard. */
interface ArtistCardDto extends ArtistDto {
  coverImageUrl: string | null;
}

export const artistService = {
  /** Directory: artists with at least one live listing. */
  async list(): Promise<(ArtistProfile & { coverImageUrl: string | null; artworkCount: number })[]> {
    const { artists } = await http.get<{ artists: ArtistCardDto[] }>("/v1/artists");
    return artists.map((a) => ({ ...toArtistProfile(a), coverImageUrl: a.coverImageUrl, artworkCount: a.artworkCount }));
  },

  async get(id: string): Promise<ArtistProfile | undefined> {
    try {
      return toArtistProfile(await http.get<ArtistDto>(`/v1/artists/${encodeURIComponent(id)}`));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },
};
