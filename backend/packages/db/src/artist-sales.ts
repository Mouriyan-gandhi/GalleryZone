// An artist's sales in the financial year, for §194-O TDS: withheld only once
// the year's sales pass ₹5 lakh (client, 30 Sep 2026), so every sale needs to
// know what came before it.
//
// The decision and the write have to agree, and two sales for one artist can
// land at once (a marketplace order and an aggregator sale). So the year's
// total is read INSIDE the same Firestore transaction that posts the sale's
// ledger entries and creates its ArtistSaleDoc: a second sale that read the
// same total makes the transaction retry, and sees the first one the second
// time. The sale record's id is the sale's idempotency key, so a replayed
// webhook can neither post twice nor count twice.
//
// The total is a query over the artist's sales for the year, not a stored
// counter: nothing to keep in step, and an artist has tens of sales a year.
// The query is two equality filters, which Firestore serves without a
// composite index.

import { Timestamp, type Firestore, type Transaction } from "firebase-admin/firestore";
import { financialYearStart, tdsAppliesOnSale, type PricingRates, type Posting } from "@galleryzone/domain";
import { Collections, type ArtistSaleDoc } from "./collections.ts";
import { postLedgerEntries } from "./ledger-repository.ts";

/** "2026-27" for any moment from 1 April 2026 to 31 March 2027, India time. */
export function financialYearKey(asOf: Date): string {
  const start = new Date(financialYearStart(asOf).getTime() + 330 * 60_000); // back to IST wall clock
  const year = start.getUTCFullYear();
  return `${year}-${String((year + 1) % 100).padStart(2, "0")}`;
}

const salesInYear = (db: Firestore, artistId: string, fyKey: string) =>
  db.collection(Collections.artistSales).where("artistId", "==", artistId).where("fyKey", "==", fyKey);

const totalOf = (docs: { data(): unknown }[]) => docs.reduce((sum, d) => sum + (d.data() as ArtistSaleDoc).artistPricePaise, 0);

/** The artist's sales so far this financial year, for an estimate. Not for deciding a real sale: see postArtistSale. */
export async function artistSalesSoFar(db: Firestore, artistId: string, asOf: Date = new Date()): Promise<number> {
  if (!artistId) return 0;
  return totalOf((await salesInYear(db, artistId, financialYearKey(asOf)).get()).docs);
}

export interface PostArtistSaleInput {
  artistId: string;
  artistPricePaise: number;
  channel: ArtistSaleDoc["channel"];
  rates: PricingRates;
  /** Unique per sale, and the sale record's id: `order:<id>` or `holding:<id>`. */
  saleKey: string;
  orderId?: string;
  holdingId?: string;
  /** The postings for this sale, given whether TDS is withheld from it. */
  build: (tdsApplies: boolean) => Posting[];
  now?: Date;
}

export interface PostedArtistSale {
  transactionId: string;
  tdsApplies: boolean;
  tdsPaise: number;
  /** What the sale credited to the artist's payable. */
  netPaise: number;
}

export async function postArtistSale(db: Firestore, input: PostArtistSaleInput): Promise<PostedArtistSale> {
  const now = input.now ?? new Date();
  const fyKey = financialYearKey(now);
  let outcome = { tdsApplies: false, tdsPaise: 0, netPaise: 0 };

  const { transactionId } = await postLedgerEntries(db, {
    postings: async (tx: Transaction) => {
      const soFar = totalOf((await tx.get(salesInYear(db, input.artistId, fyKey))).docs);
      const tdsApplies = tdsAppliesOnSale(soFar, input.artistPricePaise, input.rates);
      const postings = input.build(tdsApplies);
      // Read back from what is being posted, so the record can't drift from the ledger.
      const amountOf = (accountType: Posting["accountType"], ownerId?: string) =>
        -(postings.find((p) => p.accountType === accountType && p.ownerId === ownerId)?.amountPaise ?? 0);
      outcome = { tdsApplies, tdsPaise: amountOf("tds_payable"), netPaise: amountOf("artist_payable", input.artistId) };
      return postings;
    },
    idempotencyPrefix: input.saleKey,
    ...(input.orderId ? { relatedOrderId: input.orderId } : {}),
    ...(input.holdingId ? { relatedHoldingId: input.holdingId } : {}),
    alsoInTransaction: (tx) => {
      const doc: ArtistSaleDoc = {
        artistId: input.artistId,
        fyKey,
        channel: input.channel,
        artistPricePaise: input.artistPricePaise,
        tdsPaise: outcome.tdsPaise,
        netPaise: outcome.netPaise,
        orderId: input.orderId ?? null,
        holdingId: input.holdingId ?? null,
        soldAt: Timestamp.fromDate(now),
      };
      tx.create(db.collection(Collections.artistSales).doc(input.saleKey), doc);
    },
  });

  return { transactionId, ...outcome };
}

/** The recorded outcome of a sale, or null for one made before sales were recorded. */
export async function getArtistSale(db: Firestore, saleKey: string): Promise<ArtistSaleDoc | null> {
  const snap = await db.collection(Collections.artistSales).doc(saleKey).get();
  return snap.exists ? (snap.data() as ArtistSaleDoc) : null;
}

/** Every recorded sale by this artist, keyed by order id, for the artist's order list. */
export async function artistSalesByOrder(db: Firestore, artistId: string): Promise<Map<string, ArtistSaleDoc>> {
  const snap = await db.collection(Collections.artistSales).where("artistId", "==", artistId).get();
  const byOrder = new Map<string, ArtistSaleDoc>();
  for (const d of snap.docs) {
    const sale = d.data() as ArtistSaleDoc;
    if (sale.orderId) byOrder.set(sale.orderId, sale);
  }
  return byOrder;
}
