import { IndianRupee, Wallet, Clock3 } from "lucide-react";

// Activity entries carry a `kind` string rather than a Lucide icon component
// (not JSON-serializable); recent-activity-feed.tsx maps the kind to an icon at
// render time. The entries themselves are derived from real events in
// artistDashboardService.getActivity.
export type ActivityKind =
  | "artwork_approved"
  | "artwork_submitted"
  | "settlement"
  | "verification"
  | "withdrawal";

// The three cards at the top of the artist dashboard: which, what they are
// called and how they read. Their values are worked out from the artist's own
// wallet and artworks in artistDashboardService.getKpiMetrics.
export const KPI_METRICS = [
  { key: "revenue", label: "Total revenue", positive: true, icon: IndianRupee },
  { key: "wallet", label: "Wallet balance", positive: true, icon: Wallet },
  { key: "pendingApproval", label: "Pending approval", positive: false, icon: Clock3 },
] as const;

export interface ActivityEntry {
  id: string;
  kind: ActivityKind;
  title: string;
  detail: string;
  time: string;
}

export type WalletTransaction = {
  id: string;
  type: "settlement" | "withdrawal" | "commission" | "refund" | "adjustment";
  label: string;
  amount: number;
  date: string;
  status: "completed" | "pending" | "failed";
};

// The plan an artist's free period runs into. The free period itself (six
// months, a year for survey respondents) comes from the profile's freeAccess,
// not from here. The ₹1,200/year (+18% GST) price is live as of 9 Sep 2026.
// Static until there's a real billing system to read a plan from.
export const SUBSCRIPTION = {
  planName: "Founding Artist",
  renewalPriceLabel: "₹1,200/year + 18% GST (₹1,416 total)",
  benefits: [
    "Unlimited artwork listings",
    "0% listing and confirmation fees",
    "Aggregator display access",
    "COA and NFC passport for every accepted piece",
  ],
};
