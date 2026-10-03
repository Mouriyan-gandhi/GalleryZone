// The public passport's lifecycle (NFC_IMPLEMENTATION.md §6): one timeline of
// everything that happened to a piece, oldest first — made, approved, listed,
// shown at a gallery, sold, handed over, delivered — merged from the places
// those facts already live (the artwork and its status events, aggregator
// holdings and sales, ownership events, order status events).
//
// buildLifecycle() is pure so the privacy rule can be checked without a
// database: a collector's location is NEVER shown (plan.md §12). The types
// enforce it — an entry whose actor is a collector or the platform has
// `location: null` and nothing can put a place there; only the artist and a
// gallery (a commercial venue, public by nature) can carry one.
//
// Nothing here reads a price, an email, a phone number or an address. The
// buyer of a gallery sale is not named at all, and a gallery's place is its
// city and state, never the street.

import type { Firestore } from "firebase-admin/firestore";
import type { ArtworkStatus, HoldingStatus } from "@galleryzone/domain";
import {
  Collections,
  artworkStatusEventsCol,
  orderStatusEventsCol,
  userProfileCol,
  type AggregatorHoldingDoc,
  type AggregatorSaleDoc,
  type ArtworkDoc,
  type ArtworkStatusEventDoc,
  type ProfileDoc,
  type UserDoc,
} from "./collections.ts";
import type { OwnershipEvent } from "./ownership.ts";

/** Mirrors @galleryzone/contracts' LifecycleLocation (contracts can't be imported here without a cycle). */
export interface LifecycleLocation {
  city: string;
  /** Empty when the source only said where the place is in the world, not which state. */
  state: string;
  country: string;
}

interface LifecycleBase {
  id: string;
  /** ISO. */
  at: string;
  note: string | null;
}

/** Entries about a person or venue whose place is public: the artist and a gallery. */
export type VenueLifecycleEntry = LifecycleBase & {
  kind: "created" | "listed" | "placed_with_gallery" | "returned_from_gallery" | "sold_at_gallery";
  actor: { kind: "artist" | "gallery"; displayName: string };
  location: LifecycleLocation | null;
};

/** Entries about a collector or the platform itself. The place is always null: a collector's home is private. */
export type PrivateLifecycleEntry = LifecycleBase & {
  kind: "approved" | "sold_marketplace" | "transferred" | "displayed" | "delivered";
  actor: { kind: "collector" | "platform"; displayName: string };
  location: null;
};

export type LifecycleEntry = VenueLifecycleEntry | PrivateLifecycleEntry;

export interface LifecyclePlacement {
  id: string;
  galleryName: string;
  galleryLocation: LifecycleLocation | null;
  cycleMonth: number;
  status: HoldingStatus;
  assignedAt: Date | null;
  returnedAt: Date | null;
}

export interface LifecycleGallerySale {
  id: string;
  placementId: string;
  soldAt: Date | null;
}

export interface LifecycleInputs {
  createdAt: Date | null;
  artistName: string;
  artistLocation: LifecycleLocation | null;
  /** Oldest first. */
  statusEvents: { status: ArtworkStatus; changedAt: Date | null }[];
  placements: LifecyclePlacement[];
  gallerySales: LifecycleGallerySale[];
  ownership: Pick<OwnershipEvent, "id" | "kind" | "status" | "toName" | "orderId" | "acceptedAt">[];
  /** When each marketplace order (by id) was delivered. */
  deliveredAt: ReadonlyMap<string, Date>;
}

const EPOCH = new Date(0);
const GALLERY_FALLBACK = "A GalleryZone partner gallery";
const PLATFORM = { kind: "platform", displayName: "GalleryZone" } as const;

/** The order entries sharing one instant read in, so a sale's delivery never sorts before the sale. */
const KIND_ORDER: readonly LifecycleEntry["kind"][] = [
  "created",
  "approved",
  "listed",
  "placed_with_gallery",
  "sold_at_gallery",
  "returned_from_gallery",
  "sold_marketplace",
  "transferred",
  "displayed",
  "delivered",
];

// India's states and union territories, to tell "Pune, Maharashtra" (a state) from "Paris, France" (a country).
const INDIAN_STATES = new Set(
  [
    "andhra pradesh", "arunachal pradesh", "assam", "bihar", "chhattisgarh", "goa", "gujarat", "haryana", "himachal pradesh", "jharkhand",
    "karnataka", "kerala", "madhya pradesh", "maharashtra", "manipur", "meghalaya", "mizoram", "nagaland", "odisha", "punjab", "rajasthan",
    "sikkim", "tamil nadu", "telangana", "tripura", "uttar pradesh", "uttarakhand", "west bengal", "andaman and nicobar islands", "chandigarh",
    "dadra and nagar haveli and daman and diu", "delhi", "new delhi", "jammu and kashmir", "ladakh", "lakshadweep", "puducherry",
  ].map((s) => s.toLowerCase()),
);

/** "Pune, Maharashtra" / "Paris, France" / "Austin, Texas, USA" / "Mumbai" → a place, or null for nothing usable. */
export function parseLocation(text: string | null | undefined): LifecycleLocation | null {
  const parts = (text ?? "").split(",").map((p) => p.trim()).filter(Boolean);
  const [city, second] = parts;
  if (!city) return null;
  if (parts.length === 1) return { city, state: "", country: "India" };
  if (parts.length === 2 && second) {
    return INDIAN_STATES.has(second.toLowerCase()) ? { city, state: second, country: "India" } : { city, state: "", country: second };
  }
  return { city, state: second ?? "", country: parts[parts.length - 1] ?? "India" };
}

const iso = (d: Date | null): string => (d ?? EPOCH).toISOString();

/** Pure: merges the streams into one timeline, oldest first. */
export function buildLifecycle(input: LifecycleInputs): LifecycleEntry[] {
  const entries: LifecycleEntry[] = [];
  const firstLive = input.statusEvents.find((e) => e.status === "marketplace");
  const artist = { kind: "artist", displayName: input.artistName } as const;

  entries.push({ id: "created", kind: "created", at: iso(input.createdAt ?? input.statusEvents[0]?.changedAt ?? null), actor: artist, location: input.artistLocation, note: null });
  if (firstLive) {
    entries.push({ id: "approved", kind: "approved", at: iso(firstLive.changedAt), actor: PLATFORM, location: null, note: null });
    entries.push({ id: "listed", kind: "listed", at: iso(firstLive.changedAt), actor: artist, location: input.artistLocation, note: null });
  }

  const placementById = new Map(input.placements.map((p) => [p.id, p]));
  for (const p of input.placements) {
    const gallery = { kind: "gallery", displayName: p.galleryName || GALLERY_FALLBACK } as const;
    entries.push({ id: `placed:${p.id}`, kind: "placed_with_gallery", at: iso(p.assignedAt), actor: gallery, location: p.galleryLocation, note: `Month ${p.cycleMonth} of the gallery cycle` });
    if (p.status === "returned" && p.returnedAt) {
      entries.push({ id: `returned:${p.id}`, kind: "returned_from_gallery", at: iso(p.returnedAt), actor: gallery, location: p.galleryLocation, note: null });
    }
  }
  for (const s of input.gallerySales) {
    const p = placementById.get(s.placementId);
    if (!p) continue;
    entries.push({ id: `gallery-sale:${s.id}`, kind: "sold_at_gallery", at: iso(s.soldAt), actor: { kind: "gallery", displayName: p.galleryName || GALLERY_FALLBACK }, location: p.galleryLocation, note: null });
  }

  for (const e of input.ownership) {
    if (e.status !== "accepted") continue; // a hand-over that was never accepted did not happen
    const at = iso(e.acceptedAt?.toDate() ?? null);
    const collector = { kind: "collector", displayName: e.toName } as const;
    if (e.kind === "display") {
      entries.push({ id: `display:${e.id}`, kind: "displayed", at, actor: collector, location: null, note: "Lent for a display period" });
    } else if (e.orderId) {
      entries.push({ id: `sale:${e.id}`, kind: "sold_marketplace", at, actor: collector, location: null, note: null });
      const delivered = input.deliveredAt.get(e.orderId);
      if (delivered) entries.push({ id: `delivered:${e.orderId}`, kind: "delivered", at: iso(delivered), actor: PLATFORM, location: null, note: null });
    } else {
      entries.push({ id: `transfer:${e.id}`, kind: "transferred", at, actor: collector, location: null, note: null });
    }
  }

  return entries.sort((a, b) => a.at.localeCompare(b.at) || KIND_ORDER.indexOf(a.kind) - KIND_ORDER.indexOf(b.kind) || a.id.localeCompare(b.id));
}

// --- Loading ----------------------------------------------------------------------

export interface PassportExtras {
  nfcLinked: boolean;
  nfcLocked: boolean;
  lifecycle: LifecycleEntry[];
}

const toDate = (t: FirebaseFirestore.Timestamp | null | undefined): Date | null => t?.toDate() ?? null;

interface Gallery {
  name: string;
  location: LifecycleLocation | null;
}

async function galleryOf(db: Firestore, aggregatorId: string): Promise<Gallery> {
  const [userSnap, profileSnap] = await Promise.all([db.collection(Collections.users).doc(aggregatorId).get(), db.collection(userProfileCol(aggregatorId)).doc("data").get()]);
  const user = userSnap.data() as UserDoc | undefined;
  const profile = profileSnap.data() as ProfileDoc | undefined;
  const city = profile?.pickupCity?.trim();
  return {
    name: profile?.companyName?.trim() || user?.name || "",
    location: city ? { city, state: profile?.pickupState?.trim() ?? "", country: "India" } : null,
  };
}

/**
 * What the public passport adds on top of the artwork view: the tag's two
 * public flags (never its UID) and the lifecycle. `ownership` is passed in
 * because the passport has already read it.
 */
export async function loadPassportExtras(db: Firestore, artworkId: string, ownership: OwnershipEvent[]): Promise<PassportExtras> {
  const artworkSnap = await db.collection(Collections.artworks).doc(artworkId).get();
  const artwork = artworkSnap.data() as ArtworkDoc | undefined;
  if (!artwork) return { nfcLinked: false, nfcLocked: false, lifecycle: [] };

  const [eventsSnap, holdingsSnap] = await Promise.all([
    db.collection(artworkStatusEventsCol(artworkId)).orderBy("changedAt", "asc").get(),
    db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).orderBy("assignedAt").get(),
  ]);
  const holdings = holdingsSnap.docs.map((d) => ({ id: d.id, ...(d.data() as AggregatorHoldingDoc) }));
  const accepted = ownership.filter((e) => e.status === "accepted" && e.kind === "ownership" && e.orderId);

  const [galleries, salesSnap, deliveries] = await Promise.all([
    Promise.all([...new Set(holdings.map((h) => h.aggregatorId))].map(async (id) => [id, await galleryOf(db, id)] as const)),
    holdings.length ? db.collection(Collections.aggregatorSales).where("holdingId", "in", holdings.slice(0, 30).map((h) => h.id)).get() : null,
    Promise.all(
      accepted.map(async (e) => {
        const delivered = await db.collection(orderStatusEventsCol(e.orderId!)).where("status", "==", "delivered").limit(1).get();
        return [e.orderId!, toDate((delivered.docs[0]?.data() as { changedAt?: FirebaseFirestore.Timestamp } | undefined)?.changedAt)] as const;
      }),
    ),
  ]);
  const galleryById = new Map(galleries);

  const lifecycle = buildLifecycle({
    createdAt: toDate(artwork.createdAt),
    artistName: artwork.listing?.artistName ?? "",
    artistLocation: parseLocation(artwork.listing?.artistLocation),
    statusEvents: eventsSnap.docs.map((d) => {
      const e = d.data() as ArtworkStatusEventDoc;
      return { status: e.status, changedAt: toDate(e.changedAt) };
    }),
    placements: holdings.map((h) => ({
      id: h.id,
      galleryName: galleryById.get(h.aggregatorId)?.name ?? "",
      galleryLocation: galleryById.get(h.aggregatorId)?.location ?? null,
      cycleMonth: h.cycleMonth,
      status: h.status,
      assignedAt: toDate(h.assignedAt),
      returnedAt: toDate(h.returnedAt),
    })),
    gallerySales: (salesSnap?.docs ?? []).map((d) => {
      const s = d.data() as AggregatorSaleDoc;
      return { id: d.id, placementId: s.holdingId, soldAt: toDate(s.soldAt) };
    }),
    ownership,
    deliveredAt: new Map(deliveries.filter((d): d is readonly [string, Date] => d[1] !== null)),
  });

  const nfcLinked = Boolean(artwork.nfcLinkedAt);
  return { nfcLinked, nfcLocked: nfcLinked && Boolean(artwork.nfcLockedAt), lifecycle };
}
