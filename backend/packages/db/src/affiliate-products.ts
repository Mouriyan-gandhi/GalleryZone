// Amazon affiliate products: the public "Art supplies" shelf and its admin CRUD.
// A product is keyed by its ASIN when known, so the same item can never be
// listed twice; one added without an ASIN gets a generated id.

import { Timestamp, type Firestore } from "firebase-admin/firestore";
import { Collections, type AffiliateProductDoc } from "./collections.ts";
import { DbError } from "./errors.ts";

export class AffiliateError extends DbError {}

export interface AffiliateProductInput {
  url: string;
  asin?: string | null | undefined;
  title: string;
  brand?: string | null | undefined;
  category: string;
  images: string[];
  active?: boolean | undefined;
}

export type AffiliateProductRow = Omit<AffiliateProductDoc, "createdAt" | "updatedAt"> & {
  id: string;
  createdAt: string;
  updatedAt: string;
};

function toRow(id: string, d: AffiliateProductDoc): AffiliateProductRow {
  return { ...d, id, createdAt: d.createdAt.toDate().toISOString(), updatedAt: d.updatedAt.toDate().toISOString() };
}

function toDoc(input: AffiliateProductInput, at: Timestamp): AffiliateProductDoc {
  return {
    url: input.url,
    asin: input.asin ?? null,
    title: input.title,
    brand: input.brand ?? null,
    category: input.category,
    images: input.images,
    active: input.active ?? true,
    createdAt: at,
    updatedAt: at,
  };
}

/** Oldest first, so the shelf keeps the order products were added in. */
export async function listAffiliateProducts(db: Firestore, { activeOnly }: { activeOnly: boolean }): Promise<AffiliateProductRow[]> {
  // ponytail: whole collection in one read, filtered here; a few hundred docs. Add a
  // composite (active, createdAt) index and a where() if it ever reaches thousands.
  const snap = await db.collection(Collections.affiliateProducts).orderBy("createdAt").get();
  const rows = snap.docs.map((d) => toRow(d.id, d.data() as AffiliateProductDoc));
  return activeOnly ? rows.filter((r) => r.active) : rows;
}

export async function createAffiliateProduct(db: Firestore, input: AffiliateProductInput): Promise<AffiliateProductRow> {
  const col = db.collection(Collections.affiliateProducts);
  const ref = input.asin ? col.doc(input.asin) : col.doc();
  const doc = toDoc(input, Timestamp.now());
  try {
    await ref.create(doc);
  } catch (error) {
    if ((error as { code?: number }).code === 6) throw new AffiliateError("That product is already on the shelf");
    throw error;
  }
  return toRow(ref.id, doc);
}

/** Everything but the ASIN, which is the doc id and never changes. */
export type AffiliateProductPatch = { [K in "url" | "title" | "brand" | "category" | "images" | "active"]?: AffiliateProductDoc[K] | undefined };

export async function updateAffiliateProduct(db: Firestore, id: string, patch: AffiliateProductPatch): Promise<AffiliateProductRow> {
  const ref = db.collection(Collections.affiliateProducts).doc(id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new AffiliateError(`No affiliate product ${id}`);
    const cur = snap.data() as AffiliateProductDoc;
    const next: AffiliateProductDoc = {
      ...cur,
      url: patch.url ?? cur.url,
      title: patch.title ?? cur.title,
      brand: patch.brand === undefined ? cur.brand : patch.brand, // null clears it
      category: patch.category ?? cur.category,
      images: patch.images ?? cur.images,
      active: patch.active ?? cur.active,
      updatedAt: Timestamp.now(),
    };
    tx.set(ref, next);
    return toRow(id, next);
  });
}

export async function deleteAffiliateProduct(db: Firestore, id: string): Promise<void> {
  const ref = db.collection(Collections.affiliateProducts).doc(id);
  if (!(await ref.get()).exists) throw new AffiliateError(`No affiliate product ${id}`);
  await ref.delete();
}

/**
 * Adds every product not already on the shelf (matched by ASIN), in the order
 * given, and leaves existing ones alone so admin edits survive a re-run.
 */
export async function seedAffiliateProducts(db: Firestore, inputs: (AffiliateProductInput & { asin: string })[]): Promise<{ created: number; skipped: number }> {
  const col = db.collection(Collections.affiliateProducts);
  inputs = inputs.filter((p, i) => inputs.findIndex((q) => q.asin === p.asin) === i); // two links can share an ASIN
  const refs = inputs.map((p) => col.doc(p.asin));
  const existing = refs.length ? await db.getAll(...refs) : [];
  const start = Date.now();
  let created = 0;
  // 500 writes per batch is Firestore's limit.
  for (let i = 0; i < inputs.length; i += 500) {
    const batch = db.batch();
    inputs.slice(i, i + 500).forEach((input, j) => {
      const k = i + j;
      if (existing[k]!.exists) return;
      batch.set(refs[k]!, toDoc(input, Timestamp.fromMillis(start + k)));
      created++;
    });
    await batch.commit();
  }
  return { created, skipped: inputs.length - created };
}
