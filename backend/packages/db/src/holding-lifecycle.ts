// What happens to a holding once it is reserved, other than a sale or a return
// the aggregator makes themselves: asking to keep it, GalleryZone answering,
// and the window simply ending.
//
// Client, 30 Sep 2026. After the 30 days the painting moves on to the next
// aggregator, and the advance is back on day 31. The same aggregator keeps it
// only by raising a request with an assurance that it will sell, and only if
// GalleryZone accepts. "GalleryZone decides each time."

import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";
import { canExtendPlacement, extendedPlacementEnd, type PricingRates } from "@galleryzone/domain";
import { Collections, type AggregatorHoldingDoc } from "./collections.ts";
import { getAggregatorHolding, holdingsFor, returnHolding, type AggregatorHoldingView } from "./aggregator-reads.ts";
import { DbError } from "./errors.ts";

export class HoldingLifecycleError extends DbError {}

const MIN_ASSURANCE = 10;

async function loadHolding(db: Firestore, holdingId: string) {
  const ref = db.collection(Collections.aggregatorHoldings).doc(holdingId);
  const h = (await ref.get()).data() as AggregatorHoldingDoc | undefined;
  return { ref, h };
}

async function cycleStartOf(db: Firestore, h: AggregatorHoldingDoc): Promise<Date> {
  return (await holdingsFor(db, h.artworkId))[0]?.assignedAt.toDate() ?? h.assignedAt.toDate();
}

/** The aggregator asks to keep a piece past its window, with their assurance that it will sell. */
export async function requestHoldingExtension(
  db: Firestore,
  input: { aggregatorId: string; holdingId: string; assurance: string; rates: PricingRates; now?: Date },
): Promise<AggregatorHoldingView> {
  const now = input.now ?? new Date();
  const { ref, h } = await loadHolding(db, input.holdingId);
  if (!h || h.aggregatorId !== input.aggregatorId) throw new HoldingLifecycleError(`No holding ${input.holdingId}`);
  if (h.status !== "reserved") throw new HoldingLifecycleError("Only a piece you still hold can be extended");
  const expiresAt = h.expiresAt.toDate();
  if (expiresAt.getTime() <= now.getTime()) throw new HoldingLifecycleError("This piece's window has already ended");

  if (h.extensionRequest?.status === "pending") throw new HoldingLifecycleError("Your request is already waiting for GalleryZone");
  // One answer per window: a declined request can't be raised again until the window changes.
  if (h.extensionRequest && h.extensionRequest.previousExpiresAt.toMillis() === h.expiresAt.toMillis()) {
    throw new HoldingLifecycleError("GalleryZone has already answered your request for this window");
  }

  const assurance = input.assurance.trim();
  if (assurance.length < MIN_ASSURANCE) throw new HoldingLifecycleError("Tell GalleryZone why this piece will sell, in a sentence or two");
  if (!canExtendPlacement({ expiresAt, cycleStartedAt: await cycleStartOf(db, h), rates: input.rates })) {
    throw new HoldingLifecycleError("This piece is already held to the end of its listing period");
  }

  await ref.update({
    extensionRequest: {
      requestedAt: Timestamp.fromDate(now),
      assurance,
      status: "pending",
      decidedAt: null,
      decidedBy: null,
      note: null,
      previousExpiresAt: h.expiresAt,
    },
  });
  return (await getAggregatorHolding(db, input.aggregatorId, input.holdingId))!;
}

export interface ExtensionDecision {
  holding: AggregatorHoldingView | null;
  aggregatorId: string;
  artworkId: string;
  previousExpiresAt: Date;
  /** The new end of the window when approved. */
  newExpiresAt: Date | null;
}

/** GalleryZone answers a pending request. Approving moves the window's end out by one placement, never past the 180-day listing. */
export async function decideHoldingExtension(
  db: Firestore,
  input: { holdingId: string; adminId: string; decision: "approved" | "declined"; note?: string | undefined; rates: PricingRates; now?: Date },
): Promise<ExtensionDecision> {
  const now = input.now ?? new Date();
  const { ref, h } = await loadHolding(db, input.holdingId);
  if (!h) throw new HoldingLifecycleError(`No holding ${input.holdingId}`);
  if (h.status !== "reserved") throw new HoldingLifecycleError("This piece is no longer with the aggregator");
  const request = h.extensionRequest;
  if (!request || request.status !== "pending") throw new HoldingLifecycleError("There is no request waiting for an answer");

  const previousExpiresAt = h.expiresAt.toDate();
  let newExpiresAt: Date | null = null;
  if (input.decision === "approved") {
    newExpiresAt = extendedPlacementEnd({ expiresAt: previousExpiresAt, cycleStartedAt: await cycleStartOf(db, h), now, rates: input.rates });
    if (newExpiresAt.getTime() <= previousExpiresAt.getTime()) {
      throw new HoldingLifecycleError("This piece is already held to the end of its listing period");
    }
  }

  const note = input.note?.trim() || null;
  await ref.update({
    ...(newExpiresAt ? { expiresAt: Timestamp.fromDate(newExpiresAt) } : {}),
    extensionRequest: { ...request, status: input.decision, decidedAt: Timestamp.fromDate(now), decidedBy: input.adminId, note },
  });
  await db.collection(Collections.auditLog).add({
    adminId: input.adminId,
    action: input.decision === "approved" ? "holding.extension_approved" : "holding.extension_declined",
    entityType: "holding",
    entityId: input.holdingId,
    entityLabel: null,
    detail: { note, previousExpiresAt: previousExpiresAt.toISOString(), newExpiresAt: newExpiresAt?.toISOString() ?? null },
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    holding: await getAggregatorHolding(db, h.aggregatorId, input.holdingId),
    aggregatorId: h.aggregatorId,
    artworkId: h.artworkId,
    previousExpiresAt,
    newExpiresAt,
  };
}

export interface ExpiredHolding {
  holdingId: string;
  aggregatorId: string;
  artworkId: string;
  advancePaise: number;
}

/**
 * Ends every reserved holding whose window has passed: the advance is
 * released (day 31 in the aggregator's wallet), the piece goes back on the
 * marketplace, and it is offered to the next aggregator. The same return an
 * aggregator makes by hand, so the accounting can't differ. A request nobody
 * answered in time is closed with the window.
 *
 * Only status is queried (no composite index); the date is compared here, and
 * reserved holdings are few. ponytail: a decision landing between this read
 * and the return would lose to the sweep; add a transaction if that ever shows.
 */
export async function expireDueHoldings(
  db: Firestore,
  now: Date = new Date(),
): Promise<{ expired: ExpiredHolding[]; failed: { holdingId: string; error: string }[] }> {
  const snap = await db.collection(Collections.aggregatorHoldings).where("status", "==", "reserved").get();
  const expired: ExpiredHolding[] = [];
  const failed: { holdingId: string; error: string }[] = [];

  for (const d of snap.docs) {
    const h = d.data() as AggregatorHoldingDoc;
    if (h.expiresAt.toDate().getTime() > now.getTime()) continue;
    try {
      if (h.extensionRequest?.status === "pending") {
        await d.ref.update({
          extensionRequest: { ...h.extensionRequest, status: "declined", decidedAt: Timestamp.fromDate(now), decidedBy: null, note: "The window ended before GalleryZone answered." },
        });
      }
      await returnHolding(db, h.aggregatorId, d.id);
      expired.push({ holdingId: d.id, aggregatorId: h.aggregatorId, artworkId: h.artworkId, advancePaise: h.advanceAmountPaise });
    } catch (error) {
      failed.push({ holdingId: d.id, error: String(error) });
    }
  }
  return { expired, failed };
}
