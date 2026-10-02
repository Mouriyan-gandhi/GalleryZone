// Admin's all-artworks view + rarity ranking + delisting — Firestore
// version. The admin view legitimately includes artistPricePaise (plan.md
// §8: admin is one of the parties allowed to see it) — read from the
// pricing subcollection, same place firestore.rules gates it.

import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { artworkStateMachine } from "@galleryzone/domain";
import { appendArtworkStatus } from "./listing-projection.ts";
import {
  Collections,
  artworkPricingCol,
  artworkStatusEventsCol,
  type ArtworkDoc,
  type ArtworkPricingDoc,
  type ArtworkRarity,
  type ArtworkStatusEventDoc,
  type AuditLogDoc,
  artworkRarityValues,
} from "./collections.ts";
import { DbError } from "./errors.ts";

export class AdminArtworkError extends DbError {}

export interface AdminArtworkRow {
  id: string;
  productCode: string;
  artistId: string;
  title: string;
  category: string;
  artistPricePaise: number;
  rarityType: ArtworkRarity | null;
  status: string;
}

/** Every artwork carries a rank the admin chose, so a rank can be changed but never cleared. */
export async function setArtworkRarity(db: Firestore, artworkId: string, rarity: ArtworkRarity, adminId: string): Promise<void> {
  if (!(artworkRarityValues as readonly string[]).includes(rarity)) throw new AdminArtworkError(`Invalid rarity ${rarity}`);
  const ref = db.collection(Collections.artworks).doc(artworkId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new AdminArtworkError(`No artwork ${artworkId}`);
    tx.update(ref, { rarityType: rarity });
    const auditDoc: AuditLogDoc = {
      adminId,
      action: "artwork.rarity_set",
      entityType: "artwork",
      entityId: artworkId,
      entityLabel: null,
      detail: { rarity },
      createdAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
    };
    tx.set(db.collection(Collections.auditLog).doc(), auditDoc);
  });
}

export async function delistArtwork(db: Firestore, artworkId: string, adminId: string): Promise<void> {
  const eventSnap = await db.collection(artworkStatusEventsCol(artworkId)).orderBy("changedAt", "desc").limit(1).get();
  const current = (eventSnap.docs[0]?.data() as ArtworkStatusEventDoc | undefined)?.status ?? "draft";
  artworkStateMachine.assertTransition(current, "returned");

  await appendArtworkStatus(db, artworkId, { status: "returned", changedBy: adminId, reason: "Delisted by admin" });
  await db.runTransaction(async (tx) => {
    tx.set(db.collection(Collections.auditLog).doc(), {
      adminId,
      action: "artwork.delisted",
      entityType: "artwork",
      entityId: artworkId,
      entityLabel: null,
      detail: null,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
}

export async function getAuditLog(db: Firestore, limit = 100): Promise<(AuditLogDoc & { id: string })[]> {
  const snap = await db.collection(Collections.auditLog).orderBy("createdAt", "desc").limit(limit).get();
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as AuditLogDoc) }));
}
