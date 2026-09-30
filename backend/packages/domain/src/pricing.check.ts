// Run: node --experimental-strip-types packages/domain/src/pricing.check.ts
//
// Replays frontend-web/lib/pricing.check.ts's worked examples against this
// package's rates-parameterized functions and DEFAULT_RATE_SEED. If this
// file and the frontend's ever disagree, one of the two ports has drifted —
// exactly the class of bug that already happened once between
// frontend-web/lib/pricing.ts and mobile_flutter/lib/core/pricing.dart.

import assert from "node:assert/strict";
import {
  DEFAULT_RATE_SEED,
  serviceChargeOf,
  aggregatorAdvanceForMonth,
  aggregatorCommissionOf,
  aggregatorOfferPriceOf,
  isPriceWarning,
  artistPriceFrom,
  artistSettlementOf,
  basePriceOf,
  billableWeightKg,
  canPlaceWithAnotherAggregator,
  checkoutTotal,
  deliveryZoneBetween,
  displayPriceOf,
  estimateDelivery,
  exGst,
  isPayoutDue,
  listingEndsAt,
  listingChargeOf,
  listingFeeOf,
  nfcChargeOf,
  normalizeRates,
  payoutReleaseDate,
  placementWindow,
  subscriptionChargeOf,
} from "./pricing.ts";

const rates = DEFAULT_RATE_SEED;

// Every absolute amount in `rates` is in paise, so the worked examples below
// are too: ₹1 = 100. `R` keeps the client's own rupee figures readable.
const R = (rupees: number) => Math.round(rupees * 100);

// --- Marketplace worked example (artist price ₹1,00,000) -------------------
{
  const artistPrice = R(100_000);
  assert.equal(basePriceOf(artistPrice, rates), R(130_000), "30% markup");
  const display = displayPriceOf(artistPrice, rates);
  assert.equal(display, R(136_500), "GST inside display price");
  const checkout = checkoutTotal(display, rates);
  assert.equal(checkout.gstIncluded, R(6_500));
  assert.equal(checkout.convenienceFee, 0, "customer convenience is off during launch");
  assert.equal(checkout.convenienceGst, 0);
  assert.equal(checkout.total, R(139_000), "display + flat delivery");

  // Payout sheet, marketplace column: nothing comes off but TDS, and TDS only
  // once the artist's sales this financial year pass ₹5 lakh.
  const underTheLine = artistSettlementOf(artistPrice, "marketplace", rates);
  assert.equal(underTheLine.tdsDeduction, 0);
  assert.equal(underTheLine.net, R(100_000), "marketplace pays the artist in full");

  const pastTheLine = artistSettlementOf(artistPrice, "marketplace", rates, { tdsApplies: true });
  assert.equal(pastTheLine.tdsDeduction, R(100), "0.1% TDS once past the threshold");
  assert.equal(pastTheLine.paymentBeforeDelivery, R(99_900));
  assert.equal(pastTheLine.deliveryDeduction, 0, "marketplace delivery is the customer's, not the artist's");
  assert.equal(pastTheLine.net, R(99_900));
  assert.equal(pastTheLine.technologyDeduction, 0, "no technology charge on the marketplace");

  const galleryZoneKeeps = checkout.total - checkout.gstIncluded - checkout.deliveryCharge - underTheLine.net;
  assert.equal(galleryZoneKeeps, R(30_000));
}

// --- Aggregator payout (artist price ₹1,00,000) ----------------------------
// Client, 30 Sep 2026: convenience 2%, technology 1%, "others if happens",
// 18% GST on all of them, then the ₹2,000 delivery leg. The old sheet's ₹500
// "example tech" line is replaced by the 1% technology charge.
{
  const artistPrice = R(100_000);
  const perSale = { deliveryChargePaise: R(2_000) };

  const underTheLine = artistSettlementOf(artistPrice, "aggregator", rates, perSale);
  assert.equal(underTheLine.tdsDeduction, 0);
  assert.equal(underTheLine.convenienceDeduction, R(2_000), "2% of the artist price");
  assert.equal(underTheLine.technologyDeduction, R(1_000), "1% of the artist price");
  assert.equal(underTheLine.otherChargesDeduction, 0, "real costs only, none yet");
  assert.equal(underTheLine.serviceGstDeduction, R(540), "18% on (2,000 + 1,000)");
  assert.equal(underTheLine.chargesTotal, R(3_540));
  assert.equal(underTheLine.paymentBeforeDelivery, R(96_460));
  assert.equal(underTheLine.net, R(94_460), "final bank payout");

  const pastTheLine = artistSettlementOf(artistPrice, "aggregator", rates, { ...perSale, tdsApplies: true });
  assert.equal(pastTheLine.tdsDeduction, R(100));
  assert.equal(pastTheLine.chargesTotal, R(3_640));
  assert.equal(pastTheLine.paymentBeforeDelivery, R(96_360));
  assert.equal(pastTheLine.net, R(94_360), "final bank payout");

  // A real "other" cost, when one happens, is charged with its own 18% GST.
  const withOther = artistSettlementOf(artistPrice, "aggregator", rates, { ...perSale, otherChargesPaise: R(500) });
  assert.equal(withOther.otherChargesDeduction, R(500));
  assert.equal(withOther.serviceGstDeduction, R(630), "18% on (2,000 + 1,000 + 500)");
  assert.equal(withOther.net, R(100_000) - R(3_500) - R(630) - R(2_000));

  // Defaults, with no per-sale figures: no other charges, flat ₹2,500 delivery.
  const defaults = artistSettlementOf(artistPrice, "aggregator", rates);
  assert.equal(defaults.otherChargesDeduction, 0);
  assert.equal(defaults.deliveryDeduction, R(2_500));
  assert.equal(defaults.net, R(100_000) - R(3_000) - R(540) - R(2_500));
}

// --- Customer invoice sheet ------------------------------------------------
// Two columns: an aggregator sale priced at ₹1,50,000 pre-GST, and a plain
// marketplace sale at ₹1,30,000 pre-GST. Convenience is quoted at 0.1% with
// 18% GST on it — "for future, no applicability now" — so the sheet's own
// figures are checked against a future-rate copy, and the live rate is 0.
{
  const withAggregator = R(157_500); // withGst(1,50,000)
  const marketplaceOnly = R(136_500); // withGst(1,30,000)

  const live = checkoutTotal(withAggregator, rates);
  assert.equal(live.gstIncluded, R(7_500), "5% GST on the goods");
  assert.equal(live.convenienceFee, 0);
  assert.equal(live.total, R(160_000), "157,500 + 2,500 delivery");

  const futureRates = { ...rates, customerConvenienceRate: 0.001 };
  const aggregatorInvoice = checkoutTotal(withAggregator, futureRates);
  assert.equal(aggregatorInvoice.convenienceFee, R(150), "0.1% of 1,50,000");
  assert.equal(aggregatorInvoice.convenienceGst, R(27), "18% of 150");
  assert.equal(aggregatorInvoice.total, R(160_177));

  const marketplaceInvoice = checkoutTotal(marketplaceOnly, futureRates);
  assert.equal(marketplaceInvoice.gstIncluded, R(6_500));
  assert.equal(marketplaceInvoice.convenienceFee, R(130));
  assert.equal(marketplaceInvoice.convenienceGst, R(23.4));
  assert.equal(marketplaceInvoice.total, R(139_153.4));
}

// --- Service-charge sheet: everything GalleryZone bills carries 18% GST ----
{
  const subscription = subscriptionChargeOf(rates);
  assert.equal(subscription.amountPaise, R(1_200));
  assert.equal(subscription.gstPaise, R(216));
  assert.equal(subscription.totalPaise, R(1_416));

  const listing = listingChargeOf(R(100_000), rates);
  assert.equal(listing.amountPaise, R(1_000), "1% of 1,00,000");
  assert.equal(listing.gstPaise, R(180));
  assert.equal(listing.totalPaise, R(1_180));

  const nfc = nfcChargeOf(rates);
  assert.equal(nfc.amountPaise, R(100));
  assert.equal(nfc.gstPaise, R(18));
  assert.equal(nfc.totalPaise, R(118));

  // The sheet's "commission on art, 5% of 1 lakh" line, billed as a service.
  const commissionAsService = serviceChargeOf(R(5_000), rates);
  assert.equal(commissionAsService.gstPaise, R(900));
  assert.equal(commissionAsService.totalPaise, R(5_900));
}

// --- Aggregator commission (MOU §8) ----------------------------------------
{
  const artistPrice = R(100_000);
  const display = R(157_500);
  assert.equal(aggregatorCommissionOf(display, artistPrice, rates), R(10_000), "20% x (150,000 - 100,000)");
  assert.equal(aggregatorCommissionOf(displayPriceOfHelper(R(90_000), rates), artistPrice, rates), 0, "never negative");
}

function displayPriceOfHelper(preTax: number, r: typeof rates): number {
  return Math.round(preTax * (1 + r.gstRate));
}

// --- Ladder reversal & listing fee ------------------------------------------
{
  assert.equal(artistPriceFrom(R(136_500), rates), R(100_000));
  assert.equal(artistPriceFrom(displayPriceOf(R(23_400), rates), rates), R(23_400));
  assert.equal(listingFeeOf(R(100_000), rates), R(1_000), "1% listing fee");
}

// --- Payout timing -----------------------------------------------------------
{
  const delivered = "2026-08-01T00:00:00.000Z";
  assert.equal(payoutReleaseDate(delivered, rates).toISOString(), "2026-08-08T00:00:00.000Z");
  assert.equal(isPayoutDue(delivered, rates, Date.parse("2026-08-07T23:00:00.000Z")), false);
  assert.equal(isPayoutDue(delivered, rates, Date.parse("2026-08-08T01:00:00.000Z")), true);
}

// --- GST isolation ------------------------------------------------------------
{
  assert.equal(exGst(R(157_500), rates) - R(100_000), R(50_000), "GST base excludes markup only, not commission math");
  const commission = aggregatorCommissionOf(R(157_500), R(100_000), rates);
  assert.equal(commission, R(10_000), "commission is untaxed: exactly 20% of 50,000");
  const settlement = artistSettlementOf(R(100_000), "aggregator", rates);
  assert.ok(!("gst" in settlement), "the artist is never charged the 5% artwork GST — only 18% on services");
}

// --- 5-month cycle offer prices ------------------------------------------------
// The drop is ₹2,000 a month. If the month-1 aggregator priced above the
// offer ("appreciated"), month 2 resets to ₹1,30,000 and the drops start a
// month later (client, 30 Sep 2026).
{
  const artistPrice = R(100_000);
  const notAppreciated = [R(130_000), R(128_000), R(126_000), R(124_000), R(122_000)];
  const appreciated = [R(130_000), R(130_000), R(128_000), R(126_000), R(124_000)];
  for (let month = 1; month <= 5; month++) {
    assert.equal(aggregatorOfferPriceOf(artistPrice, month, rates), notAppreciated[month - 1], `month ${month}, not appreciated`);
    assert.equal(
      aggregatorOfferPriceOf(artistPrice, month, rates, { appreciated: true }),
      appreciated[month - 1],
      `month ${month}, appreciated`,
    );
  }
  assert.equal(aggregatorOfferPriceOf(artistPrice, 6, rates), R(122_000), "month 6 holds at month 5's rate");
  assert.equal(aggregatorOfferPriceOf(artistPrice, 9, rates), R(122_000));
  assert.equal(displayPriceOf(artistPrice, rates), R(136_500), "marketplace price never moves with the cycle");
}

// --- Aggregator price warning ---------------------------------------------------
{
  const offer = R(130_000);
  assert.equal(isPriceWarning(R(130_000), offer, rates), false, "keeping the offer");
  assert.equal(isPriceWarning(R(150_000), offer, rates), false, "the client's own ₹1,50,000 example");
  assert.equal(isPriceWarning(R(259_999), offer, rates), false, "just under double");
  assert.equal(isPriceWarning(R(260_000), offer, rates), true, "doubled: +100%");
  assert.equal(isPriceWarning(R(500_000), offer, rates), true);
  assert.equal(isPriceWarning(R(150_000), offer, { ...rates, aggregatorPriceWarnRate: 0.1 }), true, "the threshold is a rate");
}

// --- Advance by month ---------------------------------------------------------
// Month 1: 5% of the price the aggregator sets, before GST. Month 2: 5% of the
// artist price. Months 3 to 5: 3% of the artist price. (Client, 30 Sep 2026.)
{
  const artistPrice = R(100_000);

  const kept = aggregatorAdvanceForMonth({ month: 1, sellingPrice: R(130_000), artistPrice, rates });
  assert.equal(kept.advance, R(6_500), "5% of ₹1,30,000");
  assert.equal(kept.basis, "selling_price");

  const raised = aggregatorAdvanceForMonth({ month: 1, sellingPrice: R(150_000), artistPrice, rates });
  assert.equal(raised.advance, R(7_500), "5% of ₹1,50,000, before GST");
  assert.equal(raised.rate, 0.05);
  assert.equal(raised.payable, R(10_000), "advance + flat delivery deposit");

  const month2 = aggregatorAdvanceForMonth({ month: 2, sellingPrice: R(130_000), artistPrice, rates });
  assert.equal(month2.advance, R(5_000), "5% of the artist price");
  assert.equal(month2.basis, "artist_price");
  assert.equal(month2.rate, 0.05);

  for (const month of [3, 4, 5]) {
    const later = aggregatorAdvanceForMonth({ month, sellingPrice: R(130_000), artistPrice, rates });
    assert.equal(later.advance, R(3_000), `month ${month}: 3% of the artist price`);
    assert.equal(later.basis, "artist_price");
  }
}

// --- 180-day listing window ----------------------------------------------------
{
  const cycleStart = "2026-01-01T00:00:00.000Z";
  assert.equal(listingEndsAt(cycleStart, rates).toISOString(), "2026-06-30T00:00:00.000Z");

  const day0 = placementWindow({ cycleStartedAt: cycleStart, assignedAt: cycleStart, rates });
  assert.equal(day0.extended, false);

  const day130 = new Date("2026-01-01T00:00:00.000Z");
  day130.setDate(day130.getDate() + 130);
  const extended = placementWindow({ cycleStartedAt: cycleStart, assignedAt: day130, rates });
  assert.equal(extended.extended, true);

  const day120 = new Date("2026-01-01T00:00:00.000Z");
  day120.setDate(day120.getDate() + 120);
  const notExtended = placementWindow({ cycleStartedAt: cycleStart, assignedAt: day120, rates });
  assert.equal(notExtended.extended, false, "exactly 30 days left is not extended");

  const day160 = Date.parse(cycleStart) + 160 * 86_400_000;
  assert.equal(
    canPlaceWithAnotherAggregator({ cycleStartedAt: cycleStart, placementsSoFar: 3, rates, now: day160 }),
    false,
  );
  const day100 = Date.parse(cycleStart) + 100 * 86_400_000;
  assert.equal(
    canPlaceWithAnotherAggregator({ cycleStartedAt: cycleStart, placementsSoFar: 3, rates, now: day100 }),
    true,
  );
  assert.equal(
    canPlaceWithAnotherAggregator({ cycleStartedAt: cycleStart, placementsSoFar: 5, rates, now: day100 }),
    false,
  );
  assert.equal(
    canPlaceWithAnotherAggregator({ cycleStartedAt: null, placementsSoFar: 0, rates }),
    true,
  );
}

// --- Delivery -----------------------------------------------------------------
{
  assert.equal(
    billableWeightKg({ actualKg: 4, lengthCm: 100, breadthCm: 70, heightCm: 12 }),
    16.8,
    "volumetric wins",
  );
  assert.equal(
    billableWeightKg({ actualKg: 16.5, lengthCm: 45, breadthCm: 30, heightCm: 25 }),
    16.5,
    "actual wins",
  );
  assert.equal(billableWeightKg({ actualKg: 4 }), 4, "no dims => actual");

  assert.equal(deliveryZoneBetween("560001", "560078", rates), "local");
  assert.equal(deliveryZoneBetween("560001", "562159", rates), "regional");
  assert.equal(deliveryZoneBetween("560001", "500001", rates), "metro");
  assert.equal(deliveryZoneBetween("560001", "110001", rates), "national");
  assert.equal(deliveryZoneBetween("560001", "190001", rates), "remote");

  const near = estimateDelivery({ billableKg: 10, fromPincode: "560001", toPincode: "560078", rates });
  const far = estimateDelivery({ billableKg: 10, fromPincode: "560001", toPincode: "190001", rates });
  assert.ok(far.charge > near.charge, "farther costs more at same weight");

  assert.equal(near.charge, R(675), "local base ₹400 + 5 kg over the slab at ₹55");
  const light = estimateDelivery({ billableKg: 5, fromPincode: "560001", toPincode: "110001", rates });
  const heavy = estimateDelivery({ billableKg: 20, fromPincode: "560001", toPincode: "110001", rates });
  assert.ok(heavy.charge > light.charge, "heavier costs more at same distance");

  const missing = estimateDelivery({ billableKg: null, fromPincode: null, toPincode: null, rates });
  assert.equal(missing.charge, rates.deliveryChargePaise);
  assert.equal(missing.estimated, false);
}

// --- Older stored rate versions ---------------------------------------------
// A version approved before a rate existed must never hand `undefined` to a
// money calculation, and the pre-19-Sep name for the delivery charge still
// resolves.
{
  const legacy = normalizeRates({
    gstRate: 0.05,
    platformMarkup: 0.3,
    deliveryCharge: R(2_500),
  } as Partial<typeof rates> & Record<string, unknown>);
  assert.equal(legacy.deliveryChargePaise, R(2_500), "deliveryCharge reads as deliveryChargePaise");
  assert.equal(legacy.serviceGstRate, rates.serviceGstRate, "a rate the row predates falls back to the seed");
  assert.equal(legacy.artistTdsRate, rates.artistTdsRate);
  for (const [key, value] of Object.entries(legacy)) {
    assert.ok(value !== undefined && value !== null, `${key} is defined`);
    if (typeof value === "number") assert.ok(Number.isFinite(value), `${key} is a real number`);
  }
  assert.equal(legacy.artistTechnologyRate, rates.artistTechnologyRate, "an older version gets the technology charge from the seed");
  assert.equal(legacy.aggregatorPriceWarnRate, rates.aggregatorPriceWarnRate);
  const settlement = artistSettlementOf(R(100_000), "aggregator", legacy, { tdsApplies: true });
  assert.ok(Number.isFinite(settlement.net), "an older version still settles to a real number");
}

console.log("packages/domain/pricing.ts checks passed — matches frontend-web/lib/pricing.check.ts");
