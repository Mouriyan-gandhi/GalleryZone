// Admin order detail + fulfillment status transitions — Firestore version.

import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { orderStateMachine, type OrderStatus } from "@galleryzone/domain";
import { Collections, orderStatusEventsCol, type AddressDoc, type OrderDoc } from "./collections.ts";
import { decorate, type OrderView } from "./order-listings.ts";
import { assertNfcDispatchAllowed } from "./nfc.ts";
import { DbError } from "./errors.ts";

export class AdminOrderError extends DbError {}

export async function listOrdersAdmin(db: Firestore): Promise<OrderView[]> {
  const snap = await db.collection(Collections.orders).orderBy("createdAt", "desc").get();
  return Promise.all(snap.docs.map((d) => decorate(db, d.id, d.data() as OrderDoc)));
}

export async function getOrderAdmin(db: Firestore, orderId: string): Promise<OrderView | null> {
  const snap = await db.collection(Collections.orders).doc(orderId).get();
  return snap.exists ? decorate(db, snap.id, snap.data() as OrderDoc) : null;
}

export async function getAddressAdmin(db: Firestore, addressId: string): Promise<(AddressDoc & { id: string }) | null> {
  const snap = await db.collection(Collections.addresses).doc(addressId).get();
  return snap.exists ? { id: snap.id, ...(snap.data() as AddressDoc) } : null;
}

/** Advances real order fulfillment — confirmed→packed→transit→delivered, or cancelled from an early state. */
export async function advanceOrderStatus(db: Firestore, orderId: string, to: OrderStatus): Promise<void> {
  const ref = db.collection(Collections.orders).doc(orderId);
  const snap = await ref.get();
  if (!snap.exists) throw new AdminOrderError(`No order ${orderId}`);
  const order = snap.data() as OrderDoc;
  orderStateMachine.assertTransition(order.status, to);
  // Transit is the point of no return: once the courier has the piece nobody can lock the
  // chip any more, whereas packing still happens at the artist's (NFC_IMPLEMENTATION.md §5.1).
  if (to === "transit") await assertNfcDispatchAllowed(db, order.artworkId, { channel: "marketplace", refId: orderId });

  await db.runTransaction(async (tx) => {
    tx.update(ref, { status: to });
    tx.set(db.collection(orderStatusEventsCol(orderId)).doc(), { status: to, changedAt: FieldValue.serverTimestamp() });
  });
}
