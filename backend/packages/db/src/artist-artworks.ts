// Artist-side artwork submission and editing — Firestore version. A
// submitted artwork starts at "pending_approval" (the real moderation gate
// the mock frontend was missing) — pending_approval -> marketplace only
// happens through an explicit approveArtwork() call. A draft stays with
// the artist until they submit it for review.

import type { Firestore } from "firebase-admin/firestore";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { isArtistGstRegistered } from "./profiles.ts";
import { artistSettlementOf, artworkStateMachine, editWindowExpiresAt, externalSalePenaltyOf, type ArtistSettlement, type ArtworkStatus, type PricingRates } from "@galleryzone/domain";
import { Collections, normalizeRarity, artworkPricingCol, artworkStatusEventsCol, type ArtworkDoc, type ArtworkPhysical, type ArtworkPricingDoc, type ArtworkStatusEventDoc, type ExternalSalePenaltyDoc, type ListingType } from "./collections.ts";
import { listArtworkImages, type ArtworkImage } from "./artwork-images.ts";
import { getPublicArtwork, type PublicArtworkView } from "./public-artworks.ts";
import { issueCertificate } from "./coa.ts";
import { appendArtworkStatus, latestStatusOf, refreshListing } from "./listing-projection.ts";
import { DbError } from "./errors.ts";

export class ArtistArtworkError extends DbError {}

export interface SubmitArtworkInput {
  db: Firestore;
  artistId: string;
  title: string;
  description: string;
  category: string;
  medium: string;
  artistPricePaise: number;
  listingType: ListingType;
  dimensions?: string | undefined;
  yearCreated?: number | undefined;
  /** "draft" keeps it with the artist; "review" (default) submits for moderation. */
  mode?: "draft" | "review" | undefined;
  artworkType?: string | null | undefined;
  paintingStyle?: string | null | undefined;
  insuranceOpted?: boolean | undefined;
  insuranceNumber?: string | null | undefined;
  nfcTagId?: string | null | undefined;
  physical?: ArtworkPhysical | null | undefined;
  rates: PricingRates;
}

// Product code sequence — a Firestore counter doc rather than a row
// count, since Firestore has no cheap `count(*)` equivalent pre-aggregation
// query without reading every doc (this project's `count()` aggregation
// query works too, but a dedicated counter avoids an ever-growing full
// collection scan as artworks grows). Incremented via FieldValue.increment
// inside the same flow — not perfectly gapless under concurrent
// submissions (two submissions reading the counter before either commits
// could both compute the same next value), documented as the same kind
// of known race the Postgres version's row-count approach had, not a
// regression.
async function nextProductCode(db: Firestore): Promise<string> {
  const counterRef = db.collection("_counters").doc("artworks");
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const next = ((snap.data()?.value as number) ?? 0) + 1;
    tx.set(counterRef, { value: next }, { merge: true });
    return next;
  });
  return `GZ${String(result).padStart(6, "0")}`;
}

export async function submitArtwork(input: SubmitArtworkInput): Promise<{ artworkId: string; productCode: string }> {
  const productCode = await nextProductCode(input.db);
  const now = new Date();

  const artworkRef = input.db.collection(Collections.artworks).doc();
  const artworkDoc: ArtworkDoc = {
    productCode,
    artistId: input.artistId,
    title: input.title,
    description: input.description,
    category: input.category,
    medium: input.medium,
    dimensions: input.dimensions ?? null,
    yearCreated: input.yearCreated ?? null,
    artworkType: input.artworkType ?? null,
    paintingStyle: input.paintingStyle ?? null,
    physical: input.physical ?? null,
    insuranceOpted: input.insuranceOpted ?? false,
    listingType: input.listingType,
    rarityType: null,
    coaCertificateNumber: null,
    coaIssuedAt: null,
    nfcTagId: input.nfcTagId ?? null,
    insuranceNumber: input.insuranceNumber ?? null,
    insuranceStatus: input.insuranceNumber ? "submitted" : null,
    editableUntil: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp, // placeholder, overwritten below with a real computed value
    createdAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
  };
  await artworkRef.set(artworkDoc);
  // editWindowExpiresAt() needs a concrete Date, which serverTimestamp()
  // can't give us before the write resolves — set it as a genuine
  // client-computed Timestamp in a second write rather than fake a value
  // in the first.
  await artworkRef.update({ editableUntil: Timestamp.fromDate(editWindowExpiresAt(now, input.rates)) });

  const pricingDoc: ArtworkPricingDoc = { artistId: input.artistId, artistPricePaise: input.artistPricePaise };
  await input.db.collection(artworkPricingCol(artworkRef.id)).doc("data").set(pricingDoc);

  if (input.mode === "draft") {
    await appendArtworkStatus(input.db, artworkRef.id, { status: "draft", changedBy: null, reason: null });
  } else {
    await appendArtworkStatus(input.db, artworkRef.id, { status: "pending_approval", changedBy: null, reason: null });
  }
  await refreshListing(input.db, artworkRef.id, input.rates);

  return { artworkId: artworkRef.id, productCode };
}

export type UpdateArtworkPatch = {
  [K in keyof Pick<
    SubmitArtworkInput,
    | "title"
    | "description"
    | "category"
    | "medium"
    | "artistPricePaise"
    | "listingType"
    | "dimensions"
    | "yearCreated"
    | "artworkType"
    | "paintingStyle"
    | "insuranceOpted"
    | "insuranceNumber"
    | "nfcTagId"
    | "physical"
  >]?: SubmitArtworkInput[K] | undefined;
} & { mode?: "draft" | "review" | undefined };

// Statuses in which the artist may still change the piece freely. A
// marketplace listing is editable only inside its edit window (policy
// canEditArtwork); anything reserved/sold is frozen.
const FREELY_EDITABLE: ReadonlySet<ArtworkStatus> = new Set<ArtworkStatus>(["draft", "pending_approval", "returned"]);

/** Edits one of the artist's own artworks. `mode: "review"` on a draft/returned piece submits it for moderation. */
export async function updateArtwork(
  db: Firestore,
  { artistId, artworkId, patch, rates }: { artistId: string; artworkId: string; patch: UpdateArtworkPatch; rates: PricingRates },
): Promise<void> {
  const ref = db.collection(Collections.artworks).doc(artworkId);
  const snap = await ref.get();
  const artwork = snap.data() as ArtworkDoc | undefined;
  if (!artwork || artwork.artistId !== artistId) throw new ArtistArtworkError(`No artwork ${artworkId}`);
  const status = await latestStatusOf(db, artworkId);
  const editable = FREELY_EDITABLE.has(status) || (status === "marketplace" && Date.now() < artwork.editableUntil.toDate().getTime());
  if (!editable) throw new ArtistArtworkError(`An artwork that is ${status.replace("_", " ")} can no longer be edited`);

  const fields: Partial<ArtworkDoc> = {};
  if (patch.title !== undefined) fields.title = patch.title;
  if (patch.description !== undefined) fields.description = patch.description;
  if (patch.category !== undefined) fields.category = patch.category;
  if (patch.medium !== undefined) fields.medium = patch.medium;
  if (patch.listingType !== undefined) fields.listingType = patch.listingType;
  if (patch.dimensions !== undefined) fields.dimensions = patch.dimensions ?? null;
  if (patch.yearCreated !== undefined) fields.yearCreated = patch.yearCreated ?? null;
  if (patch.artworkType !== undefined) fields.artworkType = patch.artworkType ?? null;
  if (patch.paintingStyle !== undefined) fields.paintingStyle = patch.paintingStyle ?? null;
  if (patch.insuranceOpted !== undefined) fields.insuranceOpted = patch.insuranceOpted;
  if (patch.nfcTagId !== undefined) fields.nfcTagId = patch.nfcTagId ?? null;
  if (patch.physical !== undefined) fields.physical = patch.physical ?? null;
  if (patch.insuranceNumber !== undefined && patch.insuranceNumber !== artwork.insuranceNumber) {
    fields.insuranceNumber = patch.insuranceNumber ?? null;
    // A new number goes back to the admin for verification.
    fields.insuranceStatus = patch.insuranceNumber ? "submitted" : null;
  }
  if (Object.keys(fields).length) await ref.update(fields);

  if (patch.artistPricePaise !== undefined) {
    const pricingDoc: ArtworkPricingDoc = { artistId, artistPricePaise: patch.artistPricePaise };
    await db.collection(artworkPricingCol(artworkId)).doc("data").set(pricingDoc);
  }

  if (patch.mode === "review" && (status === "draft" || status === "returned")) {
    artworkStateMachine.assertTransition(status, "pending_approval");
    await appendArtworkStatus(db, artworkId, { status: "pending_approval", changedBy: null, reason: null });
  }
  await refreshListing(db, artworkId, rates);
}

/** Everything the public sees plus what only the owner may: the artist's price, net, full images, status history, insurance. */
export interface OwnerArtworkView extends PublicArtworkView {
  artistPricePaise: number;
  /**
   * What the artist is actually paid, line by line, on each channel — the
   * payout sheets' own breakdown, not just a net figure. TDS reflects this
   * artist's real GST-registration status.
   */
  artistNet: {
    marketplace: number;
    aggregatorEstimate: number;
    isGstRegistered: boolean;
    breakdown: { marketplace: ArtistSettlement; aggregator: ArtistSettlement };
  };
  images: ArtworkImage[];
  statusHistory: { status: ArtworkStatus; changedAt: string; reason: string | null }[];
  insuranceOpted: boolean;
  insuranceNumber: string | null;
  insuranceStatus: string | null;
  nfcTagId: string | null;
  artworkType: string | null;
  paintingStyle: string | null;
  physical: ArtworkPhysical | null;
  editableUntil: string;
}

async function toOwnerView(db: Firestore, artworkId: string, artwork: ArtworkDoc, rates: PricingRates): Promise<OwnerArtworkView | null> {
  const pub = await getPublicArtwork(db, artworkId);
  if (!pub) return null;
  const [pricingSnap, images, eventsSnap] = await Promise.all([
    db.collection(artworkPricingCol(artworkId)).doc("data").get(),
    listArtworkImages(db, artworkId),
    db.collection(artworkStatusEventsCol(artworkId)).orderBy("changedAt", "asc").get(),
  ]);
  const artistPricePaise = (pricingSnap.data() as ArtworkPricingDoc | undefined)?.artistPricePaise ?? 0;
  const isGstRegistered = await isArtistGstRegistered(db, artwork.artistId);
  const marketplaceSettlement = artistSettlementOf(artistPricePaise, "marketplace", rates, { isGstRegistered });
  const aggregatorSettlement = artistSettlementOf(artistPricePaise, "aggregator", rates, { isGstRegistered });
  return {
    ...pub,
    images,
    artistPricePaise,
    artistNet: {
      marketplace: marketplaceSettlement.net,
      aggregatorEstimate: aggregatorSettlement.net,
      isGstRegistered,
      breakdown: { marketplace: marketplaceSettlement, aggregator: aggregatorSettlement },
    },
    statusHistory: eventsSnap.docs.map((d) => {
      const e = d.data() as ArtworkStatusEventDoc;
      return { status: e.status, changedAt: e.changedAt?.toDate().toISOString() ?? new Date(0).toISOString(), reason: e.reason };
    }),
    insuranceOpted: artwork.insuranceOpted ?? false,
    insuranceNumber: artwork.insuranceNumber,
    insuranceStatus: artwork.insuranceStatus,
    nfcTagId: artwork.nfcTagId,
    artworkType: artwork.artworkType,
    paintingStyle: artwork.paintingStyle ?? null,
    physical: artwork.physical ?? null,
    editableUntil: artwork.editableUntil?.toDate().toISOString() ?? new Date(0).toISOString(),
  };
}

/** One of the artist's own artworks, any status. Null when missing or not theirs. */
export async function getArtistArtwork(db: Firestore, artistId: string, artworkId: string, rates: PricingRates): Promise<OwnerArtworkView | null> {
  const snap = await db.collection(Collections.artworks).doc(artworkId).get();
  const artwork = snap.data() as ArtworkDoc | undefined;
  if (!artwork || artwork.artistId !== artistId) return null;
  return toOwnerView(db, artworkId, artwork, rates);
}

/**
 * All of the artist's artworks, newest first. Sorted here rather than by
 * Firestore: an equality filter plus orderBy on another field needs a
 * composite index, and a missing one fails the whole request with
 * FAILED_PRECONDITION — which is exactly how the artist's "My artworks"
 * page went blank in production on 20 Sep 2026. One artist's list is
 * small; the index (firestore.indexes.json) is still declared for scale.
 */
export async function listArtistArtworksOwned(db: Firestore, artistId: string, rates: PricingRates): Promise<OwnerArtworkView[]> {
  const snap = await db.collection(Collections.artworks).where("artistId", "==", artistId).get();
  const docs = [...snap.docs].sort((a, b) => createdMillis(b.data() as ArtworkDoc) - createdMillis(a.data() as ArtworkDoc));
  const views = await Promise.all(docs.map((d) => toOwnerView(db, d.id, d.data() as ArtworkDoc, rates)));
  return views.filter((v): v is OwnerArtworkView => v !== null);
}

const createdMillis = (doc: ArtworkDoc): number => doc.createdAt?.toMillis?.() ?? 0;

export async function approveArtwork(db: Firestore, artworkId: string): Promise<void> {
  const current = await latestStatusOf(db, artworkId);
  artworkStateMachine.assertTransition(current, "marketplace");
  // The rank is the platform's call and is compulsory: nothing goes live without one.
  const doc = (await db.collection(Collections.artworks).doc(artworkId).get()).data() as ArtworkDoc | undefined;
  if (!normalizeRarity(doc?.rarityType)) throw new ArtistArtworkError("Rank the artwork (Rare, Unique, Original or Standard) before approving it");
  await appendArtworkStatus(db, artworkId, { status: "marketplace", changedBy: null, reason: null });
  // A listed artwork always has a certificate number (artist MOU §11) —
  // idempotent, so re-approval after a return keeps the original number.
  await issueCertificate(db, artworkId);
}

export async function rejectArtwork(db: Firestore, artworkId: string, reason: string): Promise<void> {
  if (!reason) throw new ArtistArtworkError("A rejection requires a reason");
  const current = await latestStatusOf(db, artworkId);
  artworkStateMachine.assertTransition(current, "returned");
  await appendArtworkStatus(db, artworkId, { status: "returned", changedBy: null, reason });
}

/**
 * "Sold on another platform": the piece leaves every GalleryZone channel
 * and an external-sale fee (rates.externalSalePenaltyRate × artist price)
 * is raised for admin review. Allowed from draft/marketplace/returned.
 */
export async function markSoldElsewhere(
  db: Firestore,
  { artistId, artworkId, rates }: { artistId: string; artworkId: string; rates: PricingRates },
): Promise<{ penaltyId: string; amountPaise: number }> {
  const snap = await db.collection(Collections.artworks).doc(artworkId).get();
  const artwork = snap.data() as ArtworkDoc | undefined;
  if (!artwork || artwork.artistId !== artistId) throw new ArtistArtworkError(`No artwork ${artworkId}`);
  const status = await latestStatusOf(db, artworkId);
  if (status === "sold_externally") throw new ArtistArtworkError("This artwork is already marked as sold elsewhere");
  artworkStateMachine.assertTransition(status, "sold_externally");

  const pricing = (await db.collection(artworkPricingCol(artworkId)).doc("data").get()).data() as ArtworkPricingDoc | undefined;
  const amountPaise = externalSalePenaltyOf(pricing?.artistPricePaise ?? 0, rates);

  await appendArtworkStatus(db, artworkId, { status: "sold_externally", changedBy: artistId, reason: "Sold on another platform" });
  const ref = await db.collection(Collections.externalSalePenalties).add({
    artworkId,
    amountPaise,
    status: "pending_review",
    createdAt: FieldValue.serverTimestamp(),
    decidedAt: null,
    decisionNote: null,
    settledAt: null,
  });
  await refreshListing(db, artworkId, rates);
  return { penaltyId: ref.id, amountPaise };
}

/** This artist's external-sale fees, newest first, with the artwork title. */
export async function listArtistPenalties(db: Firestore, artistId: string) {
  const artworksSnap = await db.collection(Collections.artworks).where("artistId", "==", artistId).select("title").get();
  const titles = new Map(artworksSnap.docs.map((d) => [d.id, (d.data() as { title: string }).title]));
  const ids = [...titles.keys()];
  if (!ids.length) return [];
  const chunks: string[][] = [];
  for (let i = 0; i < ids.length; i += 30) chunks.push(ids.slice(i, i + 30));
  const snaps = await Promise.all(chunks.map((c) => db.collection(Collections.externalSalePenalties).where("artworkId", "in", c).get()));
  return snaps
    .flatMap((s) => s.docs)
    .map((d) => {
      const p = d.data() as ExternalSalePenaltyDoc;
      return {
        id: d.id,
        artworkId: p.artworkId,
        artworkTitle: titles.get(p.artworkId) ?? p.artworkId,
        amountPaise: p.amountPaise,
        status: p.status,
        createdAt: p.createdAt?.toDate().toISOString() ?? new Date(0).toISOString(),
        decidedAt: p.decidedAt?.toDate().toISOString() ?? null,
        decisionNote: p.decisionNote,
        settledAt: p.settledAt?.toDate().toISOString() ?? null,
      };
    })
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}
