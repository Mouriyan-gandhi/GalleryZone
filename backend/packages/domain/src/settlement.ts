// Ledger posting construction — plan.md §9 (Money flows), rebuilt against
// the actual pricing.ts numbers rather than plan.md's superseded formulas
// (see that section's own note in the plan). Every function here returns a
// set of postings whose amounts sum to exactly zero — that invariant is
// what packages/db's ledger_entries table + DB trigger enforce at write
// time, and what settlement.check.ts's property test verifies here first,
// pre-write, so a bug is caught in a unit test rather than a failed insert.
//
// Pure, zero I/O: these functions never touch a database. packages/db's
// repository layer is what turns a Posting[] into ledger_entries rows
// inside one DB transaction, tagged with a shared transactionId.

import {
  aggregatorCommissionOf,
  artistSettlementOf,
  checkoutTotal,
  exGst,
  type PricingRates,
} from "./pricing.ts";

export type LedgerAccountType =
  | "artist_payable"
  | "aggregator_payable"
  | "aggregator_held"
  | "customer_wallet"
  | "platform_revenue"
  | "razorpay_escrow"
  | "gst_payable"
  | "tds_payable";

export interface Posting {
  accountType: LedgerAccountType;
  /** Whose account, e.g. an artist's userId — omitted for a system account. */
  ownerId?: string;
  amountPaise: number;
  reason: string;
}

function assertBalanced(postings: Posting[], label: string): Posting[] {
  const sum = postings.reduce((total, p) => total + p.amountPaise, 0);
  if (sum !== 0) {
    throw new Error(`${label}: postings do not sum to zero (got ${sum})`);
  }
  return postings;
}

// --- Marketplace checkout -----------------------------------------------------
//
// Money in: the full checkout total, captured into Razorpay Route escrow.
// Money out, immediately recognized: GST payable (statutory liability, not
// GalleryZone's revenue) and the artist's payable (released later by the
// 7-day-post-delivery job — see artistPayoutJob below — this posting is
// when the LIABILITY is recognized, not when cash actually reaches the
// artist's bank account, which is a separate RazorpayX payout event).
// What's left in escrow after GST + artist payable is GalleryZone's margin.
export function marketplaceCheckoutPostings({
  artistId,
  artistPricePaise,
  rates,
  tdsApplies = false,
}: {
  artistId: string;
  artistPricePaise: number;
  rates: PricingRates;
  /** Drives the §194-O TDS leg: true once this sale takes the artist's year past the threshold. */
  tdsApplies?: boolean;
}): Posting[] {
  const displayPrice = Math.round(artistPricePaise * (1 + rates.platformMarkup) * (1 + rates.gstRate));
  const checkout = checkoutTotal(displayPrice, rates);
  const settlement = artistSettlementOf(artistPricePaise, "marketplace", rates, { tdsApplies });
  // Residual, same reasoning as aggregatorSalePostings below: balances by
  // construction, and also carries the delivery-courier pass-through
  // (checkout.deliveryCharge is customer-paid, not artist-deducted, on
  // marketplace sales, but GalleryZone still owes it to the courier).
  // GST owed to the government: the 5% inside the artwork price, plus 18%
  // on the customer's convenience fee. Both are statutory liabilities, never
  // GalleryZone's revenue, so they leave escrow on the same leg.
  const gstLiability = checkout.gstIncluded + checkout.convenienceGst;
  const platformResidual = checkout.total - gstLiability - settlement.tdsDeduction - settlement.net;

  return assertBalanced(
    [
      { accountType: "razorpay_escrow", amountPaise: checkout.total, reason: "checkout_capture" },
      { accountType: "gst_payable", amountPaise: -gstLiability, reason: "gst_liability" },
      { accountType: "tds_payable", amountPaise: -settlement.tdsDeduction, reason: "artist_tds_withheld" },
      { accountType: "artist_payable", ownerId: artistId, amountPaise: -settlement.net, reason: "marketplace_settlement" },
      { accountType: "platform_revenue", amountPaise: -platformResidual, reason: "margin_and_delivery_passthrough" },
    ],
    "marketplaceCheckoutPostings",
  );
}

// --- Aggregator sale ------------------------------------------------------------
//
// Two money events, kept separate because they can land on different days:
// (1) the advance and delivery deposit were held from the aggregator's wallet
// at reservation time (aggregatorHoldPostings, below) — recordSale() does NOT
// take them again;
// (2) the sale itself, which recognizes the artist payable, the aggregator's
// commission payable, and releases GalleryZone's margin, while the hold goes
// back to the aggregator's wallet (client, 30 Sep 2026: the money is held, and
// "comes back when the piece sells").
export function aggregatorSalePostings({
  artistId,
  aggregatorId,
  displayPricePaise,
  artistPricePaise,
  heldPaise,
  rates,
  tdsApplies = false,
  otherChargesPaise,
  deliveryChargePaise,
}: {
  artistId: string;
  aggregatorId: string;
  displayPricePaise: number;
  artistPricePaise: number;
  /** The advance and delivery deposit held from the aggregator's wallet at reservation. */
  heldPaise: number;
  rates: PricingRates;
  tdsApplies?: boolean;
  /** "Other charges (if incurred)" actually billed on this sale. */
  otherChargesPaise?: number;
  /** The real artist→aggregator delivery leg, when it has been quoted. */
  deliveryChargePaise?: number;
}): Posting[] {
  const gstIncluded = displayPricePaise - exGst(displayPricePaise, rates);
  const settlement = artistSettlementOf(artistPricePaise, "aggregator", rates, {
    tdsApplies,
    ...(otherChargesPaise === undefined ? {} : { otherChargesPaise }),
    ...(deliveryChargePaise === undefined ? {} : { deliveryChargePaise }),
  });
  const commission = aggregatorCommissionOf(displayPricePaise, artistPricePaise, rates);

  // platform_revenue is the RESIDUAL of the capture — displayPrice minus
  // every other named leg — rather than a separately-derived figure. This
  // is deliberate: computing it as a residual makes the postings balance
  // by construction, immune to any rounding drift between this function
  // and pricing.ts's own rounding. Note this residual also carries the
  // delivery-courier pass-through (settlement.deliveryDeduction was
  // deducted from the artist but must still be paid to a real courier) —
  // it is not GalleryZone's true kept margin on its own; the worked
  // example's "GalleryZone keeps 42,000" figure is this residual MINUS
  // settlement.deliveryDeduction, a reporting-time calculation, not a
  // separate ledger account (this scaffold has no dedicated
  // courier_payable account type yet — Phase 2 can split it out once the
  // real Shiprocket/courier billing integration exists).
  // The 18% service GST withheld from the artist (on convenience, technology
  // and any other charges) is owed to the government too, so it joins the
  // artwork GST on the gst_payable leg rather than sitting in GalleryZone's
  // margin.
  const gstLiability = gstIncluded + settlement.serviceGstDeduction;
  const platformResidual =
    displayPricePaise - gstLiability - settlement.tdsDeduction - settlement.net - commission;

  return assertBalanced(
    [
      // The hold made at reservation goes back to the aggregator's wallet. It
      // isn't new money: it is the aggregatorHoldPostings legs, reversed.
      { accountType: "aggregator_held", ownerId: aggregatorId, amountPaise: heldPaise, reason: "hold_released_on_sale" },
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise: -heldPaise, reason: "hold_returned_to_wallet" },
      { accountType: "razorpay_escrow", amountPaise: displayPricePaise, reason: "aggregator_sale_capture" },
      { accountType: "gst_payable", amountPaise: -gstLiability, reason: "gst_liability" },
      { accountType: "tds_payable", amountPaise: -settlement.tdsDeduction, reason: "artist_tds_withheld" },
      { accountType: "artist_payable", ownerId: artistId, amountPaise: -settlement.net, reason: "aggregator_settlement" },
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise: -commission, reason: "aggregator_commission" },
      { accountType: "platform_revenue", amountPaise: -platformResidual, reason: "margin_and_delivery_passthrough" },
    ],
    "aggregatorSalePostings",
  );
}

// --- Aggregator wallet: top-up, hold, release -----------------------------------
//
// aggregator_payable is the wallet: what GalleryZone owes the aggregator, and
// what they can reserve with or withdraw. Money reaches it only from a real
// payment (a Razorpay top-up) or from a sale (commission, a released hold).
// aggregator_held is what is set aside for reservations: still theirs, but not
// spendable and not withdrawable until the piece sells or comes back.

/** Money in: the aggregator paid a Razorpay order. The cash is in escrow and it is now theirs to spend. */
export function walletTopupPostings({ aggregatorId, amountPaise }: { aggregatorId: string; amountPaise: number }): Posting[] {
  return assertBalanced(
    [
      { accountType: "razorpay_escrow", amountPaise, reason: "wallet_topup_capture" },
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise: -amountPaise, reason: "wallet_topup" },
    ],
    "walletTopupPostings",
  );
}

// Reserving sets aside the advance plus the delivery deposit from the wallet.
// The amounts are whatever aggregatorAdvanceForMonth decided for this month and
// were recorded on the holding; nothing here recomputes them. No cash moves:
// the money was already in escrow from the top-up.
export function aggregatorHoldPostings({
  aggregatorId,
  advancePaise,
  deliveryPaise,
}: {
  aggregatorId: string;
  advancePaise: number;
  deliveryPaise: number;
}): Posting[] {
  const hold = advancePaise + deliveryPaise;
  return assertBalanced(
    [
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise: hold, reason: "reservation_hold" },
      { accountType: "aggregator_held", ownerId: aggregatorId, amountPaise: -hold, reason: "reservation_hold" },
    ],
    "aggregatorHoldPostings",
  );
}

// --- Unsold return: advance back in the wallet, delivery forfeited ----------------
//
// The delivery deposit pays for the courier leg the piece caused, so it goes to
// GalleryZone's side (platform_revenue carries the courier pass-through, as it
// does on a sale). It comes back only on a sale.

export function aggregatorReturnPostings({
  aggregatorId,
  advancePaise,
  deliveryPaise,
}: {
  aggregatorId: string;
  advancePaise: number;
  deliveryPaise: number;
}): Posting[] {
  return assertBalanced(
    [
      { accountType: "aggregator_held", ownerId: aggregatorId, amountPaise: advancePaise + deliveryPaise, reason: "hold_released_on_return" },
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise: -advancePaise, reason: "advance_returned_to_wallet" },
      ...(deliveryPaise > 0
        ? [{ accountType: "platform_revenue" as const, amountPaise: -deliveryPaise, reason: "delivery_deposit_forfeited" }]
        : []),
    ],
    "aggregatorReturnPostings",
  );
}

// --- Cash sale: the aggregator pays the price in from their wallet ------------------
//
// A cash_at_premises sale books the customer's payment into escrow at the moment
// of sale (aggregatorSalePostings) although the cash is in the aggregator's till.
// Depositing it retires that placeholder. From the wallet: the aggregator's
// balance is reduced and the escrow leg is settled against the cash they paid in
// through the top-up, so escrow ends up equal to real money. A bank transfer to
// GalleryZone needs no posting: the cash the sale already counted has arrived.
// ponytail: an aggregator_receivable account would show the debt while it is
// open; add it if unremitted cash ever needs reporting on the books.
export function cashRemittanceFromWalletPostings({ aggregatorId, amountPaise }: { aggregatorId: string; amountPaise: number }): Posting[] {
  return assertBalanced(
    [
      { accountType: "aggregator_payable", ownerId: aggregatorId, amountPaise, reason: "cash_sale_paid_from_wallet" },
      { accountType: "razorpay_escrow", amountPaise: -amountPaise, reason: "cash_sale_remitted" },
    ],
    "cashRemittanceFromWalletPostings",
  );
}

// --- Withdrawal payout (RazorpayX) — discharges a payable once cash actually leaves --
//
// The payable was originally recognized as a negative posting on the
// owner's account (see e.g. artist_payable: -settlement.net above) — that
// negative IS the liability. Paying it out extinguishes the liability
// (posted back to zero, i.e. +amountPaise here) at the same moment the
// backing cash leaves escrow (-amountPaise) — the two exactly cancel,
// because escrow was always what the payable was a claim against. No third
// "revenue" leg is needed: this transaction doesn't create or destroy
// value, it just discharges a claim against cash that was already earmarked
// for it.
export function withdrawalPayoutPostings({
  accountType,
  ownerId,
  amountPaise,
}: {
  accountType: Extract<LedgerAccountType, "artist_payable" | "aggregator_payable" | "customer_wallet">;
  ownerId: string;
  amountPaise: number;
}): Posting[] {
  return assertBalanced(
    [
      { accountType, ownerId, amountPaise, reason: "payable_discharged" },
      { accountType: "razorpay_escrow", amountPaise: -amountPaise, reason: "razorpayx_payout" },
    ],
    "withdrawalPayoutPostings",
  );
}
