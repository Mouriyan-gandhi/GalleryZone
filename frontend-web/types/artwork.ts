export type ArtworkStatus =
  | "draft"
  | "pending_approval"
  | "marketplace"
  | "reserved"
  | "preparing_dispatch"
  | "in_transit"
  | "with_aggregator"
  | "sold"
  | "settlement_complete"
  | "delivered"
  | "completed"
  | "returned"
  // Artist sold the piece somewhere else and marked it here — it leaves every
  // GalleryZone sales channel immediately (see markSoldElsewhere in
  // services/artistDashboardService.ts).
  | "sold_externally";

// The artist picks the sales channel(s) a piece is listed through. Marketplace
// (GalleryZone's own online store) and Aggregator (partner premises that hold
// and display the physical work) are independent channels; "both" is the
// union of the two, not a third channel.
export type ListingType =
  "marketplace_only" | "aggregator_only" | "marketplace_and_aggregator";

export const LISTING_TYPE_LABEL: Record<ListingType, string> = {
  marketplace_only: "Marketplace only",
  aggregator_only: "Aggregator only",
  marketplace_and_aggregator: "Marketplace + Aggregator",
};

// Always ask these two rather than comparing against a literal: adding a
// channel later shouldn't mean hunting down every `=== "marketplace_and_
// aggregator"` in the codebase again.
export function isMarketplaceListed(listingType: ListingType): boolean {
  return listingType !== "aggregator_only";
}

export function isAggregatorListed(listingType: ListingType): boolean {
  return listingType !== "marketplace_only";
}

export interface ArtworkImage {
  url: string;
  thumbnailUrl: string;
  sortOrder: number;
  altText: string;
}

export interface SocialProofLink {
  platform: "instagram" | "youtube" | "x" | "tiktok";
  url: string;
}

export interface ArtworkStatusEvent {
  status: ArtworkStatus;
  changedAt: string; // ISO date
}

// Matches the GET /marketplace list-item shape documented in the SAD (§3.4)
export interface ArtworkSummary {
  id: string;
  title: string;
  artistId: string;
  artistName: string;
  verifiedArtist: boolean;
  category: string;
  medium: string;
  customerPrice: number;
  thumbnailUrl: string;
  insured: boolean;
  status: ArtworkStatus;
  listingType: ListingType;
  /** GalleryZone's rank. Absent on records nobody has ranked yet. */
  rarityType?: ArtworkRarity | null;
  /** Label and filter details the listing endpoint carries per row. */
  yearCreated?: number | null;
  dimensions?: string | null;
  sizeBand?: ArtworkSizeBand | null;
  artistLocation?: string | null;
}

export interface Artwork extends ArtworkSummary {
  description: string;
  dimensions: string | null;
  yearCreated: number | null;
  images: ArtworkImage[]; // up to 8, sortOrder 0 = cover
  coaCertificateNumber: string;
  coaIssueDate: string;
  socialProofLinks: SocialProofLink[];
  statusHistory: ArtworkStatusEvent[];
  // Original / print / commission / etc — a different axis from `category`
  // (medium of work) and `medium` (material). Optional so existing fixture
  // records don't need a value. See ARTWORK_TYPES.
  artworkType?: string | null;
  // Which of the 100+ world painting traditions this piece belongs to (see
  // PAINTING_ART_FORMS) — only collected when category is "painting". Optional
  // so non-painting categories and pre-existing fixture records need no value.
  paintingStyle?: string | null;
  // Policy/certificate number the artist pastes back in after buying cover
  // through the HDFC ERGO link — see INSURANCE_PARTNER_URL. Only meaningful
  // when `insured` is true.
  insuranceNumber?: string | null;
  /** Admin-reviewed, same shape as GstStatus — see admin-status-badge.tsx. */
  insuranceStatus?: InsuranceStatus;
  // The physical NFC tag on this piece, in three states (see lib/nfc.ts): not
  // linked, linked but unlocked, linked and locked for good. Only the artist's
  // own and admin views carry these; the chip's ID (nfcTagUid) is never public.
  // Optional so the fixture records don't need a value: absent means unlinked.
  nfcTagUid?: string | null;
  nfcLinkedAt?: string | null;
  nfcLockedAt?: string | null;
  // Admin views only: an admin let this piece ship without a locked tag (legacy pieces).
  nfcShipmentGateOverrideAt?: string | null;
  nfcShipmentGateOverrideReason?: string | null;
  // Ownership, physical custody and location are three independent states,
  // never one "owner" field — a piece can be legally owned by GalleryZone,
  // physically held by an aggregator, and located in a third city all at
  // once. Optional so existing fixture records don't need a value:
  // resolveCustody() derives one from `status` when it's absent.
  custody?: ArtworkCustody | null;
  // Weight, framing, format and the aggregator packing requirements. Optional
  // because the fixture records predate the fields; the form collects them on
  // every new listing and requires them once the aggregator channel is picked.
  physical?: ArtworkPhysical | null;
}

// --- Physical details -------------------------------------------------------

// How the piece arrives. MOU §12 requires work sent for aggregator display to
// be either professionally stretched on canvas or properly framed, so those
// two are the compliant options and the rest are flagged in the form.
export type FramingState =
  | "framed"
  | "stretched_canvas"
  | "unframed_rolled"
  | "mounted_board"
  | "freestanding";

export const FRAMING_LABEL: Record<FramingState, string> = {
  framed: "Framed",
  stretched_canvas: "Stretched on canvas",
  unframed_rolled: "Unframed / rolled",
  mounted_board: "Mounted on board",
  freestanding: "Freestanding (sculpture)",
};

// MOU §12: only these two are acceptable for a piece going to an aggregator.
export const AGGREGATOR_READY_FRAMING = new Set<FramingState>([
  "framed",
  "stretched_canvas",
]);

export interface ArtworkPhysical {
  weightKg: number | null;
  framing: FramingState | null;
  /** Surface or format — canvas, paper, board, panel, bronze. */
  format: string | null;
  /** MOU §12: hangers must ship with the artwork. */
  hangingHardwareIncluded: boolean;
  /** Artist has confirmed packing to GalleryZone's shipping standard. */
  packagingConfirmed: boolean;
}

// --- Ownership / custody / location -----------------------------------------

export type CustodyParty = "artist" | "galleryzone" | "aggregator" | "customer";

export const CUSTODY_PARTY_LABEL: Record<CustodyParty, string> = {
  artist: "Artist",
  galleryzone: "GalleryZone",
  aggregator: "Aggregator",
  customer: "Collector",
};

export interface ArtworkCustody {
  legalOwner: CustodyParty;
  /** Named owner once a transfer has been accepted (the buyer's own name). */
  legalOwnerName?: string | null;
  custodian: CustodyParty;
  locationLabel: string;
}

// Fallback custody for a record that doesn't carry an explicit one yet.
// Deriving from status is a stopgap for the mock phase only — once transfers
// are recorded as real events, `custody` is written on every transition and
// this map stops being consulted.
const DERIVED_CUSTODY: Record<ArtworkStatus, ArtworkCustody> = {
  draft: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Artist studio",
  },
  pending_approval: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Artist studio",
  },
  marketplace: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Artist studio",
  },
  reserved: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Artist studio",
  },
  preparing_dispatch: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Awaiting pickup",
  },
  in_transit: {
    legalOwner: "artist",
    custodian: "galleryzone",
    locationLabel: "In transit",
  },
  with_aggregator: {
    legalOwner: "artist",
    custodian: "aggregator",
    locationLabel: "Aggregator premises",
  },
  sold: {
    legalOwner: "customer",
    custodian: "galleryzone",
    locationLabel: "Awaiting delivery",
  },
  settlement_complete: {
    legalOwner: "customer",
    custodian: "galleryzone",
    locationLabel: "Awaiting delivery",
  },
  delivered: {
    legalOwner: "customer",
    custodian: "customer",
    locationLabel: "With the collector",
  },
  completed: {
    legalOwner: "customer",
    custodian: "customer",
    locationLabel: "With the collector",
  },
  returned: {
    legalOwner: "artist",
    custodian: "artist",
    locationLabel: "Returned to artist",
  },
  sold_externally: {
    legalOwner: "customer",
    custodian: "customer",
    locationLabel: "Sold outside GalleryZone",
  },
};

export function resolveCustody(artwork: Artwork): ArtworkCustody {
  return artwork.custody ?? DERIVED_CUSTODY[artwork.status];
}

// --- Edit window -------------------------------------------------------------

export const ARTWORK_EDIT_WINDOW_DAYS = 7;

// A purchase or claim ends the edit window immediately, however many of the
// 7 days are left.
const PURCHASE_LOCKED_STATUSES = new Set<ArtworkStatus>([
  "reserved",
  "preparing_dispatch",
  "in_transit",
  "sold",
  "settlement_complete",
  "delivered",
  "completed",
  "sold_externally",
]);

export type ArtworkEditState =
  | { editable: true; reason: "draft" | "within_window"; daysLeft: number }
  | { editable: false; reason: "purchased" | "window_closed"; daysLeft: 0 };

const DAY_MS = 24 * 60 * 60 * 1000;

// 7 days from first listing OR until the piece is bought/claimed — whichever
// comes first. Drafts aren't listed yet, so they stay editable indefinitely.
export function artworkEditState(
  artwork: Pick<Artwork, "status" | "statusHistory">,
  now: number = Date.now(),
): ArtworkEditState {
  if (artwork.status === "draft") {
    return {
      editable: true,
      reason: "draft",
      daysLeft: ARTWORK_EDIT_WINDOW_DAYS,
    };
  }
  if (PURCHASE_LOCKED_STATUSES.has(artwork.status)) {
    return { editable: false, reason: "purchased", daysLeft: 0 };
  }

  const listedAt = artwork.statusHistory[0]?.changedAt;
  if (!listedAt) {
    return {
      editable: true,
      reason: "within_window",
      daysLeft: ARTWORK_EDIT_WINDOW_DAYS,
    };
  }

  const elapsedDays = (now - new Date(listedAt).getTime()) / DAY_MS;
  const daysLeft = Math.ceil(ARTWORK_EDIT_WINDOW_DAYS - elapsedDays);
  return daysLeft > 0
    ? { editable: true, reason: "within_window", daysLeft }
    : { editable: false, reason: "window_closed", daysLeft: 0 };
}

// --- Selling outside GalleryZone ---------------------------------------------

// Charged on the artist's NEXT listing when they mark a piece sold elsewhere,
// as a percentage of that piece's listed price.
export const EXTERNAL_SALE_PENALTY_RATE = 0.01;

// An artist can withdraw a piece as "sold elsewhere" only while GalleryZone
// has no claim on it. One set, read by both the dashboard UI and the service
// guard, so the button and the rule can never disagree.
export const WITHDRAWABLE_STATUSES = new Set<ArtworkStatus>([
  "draft",
  "pending_approval",
  "marketplace",
]);

// Rarity / edition type, shown as a badge over the artwork image. Held on the
// Artwork itself rather than read back with `"rarityType" in artwork` casts —
// the mobile client already models it this way.
//
// GalleryZone decides this, not the artist. It is a ranking the platform puts
// its name behind, so an artist cannot self-declare their work Rare — the
// admin sets it from /admin/artworks/<id>.
//
// Every piece carries one — it is compulsory, chosen by an admin when the piece
// is approved and changeable afterwards, never cleared. "S" (Standard) was "N"
// (Normal) before the rename.
export type ArtworkRarity = "R" | "U" | "O" | "S";

/** Reads a rank from the API, mapping the retired "N" onto "S". */
export function normalizeRarity(value: string | null | undefined): ArtworkRarity | null {
  if (value === "N") return "S";
  return value === "R" || value === "U" || value === "O" || value === "S" ? value : null;
}

// Same 4 states as GstStatus (types/admin.ts) — reused rather than imported
// to keep this file's types self-contained from the admin domain; the
// literal values are what admin-status-badge.tsx's STATUS_CONFIG keys on.
export type InsuranceStatus =
  "not_submitted" | "submitted" | "approved" | "rejected";

export function insuranceStatusOf(artwork: Artwork): InsuranceStatus {
  return artwork.insuranceStatus ?? "not_submitted";
}

export const ARTWORK_RARITY_LABEL: Record<ArtworkRarity, string> = {
  R: "Rare",
  U: "Unique",
  O: "Original",
  S: "Standard",
};

export const ARTWORK_RARITY_OPTIONS: {
  value: ArtworkRarity;
  label: string;
  description: string;
}[] = [
  {
    value: "R",
    label: "Rare",
    description: "Limited or one-of-a-kind with exceptional provenance.",
  },
  {
    value: "U",
    label: "Unique",
    description: "Singular piece, the only one in existence.",
  },
  {
    value: "O",
    label: "Original",
    description: "Hand-made original by the artist.",
  },
  {
    value: "S",
    label: "Standard",
    description: "Open edition or standard listing.",
  },
];

// The off-platform sale fee is proposed, not imposed. Selling elsewhere can be
// perfectly reasonable — a piece promised to a gallery before listing, a
// commission that fell through — so an admin decides case by case whether it
// is actually charged. Only an approved fee is ever collected.
export type PenaltyStatus = "pending_review" | "approved" | "waived";

export const PENALTY_STATUS_LABEL: Record<PenaltyStatus, string> = {
  pending_review: "Awaiting review",
  approved: "Approved",
  waived: "Waived",
};

export interface ExternalSalePenalty {
  id: string;
  artworkId: string;
  artworkTitle: string;
  amount: number;
  createdAt: string;
  settledAt: string | null;
  /** Absent on records written before the fee became reviewable — those were
   *  charged automatically, so they read as already approved. */
  status?: PenaltyStatus;
  decidedAt?: string | null;
  /** The admin's note, shown back to the artist. */
  decisionNote?: string | null;
}

export function penaltyStatus(penalty: ExternalSalePenalty): PenaltyStatus {
  return penalty.status ?? "approved";
}

/** Only an approved, uncollected fee is ever taken from a wallet. */
export function isPenaltyCollectable(penalty: ExternalSalePenalty): boolean {
  return penaltyStatus(penalty) === "approved" && penalty.settledAt === null;
}

// --- Ownership transfer (NFC passport hand-over) ----------------------------

// A hand-over of the digital ownership record from the current owner to a
// named buyer: the owner starts it, the buyer accepts through a link, and the
// artwork's custody plus this list update together. The same flow runs again
// on every resale, which is what keeps provenance continuous.
export type TransferStatus = "pending" | "accepted" | "cancelled";

// Art travels to be shown, and the piece that goes on a gallery wall for a
// month has not changed hands. So a transfer is one of two things: a permanent
// hand-over of ownership, or a time-boxed hand-over of display rights that
// leaves the owner exactly where they were.
export type TransferKind = "ownership" | "display";

export const TRANSFER_KIND_LABEL: Record<TransferKind, string> = {
  ownership: "Ownership",
  display: "Display rights",
};

export interface OwnershipTransfer {
  id: string;
  artworkId: string;
  artworkTitle: string;
  fromName: string;
  toName: string;
  toEmail: string;
  initiatedAt: string;
  acceptedAt: string | null;
  cancelledAt: string | null;
  status: TransferStatus;
  /** Absent on records written before display rights existed — those are all
   *  ownership hand-overs. Read it through transferKind(). */
  kind?: TransferKind;
  /** Display transfers only: the date the display period runs to. */
  displayEndsAt?: string | null;
  /** Display transfers only: set when the owner pulls the piece back early. */
  displayEndedAt?: string | null;
}

export function transferKind(transfer: OwnershipTransfer): TransferKind {
  return transfer.kind ?? "ownership";
}

// A display transfer ends by its own date. Nothing runs to make that happen —
// every screen compares the date to now, so the display simply stops being
// active when the day passes, exactly as it stops when the owner ends it early.
export function isDisplayActive(
  transfer: OwnershipTransfer,
  now: Date = new Date(),
): boolean {
  if (transferKind(transfer) !== "display") return false;
  if (transfer.status !== "accepted") return false;
  if (transfer.displayEndedAt) return false;
  if (!transfer.displayEndsAt) return false;
  return new Date(transfer.displayEndsAt).getTime() > now.getTime();
}

/** The one display transfer currently in force for a piece, if any. */
export function activeDisplayTransfer(
  transfers: OwnershipTransfer[],
  now: Date = new Date(),
): OwnershipTransfer | null {
  return transfers.find((t) => isDisplayActive(t, now)) ?? null;
}

// --- Physical Certificate of Authenticity -----------------------------------

// MOU §12: after a sale, a buyer may ask for the COA on paper. The artist
// prints it, signs it by hand, and dispatches it through the portal — this
// record is that request and its fulfilment.
export type PhysicalCoaStatus = "requested" | "dispatched";

export interface PhysicalCoaRequest {
  id: string;
  artworkId: string;
  artworkTitle: string;
  coaCertificateNumber: string;
  requestedByName: string;
  requestedAt: string;
  deliveryAddress: {
    line1: string;
    city: string;
    state: string;
    pincode: string;
  };
  status: PhysicalCoaStatus;
  dispatchedAt: string | null;
  courierRef: string | null;
}

/** Rough size band derived from an artwork's stored dimensions — see sizeBucketOf(). */
export type ArtworkSizeBand = "small" | "medium" | "large";

export interface ArtworkFilters {
  /** Any of these categories match (OR) — empty/absent means no category filter. */
  category?: string[];
  minPrice?: number;
  maxPrice?: number;
  /** Any of these mediums match (OR) — empty/absent means no medium filter. */
  medium?: string[];
  /** GalleryZone's rank — R / U / O / N. */
  rarity?: ArtworkRarity;
  query?: string;
  sortBy?: "newest" | "price_asc" | "price_desc";
  artistId?: string;
  /** The artist's location (types/artist.ts ArtistProfile.location) — an
   * artwork doesn't carry its own location, only its artist does. */
  location?: string;
  size?: ArtworkSizeBand;
  /** "available" = currently marketplace-listed; "unavailable" = reserved,
   * sold, or otherwise off the open market but still publicly visible. */
  availability?: "available" | "unavailable";
  /** 1-based. Absent = first page. */
  page?: number;
}

/** What the marketplace listing endpoint returns: one page plus the facets
 *  (distinct filter values across the WHOLE live marketplace) that drive
 *  the filter sidebar — nothing about the filter UI is hardcoded. */
export interface MarketplacePage {
  artworks: ArtworkSummary[];
  total: number;
  page: number;
  pageSize: number;
  facets: MarketplaceFacets;
}

export interface MarketplaceFacets {
  categories: string[];
  mediums: string[];
  rarities: string[];
  rarityCounts: Partial<Record<ArtworkRarity, number>>;
  locations: string[];
  artists: { id: string; name: string }[];
  /** Rupees. Null when the marketplace is empty. */
  priceRange: { min: number; max: number } | null;
}
