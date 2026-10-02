// Aggregator portal reads + the return path. The reserve/sale writes live
// in aggregator-flow.ts; this module gives the portal what it needs to
// render: which pieces can be reserved right now and on what terms, what
// this aggregator holds, and a way to hand a piece back.
//
// Offer terms are computed by the same domain functions reserveHolding()
// uses, so the card and the reservation can never disagree.

import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";
import {
  aggregatorAdvanceForMonth,
  aggregatorOfferPriceOf,
  aggregatorReturnPostings,
  holdingStateMachine,
  placementWindow,
  withGst,
  type PricingRates,
} from "@galleryzone/domain";
import { Collections, artworkPricingCol, type AggregatorHoldingDoc, type ArtworkDoc, type ArtworkPricingDoc } from "./collections.ts";
import { isAlreadyExists, postLedgerEntries } from "./ledger-repository.ts";
import { appendArtworkStatus, latestStatusOf, refreshListing } from "./listing-projection.ts";
import { getPublicArtwork, type PublicArtworkView } from "./public-artworks.ts";
import { DbError } from "./errors.ts";

export class AggregatorReadError extends DbError {}

const AGGREGATOR_LISTING_TYPES = new Set(["aggregator_only", "marketplace_and_aggregator"]);
const ACTIVE_HOLDING = new Set(["reserved", "sold_pending_settlement"]);

export interface AggregatorOffer {
  artworkId: string;
  month: number;
  /** GalleryZone's price this month before GST: the floor in month 1, the fixed price after. */
  sellingPricePaise: number;
  /** The same with GST: what a customer sees if the aggregator keeps GalleryZone's price. */
  offerPricePaise: number;
  standardPricePaise: number;
  monthlyReductionPaise: number;
  marketplacePricePaise: number;
  /** Only month 1 lets the aggregator set their own price. */
  canSetPrice: boolean;
  gstRate: number;
  /** Month 1: the price before GST at or above which GalleryZone is warned. Null when the price can't be set. */
  priceWarnFromPaise: number | null;
  /** The advance at GalleryZone's price. In month 1 it grows with the price the aggregator chooses. */
  advancePaise: number;
  advanceRate: number;
  advanceBasePaise: number;
  advanceBasis: "selling_price" | "artist_price";
  daysLeftInListing: number;
  deliveryChargePaise: number;
  payablePaise: number;
}

export async function holdingsFor(db: Firestore, artworkId: string): Promise<(AggregatorHoldingDoc & { id: string })[]> {
  const snap = await db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).orderBy("assignedAt").get();
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as AggregatorHoldingDoc) }));
}

/** This month's terms for a piece — never exposes artistPricePaise itself. */
export async function computeOffer(db: Firestore, artworkId: string, rates: PricingRates): Promise<AggregatorOffer | null> {
  const pricing = (await db.collection(artworkPricingCol(artworkId)).doc("data").get()).data() as ArtworkPricingDoc | undefined;
  if (!pricing) return null;
  const prior = await holdingsFor(db, artworkId);
  const month = prior.length + 1;
  const now = new Date();
  const cycleStartedAt = prior[0]?.assignedAt.toDate() ?? now;
  const sellingPrice = aggregatorOfferPriceOf(pricing.artistPricePaise, month, rates, { appreciated: prior[0]?.appreciated ?? false });
  const offerPrice = withGst(sellingPrice, rates);
  const standardPrice = withGst(aggregatorOfferPriceOf(pricing.artistPricePaise, 1, rates), rates);
  const advance = aggregatorAdvanceForMonth({ month, sellingPrice, artistPrice: pricing.artistPricePaise, rates });
  const window = placementWindow({ cycleStartedAt, assignedAt: now, rates });
  const listingEnd = new Date(cycleStartedAt.getTime() + rates.aggregatorListingDays * 86_400_000);
  const artwork = (await db.collection(Collections.artworks).doc(artworkId).get()).data() as ArtworkDoc | undefined;
  return {
    artworkId,
    month,
    sellingPricePaise: sellingPrice,
    offerPricePaise: offerPrice,
    standardPricePaise: standardPrice,
    monthlyReductionPaise: Math.max(0, standardPrice - offerPrice),
    marketplacePricePaise: artwork?.listing?.displayPricePaise ?? offerPrice,
    canSetPrice: month === 1,
    gstRate: rates.gstRate,
    priceWarnFromPaise: month === 1 ? Math.ceil(sellingPrice * (1 + rates.aggregatorPriceWarnRate)) : null,
    advancePaise: advance.advance,
    advanceRate: advance.rate,
    advanceBasePaise: advance.base,
    advanceBasis: advance.basis,
    daysLeftInListing: Math.max(0, Math.ceil((listingEnd.getTime() - now.getTime()) / 86_400_000)),
    deliveryChargePaise: advance.deliveryCharge,
    payablePaise: advance.payable,
  };
}

export interface ReservableArtwork extends PublicArtworkView {
  offer: AggregatorOffer;
}

/**
 * Pieces this aggregator may reserve now: live, aggregator-listed, not held by
 * anyone, cycle not exhausted, and not one they have already held (a piece
 * moves on to a different aggregator).
 */
export async function listAggregatorInventory(db: Firestore, rates: PricingRates, aggregatorId: string): Promise<ReservableArtwork[]> {
  const snap = await db.collection(Collections.artworks).where("listing.status", "==", "marketplace").get();
  const candidates = snap.docs.filter((d) => AGGREGATOR_LISTING_TYPES.has((d.data() as ArtworkDoc).listingType));
  const out: ReservableArtwork[] = [];
  for (const d of candidates) {
    const holdings = await holdingsFor(db, d.id);
    if (holdings.some((h) => ACTIVE_HOLDING.has(h.status))) continue;
    if (holdings.some((h) => h.aggregatorId === aggregatorId)) continue;
    if (holdings.length >= rates.aggregatorCycleMonths) continue;
    const [view, offer] = await Promise.all([getPublicArtwork(db, d.id), computeOffer(db, d.id, rates)]);
    if (!view || !offer || offer.daysLeftInListing < rates.aggregatorPlacementDays) continue;
    out.push({ ...view, offer });
  }
  return out.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

/**
 * The piece as its holder sees it: the public view plus whether its NFC tag is linked and
 * locked (NFC_IMPLEMENTATION.md §4.7). The holder is told "locked" or "lock it before you
 * ship"; the chip's UID is never part of it.
 */
export type HoldingArtworkView = PublicArtworkView & { nfcLinkedAt: string | null; nfcLockedAt: string | null };

export interface AggregatorHoldingView {
  id: string;
  artworkId: string;
  artwork: HoldingArtworkView | null;
  cycleMonth: number;
  advancePercent: number;
  advancePaise: number;
  deliveryDepositPaise: number | null;
  displayPricePaise: number;
  assignmentSource: AggregatorHoldingDoc["assignmentSource"];
  assignedAt: string;
  expiresAt: string;
  windowExtended: boolean;
  status: AggregatorHoldingDoc["status"];
  returnedAt: string | null;
  /** Month 1: priced above GalleryZone's offer. */
  appreciated: boolean;
  /** Priced far enough above the offer that GalleryZone was warned. */
  priceWarning: boolean;
  /** The latest request to keep the piece past its window. Never carries which admin decided. */
  extensionRequest: {
    status: "pending" | "approved" | "declined";
    assurance: string;
    requestedAt: string;
    decidedAt: string | null;
    note: string | null;
    previousExpiresAt: string;
  } | null;
}

async function holdingArtworkOf(db: Firestore, artworkId: string): Promise<HoldingArtworkView | null> {
  const [view, doc] = await Promise.all([getPublicArtwork(db, artworkId), db.collection(Collections.artworks).doc(artworkId).get()]);
  if (!view) return null;
  const artwork = doc.data() as ArtworkDoc | undefined;
  return { ...view, nfcLinkedAt: artwork?.nfcLinkedAt?.toDate().toISOString() ?? null, nfcLockedAt: artwork?.nfcLockedAt?.toDate().toISOString() ?? null };
}

async function toHoldingView(db: Firestore, id: string, h: AggregatorHoldingDoc): Promise<AggregatorHoldingView> {
  return {
    id,
    artworkId: h.artworkId,
    artwork: await holdingArtworkOf(db, h.artworkId),
    cycleMonth: h.cycleMonth,
    advancePercent: h.advancePercent,
    advancePaise: h.advanceAmountPaise,
    deliveryDepositPaise: h.deliveryDepositPaise,
    displayPricePaise: h.displayPricePaise,
    assignmentSource: h.assignmentSource,
    assignedAt: h.assignedAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    expiresAt: h.expiresAt?.toDate().toISOString() ?? new Date(0).toISOString(),
    windowExtended: h.windowExtended,
    status: h.status,
    returnedAt: h.returnedAt?.toDate().toISOString() ?? null,
    appreciated: h.appreciated ?? false,
    priceWarning: h.priceWarning ?? false,
    extensionRequest: h.extensionRequest
      ? {
          status: h.extensionRequest.status,
          assurance: h.extensionRequest.assurance,
          requestedAt: h.extensionRequest.requestedAt?.toDate().toISOString() ?? new Date(0).toISOString(),
          decidedAt: h.extensionRequest.decidedAt?.toDate().toISOString() ?? null,
          note: h.extensionRequest.note,
          previousExpiresAt: h.extensionRequest.previousExpiresAt?.toDate().toISOString() ?? new Date(0).toISOString(),
        }
      : null,
  };
}

/** Admin: the active holding on a piece, if any. */
export async function activeHoldingForArtwork(db: Firestore, artworkId: string): Promise<AggregatorHoldingView | null> {
  const snap = await db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).where("status", "==", "reserved").limit(1).get();
  const d = snap.docs[0];
  return d ? toHoldingView(db, d.id, d.data() as AggregatorHoldingDoc) : null;
}

/** Admin pull-back: same as an unsold return, initiated by GalleryZone. */
export async function adminPullBackHolding(db: Firestore, holdingId: string, adminId: string): Promise<AggregatorHoldingView | null> {
  const h = (await db.collection(Collections.aggregatorHoldings).doc(holdingId).get()).data() as AggregatorHoldingDoc | undefined;
  if (!h) throw new AggregatorReadError(`No holding ${holdingId}`);
  await returnHolding(db, h.aggregatorId, holdingId);
  await db.collection(Collections.auditLog).add({ adminId, action: "holding.pulled_back", entityType: "holding", entityId: holdingId, entityLabel: null, detail: null, createdAt: FieldValue.serverTimestamp() });
  return getAggregatorHolding(db, h.aggregatorId, holdingId);
}

export async function listAggregatorHoldings(db: Firestore, aggregatorId: string): Promise<AggregatorHoldingView[]> {
  const snap = await db.collection(Collections.aggregatorHoldings).where("aggregatorId", "==", aggregatorId).get();
  const views = await Promise.all(snap.docs.map((d) => toHoldingView(db, d.id, d.data() as AggregatorHoldingDoc)));
  return views.sort((a, b) => b.assignedAt.localeCompare(a.assignedAt));
}

export async function getAggregatorHolding(db: Firestore, aggregatorId: string, holdingId: string): Promise<AggregatorHoldingView | null> {
  const snap = await db.collection(Collections.aggregatorHoldings).doc(holdingId).get();
  const h = snap.data() as AggregatorHoldingDoc | undefined;
  if (!h || h.aggregatorId !== aggregatorId) return null;
  return toHoldingView(db, holdingId, h);
}

/** Unsold return: the advance goes back to the aggregator's wallet, the delivery deposit is forfeited, the artwork goes back on the marketplace. */
export async function returnHolding(db: Firestore, aggregatorId: string, holdingId: string): Promise<void> {
  const ref = db.collection(Collections.aggregatorHoldings).doc(holdingId);
  const h = (await ref.get()).data() as AggregatorHoldingDoc | undefined;
  if (!h || h.aggregatorId !== aggregatorId) throw new AggregatorReadError(`No holding ${holdingId}`);
  holdingStateMachine.assertTransition(h.status, "returned");
  try {
    await postLedgerEntries(db, {
      postings: aggregatorReturnPostings({ aggregatorId, advancePaise: h.advanceAmountPaise, deliveryPaise: h.deliveryDepositPaise ?? 0 }),
      idempotencyPrefix: `holding:${holdingId}:return`,
      relatedHoldingId: holdingId,
    });
  } catch (error) {
    // A first attempt that refunded the advance and then failed before the
    // status flipped would otherwise block this holding forever. The refund is
    // already posted (it can only post once), so finish the flip.
    if (!isAlreadyExists(error)) throw error;
  }
  await ref.update({ status: "returned", returnedAt: Timestamp.now() });
  const status = await latestStatusOf(db, h.artworkId);
  if (status === "with_aggregator") await appendArtworkStatus(db, h.artworkId, { status: "marketplace", changedBy: aggregatorId, reason: `holding:${holdingId}:returned` });
  await refreshListing(db, h.artworkId);
}
