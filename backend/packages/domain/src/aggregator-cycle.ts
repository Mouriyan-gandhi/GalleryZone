// Orchestrates the individual pricing.ts primitives (aggregatorOfferPriceOf,
// aggregatorAdvanceForMonth, placementWindow, canPlaceWithAnotherAggregator)
// into the one decision the "30-day/180-day window sweep" background job
// (plan.md §13) actually needs to make: given an artwork's placement
// history, what happens next? Still pure — the job (apps/jobs, Phase 2+)
// is what calls this on a schedule and turns the result into DB writes.

import {
  addDays,
  aggregatorAdvanceForMonth,
  aggregatorOfferPriceOf,
  canPlaceWithAnotherAggregator,
  listingEndsAt,
  type AggregatorAdvance,
  type PricingRates,
} from "./pricing.ts";

export interface HoldingHistoryEntry {
  aggregatorId: string;
  month: number;
  assignedAt: string | Date;
  returnedAt: string | Date | null;
  /** Did this aggregator price the piece above GalleryZone's offer? Only month 1 can. */
  appreciated: boolean;
}

export type AggregatorCycleOutcome =
  | { kind: "hold_with_current"; expiresAt: Date; extended: boolean }
  | { kind: "return_to_artist" }
  | {
      kind: "offer_to_next_aggregator";
      month: number;
      offerPricePaise: number;
      advance: AggregatorAdvance;
    };

/**
 * Called when a holding is returned unsold (or a placement window lapses).
 * Decides what happens to the artwork next: does it get placed with another
 * aggregator, does the current one keep it because there's no time left to
 * hand off, or does the whole cycle end and it goes home to the artist.
 */
export function decideNextAggregatorStep({
  artistPricePaise,
  cycleStartedAt,
  history,
  now = new Date(),
  rates,
}: {
  artistPricePaise: number;
  cycleStartedAt: string | Date;
  history: readonly HoldingHistoryEntry[];
  now?: Date;
  rates: PricingRates;
}): AggregatorCycleOutcome {
  const placementsSoFar = history.length;
  const canPlace = canPlaceWithAnotherAggregator({
    cycleStartedAt,
    placementsSoFar,
    rates,
    now: now.getTime(),
  });

  if (!canPlace) {
    // Either the 5-placement ceiling was hit, or too little of the 180-day
    // window is left to justify one more hand-off — either way the piece
    // goes home. (placementWindow's own "extended" case is handled by the
    // caller BEFORE returning a holding, not here — by the time we're
    // deciding the next step the current placement has already ended.)
    return { kind: "return_to_artist" };
  }

  const nextMonth = placementsSoFar + 1;
  // Only the month-1 aggregator can price above GalleryZone's offer; whether
  // they did decides when the monthly drops start (aggregatorOfferPriceOf).
  const appreciated = history[0]?.appreciated ?? false;
  const offerPricePaise = aggregatorOfferPriceOf(artistPricePaise, nextMonth, rates, { appreciated });
  // The advance shown alongside an offer is the one at the offer price: the
  // aggregator may set a higher price when they reserve in month 1, which
  // raises their month-1 advance with it.
  const advance = aggregatorAdvanceForMonth({
    month: nextMonth,
    sellingPrice: offerPricePaise,
    artistPrice: artistPricePaise,
    rates,
  });

  return {
    kind: "offer_to_next_aggregator",
    month: nextMonth,
    offerPricePaise,
    advance,
  };
}

/**
 * Whether GalleryZone can still extend this placement: only while it ends
 * before the whole 180-day listing does.
 */
export function canExtendPlacement({
  expiresAt,
  cycleStartedAt,
  rates,
}: {
  expiresAt: Date;
  cycleStartedAt: Date;
  rates: PricingRates;
}): boolean {
  return expiresAt.getTime() < listingEndsAt(cycleStartedAt, rates).getTime();
}

/**
 * Where an approved extension ends: one more placement window (30 days) from
 * whichever is later, the current end or now, and never past the end of the
 * 180-day listing.
 */
export function extendedPlacementEnd({
  expiresAt,
  cycleStartedAt,
  now,
  rates,
}: {
  expiresAt: Date;
  cycleStartedAt: Date;
  now: Date;
  rates: PricingRates;
}): Date {
  const wanted = addDays(new Date(Math.max(expiresAt.getTime(), now.getTime())), rates.aggregatorPlacementDays);
  const listingEnd = listingEndsAt(cycleStartedAt, rates);
  return wanted.getTime() > listingEnd.getTime() ? listingEnd : wanted;
}

