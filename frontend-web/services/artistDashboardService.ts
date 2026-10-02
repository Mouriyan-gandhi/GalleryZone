import type { Artwork, ArtworkPhysical, ExternalSalePenalty } from "@/types/artwork";
import type { AggregatorHolding } from "@/types/aggregator";
import type { Order } from "@/types/order";
import type { DeactivationRequest, Settlement } from "@/types/admin";
import { http } from "@/lib/api";
import { ARTIST_PAYOUT_DAYS_AFTER_DELIVERY } from "@/lib/pricing";
import { paiseToRupees, toOrder, type OrderDto } from "@/lib/api-mappers";
import { artistArtworkApi, toOwnerArtwork, type OwnerArtworkDto, type SubmitImage } from "@/services/artistArtworkApi";
import { artistWalletApi } from "@/services/artistWalletApi";
import { profileApi, type FreeAccess, type OwnProfileDto, type OwnProfilePatch } from "@/services/profileApi";

// The shape the dashboard's profile/KYC screens were written against.
export interface ArtistProfileView {
  fullName: string;
  email: string;
  phone: string;
  bio: string;
  instagram: string;
  website: string;
  bankAccountMasked: string;
  /** Write-only: never returned by the API. */
  bankAccountNumber?: string;
  ifsc: string;
  aadhaarStatus: "not_submitted" | "submitted" | "approved" | "rejected";
  aadhaarMasked: string;
  gstin: string;
  pan: string | null;
  gstStatus: "not_submitted" | "submitted" | "approved" | "rejected";
  socialProofVideoUrl: string | null;
  pickupLine1: string;
  pickupLine2: string;
  pickupCity: string;
  pickupState: string;
  pickupPincode: string;
  location: string | null;
  headline: string | null;
  joinedAt: string;
  freeAccess: FreeAccess | null;
}

function toArtistProfileView(p: OwnProfileDto): ArtistProfileView {
  return {
    fullName: p.fullName,
    email: p.email,
    phone: p.phone ?? "",
    bio: p.bio ?? "",
    instagram: p.instagram ?? "",
    website: p.website ?? "",
    bankAccountMasked: p.bankAccountMasked ?? "",
    ifsc: p.ifsc ?? "",
    aadhaarStatus: p.aadhaarStatus,
    aadhaarMasked: p.aadhaarMasked ?? "",
    gstin: p.gstin ?? "",
    pan: p.pan,
    gstStatus: p.gstStatus,
    socialProofVideoUrl: p.socialProofVideoUrl,
    pickupLine1: p.pickupLine1 ?? "",
    pickupLine2: p.pickupLine2 ?? "",
    pickupCity: p.pickupCity ?? "",
    pickupState: p.pickupState ?? "",
    pickupPincode: p.pickupPincode ?? "",
    location: p.location,
    headline: p.headline,
    joinedAt: p.createdAt,
    freeAccess: p.freeAccess ?? null,
  };
}
import { KPI_METRICS } from "@/features/dashboard/dashboard-data";
import { mouService } from "@/services/mouService";
import type {
  ActivityEntry,
  WalletTransaction,
} from "@/features/dashboard/dashboard-data";

// The artist dashboard's service — every method is on the API. Artwork
// CRUD lives in artistArtworkApi.ts, the wallet in artistWalletApi.ts, the
// profile in profileApi.ts; the rest is here. Derived views (KPIs, activity,
// settlements) are computed from those reads, never stored.

export interface ArtworkKpiMetric {
  key: string;
  label: string;
  value: string;
  delta: string;
  positive: boolean;
  icon: (typeof KPI_METRICS)[number]["icon"];
}

export interface SubmitArtworkInput {
  title: string;
  description: string;
  category: string;
  medium: string;
  artworkType: string | null;
  paintingStyle: string | null;
  dimensions: string | null;
  yearCreated: number;
  artistPrice: number;
  listingType: Artwork["listingType"];
  insuranceOpted: boolean;
  insuranceNumber: string | null;
  physical: ArtworkPhysical;
  nfcTagId: string | null;
  images: SubmitImage[];
  mode: "draft" | "review";
}

interface PenaltyDto {
  id: string;
  artworkId: string;
  artworkTitle: string;
  amountPaise: number;
  status: "pending_review" | "approved" | "waived";
  createdAt: string;
  decidedAt: string | null;
  decisionNote: string | null;
  settledAt: string | null;
}
function toPenalty(p: PenaltyDto): ExternalSalePenalty {
  return { id: p.id, artworkId: p.artworkId, artworkTitle: p.artworkTitle, amount: paiseToRupees(p.amountPaise), createdAt: p.createdAt, settledAt: p.settledAt, status: p.status, decidedAt: p.decidedAt, decisionNote: p.decisionNote };
}
interface DeactivationDto {
  id: string;
  userId: string;
  userName: string;
  reason: string;
  status: "pending" | "approved" | "rejected";
  requestedAt: string;
  decidedAt: string | null;
  decisionNote: string | null;
}
function toDeactivation(d: DeactivationDto): DeactivationRequest {
  return { ...d, userRole: "artist" };
}

// Settlements are a projection of my orders: paid → pending until
// delivered + the payout window, then completed. Amounts are the artist's
// net for that order (marketplace channel pays the artist price in full).
async function settlementsFromOrders(): Promise<Settlement[]> {
  const orders = await artistDashboardService.listOrders();
  return orders
    .filter((o) => o.status !== "pending" && o.status !== "cancelled")
    .map((o) => {
      const delivered = o.statusHistory.find((e) => e.status === "delivered")?.changedAt ?? null;
      const releaseAfter = delivered ? new Date(new Date(delivered).getTime() + ARTIST_PAYOUT_DAYS_AFTER_DELIVERY * 86_400_000).toISOString() : null;
      const released = releaseAfter !== null && new Date(releaseAfter).getTime() <= Date.now();
      return {
        id: `stl-${o.id}`,
        orderId: o.id,
        artworkTitle: o.artwork?.title ?? o.artworkId,
        artistName: "",
        artistAmount: o.artistPayout,
        aggregatorCommission: 0,
        platformRevenue: Math.max(0, o.amount - o.artistPayout),
        status: released ? "processed" : "pending",
        createdAt: o.createdAt,
        processedAt: released ? releaseAfter : null,
        releaseAfter,
      } satisfies Settlement;
    });
}

// Notification preferences are per-browser until a preferences route
// exists; defaults are all-on, which is what the emails do today.
export interface ArtistSettings {
  notifyArtworkApproved: boolean;
  notifyNewSale: boolean;
  notifyWithdrawalProcessed: boolean;
  notifyNewMessage: boolean;
}
const SETTINGS_KEY = "gz.artist.settings";
const DEFAULT_SETTINGS: ArtistSettings = { notifyArtworkApproved: true, notifyNewSale: true, notifyWithdrawalProcessed: true, notifyNewMessage: true };
async function readSettings(): Promise<ArtistSettings> {
  try {
    const raw = typeof localStorage !== "undefined" ? localStorage.getItem(SETTINGS_KEY) : null;
    return raw ? { ...DEFAULT_SETTINGS, ...(JSON.parse(raw) as Partial<ArtistSettings>) } : DEFAULT_SETTINGS;
  } catch {
    return DEFAULT_SETTINGS;
  }
}

export const artistDashboardService = {
  getKpiMetrics: async (): Promise<ArtworkKpiMetric[]> => {
    const [wallet, artworks, transactions] = await Promise.all([
      artistWalletApi.getWallet(),
      artistArtworkApi.list(),
      artistWalletApi.listTransactions(),
    ]);
    const pendingCount = artworks.filter((a) => a.status === "pending_approval").length;
    const soldCount = artworks.filter((a) => ["sold", "settlement_complete", "delivered", "completed"].includes(a.status)).length;
    const revenue = transactions.filter((t) => t.type === "settlement" && t.status === "completed").reduce((sum, t) => sum + Math.max(0, t.amount), 0);
    return [
      {
        ...KPI_METRICS[0],
        value: `₹${revenue.toLocaleString("en-IN")}`,
        delta: soldCount > 0 ? `${soldCount} ${soldCount === 1 ? "sale" : "sales"} settled` : "No sales settled yet",
        positive: soldCount > 0,
      },
      {
        ...KPI_METRICS[1],
        value: `₹${wallet.balance.toLocaleString("en-IN")}`,
        delta:
          wallet.lockedBalance > 0
            ? `₹${wallet.lockedBalance.toLocaleString("en-IN")} withdrawal pending`
            : "Available to withdraw",
      },
      {
        ...KPI_METRICS[2],
        value: String(pendingCount),
        delta: pendingCount > 0 ? "Awaiting admin review" : "All caught up",
      },
    ];
  },

  // Derived from real events: artwork status history and wallet
  // transactions, newest first. No stored feed — nothing to drift.
  getActivity: async (): Promise<ActivityEntry[]> => {
    const [artworks, transactions] = await Promise.all([artistArtworkApi.list(), artistWalletApi.listTransactions()]);
    const entries: ActivityEntry[] = [];
    for (const a of artworks) {
      for (const e of a.statusHistory) {
        if (e.status === "pending_approval") entries.push({ id: `${a.id}:${e.changedAt}:sub`, kind: "artwork_submitted", title: "Submitted for review", detail: `"${a.title}" is with the curation team`, time: e.changedAt });
        else if (e.status === "marketplace") entries.push({ id: `${a.id}:${e.changedAt}:live`, kind: "artwork_approved", title: "Artwork approved", detail: `"${a.title}" is live on the marketplace`, time: e.changedAt });
        else if (e.status === "returned") entries.push({ id: `${a.id}:${e.changedAt}:ret`, kind: "artwork_submitted", title: "Artwork returned", detail: `"${a.title}" needs changes before it can be listed`, time: e.changedAt });
        else if (e.status === "sold") entries.push({ id: `${a.id}:${e.changedAt}:sold`, kind: "settlement", title: "Artwork sold", detail: `"${a.title}" has a buyer`, time: e.changedAt });
      }
    }
    for (const t of transactions) {
      if (t.type === "withdrawal") entries.push({ id: `wt:${t.id}`, kind: "withdrawal", title: t.status === "pending" ? "Withdrawal requested" : "Withdrawal processed", detail: `₹${Math.abs(t.amount).toLocaleString("en-IN")} · ${t.label}`, time: t.date });
      else if (t.type === "settlement") entries.push({ id: `wt:${t.id}`, kind: "settlement", title: "Settlement credited", detail: `₹${t.amount.toLocaleString("en-IN")} · ${t.label}`, time: t.date });
    }
    return entries.sort((a, b) => b.time.localeCompare(a.time)).slice(0, 30);
  },

  listArtworks: (): Promise<Array<Artwork & { artistPrice: number }>> =>
    artistArtworkApi.list(),

  getArtwork: (artworkId: string): Promise<Artwork & { artistPrice: number }> =>
    artistArtworkApi.get(artworkId),

  submitArtwork: (input: SubmitArtworkInput): Promise<Artwork> => {
    if (!input.title.trim()) return Promise.reject(new Error("A title is required"));
    if (input.artistPrice <= 0) return Promise.reject(new Error("Enter your price for this artwork"));
    return artistArtworkApi.submit(input);
  },

  updateArtwork: (input: {
    artworkId: string;
    patch: Omit<SubmitArtworkInput, "mode">;
    mode?: "draft" | "review";
  }): Promise<Artwork> => {
    if (!input.patch.title.trim()) return Promise.reject(new Error("A title is required"));
    if (input.patch.artistPrice <= 0) return Promise.reject(new Error("Enter your price for this artwork"));
    return artistArtworkApi.update({ artworkId: input.artworkId, patch: input.patch, ...(input.mode ? { mode: input.mode } : {}) });
  },

  // "Sold on another platform": the piece leaves every GalleryZone channel at
  // once, and a fee of EXTERNAL_SALE_PENALTY_RATE of its listed price is raised
  // for review. It is NOT charged here and not charged automatically later —
  // an admin decides whether it stands, and only then does it come out of the
  // next listing (settlePendingPenalties above).
  markSoldElsewhere: async (artworkId: string): Promise<Artwork> => {
    const { artwork } = await http.post<{ artwork: OwnerArtworkDto | null }>(`/v1/artist/artworks/${encodeURIComponent(artworkId)}/sold-elsewhere`);
    if (!artwork) throw new Error("Artwork not found");
    return toOwnerArtwork(artwork);
  },

  listPenalties: async (): Promise<ExternalSalePenalty[]> => {
    const { penalties } = await http.get<{ penalties: PenaltyDto[] }>("/v1/artist/penalties");
    return penalties.map(toPenalty);
  },

  // Wallet is real (services/artistWalletApi.ts). "pending" = settled
  // sales still inside the payout clock is not modelled by the ledger yet,
  // so pendingBalance is 0; locked = withdrawal requests awaiting approval.
  getWallet: (): Promise<{
    balance: number;
    pendingBalance: number;
    lockedBalance: number;
  }> => artistWalletApi.getWallet(),

  listWalletTransactions: (): Promise<WalletTransaction[]> =>
    artistWalletApi.listTransactions(),

  /** Sales waiting on the 7-day post-delivery clock. */
  /** Sales waiting on delivery + the payout clock — derived from my orders. */
  listPendingSettlements: async (): Promise<Settlement[]> =>
    (await settlementsFromOrders()).filter((s) => s.status === "pending"),

  simulateDelivery: async (_settlementId: string): Promise<void> => {
    throw new Error("Deliveries are recorded by the operations team, not simulated");
  },

  requestWithdrawal: (amount: number): Promise<WalletTransaction> => {
    if (amount < 1000) return Promise.reject(new Error("Minimum withdrawal is ₹1,000"));
    return artistWalletApi.requestWithdrawal(amount);
  },

  // The account's own profile (GET /v1/me/profile) plus the MOU: the
  // signature of the version in force (null for an older one, which forces a
  // re-sign) and the draft, the current text's blanks filled from this
  // profile — so saving the profile refreshes what the unsigned MOU shows.
  getProfile: async () => {
    const [p, mou] = await Promise.all([profileApi.get(), mouService.get("artist")]);
    return { ...toArtistProfileView(p), mouAcceptance: mou.acceptance, mouDraft: mou.draft };
  },

  // Signing the MOU is its own call rather than a profile patch: the server
  // records the signing time, checks the version, the typed name and that
  // every required blank can be filled, snapshots those blanks, and never
  // lets an ordinary profile save overwrite the record.
  acceptMou: async (input: { signatureName: string; version: string; signatureDataUrl: string }) => {
    await mouService.accept("artist", input);
    return artistDashboardService.getProfile();
  },

  updateProfile: async (patch: Partial<ArtistProfileView>) => {
    const body: OwnProfilePatch = {};
    if (patch.fullName !== undefined) body.fullName = patch.fullName;
    if (patch.phone !== undefined) body.phone = patch.phone || null;
    if (patch.bio !== undefined) body.bio = patch.bio || null;
    if (patch.instagram !== undefined) body.instagram = patch.instagram || null;
    if (patch.website !== undefined) body.website = patch.website || null;
    if (patch.socialProofVideoUrl !== undefined) body.socialProofVideoUrl = patch.socialProofVideoUrl || null;
    if (patch.pan !== undefined) body.pan = patch.pan || null;
    if (patch.gstin !== undefined) body.gstin = patch.gstin || null;
    if (patch.ifsc !== undefined) body.ifsc = patch.ifsc || null;
    if (patch.bankAccountNumber !== undefined) body.bankAccountNumber = patch.bankAccountNumber || null;
    for (const key of ["pickupLine1", "pickupLine2", "pickupCity", "pickupState", "pickupPincode"] as const) {
      if (patch[key] !== undefined) body[key] = patch[key] || null;
    }
    const updated = toArtistProfileView(await profileApi.update(body));
    const mou = await mouService.get("artist");
    return { ...updated, mouAcceptance: mou.acceptance, mouDraft: mou.draft };
  },

  listOrders: async (): Promise<Array<Order & { artistPayout: number }>> => {
    const { orders } = await http.get<{ orders: (OrderDto & { artistNetPaise: number })[] }>("/v1/artist/orders");
    return orders.map((o) => ({ ...toOrder(o), artistPayout: paiseToRupees(o.artistNetPaise) }));
  },

  listSettlements: (): Promise<Settlement[]> => settlementsFromOrders(),

  // Partner-gallery placements need the aggregator flow on the API; until
  // then the table is empty rather than fixture-filled.
  listGallerySpaces: async (): Promise<Array<AggregatorHolding & { artwork: Artwork }>> => [],

  // --- Account deactivation ------------------------------------------------
  // Asking is all the artist can do. An admin decides, because a closing
  // account may still owe a settlement, hold a piece with an aggregator, or
  // have a transfer someone is waiting to accept.

  getDeactivationRequest: async (): Promise<DeactivationRequest | null> => {
    const { request } = await http.get<{ request: DeactivationDto | null }>("/v1/artist/deactivation");
    return request ? toDeactivation(request) : null;
  },

  requestDeactivation: async (input: { reason: string }): Promise<DeactivationRequest> => {
    if (!input.reason.trim()) throw new Error("Tell us why you're leaving so an admin can review it");
    await http.post("/v1/artist/deactivation", { reason: input.reason.trim() });
    const { request } = await http.get<{ request: DeactivationDto | null }>("/v1/artist/deactivation");
    if (!request) throw new Error("The request was not recorded");
    return toDeactivation(request);
  },

  // Withdrawing a pending request isn't a backend operation yet; an admin
  // rejecting it has the same effect. Surfaced as an error, not a silent no-op.
  withdrawDeactivation: async (_requestId: string): Promise<{ id: string }> => {
    throw new Error("Contact support to withdraw a pending deactivation request");
  },

  getSettings: (): Promise<ArtistSettings> => readSettings(),

  updateSettings: async (patch: Partial<ArtistSettings>): Promise<ArtistSettings> => {
    const next = { ...(await readSettings()), ...patch };
    try {
      localStorage.setItem(SETTINGS_KEY, JSON.stringify(next));
    } catch {
      /* private mode */
    }
    return next;
  },

};
