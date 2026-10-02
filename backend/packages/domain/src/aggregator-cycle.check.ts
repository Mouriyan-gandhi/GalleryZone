// Run: node --experimental-strip-types packages/domain/src/aggregator-cycle.check.ts

import assert from "node:assert/strict";
import { DEFAULT_RATE_SEED } from "./pricing.ts";
import { canExtendPlacement, decideNextAggregatorStep, extendedPlacementEnd } from "./aggregator-cycle.ts";

const rates = DEFAULT_RATE_SEED;
const cycleStart = "2026-01-01T00:00:00.000Z";
const artistPrice = 100_000_00; // ₹1,00,000 in paise

// No placements yet — first offer is month 1.
{
  const outcome = decideNextAggregatorStep({
    artistPricePaise: artistPrice,
    cycleStartedAt: cycleStart,
    history: [],
    now: new Date(cycleStart),
    rates,
  });
  assert.equal(outcome.kind, "offer_to_next_aggregator");
  if (outcome.kind === "offer_to_next_aggregator") {
    assert.equal(outcome.month, 1);
    assert.equal(outcome.offerPricePaise, 130_000_00);
    assert.equal(outcome.advance.basis, "selling_price");
    assert.equal(outcome.advance.advance, 6_500_00, "5% of the ₹1,30,000 offer");
  }
}

// Five placements already made — cycle ceiling hit, piece goes home.
{
  const history = Array.from({ length: 5 }, (_, i) => ({
    aggregatorId: `agg-${i}`,
    month: i + 1,
    assignedAt: cycleStart,
    returnedAt: cycleStart,
    appreciated: false,
  }));
  const outcome = decideNextAggregatorStep({
    artistPricePaise: artistPrice,
    cycleStartedAt: cycleStart,
    history,
    now: new Date(Date.parse(cycleStart) + 100 * 86_400_000),
    rates,
  });
  assert.equal(outcome.kind, "return_to_artist");
}

// Late in the window (< 30 days left) — also goes home even with placements to spare.
{
  const outcome = decideNextAggregatorStep({
    artistPricePaise: artistPrice,
    cycleStartedAt: cycleStart,
    history: [{ aggregatorId: "agg-1", month: 1, assignedAt: cycleStart, returnedAt: cycleStart, appreciated: false }],
    now: new Date(Date.parse(cycleStart) + 160 * 86_400_000),
    rates,
  });
  assert.equal(outcome.kind, "return_to_artist");
}

// The month-2 offer depends on whether the month-1 aggregator appreciated.
{
  for (const [appreciated, expectedOffer] of [
    [false, 128_000_00],
    [true, 130_000_00],
  ] as const) {
    const outcome = decideNextAggregatorStep({
      artistPricePaise: artistPrice,
      cycleStartedAt: cycleStart,
      history: [{ aggregatorId: "agg-1", month: 1, assignedAt: cycleStart, returnedAt: cycleStart, appreciated }],
      now: new Date(Date.parse(cycleStart) + 31 * 86_400_000),
      rates,
    });
    assert.equal(outcome.kind, "offer_to_next_aggregator");
    if (outcome.kind === "offer_to_next_aggregator") {
      assert.equal(outcome.month, 2);
      assert.equal(outcome.offerPricePaise, expectedOffer, `appreciated=${appreciated}`);
      assert.equal(outcome.advance.advance, 5_000_00, "month 2 is 5% of the artist price either way");
    }
  }
}

// GalleryZone can extend a placement only while it ends before the 180 days do,
// and never past them.
{
  const start = new Date(cycleStart);
  const day = (n: number) => new Date(start.getTime() + n * 86_400_000);
  assert.equal(canExtendPlacement({ expiresAt: day(30), cycleStartedAt: start, rates }), true);
  assert.equal(canExtendPlacement({ expiresAt: day(179), cycleStartedAt: start, rates }), true);
  assert.equal(canExtendPlacement({ expiresAt: day(180), cycleStartedAt: start, rates }), false, "already running to the end");
  assert.equal(extendedPlacementEnd({ expiresAt: day(30), cycleStartedAt: start, now: day(31), rates }).toISOString(), day(61).toISOString(), "30 days from now, once the window has passed");
  assert.equal(extendedPlacementEnd({ expiresAt: day(30), cycleStartedAt: start, now: day(20), rates }).toISOString(), day(60).toISOString(), "30 days from the current end if it has not passed yet");
  assert.equal(extendedPlacementEnd({ expiresAt: day(160), cycleStartedAt: start, now: day(161), rates }).toISOString(), day(180).toISOString(), "capped at the end of the 180 days");
}

console.log("packages/domain/aggregator-cycle.ts checks passed");
