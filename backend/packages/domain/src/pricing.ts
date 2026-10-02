// Every rupee figure in GalleryZone comes from here — ported function-for-
// function from frontend-web/lib/pricing.ts (see that file's header for the
// full worked example and the business context behind each rule).
//
// The one structural difference from the frontend copy: nothing here is a
// module-level constant. Every function takes a `PricingRates` object as its
// first (or only extra) argument. That object is resolved by
// packages/config from the versioned `rate_config` table — never hardcoded
// in application code — so a rate change is a DB write plus an admin
// approval (see the plan's "Admin rules console" section), not a deploy.
//
// packages/domain/src/pricing.check.ts replays every worked example from
// frontend-web/lib/pricing.check.ts against DEFAULT_RATE_SEED below and
// fails loudly if anything drifts from the client's numbers.

export interface DeliveryZoneRate {
  base: number;
  perExtraKg: number;
}

export type DeliveryZone = "local" | "regional" | "metro" | "national" | "remote";

export interface PricingRates {
  /** HSN 9701. Confirmed by the client (25 Aug 2026): 5%, not the 2025-era 12%. */
  gstRate: number;
  /** GalleryZone's margin over the artist's price, before GST. */
  platformMarkup: number;
  /** Listing charge, as a fraction of the artist's price. Service sheet: 1% (+18% GST). */
  artistListingFeeRate: number;
  /**
   * GST on GalleryZone's own SERVICE charges — the convenience fee, the
   * listing fee, tech/NFC, subscription, exhibition and advertising. Always
   * 18%, and never mixed with `gstRate`, which taxes the artwork itself.
   */
  serviceGstRate: number;
  /**
   * Income-tax TDS on the artist's own price (§194-O). Withheld from the sale
   * that takes the artist's financial-year sales past
   * `earningsAbove5LThresholdPaise`, and from every sale after it (client,
   * 30 Sep 2026: "only when the artist's sales this year cross ₹5 lakh").
   * GST registration does not decide it. Separate from GST in every direction.
   */
  artistTdsRate: number;
  /** Aggregator MOU §7 — security deposit paid before taking possession. */
  aggregatorAdvanceRate: number;
  /** Aggregator MOU §8 — 20% of (selling price − artist price). */
  aggregatorCommissionRate: number;
  /** Deducted from the artist's settlement on aggregator sales only. */
  artistConvenienceRate: number;
  /**
   * Technology charge, of the artist's price, on aggregator sales only (+ service
   * GST). Client, 30 Sep 2026: "convenience 2%, technology 1%, others if happens".
   */
  artistTechnologyRate: number;
  /**
   * The payout sheet's "other charges (if incurred)" line: real costs that
   * actually happen on a sale. Default charge applied to an aggregator
   * settlement when the caller does not pass a real, per-sale figure. Zero
   * until a real trigger exists.
   */
  artistOtherChargePaise: number;
  /**
   * Customer convenience fee, as a fraction of the pre-GST order value, plus
   * `serviceGstRate` on the fee itself. The invoice sheet carries it at 0.1%
   * marked "for future — no applicability now", so it ships at zero.
   */
  customerConvenienceRate: number;
  /** One-off charge when an NFC tag is issued for a piece (+ service GST). */
  nfcTagChargePaise: number;
  /** Artist subscription, per billing period (+ service GST). */
  subscriptionFeePaise: number;
  /** Flat fallback delivery charge when weight/pincode data is missing. */
  deliveryChargePaise: number;
  /** Days after delivery before the artist's settlement is released. */
  artistPayoutDaysAfterDelivery: number;
  /** How many aggregators a piece can rotate through in one listing cycle. */
  aggregatorCycleMonths: number;
  /** Artist MOU §18 — whole listing window, in days. */
  aggregatorListingDays: number;
  /** One aggregator's display window, in days. */
  aggregatorPlacementDays: number;
  /** Percent-off-artist-price ladder applied to the next aggregator's offer, index 0 = month 1. */
  aggregatorMonthlyDiscountRates: readonly number[];
  /**
   * An aggregator pricing a piece this far above GalleryZone's offer (1 = +100%,
   * i.e. doubled) is allowed, but GalleryZone is sent a warning.
   */
  aggregatorPriceWarnRate: number;
  /** Rate card per delivery zone. */
  deliveryZoneRates: Record<DeliveryZone, DeliveryZoneRate>;
  /** Base weight slab (kg) included in a zone's base rate. */
  deliveryBaseSlabKg: number;
  /** Pincode 2-digit prefixes billed at the "remote" zone rate (J&K/HP/NE). */
  remotePincodePrefixes: readonly string[];
  /** Days an artist may freely edit a listing after it first goes live. */
  artistEditWindowDays: number;
  /** External-sale penalty, as a fraction of artist price (1% per the mock). */
  externalSalePenaltyRate: number;
  /** Minimum a wallet withdrawal must reach (paise) — artist/aggregator. */
  minWithdrawalPaise: number;
  /** Minimum a customer wallet withdrawal must reach (paise) — separate from the above; the frontend's own customerWalletService uses a lower figure. */
  minCustomerWithdrawalPaise: number;
  /** Artwork price at/above which transit insurance is recommended. */
  insuranceThresholdPaise: number;
  /**
   * Financial-year (April to March) sales, in paise, past which §194-O TDS is
   * withheld from an artist. ₹5,00,000. See policies.ts tdsAppliesOnSale.
   */
  earningsAbove5LThresholdPaise: number;
  /**
   * NFC rollout phase 3 (NFC_IMPLEMENTATION.md §12). Off: dispatching a piece
   * whose tag is not locked is logged and allowed, so ops can see what would be
   * blocked and lock or override it first. On: it is refused (409 nfc_lock_required).
   */
  nfcShipmentGateEnforced: boolean;
}

// Seed values for the `rate_config` table's first migration only. Not
// imported by any pricing function above — every function takes `rates`
// explicitly, so this object is data, not logic. Values match the client's
// "How the money flows" sheets (21 Aug 2026, confirmed 25 Aug), the payout
// sheet "How pay out looks as per Govt guidelines" (9 Sep), the service-GST
// sheet and the customer invoice sheet (19 Sep 2026).
//
// EVERY absolute amount here is in PAISE. The rate fields are fractions.
export const DEFAULT_RATE_SEED: PricingRates = {
  gstRate: 0.05,
  platformMarkup: 0.3,
  artistListingFeeRate: 0.01,
  serviceGstRate: 0.18,
  artistTdsRate: 0.001,
  aggregatorAdvanceRate: 0.05,
  aggregatorCommissionRate: 0.2,
  artistConvenienceRate: 0.02,
  artistTechnologyRate: 0.01,
  artistOtherChargePaise: 0,
  customerConvenienceRate: 0,
  nfcTagChargePaise: 10_000, // ₹100
  subscriptionFeePaise: 120_000, // ₹1,200
  deliveryChargePaise: 250_000, // ₹2,500
  artistPayoutDaysAfterDelivery: 7,
  aggregatorCycleMonths: 5,
  aggregatorListingDays: 180,
  aggregatorPlacementDays: 30,
  aggregatorMonthlyDiscountRates: [0, 0.02, 0.04, 0.06, 0.08],
  aggregatorPriceWarnRate: 1,
  deliveryZoneRates: {
    local: { base: 40_000, perExtraKg: 5_500 },
    regional: { base: 62_000, perExtraKg: 8_000 },
    metro: { base: 78_000, perExtraKg: 9_500 },
    national: { base: 95_000, perExtraKg: 12_000 },
    remote: { base: 140_000, perExtraKg: 17_500 },
  },
  deliveryBaseSlabKg: 5,
  remotePincodePrefixes: ["18", "19", "78", "79"],
  artistEditWindowDays: 7,
  externalSalePenaltyRate: 0.01,
  minWithdrawalPaise: 100_000, // ₹1,000, matches artistDashboardService/aggregatorSalesService
  minCustomerWithdrawalPaise: 50_000, // ₹500, matches customerWalletService
  insuranceThresholdPaise: 2_000_000, // ₹20,000, matches PlatformSettings.insuranceThreshold
  earningsAbove5LThresholdPaise: 50_000_000, // ₹5,00,000
  nfcShipmentGateEnforced: false,
};

/**
 * A stored rate version was written against whatever PricingRates looked
 * like on the day it was approved. When a new rate is introduced, older rows
 * carry no value for it — and a missing rate must never reach a calculation
 * as `undefined`, which would silently produce NaN money. Anything absent
 * falls back to the seed, and `deliveryCharge` (the pre-19-Sep-2026 name for
 * the same paise figure) is read as `deliveryChargePaise`.
 *
 * A read-time shim, not a migration: the stored document is left exactly as
 * approved, so the record of what was in force still holds.
 */
export function normalizeRates(stored: Partial<PricingRates> & Record<string, unknown>): PricingRates {
  const defined = Object.fromEntries(
    Object.entries(stored).filter(([, value]) => value !== undefined && value !== null),
  ) as Partial<PricingRates>;
  const legacyDelivery = (stored as { deliveryCharge?: number }).deliveryCharge;
  return {
    ...DEFAULT_RATE_SEED,
    ...(legacyDelivery === undefined ? {} : { deliveryChargePaise: legacyDelivery }),
    ...defined,
  };
}

// --- Price ladder -----------------------------------------------------------

/** Artist's price → GalleryZone's price before GST. 1,00,000 → 1,30,000. */
export function basePriceOf(artistPrice: number, rates: PricingRates): number {
  return Math.round(artistPrice * (1 + rates.platformMarkup));
}

/** Artist's price → the number shown on the site, GST included. */
export function displayPriceOf(artistPrice: number, rates: PricingRates): number {
  return withGst(basePriceOf(artistPrice, rates), rates);
}

/** Adds GST to a pre-tax figure. 1,30,000 → 1,36,500. */
export function withGst(preTax: number, rates: PricingRates): number {
  return Math.round(preTax * (1 + rates.gstRate));
}

/** Strips GST back out of a displayed price. 1,36,500 → 1,30,000. */
export function exGst(displayPrice: number, rates: PricingRates): number {
  return Math.round(displayPrice / (1 + rates.gstRate));
}

/** The GST already contained in a displayed price. 1,36,500 → 6,500. */
export function gstIncludedIn(displayPrice: number, rates: PricingRates): number {
  return displayPrice - exGst(displayPrice, rates);
}

/** Works the ladder backwards — displayed price → the artist price behind it. */
export function artistPriceFrom(displayPrice: number, rates: PricingRates): number {
  return Math.round(exGst(displayPrice, rates) / (1 + rates.platformMarkup));
}

/** The listing fee an artist owes for putting a piece up: 1% of their price. */
export function listingFeeOf(artistPrice: number, rates: PricingRates): number {
  return Math.round(artistPrice * rates.artistListingFeeRate);
}

// --- Service charges --------------------------------------------------------
//
// Everything GalleryZone charges for a SERVICE rather than for the artwork —
// subscription, listing, technology/NFC, aggregator-style commission billed
// as a fee, exhibition and advertising. All of them carry 18% GST on the fee
// itself (never the 5% artwork rate), which is the whole content of the
// client's service-GST sheet.

export interface ServiceCharge {
  /** The fee itself, before GST. */
  amountPaise: number;
  gstPaise: number;
  /** What the invoice for this line actually comes to. */
  totalPaise: number;
}

export function serviceChargeOf(amountPaise: number, rates: PricingRates): ServiceCharge {
  const gstPaise = Math.round(amountPaise * rates.serviceGstRate);
  return { amountPaise, gstPaise, totalPaise: amountPaise + gstPaise };
}

/** Listing fee + its 18% GST. Sheet: ₹1,00,000 → ₹1,000 + ₹180 = ₹1,180. */
export function listingChargeOf(artistPrice: number, rates: PricingRates): ServiceCharge {
  return serviceChargeOf(listingFeeOf(artistPrice, rates), rates);
}

/** NFC/technology charge + its 18% GST. Sheet: ₹100 + ₹18 = ₹118. */
export function nfcChargeOf(rates: PricingRates): ServiceCharge {
  return serviceChargeOf(rates.nfcTagChargePaise, rates);
}

/** Subscription + its 18% GST. Sheet: ₹1,200 + ₹216 = ₹1,416. */
export function subscriptionChargeOf(rates: PricingRates): ServiceCharge {
  return serviceChargeOf(rates.subscriptionFeePaise, rates);
}

// --- Checkout ---------------------------------------------------------------

export interface CheckoutTotal {
  /** The artwork's price with the 5% artwork GST already inside it. */
  displayPrice: number;
  /** The artwork GST portion of `displayPrice` — shown, never added again. */
  gstIncluded: number;
  /** Convenience fee on the pre-GST order value (0 during launch). */
  convenienceFee: number;
  /** 18% service GST on the convenience fee itself. */
  convenienceGst: number;
  deliveryCharge: number;
  /** What the customer actually pays. */
  total: number;
}

// The customer invoice sheet, top to bottom: artwork (artist price + every
// appreciation) with 5% GST inside it, then the convenience fee, then 18%
// GST on that fee, then delivery. Never add gstIncluded to the total — it is
// already part of displayPrice.
export function checkoutTotal(
  displayPrice: number,
  rates: PricingRates,
  deliveryChargePaise?: number,
): CheckoutTotal {
  const delivery = deliveryChargePaise ?? rates.deliveryChargePaise;
  const convenienceFee = Math.round(exGst(displayPrice, rates) * rates.customerConvenienceRate);
  const convenienceGst = Math.round(convenienceFee * rates.serviceGstRate);
  return {
    displayPrice,
    gstIncluded: gstIncludedIn(displayPrice, rates),
    convenienceFee,
    convenienceGst,
    deliveryCharge: delivery,
    total: displayPrice + convenienceFee + convenienceGst + delivery,
  };
}

// --- Settlements ------------------------------------------------------------

export type SaleChannel = "marketplace" | "aggregator";

export interface ArtistSettlement {
  /** The artist's own price — GalleryZone's markup is never theirs. */
  gross: number;
  /** §194-O income-tax TDS, 0 until the artist's financial-year sales pass the threshold. */
  tdsDeduction: number;
  convenienceDeduction: number;
  technologyDeduction: number;
  otherChargesDeduction: number;
  /** 18% GST on (convenience + technology + other charges) — a service, not the artwork. */
  serviceGstDeduction: number;
  /** The sheet's "Total of charges" line. */
  chargesTotal: number;
  /** The sheet's "Payment before delivery" line. */
  paymentBeforeDelivery: number;
  deliveryDeduction: number;
  /** The sheet's "Final Bank Payout" line. */
  net: number;
}

export interface ArtistSettlementOptions {
  /**
   * True once this sale takes the artist's financial-year sales past the
   * §194-O threshold (policies.ts tdsAppliesOnSale). The caller knows the
   * year's sales; this function only prices a sale.
   */
  tdsApplies?: boolean;
  /** Real "other charges (if incurred)" for this sale; defaults to the configured rate. */
  otherChargesPaise?: number;
  /** The actual artist→aggregator delivery leg, when it has been quoted. */
  deliveryChargePaise?: number;
}

// The client's payout sheets, updated with their answers of 30 Sep 2026
// (convenience 2%, technology 1%, "others if happens"; TDS only past ₹5 lakh
// of sales in the financial year).
//
//   MARKETPLACE            under the line    past it
//   Artist price              1,00,000        1,00,000
//   0.1% TDS                         0             100
//   convenience / technology / service GST   0       0
//   delivery                         0               0
//   Final bank payout         1,00,000          99,900
//
//   AGGREGATOR             under the line    past it
//   Artist price              1,00,000        1,00,000
//   0.1% TDS                         0             100
//   2% convenience               2,000           2,000
//   1% technology                1,000           1,000
//   other charges (real costs)       0               0
//   18% GST on those charges       540             540
//   Total of charges             3,540           3,640
//   Payment before delivery     96,460          96,360
//   delivery                     2,000           2,000
//   Final bank payout           94,460          94,360
//
// Marketplace takes nothing off the artist's price ("in the marketplace we
// pay 100% of the artist quoted price", 25 Aug) — TDS is the one exception,
// and it is money withheld for the government, not GalleryZone's margin.
export function artistSettlementOf(
  artistPrice: number,
  channel: SaleChannel,
  rates: PricingRates,
  options: ArtistSettlementOptions = {},
): ArtistSettlement {
  const tdsDeduction = options.tdsApplies ? Math.round(artistPrice * rates.artistTdsRate) : 0;

  if (channel === "marketplace") {
    return {
      gross: artistPrice,
      tdsDeduction,
      convenienceDeduction: 0,
      technologyDeduction: 0,
      otherChargesDeduction: 0,
      serviceGstDeduction: 0,
      chargesTotal: tdsDeduction,
      paymentBeforeDelivery: artistPrice - tdsDeduction,
      deliveryDeduction: 0,
      net: artistPrice - tdsDeduction,
    };
  }

  const convenienceDeduction = Math.round(artistPrice * rates.artistConvenienceRate);
  const technologyDeduction = Math.round(artistPrice * rates.artistTechnologyRate);
  const otherChargesDeduction = options.otherChargesPaise ?? rates.artistOtherChargePaise;
  const serviceGstDeduction = Math.round(
    (convenienceDeduction + technologyDeduction + otherChargesDeduction) * rates.serviceGstRate,
  );
  const deliveryDeduction = options.deliveryChargePaise ?? rates.deliveryChargePaise;
  const chargesTotal = tdsDeduction + convenienceDeduction + technologyDeduction + otherChargesDeduction + serviceGstDeduction;
  const paymentBeforeDelivery = artistPrice - chargesTotal;

  return {
    gross: artistPrice,
    tdsDeduction,
    convenienceDeduction,
    technologyDeduction,
    otherChargesDeduction,
    serviceGstDeduction,
    chargesTotal,
    paymentBeforeDelivery,
    deliveryDeduction,
    net: paymentBeforeDelivery - deliveryDeduction,
  };
}

/** Aggregator MOU §8. Both prices compared before GST. */
export function aggregatorCommissionOf(
  displayPrice: number,
  artistPrice: number,
  rates: PricingRates,
): number {
  const markup = Math.max(0, exGst(displayPrice, rates) - artistPrice);
  return Math.round(markup * rates.aggregatorCommissionRate);
}

/**
 * True when the aggregator's price is at least `aggregatorPriceWarnRate` above
 * GalleryZone's offer (1 = doubled). Both prices before GST. Never blocks a
 * reservation: it tells GalleryZone.
 */
export function isPriceWarning(sellingPrice: number, offerPrice: number, rates: PricingRates): boolean {
  return offerPrice > 0 && sellingPrice >= offerPrice * (1 + rates.aggregatorPriceWarnRate);
}

// --- The aggregator cycle ---------------------------------------------------

const DAY_MS = 24 * 60 * 60 * 1000;

export function addDays(from: string | Date, days: number): Date {
  return new Date(new Date(from).getTime() + days * DAY_MS);
}

export function listingEndsAt(cycleStartedAt: string | Date, rates: PricingRates): Date {
  return addDays(cycleStartedAt, rates.aggregatorListingDays);
}

export function daysLeftInListing(
  cycleStartedAt: string | Date,
  rates: PricingRates,
  now: number = Date.now(),
): number {
  return Math.max(0, Math.ceil((listingEndsAt(cycleStartedAt, rates).getTime() - now) / DAY_MS));
}

export function canPlaceWithAnotherAggregator({
  cycleStartedAt,
  placementsSoFar,
  rates,
  now = Date.now(),
}: {
  cycleStartedAt: string | Date | null;
  placementsSoFar: number;
  rates: PricingRates;
  now?: number;
}): boolean {
  if (cycleStartedAt === null) return true;
  if (placementsSoFar >= rates.aggregatorCycleMonths) return false;
  return daysLeftInListing(cycleStartedAt, rates, now) >= rates.aggregatorPlacementDays;
}

export interface PlacementWindow {
  expiresAt: Date;
  extended: boolean;
}

export function placementWindow({
  cycleStartedAt,
  assignedAt,
  rates,
}: {
  cycleStartedAt: string | Date;
  assignedAt: string | Date;
  rates: PricingRates;
}): PlacementWindow {
  const listingEnd = listingEndsAt(cycleStartedAt, rates);
  const naturalEnd = addDays(assignedAt, rates.aggregatorPlacementDays);
  const leftover = listingEnd.getTime() - naturalEnd.getTime();

  if (leftover < rates.aggregatorPlacementDays * DAY_MS) {
    return { expiresAt: listingEnd, extended: leftover > 0 };
  }
  return { expiresAt: naturalEnd, extended: false };
}

/** Clamps a cycle month into the configured table. Month past the end holds at the last rate. */
function cycleIndex(month: number, rates: PricingRates): number {
  if (month < 1) return 0;
  return Math.min(month, rates.aggregatorCycleMonths) - 1;
}

export function aggregatorDiscountRateOf(month: number, rates: PricingRates): number {
  const rate = rates.aggregatorMonthlyDiscountRates[cycleIndex(month, rates)];
  if (rate === undefined) {
    throw new Error(
      `aggregatorMonthlyDiscountRates has no entry for cycle index ${cycleIndex(month, rates)}`,
    );
  }
  return rate;
}

// The ladder steps down ₹2,000 a month (2% of the artist's price). When the
// month-1 aggregator priced above GalleryZone's offer ("appreciated"), the
// next aggregator's price resets to the offer and the drops start a month
// later. Client, 30 Sep 2026: "2000 less in each month as per earlier plan; if
// appreciated by aggregator then 3rd month, if not then drop starts from
// 2nd month itself". On ₹1,00,000:
//
//   month                     1          2          3          4          5
//   month 1 not appreciated  1,30,000   1,28,000   1,26,000   1,24,000   1,22,000
//   month 1 appreciated      1,30,000   1,30,000   1,28,000   1,26,000   1,24,000
export function aggregatorOfferPriceOf(
  artistPrice: number,
  month: number,
  rates: PricingRates,
  { appreciated = false }: { appreciated?: boolean } = {},
): number {
  const steps = appreciated ? Math.max(1, month - 1) : month;
  const reduction = Math.round(artistPrice * aggregatorDiscountRateOf(steps, rates));
  return basePriceOf(artistPrice, rates) - reduction;
}

export interface AggregatorAdvance {
  month: number;
  rate: number;
  base: number;
  basis: "selling_price" | "artist_price";
  advance: number;
  deliveryCharge: number;
  payable: number;
}

// Client, 30 Sep 2026. Month 1: 5% of the price the aggregator sets, before
// GST (₹7,500 on ₹1,50,000; ₹6,500 if they keep ₹1,30,000). Month 2: 5% of the
// artist's price. Months 3 to 5: 3% of the artist's price. (The 3% is left as
// a literal, matching frontend-web/lib/pricing.ts, until the client wants it
// tuned.)
export function aggregatorAdvanceForMonth({
  month,
  sellingPrice,
  artistPrice,
  rates,
  deliveryCharge,
}: {
  month: number;
  /** What the aggregator sells at, before GST. Only month 1 uses it. */
  sellingPrice: number;
  artistPrice: number;
  rates: PricingRates;
  deliveryCharge?: number;
}): AggregatorAdvance {
  const resolvedDeliveryCharge = deliveryCharge ?? rates.deliveryChargePaise;
  const firstMonth = month <= 1;
  const rate = month <= 2 ? rates.aggregatorAdvanceRate : 0.03;
  const base = firstMonth ? sellingPrice : artistPrice;
  const advance = Math.round(base * rate);

  return {
    month,
    rate,
    base,
    basis: firstMonth ? "selling_price" : "artist_price",
    advance,
    deliveryCharge: resolvedDeliveryCharge,
    payable: advance + resolvedDeliveryCharge,
  };
}

// --- Delivery ---------------------------------------------------------------

function digitsOf(pincode: string): string {
  return pincode.replace(/[^0-9]/g, "");
}

export function deliveryZoneBetween(
  from: string,
  to: string,
  rates: PricingRates,
): DeliveryZone {
  const a = digitsOf(from);
  const b = digitsOf(to);
  if (a.length < 6 || b.length < 6) return "national";
  if (
    rates.remotePincodePrefixes.includes(a.slice(0, 2)) ||
    rates.remotePincodePrefixes.includes(b.slice(0, 2))
  ) {
    return "remote";
  }
  if (a.slice(0, 3) === b.slice(0, 3)) return "local";
  if (a.slice(0, 2) === b.slice(0, 2)) return "regional";
  if (a.slice(0, 1) === b.slice(0, 1)) return "metro";
  return "national";
}

export function billableWeightKg({
  actualKg,
  lengthCm,
  breadthCm,
  heightCm,
}: {
  actualKg: number;
  lengthCm?: number | null;
  breadthCm?: number | null;
  heightCm?: number | null;
}): number {
  if (!lengthCm || !breadthCm || !heightCm) return actualKg;
  const volumetric = (lengthCm * breadthCm * heightCm) / 5000;
  return Math.max(actualKg, Math.round(volumetric * 10) / 10);
}

export interface DeliveryEstimate {
  zone: DeliveryZone;
  billableKg: number;
  charge: number;
  estimated: boolean;
}

export function estimateDelivery({
  billableKg,
  fromPincode,
  toPincode,
  rates,
}: {
  billableKg?: number | null;
  fromPincode?: string | null;
  toPincode?: string | null;
  rates: PricingRates;
}): DeliveryEstimate {
  if (!billableKg || billableKg <= 0 || !fromPincode || !toPincode) {
    return { zone: "national", billableKg: billableKg ?? 0, charge: rates.deliveryChargePaise, estimated: false };
  }

  const zone = deliveryZoneBetween(fromPincode, toPincode, rates);
  const { base, perExtraKg } = rates.deliveryZoneRates[zone];
  const extraKg = Math.max(0, Math.ceil(billableKg - rates.deliveryBaseSlabKg));
  // Rounded to the nearest rupee, the way a courier quotes.
  const charge = Math.round((base + extraKg * perExtraKg) / 100) * 100;

  return { zone, billableKg, charge, estimated: true };
}

// --- Payout timing ----------------------------------------------------------

export function payoutReleaseDate(deliveredAt: string | Date, rates: PricingRates): Date {
  const delivered = new Date(deliveredAt);
  const release = new Date(delivered);
  release.setDate(release.getDate() + rates.artistPayoutDaysAfterDelivery);
  return release;
}

export function isPayoutDue(
  deliveredAt: string | Date,
  rates: PricingRates,
  now: number = Date.now(),
): boolean {
  return payoutReleaseDate(deliveredAt, rates).getTime() <= now;
}
