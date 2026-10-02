// Aggregator reserve -> sale flow — Firestore version. Same
// simplifications as the Postgres version, documented there and carried
// over: cycleStartedAt is derived from the artwork's earliest holding
// (Firestore has no dedicated cycle-id field either), and a sale reads
// whichever rate is active AT SALE TIME rather than pinning a version at
// reservation.
//
// Pricing (client, 30 Sep 2026): the aggregator sets their price ONLY when
// reserving, and only in month 1 (never below GalleryZone's offer). From
// month 2 the price is GalleryZone's and fixed.

import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";
import {
  aggregatorAdvanceForMonth,
  aggregatorHoldPostings,
  aggregatorOfferPriceOf,
  aggregatorSalePostings,
  canPlaceWithAnotherAggregator,
  cashRemittanceDueAt,
  holdingStateMachine,
  isPriceWarning,
  placementWindow,
  withGst,
  type PricingRates,
} from "@galleryzone/domain";
import { FirestoreRateConfigStore } from "./firestore-rate-config-store.ts";
import { postArtistSale } from "./artist-sales.ts";
import { postLedgerEntries } from "./ledger-repository.ts";
import { getWalletBalance } from "./wallets.ts";
import { Collections, artworkPricingCol, type AggregatorHoldingDoc, type AggregatorSaleDoc, type ArtworkPricingDoc } from "./collections.ts";
import { appendArtworkStatus, latestStatusOf, refreshListing } from "./listing-projection.ts";
import { artworkStateMachine } from "@galleryzone/domain";
import { DbError } from "./errors.ts";

export class AggregatorFlowError extends DbError {}

const inr = (paise: number) => `₹${(paise / 100).toLocaleString("en-IN")}`;

async function requireActiveRates(db: Firestore): Promise<PricingRates> {
  const store = new FirestoreRateConfigStore(db);
  const version = await store.getActiveVersion(new Date());
  if (!version) throw new AggregatorFlowError("No approved rate_config_versions row exists yet");
  return version.rates;
}

export interface ReserveHoldingResult {
  holdingId: string;
  advanceAmountPaise: number;
  displayPricePaise: number;
  /** The price before GST the aggregator is selling at. */
  sellingPricePaise: number;
  /** GalleryZone's offer before GST: the floor in month 1. */
  offerSellingPricePaise: number;
  /** Priced far enough above the offer that GalleryZone should be told. */
  priceWarning: boolean;
  expiresAt: Date;
}

export async function reserveHolding({
  db,
  aggregatorId,
  artworkId,
  sellingPricePaise,
}: {
  db: Firestore;
  aggregatorId: string;
  artworkId: string;
  /** The price before GST the aggregator chooses. Month 1 only; omitted means GalleryZone's offer. */
  sellingPricePaise?: number | undefined;
}): Promise<ReserveHoldingResult> {
  const pricingSnap = await db.collection(artworkPricingCol(artworkId)).doc("data").get();
  if (!pricingSnap.exists) throw new AggregatorFlowError(`No artwork ${artworkId}`);
  const pricing = pricingSnap.data() as ArtworkPricingDoc;

  const rates = await requireActiveRates(db);

  // Only a live piece can leave for a gallery; someone else's hold wins.
  const artworkStatus = await latestStatusOf(db, artworkId);
  if (artworkStatus !== "marketplace") throw new AggregatorFlowError("This artwork is no longer available to reserve");
  const activeSnap = await db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).where("status", "==", "reserved").limit(1).get();
  if (!activeSnap.empty) throw new AggregatorFlowError("Another gallery has already reserved this artwork");

  const priorSnap = await db.collection(Collections.aggregatorHoldings).where("artworkId", "==", artworkId).orderBy("assignedAt").get();
  const priorHoldings = priorSnap.docs.map((d) => d.data() as AggregatorHoldingDoc);

  // A piece that doesn't sell moves on to a DIFFERENT aggregator. The same one
  // can only keep it through an extension GalleryZone approves (holding-lifecycle.ts).
  if (priorHoldings.some((h) => h.aggregatorId === aggregatorId)) {
    throw new AggregatorFlowError("You have already held this artwork. It goes to a different aggregator next.");
  }

  const month = priorHoldings.length + 1;
  const now = new Date();
  const cycleStartedAt = priorHoldings[0]?.assignedAt.toDate() ?? now;
  if (!canPlaceWithAnotherAggregator({ cycleStartedAt: priorHoldings[0]?.assignedAt.toDate() ?? null, placementsSoFar: priorHoldings.length, rates, now: now.getTime() })) {
    throw new AggregatorFlowError("This artwork has no aggregator placement left in its listing period");
  }

  // Only the month-1 aggregator can price above the offer; whether they did
  // decides when the next aggregator's monthly drops start.
  const offerPricePaise = aggregatorOfferPriceOf(pricing.artistPricePaise, month, rates, { appreciated: priorHoldings[0]?.appreciated ?? false });
  let chosenPricePaise = offerPricePaise;
  if (sellingPricePaise !== undefined && sellingPricePaise !== offerPricePaise) {
    if (month > 1) throw new AggregatorFlowError("The selling price is set by GalleryZone after month 1");
    if (sellingPricePaise < offerPricePaise) throw new AggregatorFlowError("The selling price can't go below GalleryZone's offer price");
    chosenPricePaise = sellingPricePaise;
  }
  const appreciated = month === 1 && chosenPricePaise > offerPricePaise;
  const priceWarning = month === 1 && isPriceWarning(chosenPricePaise, offerPricePaise, rates);
  const displayPricePaise = withGst(chosenPricePaise, rates);
  const advance = aggregatorAdvanceForMonth({ month, sellingPrice: chosenPricePaise, artistPrice: pricing.artistPricePaise, rates });
  const window = placementWindow({ cycleStartedAt, assignedAt: now, rates });

  const holdingRef = db.collection(Collections.aggregatorHoldings).doc();
  const doc: AggregatorHoldingDoc = {
    artworkId,
    aggregatorId,
    cycleMonth: month,
    advancePercent: Math.round(advance.rate * 100),
    advanceAmountPaise: advance.advance,
    deliveryDepositPaise: advance.deliveryCharge,
    displayPricePaise,
    sellingPricePaise: chosenPricePaise,
    appreciated,
    priceWarning,
    assignmentSource: "self_reserved",
    assignedAt: Timestamp.fromDate(now),
    expiresAt: Timestamp.fromDate(window.expiresAt),
    windowExtended: window.extended,
    status: "reserved",
    returnedAt: null,
  };

  // The advance and the delivery deposit are set aside from the aggregator's
  // wallet (client, 30 Sep 2026: money comes in by Razorpay top-up). The funds
  // check, the hold and the holding itself commit in ONE transaction, so a
  // reservation can never exist without its money, or take money twice.
  await postLedgerEntries(db, {
    postings: async (tx) => {
      const { balancePaise } = await getWalletBalance(db, "aggregator_payable", aggregatorId, tx);
      if (balancePaise < advance.payable) {
        throw new AggregatorFlowError(`Your wallet needs ${inr(advance.payable)} free to reserve this piece and has ${inr(Math.max(0, balancePaise))}. Add funds in Earnings & Wallet.`);
      }
      return aggregatorHoldPostings({ aggregatorId, advancePaise: advance.advance, deliveryPaise: advance.deliveryCharge });
    },
    idempotencyPrefix: `holding:${holdingRef.id}:hold`,
    relatedHoldingId: holdingRef.id,
    alsoInTransaction: (tx) => tx.create(holdingRef, doc),
  });

  artworkStateMachine.assertTransition("marketplace", "with_aggregator");
  await appendArtworkStatus(db, artworkId, { status: "with_aggregator", changedBy: aggregatorId, reason: `holding:${holdingRef.id}` });
  await refreshListing(db, artworkId, rates);

  return {
    holdingId: holdingRef.id,
    advanceAmountPaise: advance.advance,
    displayPricePaise,
    sellingPricePaise: chosenPricePaise,
    offerSellingPricePaise: offerPricePaise,
    priceWarning,
    expiresAt: window.expiresAt,
  };
}

export interface RecordSaleInput {
  db: Firestore;
  holdingId: string;
  soldPricePaise: number;
  buyerName: string;
  buyerEmail: string;
  buyerPhone?: string | undefined;
  deliveryAddress?: string | undefined;
  deliveryMode: "courier" | "self_pickup";
  paymentRoute: "direct_to_galleryzone" | "cash_at_premises";
}

export async function recordAggregatorSale(input: RecordSaleInput): Promise<{ saleId: string; transactionId: string }> {
  const { db, holdingId } = input;
  const holdingRef = db.collection(Collections.aggregatorHoldings).doc(holdingId);
  const holdingSnap = await holdingRef.get();
  if (!holdingSnap.exists) throw new AggregatorFlowError(`No holding ${holdingId}`);
  const holding = holdingSnap.data() as AggregatorHoldingDoc;
  holdingStateMachine.assertTransition(holding.status, "sold_pending_settlement");

  // soldPricePaise was recorded as given while every posting below settles on
  // holding.displayPricePaise, so the sale record and the ledger could
  // disagree about what the piece went for — and for a cash_at_premises sale
  // the remittance owed to GalleryZone is chased against that record. The
  // display price is the agreed selling price, fixed when the aggregator
  // reserved, so any other figure here is a mistake.
  if (input.soldPricePaise !== holding.displayPricePaise) {
    throw new AggregatorFlowError(`A sale must be recorded at the piece's selling price (${holding.displayPricePaise} paise).`);
  }

  const pricingSnap = await db.collection(artworkPricingCol(holding.artworkId)).doc("data").get();
  if (!pricingSnap.exists) throw new AggregatorFlowError(`No artwork ${holding.artworkId}`);
  const pricing = pricingSnap.data() as ArtworkPricingDoc;

  const rates = await requireActiveRates(db);

  const buildPostings = (tdsApplies: boolean) =>
    aggregatorSalePostings({
      artistId: pricing.artistId,
      aggregatorId: holding.aggregatorId,
      displayPricePaise: holding.displayPricePaise,
      artistPricePaise: pricing.artistPricePaise,
      // What was set aside from the wallet at reservation comes back on a sale.
      heldPaise: holding.advanceAmountPaise + (holding.deliveryDepositPaise ?? 0),
      rates,
      tdsApplies,
      // The delivery leg the aggregator was actually charged at reservation is
      // what comes off the artist, not the flat fallback.
      ...(holding.deliveryDepositPaise === null ? {} : { deliveryChargePaise: holding.deliveryDepositPaise }),
    });

  const saleRef = db.collection(Collections.aggregatorSales).doc();
  const soldAt = new Date();
  const saleDoc: AggregatorSaleDoc = {
    holdingId,
    artworkId: holding.artworkId,
    soldPricePaise: input.soldPricePaise,
    buyerName: input.buyerName,
    buyerEmail: input.buyerEmail,
    buyerPhone: input.buyerPhone ?? null,
    deliveryAddress: input.deliveryAddress ?? null,
    deliveryMode: input.deliveryMode,
    paymentRoute: input.paymentRoute,
    remittedAt: null,
    // Cash is GalleryZone's money: the full price is due within two days.
    remitDueAt: input.paymentRoute === "cash_at_premises" ? Timestamp.fromDate(cashRemittanceDueAt(soldAt)) : null,
    remittedVia: null,
    shipmentStatus: "preparing",
    dispatchedAt: null,
    deliveredAt: null,
    courierRef: null,
    soldAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
  };
  await saleRef.set(saleDoc);

  // TDS depends on what the artist has already sold this financial year, so it
  // is decided inside the same transaction that posts the ledger entries.
  const { transactionId } = await postArtistSale(db, {
    artistId: pricing.artistId,
    artistPricePaise: pricing.artistPricePaise,
    channel: "aggregator",
    rates,
    saleKey: `holding:${holdingId}`,
    holdingId,
    build: buildPostings,
  });

  await holdingRef.update({ status: "sold_pending_settlement" });
  const artworkStatus = await latestStatusOf(db, holding.artworkId);
  if (artworkStatus === "with_aggregator") {
    await appendArtworkStatus(db, holding.artworkId, { status: "sold", changedBy: holding.aggregatorId, reason: `sale:${saleRef.id}` });
    await refreshListing(db, holding.artworkId, rates);
  }

  return { saleId: saleRef.id, transactionId };
}
