// Which pieces a signed-in person is connected to, for GET /v1/passport/mine.
// Three ways to be connected: you OWN it (the ownership ledger), you MADE it
// (artworks.artistId), or you HOLD it on display (an active aggregator
// holding). The same piece can be several at once, e.g. an artist who
// bought back their own work.
//
// This file only finds the artwork ids. The passport itself is built by the
// API from the same public builder /v1/verify uses, so nothing private can
// ride along.

import type { Firestore } from "firebase-admin/firestore";
import { Collections, type AggregatorHoldingDoc, type ArtworkDoc, type UserRole } from "./collections.ts";
import { listCollection } from "./ownership.ts";

/** Mirrors @galleryzone/contracts' PassportRelation (contracts can't be imported here without a cycle). */
export type PassportRelation = "owner" | "artist" | "holder";

export interface PassportLink {
  artworkId: string;
  relations: PassportRelation[];
  nfcLinked: boolean | null;
  holdingId: string | null;
}

interface Found {
  artworkId: string;
  nfcLinked?: boolean;
  holdingId?: string;
}

/** The order a role reads its own list in: what they came for first, anything else after. */
const RELATION_ORDER: Record<UserRole, PassportRelation[]> = {
  artist: ["artist", "owner"],
  aggregator: ["holder", "owner"],
  customer: ["owner"],
  admin: ["owner"],
};

/** One entry per piece, relations collected, list order = role's relation order then each source's own order. Pure. */
export function mergePassportLinks(role: UserRole, found: Record<PassportRelation, Found[]>): PassportLink[] {
  const byArtwork = new Map<string, PassportLink>();
  for (const relation of RELATION_ORDER[role]) {
    for (const f of found[relation]) {
      const link = byArtwork.get(f.artworkId) ?? { artworkId: f.artworkId, relations: [], nfcLinked: null, holdingId: null };
      link.relations.push(relation);
      if (f.nfcLinked !== undefined) link.nfcLinked = f.nfcLinked;
      if (f.holdingId !== undefined) link.holdingId = f.holdingId;
      byArtwork.set(f.artworkId, link);
    }
  }
  return [...byArtwork.values()];
}

export async function listPassportLinks(db: Firestore, userId: string, role: UserRole): Promise<PassportLink[]> {
  const [owned, made, held] = await Promise.all([
    listCollection(db, userId),
    role === "artist" ? db.collection(Collections.artworks).where("artistId", "==", userId).get() : null,
    role === "aggregator" ? db.collection(Collections.aggregatorHoldings).where("aggregatorId", "==", userId).where("status", "==", "reserved").get() : null,
  ]);

  const createdMillis = (doc: ArtworkDoc): number => doc.createdAt?.toMillis?.() ?? 0;
  const assignedMillis = (doc: AggregatorHoldingDoc): number => doc.assignedAt?.toMillis?.() ?? 0;

  return mergePassportLinks(role, {
    owner: owned.map((e) => ({ artworkId: e.artworkId })),
    artist: (made?.docs ?? [])
      .map((d) => ({ id: d.id, doc: d.data() as ArtworkDoc }))
      .sort((a, b) => createdMillis(b.doc) - createdMillis(a.doc))
      .map(({ id, doc }) => ({ artworkId: id, nfcLinked: Boolean(doc.nfcTagId) })),
    holder: (held?.docs ?? [])
      .map((d) => ({ id: d.id, doc: d.data() as AggregatorHoldingDoc }))
      .sort((a, b) => assignedMillis(b.doc) - assignedMillis(a.doc))
      .map(({ id, doc }) => ({ artworkId: doc.artworkId, holdingId: id })),
  });
}
