// Small pure policies that aren't strictly "pricing" but are exactly the
// kind of number the plan's "nothing hardcoded" rule covers — edit windows,
// penalty rates, withdrawal minimums, insurance/TDS thresholds. Kept in
// their own file rather than pricing.ts because they gate BEHAVIOR
// (can this artist edit? is this withdrawal allowed?) rather than compute a
// rupee figure, but they still take `rates` as a parameter for the same
// reason every pricing.ts function does.

import type { PricingRates } from "./pricing.ts";
import { addDays } from "./pricing.ts";
import type { ArtworkStatus } from "./state-machine.ts";

// Statuses past which an artist can no longer freely edit a listing, even
// if inside the day window — matches artistDashboardService's
// PURCHASE_LOCKED_STATUSES concept (the mock's own name for this set).
export const PURCHASE_LOCKED_ARTWORK_STATUSES: readonly ArtworkStatus[] = [
  "reserved",
  "with_aggregator",
  "sold",
  "settlement_complete",
  "delivered",
  "completed",
  "sold_externally",
];

export function editWindowExpiresAt(firstListedAt: string | Date, rates: PricingRates): Date {
  return addDays(firstListedAt, rates.artistEditWindowDays);
}

export function canEditArtwork({
  firstListedAt,
  status,
  rates,
  now = new Date(),
}: {
  firstListedAt: string | Date;
  status: ArtworkStatus;
  rates: PricingRates;
  now?: Date;
}): boolean {
  if (PURCHASE_LOCKED_ARTWORK_STATUSES.includes(status)) return false;
  return now.getTime() < editWindowExpiresAt(firstListedAt, rates).getTime();
}

// External-sale penalty (artistDashboardService.markSoldElsewhere) — a
// piece withdrawn from GalleryZone to sell elsewhere while still listed
// owes a fraction of the artist's own quoted price, not the display price
// (the artist never disclosed a display price for an off-platform sale).
export function externalSalePenaltyOf(artistPricePaise: number, rates: PricingRates): number {
  return Math.round(artistPricePaise * rates.externalSalePenaltyRate);
}

export function meetsMinWithdrawal(amountPaise: number, rates: PricingRates): boolean {
  return amountPaise >= rates.minWithdrawalPaise;
}

export function meetsMinCustomerWithdrawal(amountPaise: number, rates: PricingRates): boolean {
  return amountPaise >= rates.minCustomerWithdrawalPaise;
}

export function insuranceRecommended(artistPricePaise: number, rates: PricingRates): boolean {
  return artistPricePaise >= rates.insuranceThresholdPaise;
}

// Drives the admin-editable "earnings above 5L" flag's automatic side —
// types/admin.ts's earningsAbove5L is admin-toggleable, but this function
// is what a background job (Phase 2+) uses to suggest the flip rather than
// requiring an admin to notice on their own.
export function shouldFlagEarningsAbove5L(yearToDateEarningsPaise: number, rates: PricingRates): boolean {
  return yearToDateEarningsPaise >= rates.earningsAbove5LThresholdPaise;
}

// One wallet top-up through Razorpay. The floor is about what one reservation
// needs; the ceiling keeps a mistyped amount from becoming a very large charge.
// ponytail: fixed here, not in the admin rate console; move it there if it ever needs tuning.
export const WALLET_TOPUP_MIN_PAISE = 100_000; // ₹1,000
export const WALLET_TOPUP_MAX_PAISE = 50_000_000; // ₹5,00,000

/** Cash taken at the counter is GalleryZone's money. The full price is due within this many days (client, 30 Sep 2026: "2 days to deposit"). */
export const CASH_REMITTANCE_DAYS = 2;

export function cashRemittanceDueAt(soldAt: Date): Date {
  return new Date(soldAt.getTime() + CASH_REMITTANCE_DAYS * 86_400_000);
}

const IST_OFFSET_MS = 330 * 60_000;

/** 1 April, 00:00 India time, of the financial year that `asOf` falls in. §194-O counts April to March. */
export function financialYearStart(asOf: Date): Date {
  const ist = new Date(asOf.getTime() + IST_OFFSET_MS);
  const year = ist.getUTCMonth() >= 3 ? ist.getUTCFullYear() : ist.getUTCFullYear() - 1;
  return new Date(Date.UTC(year, 3, 1) - IST_OFFSET_MS);
}

/**
 * §194-O TDS on an artist's sale (client, 30 Sep 2026: "only when the artist's
 * sales this year cross ₹5 lakh"). It applies to the sale that takes the
 * financial year's total past the threshold, and to every sale after it, on
 * that sale's whole artist price. `salesSoFarPaise` is the year's sales BEFORE
 * this one. Deducting on the whole crossing sale, not only the part above the
 * line, errs towards withholding too much (claimable back) over too little.
 */
export function tdsAppliesOnSale(salesSoFarPaise: number, artistPricePaise: number, rates: PricingRates): boolean {
  return salesSoFarPaise + artistPricePaise > rates.earningsAbove5LThresholdPaise;
}

/**
 * Early Artist Program (owner, 1 Oct 2026): every artist's first 6 months are
 * free, counted from the day they join. An artist who filled in the artist
 * survey before launch gets a full year instead.
 */
export const EARLY_ACCESS_MONTHS = 6;
export const EARLY_ACCESS_SURVEY_MONTHS = 12;

/** When free access ends: `joinedAt` plus the months, by calendar. A 31st joined into a shorter month ends on that month's last day. */
export function earlyAccessEndsAt(joinedAt: Date, surveyRespondent: boolean): Date {
  const months = surveyRespondent ? EARLY_ACCESS_SURVEY_MONTHS : EARLY_ACCESS_MONTHS;
  const end = new Date(joinedAt);
  const day = end.getUTCDate();
  end.setUTCDate(1);
  end.setUTCMonth(end.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth() + 1, 0)).getUTCDate();
  end.setUTCDate(Math.min(day, lastDay));
  return end;
}
