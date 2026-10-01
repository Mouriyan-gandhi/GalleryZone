import { IndianRupee, Wallet, Clock3 } from "lucide-react";

// Activity feed entries are persisted (lib/mock-collections.ts's
// artistActivityCol) so real actions (submit, approve, withdraw) can be
// appended on top of this seed — a Lucide icon component isn't
// JSON-serializable, so entries carry a `kind` string instead and
// recent-activity-feed.tsx maps that to an icon at render time.
export type ActivityKind =
  | "artwork_approved"
  | "artwork_submitted"
  | "settlement"
  | "verification"
  | "withdrawal";

export const ARTIST = {
  name: "Devika Rao",
  avatar: "/early-program/avatar-3.png",
  verifiedTier: 2,
  // Where she works, shown on her own profile summary. The pickup address on
  // PROFILE below is the courier's origin and is never displayed publicly;
  // this is the city line a collector would see.
  location: "Udaipur, Rajasthan",
  joinedAt: "2025-07-05T00:00:00.000Z",
};

export const KPI_METRICS = [
  {
    key: "revenue",
    label: "Total revenue",
    value: "₹1,84,320",
    delta: "+12.4% vs. last month",
    positive: true,
    icon: IndianRupee,
  },
  {
    key: "wallet",
    label: "Wallet balance",
    value: "₹42,180",
    delta: "₹6,400 pending settlement",
    positive: true,
    icon: Wallet,
  },
  {
    key: "pendingApproval",
    label: "Pending approval",
    value: "2",
    delta: "1 submitted yesterday",
    positive: false,
    icon: Clock3,
  },
] as const;

export const REVENUE_SERIES = [
  { month: "Mar", amount: 62000 },
  { month: "Apr", amount: 78500 },
  { month: "May", amount: 71200 },
  { month: "Jun", amount: 96800 },
  { month: "Jul", amount: 118400 },
  { month: "Aug", amount: 184320 },
];

export interface ActivityEntry {
  id: string;
  kind: ActivityKind;
  title: string;
  detail: string;
  time: string;
}

export const ACTIVITY_FEED: ActivityEntry[] = [
  {
    id: "act-1",
    kind: "artwork_approved",
    title: "“Monsoon Reverie” was approved",
    detail: "Live on the marketplace at ₹28,000",
    time: "2 hours ago",
  },
  {
    id: "act-2",
    kind: "settlement",
    title: "Settlement received",
    detail: "₹25,200 credited after commission",
    time: "Yesterday",
  },
  {
    id: "act-3",
    kind: "artwork_submitted",
    title: "“Terracotta Study No. 4” submitted",
    detail: "Awaiting admin review",
    time: "2 days ago",
  },
  {
    id: "act-4",
    kind: "verification",
    title: "Tier 2 verification complete",
    detail: "Active plan confirmed",
    time: "5 days ago",
  },
];

export const VERIFICATION_TIERS = [
  {
    tier: 1,
    title: "Social media",
    description: "Linked an official handle to authenticate your identity.",
    detail:
      "Link at least one official social media handle (Instagram, YouTube, or a personal site) so collectors can verify you're a real, active artist.",
    status: "complete" as const,
    completedOn: "2026-02-14",
  },
  {
    tier: 2,
    title: "Active plan",
    description: "Maintained an active plan for 3 months.",
    detail:
      "Keep an active GalleryZone plan for 3 consecutive months. This is free with the physical/aggregator listing model.",
    status: "complete" as const,
    completedOn: "2026-05-20",
  },
  {
    tier: 3,
    title: "First sale",
    description: "Complete your first confirmed sale on GalleryZone.",
    detail:
      "Sell one artwork through the marketplace or an aggregator. Once confirmed, you'll unlock the Gold ✦ Verified badge shown on your public profile and listings.",
    status: "active" as const,
    completedOn: null,
  },
];

export type WalletTransaction = {
  id: string;
  type: "settlement" | "withdrawal" | "commission" | "refund" | "adjustment";
  label: string;
  amount: number;
  date: string;
  status: "completed" | "pending" | "failed";
};

export const WALLET_SUMMARY = {
  balance: 42180,
  pendingBalance: 6400,
  lockedBalance: 0,
};

export const WALLET_TRANSACTIONS: WalletTransaction[] = [
  {
    id: "wt-1",
    type: "settlement",
    label: "Settlement: “Monsoon Reverie”",
    amount: 25200,
    date: "2026-08-09",
    status: "completed",
  },
  {
    id: "wt-2",
    type: "withdrawal",
    label: "Withdrawal to bank •••6142",
    amount: -20000,
    date: "2026-08-05",
    status: "completed",
  },
  {
    id: "wt-3",
    type: "settlement",
    label: "Settlement: “Fragments of Dawn”",
    amount: 17550,
    date: "2026-07-30",
    status: "completed",
  },
  {
    id: "wt-4",
    type: "settlement",
    label: "Settlement: “Whispers in Bronze”",
    amount: 6400,
    date: "2026-08-10",
    status: "pending",
  },
  {
    id: "wt-5",
    type: "withdrawal",
    label: "Withdrawal to bank •••6142",
    amount: -15000,
    date: "2026-06-22",
    status: "completed",
  },
];

export const PROFILE = {
  fullName: "Devika Rao",
  email: "devika.rao@example.com",
  phone: "+91 98765 43210",
  bio: "Contemporary landscape and abstract painter based in Udaipur, working primarily in oil and acrylic. Exploring the intersection of monsoon light and memory.",
  instagram: "devikarao.art",
  website: "devikarao.com",
  bankAccountMasked: "•••• •••• •••• 6142",
  ifsc: "HDFC0001234",
  aadhaarStatus: "verified" as const,
  aadhaarMasked: "•••• •••• 4821",
  // Optional — an artist without a GSTIN leaves this blank. Used by
  // GalleryZone for invoicing/settlement only, never shown publicly.
  gstin: "",
  // Where the courier collects. Private, and the one thing without which a
  // delivery cannot be quoted at all: Shiprocket prices on the distance
  // between two pincodes, and this is the origin for both the leg to an
  // aggregator and the leg to a buyer.
  pickupLine1: "14, Gangaur Ghat Marg",
  pickupLine2: "Behind Bagore Ki Haveli",
  pickupCity: "Udaipur",
  pickupState: "Rajasthan",
  pickupPincode: "313001",
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
