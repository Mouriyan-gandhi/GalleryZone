// The public artwork passport — what GET /v1/verify/:artworkId (the QR /
// NFC target) returns to ANYONE. plan.md §12: title, artist, product id,
// ownership status, certificate. Never a price of any kind, never an
// email, phone or address, never a user id of a collector.
// verify-dto.check.ts enforces the forbidden-field list on this interface.

export interface VerifyPassportDto {
  artworkId: string;
  productCode: string;
  title: string;
  artistId: string;
  artistName: string;
  category: string;
  medium: string;
  dimensions: string | null;
  yearCreated: number | null;
  images: { url: string; thumbnailUrl: string | null; altText: string | null; sortOrder: number }[];
  status: string;
  coaCertificateNumber: string | null;
  coaIssuedAt: string | null;
  listedAt: string;
  owner: { kind: "artist" | "collector"; displayName: string };
  events: {
    id: string;
    kind: "ownership" | "display";
    status: "pending" | "accepted" | "cancelled";
    fromName: string;
    toName: string;
    /** True when the transfer was a marketplace sale rather than a manual hand-over. */
    viaSale: boolean;
    initiatedAt: string;
    acceptedAt: string | null;
    cancelledAt: string | null;
    displayEndsAt: string | null;
    displayEndedAt: string | null;
  }[];
  /** A physical tag is linked to the piece (the app wrote it and the server recorded it). The chip's own ID is never public. */
  nfcLinked: boolean;
  /** The tag was locked read-only for good: it cannot be rewritten to point anywhere else. */
  nfcLocked: boolean;
  /** Everything that happened to the piece, oldest first: made, approved, listed, shown at a gallery, sold, handed over, delivered. */
  lifecycle: LifecycleEntry[];
}

export interface LifecycleLocation {
  city: string;
  /** Empty when the source only said which country. */
  state: string;
  country: string;
}

interface LifecycleBase {
  id: string;
  /** ISO. */
  at: string;
  /** A short line of context, such as which month of the gallery cycle. */
  note: string | null;
}

/** The artist and a gallery: a place can be shown, because both are public by nature. */
export type VenueLifecycleEntry = LifecycleBase & {
  kind: "created" | "listed" | "placed_with_gallery" | "returned_from_gallery" | "sold_at_gallery";
  actor: { kind: "artist" | "gallery"; displayName: string };
  location: LifecycleLocation | null;
};

/** A collector or GalleryZone itself. A collector's home is private, so the place is always null, and the type cannot hold one. */
export type PrivateLifecycleEntry = LifecycleBase & {
  kind: "approved" | "sold_marketplace" | "transferred" | "displayed" | "delivered";
  actor: { kind: "collector" | "platform"; displayName: string };
  location: null;
};

export type LifecycleEntry = VenueLifecycleEntry | PrivateLifecycleEntry;

/** How the signed-in viewer is connected to a piece: they own it, made it, or hold it on display. */
export type PassportRelation = "owner" | "artist" | "holder";

/**
 * GET /v1/passport/mine — the passports of the pieces the signed-in viewer is
 * connected to. Each entry carries the SAME public passport /v1/verify serves
 * (so it can never show more than a scan would) plus how the viewer relates
 * to the piece. `total` is the full count when `items` was capped.
 */
export interface MyPassportsDto {
  total: number;
  items: {
    relations: PassportRelation[];
    /** Only for a piece the viewer made: whether a physical tag is linked. Null otherwise. */
    nfcLinked: boolean | null;
    /** Only for a piece the viewer holds on display: the holding to open. Null otherwise. */
    holdingId: string | null;
    passport: VerifyPassportDto;
  }[];
}
