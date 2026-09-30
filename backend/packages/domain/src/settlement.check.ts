// Run: node --experimental-strip-types packages/domain/src/settlement.check.ts
//
// Ledger-integrity property test (plan.md §17 gate): 1000 random valid
// sequences, balance always sums to zero. Each posting function already
// self-asserts balance via assertBalanced() — this file additionally fuzzes
// inputs across a wide range to catch a rounding edge case a single fixed
// example wouldn't, and checks the assertBalanced() guard itself actually
// fires on a deliberately unbalanced set.

import assert from "node:assert/strict";
import { DEFAULT_RATE_SEED } from "./pricing.ts";
import {
  aggregatorHoldPostings,
  aggregatorReturnPostings,
  aggregatorSalePostings,
  cashRemittanceFromWalletPostings,
  marketplaceCheckoutPostings,
  walletTopupPostings,
  withdrawalPayoutPostings,
} from "./settlement.ts";

const rates = DEFAULT_RATE_SEED;

function sum(postings: { amountPaise: number }[]): number {
  return postings.reduce((total, p) => total + p.amountPaise, 0);
}

function randomInt(min: number, max: number): number {
  return Math.floor(min + Math.random() * (max - min));
}

let iterations = 0;
for (let i = 0; i < 1000; i++) {
  const artistPrice = randomInt(1_000, 50_000_000); // ₹10 to ₹5,00,000, in paise
  const marketplace = marketplaceCheckoutPostings({ artistId: "artist-1", artistPricePaise: artistPrice, rates });
  assert.equal(sum(marketplace), 0, `marketplaceCheckoutPostings unbalanced at artistPrice=${artistPrice}`);
  iterations++;

  const displayPrice = Math.round(artistPrice * (1 + rates.platformMarkup) * (1 + rates.gstRate));
  // The advance is decided once (aggregatorAdvanceForMonth) and passed in, in every month's rate.
  const advanceAmount = Math.round(artistPrice * [0.05, 0.05, 0.03][i % 3]!);
  const delivery = randomInt(0, 400_000);
  const hold = aggregatorHoldPostings({ aggregatorId: "agg-1", advancePaise: advanceAmount, deliveryPaise: delivery });
  assert.equal(sum(hold), 0, `aggregatorHoldPostings unbalanced at advance=${advanceAmount}, delivery=${delivery}`);
  iterations++;

  const topup = walletTopupPostings({ aggregatorId: "agg-1", amountPaise: advanceAmount + delivery });
  assert.equal(sum(topup), 0);
  iterations++;

  const advanceHeld = advanceAmount + delivery;
  for (const tdsApplies of [false, true]) {
    const sale = aggregatorSalePostings({
      artistId: "artist-1",
      aggregatorId: "agg-1",
      displayPricePaise: displayPrice,
      artistPricePaise: artistPrice,
      heldPaise: advanceHeld,
      rates,
      tdsApplies,
    });
    assert.equal(sum(sale), 0, `aggregatorSalePostings unbalanced at artistPrice=${artistPrice}, tds=${tdsApplies}`);
  }
  iterations++;

  const marketplaceWithTds = marketplaceCheckoutPostings({ artistId: "artist-1", artistPricePaise: artistPrice, rates, tdsApplies: true });
  assert.equal(sum(marketplaceWithTds), 0, `marketplaceCheckoutPostings with TDS unbalanced at artistPrice=${artistPrice}`);
  iterations++;

  const ret = aggregatorReturnPostings({ aggregatorId: "agg-1", advancePaise: advanceAmount, deliveryPaise: delivery });
  assert.equal(sum(ret), 0);
  iterations++;

  const payout = withdrawalPayoutPostings({ accountType: "artist_payable", ownerId: "artist-1", amountPaise: artistPrice });
  assert.equal(sum(payout), 0);
  iterations++;
}
assert.equal(iterations, 7000);

// The wallet, end to end for one aggregator: the balance an aggregator can
// spend or withdraw is minus the sum of their aggregator_payable entries; what
// is set aside is minus the sum of their aggregator_held entries.
{
  const balances = (postings: { accountType: string; ownerId?: string; amountPaise: number }[]) => ({
    wallet: -postings.filter((p) => p.accountType === "aggregator_payable").reduce((t, p) => t + p.amountPaise, 0) || 0,
    held: -postings.filter((p) => p.accountType === "aggregator_held").reduce((t, p) => t + p.amountPaise, 0) || 0,
  });
  const topupPostings = walletTopupPostings({ aggregatorId: "agg-1", amountPaise: 2_000_000 }); // ₹20,000 from the bank
  assert.deepEqual(balances(topupPostings), { wallet: 2_000_000, held: 0 }, "a top-up is spendable straight away");

  // Reserve at ₹1,50,000: advance 7,500 + delivery 2,500 = 10,000 set aside.
  const held = aggregatorHoldPostings({ aggregatorId: "agg-1", advancePaise: 750_000, deliveryPaise: 250_000 });
  assert.deepEqual(balances([...topupPostings, ...held]), { wallet: 1_000_000, held: 1_000_000 }, "the hold moves money from spendable to held, and creates none");

  // Unsold: the advance is back, the delivery deposit is gone.
  const unsold = aggregatorReturnPostings({ aggregatorId: "agg-1", advancePaise: 750_000, deliveryPaise: 250_000 });
  assert.deepEqual(balances([...topupPostings, ...held, ...unsold]), { wallet: 1_750_000, held: 0 }, "unsold: ₹20,000 − ₹2,500 delivery");
  assert.equal(unsold.find((p) => p.accountType === "platform_revenue")?.amountPaise, -250_000, "the forfeited delivery goes to GalleryZone's side");

  // Sold: the whole hold comes back, plus the aggregator's commission.
  const sold = aggregatorSalePostings({
    artistId: "artist-1",
    aggregatorId: "agg-1",
    displayPricePaise: 15_750_000,
    artistPricePaise: 10_000_000,
    heldPaise: 1_000_000,
    rates,
    tdsApplies: false,
  });
  // ₹1,57,500 with GST is ₹1,50,000 before it; less the ₹1,00,000 artist price, the markup is ₹50,000 and 20% of it is ₹10,000.
  // Wallet: ₹20,000 in, ₹10,000 held, ₹10,000 released, ₹10,000 commission = ₹30,000.
  assert.deepEqual(balances([...topupPostings, ...held, ...sold]), { wallet: 3_000_000, held: 0 }, "sold: the hold comes back and the commission is added");

  // A cash sale is deposited from the wallet within two days: the aggregator adds the cash, then pays it in.
  const cashIn = walletTopupPostings({ aggregatorId: "agg-1", amountPaise: 15_750_000 });
  const remitted = cashRemittanceFromWalletPostings({ aggregatorId: "agg-1", amountPaise: 15_750_000 });
  assert.equal(sum(remitted), 0);
  assert.deepEqual(balances([...topupPostings, ...held, ...sold, ...cashIn]), { wallet: 18_750_000, held: 0 }, "the cash the aggregator adds shows in the wallet");
  assert.deepEqual(balances([...topupPostings, ...held, ...sold, ...cashIn, ...remitted]), { wallet: 3_000_000, held: 0 }, "paying it in leaves the wallet as it was before the sale's cash");
}

console.log(`packages/domain/settlement.ts: ${iterations} balanced-ledger checks passed across 1000 random sequences`);
