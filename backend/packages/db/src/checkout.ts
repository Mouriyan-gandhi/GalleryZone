// Marketplace checkout orchestration — Firestore version. Two steps:
// createOrder() records intent at "pending" with nothing captured yet;
// markOrderPaid() moves it to "paid", posts the ledger entries, passes
// title to the buyer and takes the piece off the marketplace. Who calls
// markOrderPaid depends on PAYMENTS_MODE: the Razorpay webhook / checkout
// verification (payments.controller.ts) in production, or the customer's
// own simulate-payment call in simulated mode. Idempotent on the order.

import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import {
  checkoutTotal,
  displayPriceOf,
  gstIncludedIn,
  marketplaceCheckoutPostings,
  orderStateMachine,
  artworkStateMachine,
  type PricingRates, artistSettlementOf } from "@galleryzone/domain";
import { FirestoreRateConfigStore } from "./firestore-rate-config-store.ts";
import { getArtistSale, postArtistSale } from "./artist-sales.ts";
import { Collections, artworkPricingCol, orderStatusEventsCol, type ArtworkPricingDoc, type OrderDoc, type PaymentDoc } from "./collections.ts";
import { appendArtworkStatus, latestStatusOf } from "./listing-projection.ts";
import { recordSaleTransfer } from "./ownership.ts";
import { DbError } from "./errors.ts";

export class CheckoutError extends DbError {}

export interface CreateOrderInput {
  db: Firestore;
  customerId: string;
  artworkId: string;
  addressId: string;
  idempotencyKey: string;
}

export interface CreateOrderResult {
  orderId: string;
  totalPaise: number;
}

export async function createOrder({ db, customerId, artworkId, addressId, idempotencyKey }: CreateOrderInput): Promise<CreateOrderResult> {
  const pricingSnap = await db.collection(artworkPricingCol(artworkId)).doc("data").get();
  if (!pricingSnap.exists) throw new CheckoutError(`No artwork ${artworkId}`);
  const pricing = pricingSnap.data() as ArtworkPricingDoc;

  // Both of these used to be taken on trust, which meant an order could be
  // opened — and, in razorpay mode, actually paid — for a piece that was
  // never for sale. markOrderPaid would then throw on the marketplace ->
  // sold transition, AFTER the card was charged. Refusing here, before any
  // money moves, is the only safe place for it. It also stops two buyers
  // holding pending orders on the same one-of-a-kind original.
  const artworkStatus = await latestStatusOf(db, artworkId);
  if (artworkStatus !== "marketplace") {
    throw new CheckoutError("This artwork is not available to buy");
  }

  // An addressId belonging to somebody else would ship the piece to a
  // stranger and leak their address onto this order.
  const addressSnap = await db.collection(Collections.addresses).doc(addressId).get();
  if (!addressSnap.exists || (addressSnap.data() as { userId?: string }).userId !== customerId) {
    throw new CheckoutError(`No address ${addressId}`);
  }

  const rateStore = new FirestoreRateConfigStore(db);
  const activeVersion = await rateStore.getActiveVersion(new Date());
  if (!activeVersion) {
    throw new CheckoutError(
      "No approved rate_config_versions row exists yet — seed one via the admin rules console before checkout can run.",
    );
  }
  const rates: PricingRates = activeVersion.rates;

  const displayPrice = displayPriceOf(pricing.artistPricePaise, rates);
  const checkout = checkoutTotal(displayPrice, rates);
  const gstPaise = gstIncludedIn(displayPrice, rates);

  const orderRef = db.collection(Collections.orders).doc();
  const orderDoc: OrderDoc = {
    artworkId,
    customerId,
    addressId,
    displayPricePaise: checkout.displayPrice,
    gstPaise,
    deliveryChargePaise: checkout.deliveryCharge,
    convenienceFeePaise: checkout.convenienceFee,
    convenienceGstPaise: checkout.convenienceGst,
    totalPaise: checkout.total,
    status: "pending",
    rateConfigVersionId: activeVersion.id,
    createdAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
  };
  await orderRef.set(orderDoc);
  await db.collection(orderStatusEventsCol(orderRef.id)).add({ status: "pending", changedAt: FieldValue.serverTimestamp() });

  const paymentDoc: PaymentDoc = {
    orderId: orderRef.id,
    provider: "razorpay",
    providerPaymentId: null,
    method: "simulated",
    amountPaise: checkout.total,
    idempotencyKey,
    status: "pending",
    rawWebhookPayload: null,
    createdAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
  };
  // idempotencyKey as the doc ID, same pattern as ledger-repository.ts —
  // a retried checkout request with the same key fails loudly instead of
  // creating a second payment record.
  await db.collection(Collections.payments).doc(idempotencyKey).create(paymentDoc);

  return { orderId: orderRef.id, totalPaise: checkout.total };
}

export interface PaymentCapture {
  method: string;
  providerPaymentId: string | null;
  rawWebhookPayload?: unknown;
}

export interface PaymentConfirmation {
  transactionId: string;
  orderId: string;
  customerId: string;
  artistId: string;
  artworkId: string;
  artworkTitle: string;
  totalPaise: number;
  artistNetPaise: number;
}

/** Simulated capture — only reachable while PAYMENTS_MODE=simulated (orders.controller.ts gates it). */
export function confirmSimulatedPayment(db: Firestore, orderId: string): Promise<PaymentConfirmation> {
  return markOrderPaid(db, orderId, { method: "simulated", providerPaymentId: null });
}

/** Records the gateway's order id against our payment doc so a webhook can find the order. */
export async function attachProviderOrder(db: Firestore, orderId: string, providerOrderId: string): Promise<void> {
  const snap = await db.collection(Collections.payments).where("orderId", "==", orderId).limit(1).get();
  if (snap.empty) throw new CheckoutError(`No payment record for order ${orderId}`);
  await snap.docs[0]!.ref.update({ providerOrderId });
}

export async function orderIdForProviderOrder(db: Firestore, providerOrderId: string): Promise<string | null> {
  const snap = await db.collection(Collections.payments).where("providerOrderId", "==", providerOrderId).limit(1).get();
  return snap.empty ? null : (snap.docs[0]!.data() as PaymentDoc).orderId;
}

export async function markPaymentFailed(db: Firestore, orderId: string, detail: { providerPaymentId: string | null; rawWebhookPayload: unknown }): Promise<void> {
  const snap = await db.collection(Collections.payments).where("orderId", "==", orderId).limit(1).get();
  if (snap.empty) return;
  const payment = snap.docs[0]!.data() as PaymentDoc;
  // A failed attempt never overwrites a capture that already happened.
  if (payment.status === "captured") return;
  await snap.docs[0]!.ref.update({ status: "failed", providerPaymentId: detail.providerPaymentId, rawWebhookPayload: detail.rawWebhookPayload ?? null });
}

/**
 * The one place an order becomes paid. Idempotent: a second call for an
 * already-paid order (webhook after checkout verification, or a retried
 * webhook) returns the same confirmation without posting anything twice —
 * the ledger's idempotencyPrefix and the state machine both guard it.
 */
export async function markOrderPaid(db: Firestore, orderId: string, capture: PaymentCapture): Promise<PaymentConfirmation> {
  const orderRef = db.collection(Collections.orders).doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw new CheckoutError(`No order ${orderId}`);
  const order = orderSnap.data() as OrderDoc;

  if (order.status !== "pending") {
    if (order.status === "cancelled") throw new CheckoutError(`Order ${orderId} was cancelled`);
    return confirmationFor(db, orderId, order, null);
  }
  orderStateMachine.assertTransition(order.status, "paid");

  const pricingSnap = await db.collection(artworkPricingCol(order.artworkId)).doc("data").get();
  if (!pricingSnap.exists) throw new CheckoutError(`No artwork ${order.artworkId}`);
  const pricing = pricingSnap.data() as ArtworkPricingDoc;

  const rateStore = new FirestoreRateConfigStore(db);
  const version = await rateStore.getActiveVersion(order.createdAt.toDate());
  if (!version) throw new CheckoutError("Order references a rate_config_version that is no longer resolvable");

  // TDS depends on what the artist has already sold this financial year, so
  // it is decided inside the same transaction that posts the ledger entries.
  const { transactionId } = await postArtistSale(db, {
    artistId: pricing.artistId,
    artistPricePaise: pricing.artistPricePaise,
    channel: "marketplace",
    rates: version.rates,
    saleKey: `order:${orderId}`,
    orderId,
    build: (tdsApplies) =>
      marketplaceCheckoutPostings({ artistId: pricing.artistId, artistPricePaise: pricing.artistPricePaise, rates: version.rates, tdsApplies }),
  });

  await orderRef.update({ status: "paid" });
  await db.collection(orderStatusEventsCol(orderId)).add({ status: "paid", changedAt: FieldValue.serverTimestamp() });

  // Title passes on payment (user decision 2026-09-13; plan.md §3.2 said
  // delivery). Idempotent on orderId. The artwork leaves the marketplace
  // at the same moment — a one-of-a-kind original can't be bought twice.
  await recordSaleTransfer(db, { artworkId: order.artworkId, orderId, buyerId: order.customerId });
  const artworkStatus = await latestStatusOf(db, order.artworkId);
  if (artworkStatus !== "sold") {
    artworkStateMachine.assertTransition(artworkStatus, "sold");
    await appendArtworkStatus(db, order.artworkId, { status: "sold", changedBy: null, reason: `order:${orderId}` });
  }
  // The inner update() used to be left unawaited inside the .then(), so this
  // function could return — and the "paid" email go out — before the payment
  // doc was marked captured. A webhook arriving in that window would see a
  // pending capture and could mark it failed.
  const paymentSnap = await db.collection(Collections.payments).where("orderId", "==", orderId).limit(1).get();
  if (!paymentSnap.empty) {
    await paymentSnap.docs[0]!.ref.update({
      status: "captured",
      method: capture.method,
      providerPaymentId: capture.providerPaymentId,
      rawWebhookPayload: capture.rawWebhookPayload ?? null,
    });
  }

  return confirmationFor(db, orderId, order, transactionId);
}

async function confirmationFor(db: Firestore, orderId: string, order: OrderDoc, transactionId: string | null): Promise<PaymentConfirmation> {
  const [artworkSnap, pricingSnap] = await Promise.all([
    db.collection(Collections.artworks).doc(order.artworkId).get(),
    db.collection(artworkPricingCol(order.artworkId)).doc("data").get(),
  ]);
  const pricing = pricingSnap.data() as ArtworkPricingDoc | undefined;
  const rateStore = new FirestoreRateConfigStore(db);
  const version = await rateStore.getActiveVersion(order.createdAt.toDate());
  const artworkTitle = (artworkSnap.data() as { title?: string } | undefined)?.title ?? "your artwork";
  // What was actually paid out is on the sale record. An order paid before
  // sales were recorded has none; it falls back to the artist's price, which
  // the old rules only ever moved by 0.1% TDS.
  const sale = await getArtistSale(db, `order:${orderId}`);
  return {
    transactionId: transactionId ?? `order:${orderId}`,
    orderId,
    customerId: order.customerId,
    artistId: pricing?.artistId ?? "",
    artworkId: order.artworkId,
    artworkTitle,
    totalPaise: order.totalPaise,
    artistNetPaise: sale?.netPaise ?? (pricing && version ? artistSettlementOf(pricing.artistPricePaise, "marketplace", version.rates).net : 0),
  };
}
