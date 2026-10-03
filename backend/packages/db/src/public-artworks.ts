// Public (customer-facing) artwork reads — the marketplace listing, one
// artwork, and one artist's listings. SECURITY-CRITICAL despite being
// public: this is exactly the surface the price-leak contract test
// (packages/contracts/artwork-dto.check.ts) protects. The DTO is built
// field-by-field from the artwork doc's denormalised `listing` projection
// (listing-projection.ts) — artistPricePaise never reaches this file.
//
// Read cost: the listing is ONE query on `listing.onMarketplace == true`
// (a single-field index), then filter/sort/page in memory. That is the
// right trade until the marketplace holds several thousand live pieces —
// the API layer caches the result for a minute, so Firestore sees one
// read per minute per instance no matter the traffic. Past that scale the
// next step is a search index (Algolia/Typesense), not composite indexes
// for every filter permutation.

import type { Firestore } from "firebase-admin/firestore";
import type { ArtworkStatus } from "@galleryzone/domain";
import { Collections, publicRank, type ArtworkDoc } from "./collections.ts";
import { latestStatusOf, refreshListing } from "./listing-projection.ts";

export { latestStatusOf as latestArtworkStatus };

/** Mirrors @galleryzone/contracts' CustomerArtworkDto (kept structurally identical; contracts can't be imported here without a cycle). */
export interface PublicArtworkView {
  id: string;
  productCode: string;
  artistId: string;
  artistName: string;
  title: string;
  description: string;
  category: string;
  medium: string;
  dimensions: string | null;
  yearCreated: number | null;
  images: { url: string; thumbnailUrl: string | null; altText: string | null; sortOrder: number }[];
  displayPricePaise: number;
  insured: boolean;
  status: ArtworkStatus;
  listingType: string;
  rarityType: string | null;
  coaCertificateNumber: string | null;
  coaIssuedAt: string | null;
  createdAt: string;
  artistLocation: string | null;
  sizeBand: "small" | "medium" | "large" | null;
}

/**
 * What the marketplace serves: the piece without its certificate. The COA is
 * not part of a marketplace listing; it stays on PublicArtworkView for the
 * passport page and the owner's own views, which read it from getPublicArtwork.
 */
export type MarketplaceArtworkView = Omit<PublicArtworkView, "coaCertificateNumber" | "coaIssuedAt">;

export function toMarketplaceView(view: PublicArtworkView): MarketplaceArtworkView {
  const { coaCertificateNumber: _number, coaIssuedAt: _issuedAt, ...rest } = view;
  return rest;
}

async function toPublicView(db: Firestore, id: string, artwork: ArtworkDoc): Promise<PublicArtworkView> {
  // Docs written before the projection existed get it built on first read.
  const listing = artwork.listing ?? (await refreshListing(db, id));
  if (!listing) throw new Error(`Artwork ${id} vanished during read`);
  return {
    id,
    productCode: artwork.productCode,
    artistId: artwork.artistId,
    artistName: listing.artistName,
    title: artwork.title,
    description: artwork.description,
    category: artwork.category,
    medium: artwork.medium,
    dimensions: artwork.dimensions,
    yearCreated: artwork.yearCreated,
    images: listing.coverImageUrl
      ? [{ url: listing.coverImageUrl, thumbnailUrl: listing.coverThumbnailUrl, altText: artwork.title, sortOrder: 0 }]
      : [],
    displayPricePaise: listing.displayPricePaise,
    insured: artwork.insuranceStatus === "approved",
    status: listing.status,
    listingType: artwork.listingType,
    rarityType: publicRank(artwork.rarityType),
    coaCertificateNumber: artwork.coaCertificateNumber,
    coaIssuedAt: artwork.coaIssuedAt?.toDate().toISOString() ?? null,
    createdAt: artwork.createdAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    artistLocation: listing.artistLocation ?? null,
    sizeBand: listing.sizeBand ?? null,
  };
}

export interface MarketplaceQuery {
  /** Any of these categories match (OR). */
  category?: string[] | undefined;
  /** Any of these mediums match (OR). */
  medium?: string[] | undefined;
  rarity?: string | undefined;
  artistId?: string | undefined;
  location?: string | undefined;
  size?: "small" | "medium" | "large" | undefined;
  minPricePaise?: number | undefined;
  maxPricePaise?: number | undefined;
  /** Free-text over title, artist name, medium, category, product code. */
  q?: string | undefined;
  sort?: "newest" | "price_asc" | "price_desc" | undefined;
  page?: number | undefined;
  pageSize?: number | undefined;
}

export interface MarketplacePage {
  artworks: MarketplaceArtworkView[];
  total: number;
  page: number;
  pageSize: number;
  /** Distinct values across the WHOLE live marketplace (not just this page) — drives the filter UI. */
  facets: {
    categories: string[];
    mediums: string[];
    rarities: string[];
    /** Live pieces per rank, across the whole marketplace. */
    rarityCounts: Record<string, number>;
    locations: string[];
    artists: { id: string; name: string }[];
    priceRangePaise: { min: number; max: number } | null;
  };
}

const MAX_PAGE_SIZE = 60;

/** Every live marketplace piece, unfiltered — the unit the API caches. */
export async function loadMarketplace(db: Firestore): Promise<PublicArtworkView[]> {
  const snap = await db.collection(Collections.artworks).where("listing.onMarketplace", "==", true).get();
  return Promise.all(snap.docs.map((doc) => toPublicView(db, doc.id, doc.data() as ArtworkDoc)));
}

/** Pure: filter + sort + page over an already-loaded marketplace. Exported so the cache layer can reuse one load for many queries. */
export function queryMarketplace(all: PublicArtworkView[], query: MarketplaceQuery): MarketplacePage {
  const q = query.q?.trim().toLowerCase();
  const filtered = all.filter((a) => {
    if (query.category?.length && !query.category.includes(a.category)) return false;
    if (query.medium?.length && !query.medium.includes(a.medium)) return false;
    if (query.rarity && a.rarityType !== query.rarity) return false;
    if (query.artistId && a.artistId !== query.artistId) return false;
    if (query.location && a.artistLocation !== query.location) return false;
    if (query.size && a.sizeBand !== query.size) return false;
    if (typeof query.minPricePaise === "number" && a.displayPricePaise < query.minPricePaise) return false;
    if (typeof query.maxPricePaise === "number" && a.displayPricePaise > query.maxPricePaise) return false;
    if (q) {
      const hay = `${a.title} ${a.artistName} ${a.medium} ${a.category} ${a.productCode}`.toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  const sorted = [...filtered];
  switch (query.sort) {
    case "price_asc":
      sorted.sort((a, b) => a.displayPricePaise - b.displayPricePaise);
      break;
    case "price_desc":
      sorted.sort((a, b) => b.displayPricePaise - a.displayPricePaise);
      break;
    default:
      sorted.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  const pageSize = Math.min(Math.max(query.pageSize ?? 24, 1), MAX_PAGE_SIZE);
  const page = Math.max(query.page ?? 1, 1);
  const start = (page - 1) * pageSize;

  const distinct = (pick: (a: PublicArtworkView) => string | null) =>
    [...new Set(all.map(pick).filter((v): v is string => !!v))].sort((x, y) => x.localeCompare(y));
  const prices = all.map((a) => a.displayPricePaise);

  return {
    artworks: sorted.slice(start, start + pageSize).map(toMarketplaceView),
    total: sorted.length,
    page,
    pageSize,
    facets: {
      categories: distinct((a) => a.category),
      mediums: distinct((a) => a.medium),
      rarities: distinct((a) => a.rarityType),
      rarityCounts: all.reduce<Record<string, number>>((acc, a) => {
        if (a.rarityType) acc[a.rarityType] = (acc[a.rarityType] ?? 0) + 1;
        return acc;
      }, {}),
      locations: distinct((a) => a.artistLocation),
      artists: [...new Map(all.map((a) => [a.artistId, a.artistName])).entries()]
        .map(([id, name]) => ({ id, name }))
        .sort((x, y) => x.name.localeCompare(y.name)),
      priceRangePaise: prices.length ? { min: Math.min(...prices), max: Math.max(...prices) } : null,
    },
  };
}

/** One artist's public listings (artist page rail). */
export async function listArtistPublicArtworks(db: Firestore, artistId: string): Promise<MarketplaceArtworkView[]> {
  const snap = await db
    .collection(Collections.artworks)
    .where("artistId", "==", artistId)
    .where("listing.onMarketplace", "==", true)
    .get();
  const views = await Promise.all(snap.docs.map((doc) => toPublicView(db, doc.id, doc.data() as ArtworkDoc)));
  return views.sort((a, b) => b.createdAt.localeCompare(a.createdAt)).map(toMarketplaceView);
}

/** One artwork by id, any status — a passport link must resolve after the piece is sold. Null if missing. Carries the COA; marketplace responses go through toMarketplaceView. */
export async function getPublicArtwork(db: Firestore, id: string): Promise<PublicArtworkView | null> {
  const snap = await db.collection(Collections.artworks).doc(id).get();
  if (!snap.exists) return null;
  return toPublicView(db, id, snap.data() as ArtworkDoc);
}
