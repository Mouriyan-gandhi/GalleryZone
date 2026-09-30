// Wallet balance reads — Firestore version. Same sign-flip convention as
// withdrawals.ts's currentBalance() (kept as a separate, tiny
// implementation here rather than importing that one, since this module
// intentionally has no other dependency on withdrawals.ts).

import type { Firestore, Query, Transaction } from "firebase-admin/firestore";
import { Collections, type LedgerEntryDoc } from "./collections.ts";

export type WalletAccountType = "artist_payable" | "aggregator_payable" | "aggregator_held" | "customer_wallet";

export interface WalletBalance {
  accountType: WalletAccountType;
  balancePaise: number;
}

/** Pass `tx` to read inside a transaction, so a decision made on the balance and the write that follows see the same money. */
export async function getWalletBalance(db: Firestore, accountType: WalletAccountType, ownerId: string, tx?: Transaction): Promise<WalletBalance> {
  const read = (query: Query) => (tx ? tx.get(query) : query.get());
  const accountSnap = await read(db.collection(Collections.ledgerAccounts).where("type", "==", accountType).where("ownerId", "==", ownerId).limit(1));
  if (accountSnap.empty) return { accountType, balancePaise: 0 };
  const accountId = accountSnap.docs[0]!.id;

  const entriesSnap = await read(db.collection(Collections.ledgerEntries).where("accountId", "==", accountId));
  const sum = entriesSnap.docs.reduce((total, doc) => total + (doc.data() as LedgerEntryDoc).amountPaise, 0);
  return { accountType, balancePaise: -sum || 0 };
}

export interface WalletTransaction {
  id: string;
  amountPaise: number;
  reason: string;
  /** The reservation this entry belongs to, when it does. */
  relatedHoldingId: string | null;
  createdAt: Date;
}

export async function listWalletTransactions(db: Firestore, accountType: WalletAccountType, ownerId: string): Promise<WalletTransaction[]> {
  const accountSnap = await db.collection(Collections.ledgerAccounts).where("type", "==", accountType).where("ownerId", "==", ownerId).limit(1).get();
  if (accountSnap.empty) return [];
  const accountId = accountSnap.docs[0]!.id;

  // Sorted in memory: where(accountId) + orderBy(createdAt) needs a composite
  // index that is declared but not created in production, so this query would
  // have thrown FAILED_PRECONDITION and 500'd the wallet page for the first
  // artist to actually have transactions. It reads clean today only because
  // an account with no entries returns above. One account's entries is a
  // small read; the page must not wait on an index deploy.
  const entriesSnap = await db.collection(Collections.ledgerEntries).where("accountId", "==", accountId).get();
  return entriesSnap.docs
    .map((doc) => {
      const data = doc.data() as LedgerEntryDoc;
      return { id: doc.id, amountPaise: -data.amountPaise, reason: data.reason, relatedHoldingId: data.relatedHoldingId ?? null, createdAt: data.createdAt?.toDate() ?? new Date(0) };
    })
    .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
}
