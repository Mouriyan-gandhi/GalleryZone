// Aggregator wallet top-ups. Client, 30 Sep 2026: money goes in "from his bank
// account like Razorpay". A top-up is our record of one Razorpay order: created
// pending, credited to the wallet exactly once when the payment is captured.
//
// Both the checkout callback and Razorpay's webhook can report the same
// payment, so markTopupPaid is idempotent: the ledger entries are keyed on the
// top-up id (a replayed post throws ALREADY_EXISTS) and the status flips in the
// same transaction as the credit. The amount credited is always the amount we
// recorded when the order was created, never a figure sent back by the browser.

import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { WALLET_TOPUP_MAX_PAISE, WALLET_TOPUP_MIN_PAISE, walletTopupPostings } from "@galleryzone/domain";
import { Collections, type WalletTopupDoc } from "./collections.ts";
import { isAlreadyExists, postLedgerEntries } from "./ledger-repository.ts";
import { DbError } from "./errors.ts";

export class WalletTopupError extends DbError {}

export type WalletTopup = WalletTopupDoc & { id: string };

export async function createWalletTopup(db: Firestore, input: { userId: string; amountPaise: number }): Promise<{ topupId: string }> {
  if (!Number.isInteger(input.amountPaise) || input.amountPaise < WALLET_TOPUP_MIN_PAISE || input.amountPaise > WALLET_TOPUP_MAX_PAISE) {
    throw new WalletTopupError(`A top-up must be between ₹${WALLET_TOPUP_MIN_PAISE / 100} and ₹${WALLET_TOPUP_MAX_PAISE / 100}`);
  }
  const ref = db.collection(Collections.walletTopups).doc();
  const doc: WalletTopupDoc = {
    userId: input.userId,
    amountPaise: input.amountPaise,
    status: "pending",
    providerOrderId: null,
    providerPaymentId: null,
    method: null,
    createdAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
    paidAt: null,
  };
  await ref.set(doc);
  return { topupId: ref.id };
}

export async function getWalletTopup(db: Firestore, topupId: string): Promise<WalletTopup | null> {
  const snap = await db.collection(Collections.walletTopups).doc(topupId).get();
  return snap.exists ? { id: snap.id, ...(snap.data() as WalletTopupDoc) } : null;
}

export async function attachTopupProviderOrder(db: Firestore, topupId: string, providerOrderId: string): Promise<void> {
  await db.collection(Collections.walletTopups).doc(topupId).update({ providerOrderId });
}

export async function topupIdForProviderOrder(db: Firestore, providerOrderId: string): Promise<string | null> {
  const snap = await db.collection(Collections.walletTopups).where("providerOrderId", "==", providerOrderId).limit(1).get();
  return snap.docs[0]?.id ?? null;
}

/** Credits the wallet once. A second report of the same payment changes nothing. */
export async function markTopupPaid(
  db: Firestore,
  topupId: string,
  capture: { method: string; providerPaymentId: string | null },
): Promise<{ userId: string; amountPaise: number; alreadyPaid: boolean }> {
  const ref = db.collection(Collections.walletTopups).doc(topupId);
  const topup = (await ref.get()).data() as WalletTopupDoc | undefined;
  if (!topup) throw new WalletTopupError(`No top-up ${topupId}`);
  if (topup.status === "paid") return { userId: topup.userId, amountPaise: topup.amountPaise, alreadyPaid: true };

  try {
    // A payment that failed once can be retried on the same Razorpay order and
    // succeed, so "failed" is not final: only "paid" is.
    await postLedgerEntries(db, {
      postings: walletTopupPostings({ aggregatorId: topup.userId, amountPaise: topup.amountPaise }),
      idempotencyPrefix: `topup:${topupId}`,
      alsoInTransaction: (tx) => tx.update(ref, { status: "paid", method: capture.method, providerPaymentId: capture.providerPaymentId, paidAt: FieldValue.serverTimestamp() }),
    });
  } catch (error) {
    // The other of the two reports (callback / webhook) got there first.
    if (!isAlreadyExists(error)) throw error;
    return { userId: topup.userId, amountPaise: topup.amountPaise, alreadyPaid: true };
  }
  return { userId: topup.userId, amountPaise: topup.amountPaise, alreadyPaid: false };
}

/** The gateway declined. Nothing was charged and nothing is credited; the aggregator can start again. */
export async function markTopupFailed(db: Firestore, topupId: string, detail: { providerPaymentId: string | null }): Promise<void> {
  const ref = db.collection(Collections.walletTopups).doc(topupId);
  await db.runTransaction(async (tx) => {
    const topup = (await tx.get(ref)).data() as WalletTopupDoc | undefined;
    if (!topup || topup.status !== "pending") return;
    tx.update(ref, { status: "failed", providerPaymentId: detail.providerPaymentId });
  });
}
