// How the pricing rules are presented in the admin console: which group a
// rate belongs to, what unit it is in, and the one-line explanation of what
// changing it actually does. The keys mirror PricingRates on the API
// (packages/domain/src/pricing.ts) — anything the API sends that isn't
// listed here still renders, under "Other", so a new rate is never hidden.

export type RateUnit = "percent" | "rupees" | "days" | "number" | "list" | "zones";

export interface RateField {
  key: string;
  label: string;
  unit: RateUnit;
  hint: string;
}

export interface RateGroup {
  title: string;
  description: string;
  fields: RateField[];
}

export const RATE_GROUPS: RateGroup[] = [
  {
    title: "The artwork price",
    description: "What the customer sees, and how it is built from the artist's own price.",
    fields: [
      { key: "platformMarkup", label: "GalleryZone appreciation", unit: "percent", hint: "Added over the artist's price. ₹1,00,000 + 30% = ₹1,30,000." },
      { key: "gstRate", label: "GST on the artwork", unit: "percent", hint: "HSN 9701. Sits inside the displayed price — never added again at checkout." },
    ],
  },
  {
    title: "What the customer pays",
    description: "The invoice, line by line, below the artwork price.",
    fields: [
      { key: "customerConvenienceRate", label: "Customer convenience fee", unit: "percent", hint: "Of the pre-GST order value. Quoted at 0.1% on the invoice sheet but not charged yet — leave at 0 to keep it off." },
      { key: "deliveryChargePaise", label: "Flat delivery charge", unit: "rupees", hint: "Fallback used when an artwork has no weight or the destination is unknown." },
    ],
  },
  {
    title: "What the artist is paid",
    description: "Deductions from the artist's own price. Marketplace takes nothing but TDS.",
    fields: [
      { key: "artistTdsRate", label: "Income-tax TDS", unit: "percent", hint: "§194-O, on the artist's price. Withheld only once the artist's sales in the financial year pass the tracking threshold below." },
      { key: "artistConvenienceRate", label: "Artist convenience charge", unit: "percent", hint: "Aggregator sales only. ₹1,00,000 → ₹2,000." },
      { key: "artistTechnologyRate", label: "Artist technology charge", unit: "percent", hint: "Aggregator sales only. ₹1,00,000 → ₹1,000." },
      { key: "artistOtherChargePaise", label: "Other charges (default)", unit: "rupees", hint: "The sheet's “if incurred — e.g. tech” line. Stays 0 until a real trigger exists." },
      { key: "serviceGstRate", label: "GST on service charges", unit: "percent", hint: "18% on the convenience, listing, tech and subscription fees — never on the artwork." },
      { key: "artistPayoutDaysAfterDelivery", label: "Payout released after", unit: "days", hint: "Days from delivery before the artist's settlement can be withdrawn." },
    ],
  },
  {
    title: "Service charges",
    description: "Billed separately from any sale. Each carries the 18% service GST above.",
    fields: [
      { key: "artistListingFeeRate", label: "Listing fee", unit: "percent", hint: "Of the artist's price, charged at listing. ₹1,00,000 → ₹1,000 + ₹180 GST." },
      { key: "subscriptionFeePaise", label: "Subscription", unit: "rupees", hint: "Per billing period. ₹1,200 + ₹216 GST = ₹1,416." },
      { key: "nfcTagChargePaise", label: "Technology / NFC tag", unit: "rupees", hint: "Charged once per tag issued. ₹100 + ₹18 GST = ₹118." },
    ],
  },
  {
    title: "Aggregators",
    description: "Consignment terms — the advance, the commission and the rotation window.",
    fields: [
      { key: "aggregatorAdvanceRate", label: "Advance / security deposit", unit: "percent", hint: "MOU §7. Month 1: of the price the aggregator chose, before GST. Month 2: of the artist price. Months 3 to 5 are charged at 3%." },
      { key: "aggregatorCommissionRate", label: "Aggregator commission", unit: "percent", hint: "MOU §8. Of (selling price − artist price), both before GST." },
      { key: "aggregatorListingDays", label: "Listing window", unit: "days", hint: "The whole cycle a piece may rotate through aggregators." },
      { key: "aggregatorPlacementDays", label: "One placement", unit: "days", hint: "How long a single aggregator may hold a piece." },
      { key: "aggregatorCycleMonths", label: "Aggregators per cycle", unit: "number", hint: "How many aggregators a piece can pass through before it must come back." },
      { key: "aggregatorMonthlyDiscountRates", label: "Monthly offer ladder", unit: "list", hint: "Percent off the artist price for each successive month, starting at month 1. It starts a month later if the first aggregator priced above GalleryZone's offer." },
      { key: "aggregatorPriceWarnRate", label: "Price warning", unit: "percent", hint: "When an aggregator's month-1 price is this far above GalleryZone's offer, GalleryZone is emailed. It never blocks the reservation. 100% = doubled." },
    ],
  },
  {
    title: "Limits and thresholds",
    description: "Guard rails the portals enforce.",
    fields: [
      { key: "minWithdrawalPaise", label: "Minimum withdrawal", unit: "rupees", hint: "Artists and aggregators." },
      { key: "minCustomerWithdrawalPaise", label: "Minimum withdrawal (collector)", unit: "rupees", hint: "Collector wallets." },
      { key: "insuranceThresholdPaise", label: "Insurance recommended above", unit: "rupees", hint: "Transit insurance is suggested on the upload form at or above this price." },
      { key: "earningsAbove5LThresholdPaise", label: "TDS tracking threshold", unit: "rupees", hint: "Financial-year (April to March) sales at which TDS starts being withheld from an artist. ₹5,00,000." },
      { key: "externalSalePenaltyRate", label: "External-sale fee", unit: "percent", hint: "Charged when an artist sells a listed piece elsewhere." },
      { key: "artistEditWindowDays", label: "Free edit window", unit: "days", hint: "How long an artist may edit a listing after it goes live." },
    ],
  },
  {
    title: "Delivery rate card",
    description: "Used when an artwork has a weight and both pincodes are known.",
    fields: [
      { key: "deliveryBaseSlabKg", label: "Base weight slab", unit: "number", hint: "Kilograms included in each zone's base rate." },
      { key: "deliveryZoneRates", label: "Zone rates", unit: "zones", hint: "Base charge and per-extra-kg charge for each distance zone." },
      { key: "remotePincodePrefixes", label: "Remote pincode prefixes", unit: "list", hint: "Two-digit prefixes billed at the remote-zone rate." },
    ],
  },
];

export const FIELD_BY_KEY = new Map(RATE_GROUPS.flatMap((g) => g.fields.map((f) => [f.key, f] as const)));

/** Rates the API sends that no group claims — rendered read-only under "Other". */
export function ungroupedKeys(rates: Record<string, unknown>): string[] {
  return Object.keys(rates).filter((key) => !FIELD_BY_KEY.has(key));
}

export function formatRate(key: string, value: unknown): string {
  const unit = FIELD_BY_KEY.get(key)?.unit;
  if (typeof value === "number") {
    if (unit === "percent") return `${+(value * 100).toFixed(4)}%`;
    if (unit === "rupees") return `₹${(value / 100).toLocaleString("en-IN")}`;
    if (unit === "days") return `${value} days`;
    return String(value);
  }
  if (Array.isArray(value)) return value.map((v) => (typeof v === "number" ? `${+(v * 100).toFixed(2)}%` : String(v))).join(", ");
  if (value && typeof value === "object") return `${Object.keys(value).length} zones`;
  return String(value);
}

/** The editable form value for a rate: percent as a percentage, paise as rupees. */
export function toFormValue(key: string, value: number): number {
  const unit = FIELD_BY_KEY.get(key)?.unit;
  if (unit === "percent") return +(value * 100).toFixed(4);
  if (unit === "rupees") return value / 100;
  return value;
}

/** The inverse of toFormValue — what the API is sent. */
export function fromFormValue(key: string, value: number): number {
  const unit = FIELD_BY_KEY.get(key)?.unit;
  if (unit === "percent") return +(value / 100).toFixed(6);
  if (unit === "rupees") return Math.round(value * 100);
  return value;
}
