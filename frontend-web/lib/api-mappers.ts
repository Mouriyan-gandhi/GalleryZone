// Backend DTO -> frontend type mappers. The backend speaks paise and
// nullable-by-default; the UI types (types/*.ts) were written against the
// fixtures in rupees. Mapping lives here, in one place, so services stay
// thin and nothing in features/ learns the wire shape.

import { normalizeRarity, type Artwork, type ArtworkStatus, type ArtworkSummary, type ListingType, type ArtworkRarity, type MarketplacePage } from "@/types/artwork";
import type { ArtistProfile } from "@/types/artist";
import type { Order, OrderStatus } from "@/types/order";
import type { Address } from "@/types/customer";

/** Mirrors backend/packages/contracts CustomerArtworkDto. */
export interface ArtworkDto {
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
  listingType: ListingType;
  rarityType: ArtworkRarity | null;
  /** Not on marketplace responses; only the owner's own views carry the certificate. */
  coaCertificateNumber?: string | null;
  coaIssuedAt?: string | null;
  createdAt: string;
  artistLocation?: string | null;
  sizeBand?: "small" | "medium" | "large" | null;
}

/** Mirrors backend MarketplacePage (packages/db/public-artworks.ts). */
export interface MarketplacePageDto {
  artworks: ArtworkDto[];
  total: number;
  page: number;
  pageSize: number;
  facets: {
    categories: string[];
    mediums: string[];
    rarities: string[];
    rarityCounts: Record<string, number>;
    locations: string[];
    artists: { id: string; name: string }[];
    priceRangePaise: { min: number; max: number } | null;
  };
}

export function toMarketplacePage(dto: MarketplacePageDto): MarketplacePage {
  return {
    artworks: dto.artworks.map(toArtworkSummary),
    total: dto.total,
    page: dto.page,
    pageSize: dto.pageSize,
    facets: {
      categories: dto.facets.categories,
      mediums: dto.facets.mediums,
      rarities: [...new Set(dto.facets.rarities.map((r) => normalizeRarity(r) ?? r))],
      rarityCounts: Object.entries(dto.facets.rarityCounts).reduce<MarketplacePage["facets"]["rarityCounts"]>((acc, [rank, n]) => {
        const key = normalizeRarity(rank);
        if (key) acc[key] = (acc[key] ?? 0) + n;
        return acc;
      }, {}),
      locations: dto.facets.locations,
      artists: dto.facets.artists,
      priceRange: dto.facets.priceRangePaise
        ? { min: paiseToRupees(dto.facets.priceRangePaise.min), max: paiseToRupees(dto.facets.priceRangePaise.max) }
        : null,
    },
  };
}

// Until the image upload pipeline exists every backend artwork has
// images: [] — show a neutral placeholder rather than a broken <img>.
export const ARTWORK_PLACEHOLDER_IMAGE = "/artworks/framed-painting.png";

// Multiple artworks without a real photo all resolve to the same fallback
// URL above — callers use this to render an honest "no image yet" state
// instead of an <Image>, so unrelated listings don't look like duplicates.
export function isPlaceholderImage(url: string): boolean {
  return url === ARTWORK_PLACEHOLDER_IMAGE;
}

export function paiseToRupees(paise: number): number {
  return Math.round(paise) / 100;
}

export function toArtwork(dto: ArtworkDto): Artwork {
  const images = [...dto.images]
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .map((img) => ({
      url: img.url,
      thumbnailUrl: img.thumbnailUrl ?? img.url,
      sortOrder: img.sortOrder,
      altText: img.altText ?? dto.title,
    }));
  const cover = images[0];
  return {
    id: dto.id,
    title: dto.title,
    artistId: dto.artistId,
    artistName: dto.artistName,
    // Verification tiers aren't on the public DTO yet.
    verifiedArtist: false,
    category: dto.category,
    medium: dto.medium,
    customerPrice: paiseToRupees(dto.displayPricePaise),
    thumbnailUrl: cover?.thumbnailUrl ?? ARTWORK_PLACEHOLDER_IMAGE,
    insured: dto.insured,
    status: dto.status,
    listingType: dto.listingType,
    rarityType: normalizeRarity(dto.rarityType),
    sizeBand: dto.sizeBand ?? null,
    description: dto.description,
    dimensions: dto.dimensions,
    yearCreated: dto.yearCreated,
    images: images.length
      ? images
      : [{ url: ARTWORK_PLACEHOLDER_IMAGE, thumbnailUrl: ARTWORK_PLACEHOLDER_IMAGE, sortOrder: 0, altText: dto.title }],
    // Empty until the certificate is issued on approval (backend coa.ts).
    coaCertificateNumber: dto.coaCertificateNumber ?? "",
    coaIssueDate: dto.coaIssuedAt ?? "",
    socialProofLinks: [],
    // The public DTO carries only the current status; the full event log
    // comes with the verify passport. One synthetic entry keeps "newest"
    // sorting and timelines working.
    statusHistory: [{ status: dto.status, changedAt: dto.createdAt }],
  };
}

export function toArtworkSummary(dto: ArtworkDto): ArtworkSummary {
  const a = toArtwork(dto);
  return {
    id: a.id,
    title: a.title,
    artistId: a.artistId,
    artistName: a.artistName,
    verifiedArtist: a.verifiedArtist,
    category: a.category,
    medium: a.medium,
    customerPrice: a.customerPrice,
    thumbnailUrl: a.thumbnailUrl,
    insured: a.insured,
    status: a.status,
    listingType: a.listingType,
    rarityType: normalizeRarity(a.rarityType),
    yearCreated: a.yearCreated,
    dimensions: a.dimensions,
    sizeBand: dto.sizeBand ?? null,
    artistLocation: dto.artistLocation ?? null,
  };
}

/** Mirrors backend PublicArtistProfile. */
export interface ArtistDto {
  id: string;
  name: string;
  headline: string | null;
  bio: string | null;
  location: string | null;
  profileImageUrl: string | null;
  artworkCount: number;
}

export const ARTIST_PLACEHOLDER_IMAGE = "/artworks/portrait-woman.png";

export function toArtistProfile(dto: ArtistDto): ArtistProfile {
  return {
    id: dto.id,
    name: dto.name,
    bio: dto.bio ?? "",
    profileImageUrl: dto.profileImageUrl ?? ARTIST_PLACEHOLDER_IMAGE,
    verification: { tier1SocialMedia: false, tier2ActivePlan: false, tier3FirstSale: false },
    socialLinks: [],
    headline: dto.headline ?? "",
    location: dto.location ?? "",
    joinedAt: "",
  };
}

/** Mirrors backend OrderDoc & { id } (order-listings.ts). Timestamps arrive as Firestore {_seconds,_nanoseconds} or ISO. */
export interface OrderDto {
  id: string;
  artworkId: string;
  customerId: string;
  addressId: string;
  displayPricePaise: number;
  gstPaise: number;
  deliveryChargePaise: number;
  convenienceFeePaise: number;
  convenienceGstPaise?: number;
  totalPaise: number;
  status: OrderStatus;
  rateConfigVersionId: string;
  createdAt: FirestoreTimestampLike | string;
  payment?: { method: string | null; providerPaymentId: string | null; status: string } | null;
  statusHistory?: { status: OrderStatus; changedAt: string }[];
  artwork?: { title: string; artistName: string; artistId: string; thumbnailUrl: string | null; productCode: string } | null;
  artistNetPaise?: number;
}

export interface FirestoreTimestampLike {
  _seconds: number;
  _nanoseconds: number;
}

export function timestampToIso(value: FirestoreTimestampLike | string | null | undefined): string {
  if (!value) return "";
  if (typeof value === "string") return value;
  return new Date(value._seconds * 1000 + Math.floor(value._nanoseconds / 1e6)).toISOString();
}

export function toOrder(dto: OrderDto): Order {
  const createdAt = timestampToIso(dto.createdAt);
  return {
    id: dto.id,
    artworkId: dto.artworkId,
    addressId: dto.addressId,
    customerId: dto.customerId,
    amount: paiseToRupees(dto.displayPricePaise),
    gstAmount: paiseToRupees(dto.gstPaise),
    deliveryCharge: paiseToRupees(dto.deliveryChargePaise),
    convenienceFee: paiseToRupees(dto.convenienceFeePaise),
    convenienceGst: paiseToRupees(dto.convenienceGstPaise ?? 0),
    status: dto.status,
    createdAt,
    statusHistory: dto.statusHistory?.length ? dto.statusHistory : [{ status: dto.status, changedAt: createdAt }],
    artwork: dto.artwork ? { ...dto.artwork, thumbnailUrl: dto.artwork.thumbnailUrl ?? ARTWORK_PLACEHOLDER_IMAGE } : null,
    payment:
      dto.payment && dto.payment.status === "captured"
        ? {
            provider: "razorpay",
            paymentId: dto.payment.providerPaymentId ?? "",
            method: dto.payment.method ?? "razorpay",
            simulated: dto.payment.method === "simulated",
          }
        : null,
  };
}

/** Mirrors backend AddressDoc & { id }. */
export interface AddressDto {
  id: string;
  line1: string;
  line2: string | null;
  city: string;
  state: string;
  pincode: string;
  isDefault: boolean;
}

export function toAddress(dto: AddressDto): Address {
  return {
    id: dto.id,
    line1: dto.line1,
    line2: dto.line2 ?? undefined,
    city: dto.city,
    state: dto.state,
    pincode: dto.pincode,
    isDefault: dto.isDefault,
  };
}
