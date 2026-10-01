// Run: node --experimental-strip-types packages/domain/src/policies.check.ts

import assert from "node:assert/strict";
import { DEFAULT_RATE_SEED } from "./pricing.ts";
import {
  canEditArtwork,
  cashRemittanceDueAt,
  earlyAccessEndsAt,
  editWindowExpiresAt,
  externalSalePenaltyOf,
  insuranceRecommended,
  meetsMinCustomerWithdrawal,
  financialYearStart,
  meetsMinWithdrawal,
  shouldFlagEarningsAbove5L,
  tdsAppliesOnSale,
} from "./policies.ts";

const rates = DEFAULT_RATE_SEED;

// --- Edit window ---------------------------------------------------------------
{
  const listedAt = "2026-01-01T00:00:00.000Z";
  assert.equal(editWindowExpiresAt(listedAt, rates).toISOString(), "2026-01-08T00:00:00.000Z");

  assert.equal(
    canEditArtwork({ firstListedAt: listedAt, status: "marketplace", rates, now: new Date("2026-01-05T00:00:00.000Z") }),
    true,
    "inside the 7-day window and not purchase-locked",
  );
  assert.equal(
    canEditArtwork({ firstListedAt: listedAt, status: "marketplace", rates, now: new Date("2026-01-09T00:00:00.000Z") }),
    false,
    "past the 7-day window",
  );
  assert.equal(
    canEditArtwork({ firstListedAt: listedAt, status: "sold", rates, now: new Date("2026-01-02T00:00:00.000Z") }),
    false,
    "purchase-locked status blocks editing even inside the window",
  );
  assert.equal(
    canEditArtwork({ firstListedAt: listedAt, status: "draft", rates, now: new Date("2026-01-02T00:00:00.000Z") }),
    true,
    "draft is not purchase-locked",
  );
}

// --- External-sale penalty ------------------------------------------------------
{
  assert.equal(externalSalePenaltyOf(100_000_00, rates), 100_000, "1% of ₹1,00,000 = ₹1,000 (in paise)");
}

// --- Withdrawal minimums ----------------------------------------------------------
{
  assert.equal(meetsMinWithdrawal(100_000, rates), true, "exactly ₹1,000 meets the artist/aggregator minimum");
  assert.equal(meetsMinWithdrawal(99_999, rates), false);
  assert.equal(meetsMinCustomerWithdrawal(50_000, rates), true, "exactly ₹500 meets the customer minimum");
  assert.equal(meetsMinCustomerWithdrawal(49_999, rates), false);
}

// --- Insurance / TDS thresholds -----------------------------------------------------
{
  assert.equal(insuranceRecommended(2_000_000, rates), true, "exactly ₹20,000 recommends insurance");
  assert.equal(insuranceRecommended(1_999_999, rates), false);
  assert.equal(shouldFlagEarningsAbove5L(50_000_000, rates), true, "exactly ₹5,00,000 flags TDS tracking");
  assert.equal(shouldFlagEarningsAbove5L(49_999_999, rates), false);
}

// --- Financial year (April to March, India time) ---------------------------------
{
  const iso = (d: Date) => d.toISOString();
  // 1 April 00:00 IST is 31 March 18:30 UTC.
  assert.equal(iso(financialYearStart(new Date("2026-09-30T10:00:00.000Z"))), "2026-03-31T18:30:00.000Z", "September is in FY 2026-27");
  assert.equal(iso(financialYearStart(new Date("2027-02-14T10:00:00.000Z"))), "2026-03-31T18:30:00.000Z", "February belongs to the year that began the April before");
  assert.equal(iso(financialYearStart(new Date("2026-03-31T18:29:59.000Z"))), "2025-03-31T18:30:00.000Z", "the last second of March IST is still last year's");
  assert.equal(iso(financialYearStart(new Date("2026-03-31T18:30:00.000Z"))), "2026-03-31T18:30:00.000Z", "1 April 00:00 IST starts the new year");
}

// --- TDS §194-O: only once the year's sales pass ₹5 lakh (client, 30 Sep 2026) ----
{
  const R = (rupees: number) => rupees * 100;
  assert.equal(tdsAppliesOnSale(0, R(100_000), rates), false, "a first ₹1,00,000 sale is under the line");
  assert.equal(tdsAppliesOnSale(R(300_000), R(100_000), rates), false, "₹4,00,000 in total");
  assert.equal(tdsAppliesOnSale(R(400_000), R(100_000), rates), false, "exactly ₹5,00,000 is not past it");
  assert.equal(tdsAppliesOnSale(R(400_000), R(100_001), rates), true, "one rupee over crosses it");
  assert.equal(tdsAppliesOnSale(R(450_000), R(100_000), rates), true, "the crossing sale is taxed on its whole price");
  assert.equal(tdsAppliesOnSale(R(900_000), R(100_000), rates), true, "and every sale after it");
  assert.equal(tdsAppliesOnSale(0, R(600_000), rates), true, "a single sale can cross it alone");
}

// --- Cash sale deposit: two days -------------------------------------------------
{
  assert.equal(cashRemittanceDueAt(new Date("2026-09-30T10:00:00.000Z")).toISOString(), "2026-10-02T10:00:00.000Z", "due two days after the sale");
}

// --- Early Artist Program: 6 months free, a year for survey respondents ----------
{
  const ends = (joined: string, survey: boolean) => earlyAccessEndsAt(new Date(joined), survey).toISOString();
  assert.equal(ends("2026-10-01T09:30:00.000Z", false), "2027-04-01T09:30:00.000Z", "six months from joining");
  assert.equal(ends("2026-10-01T09:30:00.000Z", true), "2027-10-01T09:30:00.000Z", "a survey respondent gets a full year");
  assert.equal(ends("2026-08-31T00:00:00.000Z", false), "2027-02-28T00:00:00.000Z", "31 Aug + 6 months lands on the last day of February, not in March");
  assert.equal(ends("2027-08-31T00:00:00.000Z", false), "2028-02-29T00:00:00.000Z", "and on the 29th in a leap year");
  assert.equal(ends("2026-12-15T00:00:00.000Z", false), "2027-06-15T00:00:00.000Z", "a year boundary carries over");
}

console.log("packages/domain/policies.ts checks passed");
