// Role-scoped Artwork DTOs — plan.md §8's price-visibility problem, made
// concrete. artistPricePaise never appears in the shape a customer's
// browser receives; artwork-dto.check.ts is the CI gate that enforces it
// by construction (it inspects the actual exported type's keys, not just
// "we promise not to include it").

export interface CustomerArtworkDto {
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
  /** GST-inclusive, what the customer actually pays before delivery. */
  displayPricePaise: number;
  insured: boolean;
  status: string;
  listingType: string;
  rarityType: string | null;
  createdAt: string;
  /** The artist's public location; an artwork has none of its own. */
  artistLocation: string | null;
  /** small / medium / large by canvas area; null when dimensions are unparseable. */
  sizeBand: "small" | "medium" | "large" | null;
}

// Everything a customer sees, plus the artist's own price — visible only to
// the owning artist, an aggregator with an active consignment on this
// piece, or an admin. Never serialized into any response reachable by a
// plain customer session.
export interface OwnerArtworkDto extends CustomerArtworkDto {
  /** The certificate belongs to the owner's views, not the marketplace listing. */
  coaCertificateNumber: string | null;
  coaIssuedAt: string | null;
  artistPricePaise: number;
  artistNet: {
    marketplace: number;
    aggregatorEstimate: number;
  };
}

export interface AdminArtworkDto extends OwnerArtworkDto {
  insuranceNumber: string | null;
  insuranceStatus: string | null;
  nfcTagId: string | null;
  editableUntil: string;
}
