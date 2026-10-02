// Aggregator's own sales/shipment/remittance management — Firestore version.

import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { cashRemittanceFromWalletPostings, shipmentStateMachine, type ShipmentStatus } from "@galleryzone/domain";
import { Collections, type AggregatorHoldingDoc, type AggregatorSaleDoc, type ArtworkDoc } from "./collections.ts";
import { isAlreadyExists, postLedgerEntries } from "./ledger-repository.ts";
import { getWalletBalance } from "./wallets.ts";
import { assertNfcDispatchAllowed } from "./nfc.ts";
import { DbError } from "./errors.ts";

export class AggregatorSalesError extends DbError {}

// aggregatorSales doesn't carry aggregatorId directly (it's on the parent
// holding) — resolve via the holdings the aggregator owns first, same
// "join" the Postgres version did with an INNER JOIN, done here as two
// queries since Firestore has no cross-collection join.
async function holdingIdsFor(db: Firestore, aggregatorId: string): Promise<string[]> {
  const snap = await db.collection(Collections.aggregatorHoldings).where("aggregatorId", "==", aggregatorId).get();
  return snap.docs.map((d) => d.id);
}

/** A sale with the tag state of its piece, so the shipping list can say "lock the tag before you dispatch" (§4.7, §5.2b). */
export type AggregatorSaleRow = AggregatorSaleDoc & { id: string; nfcLocked: boolean; nfcGateOverridden: boolean };

export async function listAggregatorSales(db: Firestore, aggregatorId: string): Promise<AggregatorSaleRow[]> {
  const holdingIds = await holdingIdsFor(db, aggregatorId);
  if (holdingIds.length === 0) return [];
  // Firestore's `in` operator caps at 30 values, so the holdings are queried
  // in chunks of 30 and merged. An aggregator past their 30th holding used to
  // silently lose every sale after it.
  const chunks: string[][] = [];
  for (let i = 0; i < holdingIds.length; i += 30) chunks.push(holdingIds.slice(i, i + 30));
  const snaps = await Promise.all(
    chunks.map((chunk) => db.collection(Collections.aggregatorSales).where("holdingId", "in", chunk).get()),
  );
  const sales = snaps.flatMap((snap) => snap.docs.map((d) => ({ id: d.id, ...(d.data() as AggregatorSaleDoc) })));
  const artworkIds = [...new Set(sales.map((s) => s.artworkId))];
  const artworks = artworkIds.length ? await db.getAll(...artworkIds.map((id) => db.collection(Collections.artworks).doc(id))) : [];
  const byId = new Map(artworks.map((a) => [a.id, a.data() as ArtworkDoc | undefined]));
  return sales.map((s) => ({ ...s, nfcLocked: Boolean(byId.get(s.artworkId)?.nfcLockedAt), nfcGateOverridden: Boolean(byId.get(s.artworkId)?.nfcShipmentGateOverrideAt) }));
}

// A sale is owned by whoever owns its parent holding. Every mutation resolves
// that here rather than trusting the caller, so a sale id from another
// aggregator can't be advanced or marked remitted.
async function ownedSale(db: Firestore, saleId: string, aggregatorId: string): Promise<AggregatorSaleDoc> {
  const snap = await db.collection(Collections.aggregatorSales).doc(saleId).get();
  if (!snap.exists) throw new AggregatorSalesError(`No sale ${saleId}`);
  const sale = snap.data() as AggregatorSaleDoc;
  const holding = (await db.collection(Collections.aggregatorHoldings).doc(sale.holdingId).get()).data() as
    | AggregatorHoldingDoc
    | undefined;
  // Same message as a missing sale: a stranger must not learn that the id is real.
  if (!holding || holding.aggregatorId !== aggregatorId) throw new AggregatorSalesError(`No sale ${saleId}`);
  return sale;
}

export async function advanceShipment(db: Firestore, aggregatorId: string, saleId: string, to: ShipmentStatus, courierRef?: string): Promise<void> {
  const sale = await ownedSale(db, saleId, aggregatorId);
  const ref = db.collection(Collections.aggregatorSales).doc(saleId);
  shipmentStateMachine.assertTransition(sale.shipmentStatus, to);
  // The piece reached the gallery locked, so this is normally a sanity check (NFC_IMPLEMENTATION.md §5.2b).
  if (to === "dispatched") await assertNfcDispatchAllowed(db, sale.artworkId, { channel: "aggregator", refId: saleId });

  const timestampField = to === "dispatched" ? "dispatchedAt" : "deliveredAt";
  await ref.update({ shipmentStatus: to, courierRef: courierRef ?? null, [timestampField]: FieldValue.serverTimestamp() });
}

const inr = (paise: number) => `₹${(paise / 100).toLocaleString("en-IN")}`;

/**
 * Pays in a cash sale's FULL price to GalleryZone — never netted against commission
 * (client, 30 Sep 2026: within 2 days, "in portal in wallet or bank").
 *  - "wallet": taken from the aggregator's free wallet balance, checked and posted in one
 *    transaction with the sale's status, so it can neither overdraw nor happen twice.
 *  - "bank": the aggregator says they transferred to GalleryZone's bank account.
 *    ponytail: a bank transfer is taken on their word; add an admin "received" step if that ever bites.
 */
export async function markRemitted(db: Firestore, aggregatorId: string, saleId: string, via: "wallet" | "bank" = "bank"): Promise<void> {
  const sale = await ownedSale(db, saleId, aggregatorId);
  const ref = db.collection(Collections.aggregatorSales).doc(saleId);
  if (sale.paymentRoute !== "cash_at_premises") throw new AggregatorSalesError("Only cash_at_premises sales require remittance");
  if (sale.remittedAt) throw new AggregatorSalesError(`Sale ${saleId} was already marked remitted`);

  if (via === "bank") {
    await ref.update({ remittedAt: FieldValue.serverTimestamp(), remittedVia: "bank" });
    return;
  }

  try {
    await postLedgerEntries(db, {
      postings: async (tx) => {
        const { balancePaise } = await getWalletBalance(db, "aggregator_payable", aggregatorId, tx);
        if (balancePaise < sale.soldPricePaise) {
          const short = sale.soldPricePaise - Math.max(0, balancePaise);
          throw new AggregatorSalesError(`Your wallet has ${inr(Math.max(0, balancePaise))} free and this sale is ${inr(sale.soldPricePaise)}. Add ${inr(short)} to your wallet, then pay it in.`);
        }
        return cashRemittanceFromWalletPostings({ aggregatorId, amountPaise: sale.soldPricePaise });
      },
      idempotencyPrefix: `remit:${saleId}`,
      relatedHoldingId: sale.holdingId,
      alsoInTransaction: (tx) => tx.update(ref, { remittedAt: FieldValue.serverTimestamp(), remittedVia: "wallet" }),
    });
  } catch (error) {
    // A second request for the same sale: the first one already paid it in.
    if (!isAlreadyExists(error)) throw error;
    throw new AggregatorSalesError(`Sale ${saleId} was already marked remitted`);
  }
}

export async function listRemittancesDue(db: Firestore, aggregatorId: string): Promise<AggregatorSaleRow[]> {
  const sales = await listAggregatorSales(db, aggregatorId);
  return sales.filter((sale) => sale.paymentRoute === "cash_at_premises" && !sale.remittedAt);
}
