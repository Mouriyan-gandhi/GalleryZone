import {
  penaltyStatus,
  type Artwork,
  type ArtworkRarity,
  type ExternalSalePenalty,
  type ArtworkSummary,
} from "@/types/artwork";
import type { Order } from "@/types/order";
import type { ArtistProfile } from "@/types/artist";
import type {
  AdminActivityEvent,
  AdminKpis,
  AdminUser,
  AuditLogEntry,
  Category,
  DeactivationRequest,
  GeneratedReport,
  GenerateReportInput,
  PlatformSettings,
  ReportType,
  Settlement,
  UserRole,
  UserStatus,
  WithdrawalRequest,
} from "@/types/admin";
import type { Address } from "@/types/customer";
import type { AggregatorHolding, HoldingExtensionRequest } from "@/types/aggregator";
import { adminApi } from "@/services/adminApi";
import { artistService } from "@/services/artworkService";
import { http } from "@/lib/api";
import { paiseToRupees, toArtworkSummary, type ArtworkDto } from "@/lib/api-mappers";
import { aggregatorService } from "@/services/aggregatorService";

// ---------------------------------------------------------------------------
// Mock admin service. Reads/writes for the moderation → catalog pipeline
// (pending artworks, the marketplace catalog, admin users, orders, addresses)
// go through lib/mock-collections.ts, so an approval here actually shows up
// on the Marketplace and in the Artist Dashboard, and survives a refresh.
// Everything else (withdrawals, categories, settlements, audit log, settings,
// reports) keeps the original mock contract — reads resolve fixture data,
// mutations resolve a *plausible next value* WITHOUT persisting it, exactly
// like customerService/aggregatorService document. Those pages already work
// correctly via TanStack Query's optimistic setQueryData (the audit log page
// additionally has its own live-append store, store/useAdminAuditStore) and
// sit outside the artist → admin → marketplace → checkout loop this
// persistence layer exists to support.
//
// Swapping any of this for a real axios call later is a same-shape change.
// ---------------------------------------------------------------------------

const REPORT_TYPE_LABELS: Record<ReportType, string> = {
  sales: "Marketplace sales",
  settlements: "Settlement register",
  artist_payouts: "Artist payouts",
  aggregator_commission: "Aggregator commission",
  gst: "GST summary",
};

const DAY_MS = 24 * 60 * 60 * 1000;

function formatReportRange(from: string, to: string): string {
  const options: Intl.DateTimeFormatOptions = {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  };
  return `${new Date(from).toLocaleDateString("en-IN", options)} – ${new Date(to).toLocaleDateString("en-IN", options)}`;
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

interface SettlementDto {
  id: string;
  orderId: string | null;
  holdingId: string | null;
  artistId: string;
  artistName: string;
  artworkTitle: string;
  artistAmountPaise: number;
  aggregatorCommissionPaise: number | null;
  platformRevenuePaise: number;
  status: Settlement["status"];
  releaseAfter: string;
  createdAt: string;
  processedAt: string | null;
}
let sessionReports: GeneratedReport[] = [];

interface AdminHoldingDto {
  id: string;
  artworkId: string;
  artwork: ArtworkDto | null;
  cycleMonth: number;
  advancePercent: number;
  advancePaise: number;
  deliveryDepositPaise: number | null;
  displayPricePaise: number;
  assignmentSource: "self_reserved" | "gz_assigned";
  assignedAt: string;
  expiresAt: string;
  windowExtended: boolean;
  status: AggregatorHolding["status"];
  returnedAt: string | null;
  appreciated: boolean;
  priceWarning: boolean;
  extensionRequest: HoldingExtensionRequest | null;
}
function toAdminHolding(h: AdminHoldingDto): AggregatorHolding & { artwork: ArtworkSummary } {
  return {
    id: h.id,
    artworkId: h.artworkId,
    advancePercent: (h.advancePercent === 3 ? 3 : 5) as 5 | 3,
    advanceAmount: paiseToRupees(h.advancePaise),
    deliveryDeposit: h.deliveryDepositPaise === null ? undefined : paiseToRupees(h.deliveryDepositPaise),
    displayPrice: paiseToRupees(h.displayPricePaise),
    assignedAt: h.assignedAt,
    expiresAt: h.expiresAt,
    status: h.status,
    cycleMonth: h.cycleMonth,
    returnedAt: h.returnedAt,
    windowExtended: h.windowExtended,
    assignmentSource: h.assignmentSource,
    appreciated: h.appreciated,
    priceWarning: h.priceWarning,
    extensionRequest: h.extensionRequest,
    artwork: h.artwork ? toArtworkSummary(h.artwork) : { id: h.artworkId, title: "Artwork", artistId: "", artistName: "", verifiedArtist: false, category: "", medium: "", customerPrice: 0, thumbnailUrl: "/artworks/framed-painting.png", insured: false, status: "marketplace", listingType: "marketplace_and_aggregator" },
  };
}

export const adminService = {
  // --- overview + analytics ------------------------------------------------
  // gmv/platformRevenue/artistPayouts/totalOrders stay the seeded 12-month
  // analytics aggregates (see lib/mock-data/admin.ts's own comment on why —
  // deriving them from the handful of live orders would require hundreds of
  // fabricated rows). The four queue-sized counters are recomputed live so
  // every KPI tile agrees with the table/queue it links to.
  getKpis: (): Promise<AdminKpis> => adminApi.getKpis(),

  // Derived from the audit log and recent orders — no stored feed.
  getActivity: async (): Promise<AdminActivityEvent[]> => {
    const [audit, orders] = await Promise.all([adminApi.listAuditLog(), adminApi.listOrders()]);
    const events: AdminActivityEvent[] = audit.map((a) => ({
      id: `audit:${a.id}`,
      label: a.action.replace(/[._]/g, " "),
      detail: a.entityLabel,
      at: a.createdAt,
      kind: a.entityType === "artwork" ? "artwork" : a.entityType === "withdrawal" ? "withdrawal" : a.entityType === "settlement" ? "settlement" : "user",
    }));
    for (const o of orders.slice(0, 20)) {
      events.push({ id: `order:${o.id}`, label: o.status === "pending" ? "Order started" : `Order ${o.status}`, detail: o.artwork?.title ?? o.artworkId, at: o.createdAt, kind: "order" });
    }
    return events.sort((a, b) => b.at.localeCompare(a.at)).slice(0, 40);
  },

  // --- moderation ----------------------------------------------------------
  listPendingArtworks: (): Promise<Artwork[]> => adminApi.listPendingArtworks(),

  getPendingArtwork: (id: string): Promise<Artwork | undefined> => adminApi.getArtwork(id),

  approveArtwork: (id: string): Promise<{ id: string; status: "marketplace" }> => adminApi.approveArtwork(id),

  rejectArtwork: (id: string, reason: string): Promise<{ id: string; status: "returned"; reason: string }> => {
    if (!reason.trim()) return Promise.reject(new Error("A rejection reason is required"));
    return adminApi.rejectArtwork(id, reason);
  },

  listKycQueue: (): Promise<AdminUser[]> => adminApi.listKycQueue(),

  approveKyc: async (userId: string): Promise<{ userId: string; kycStatus: "approved" }> => {
    await adminApi.decideKyc(userId, "approve");
    return { userId, kycStatus: "approved" as const };
  },

  rejectKyc: async (userId: string, reason: string): Promise<{ userId: string; kycStatus: "rejected"; reason: string }> => {
    if (!reason.trim()) throw new Error("A rejection reason is required");
    await adminApi.decideKyc(userId, "reject", reason);
    return { userId, kycStatus: "rejected" as const, reason };
  },

  listGstQueue: (): Promise<AdminUser[]> => adminApi.listGstQueue(),

  approveGst: async (userId: string): Promise<{ userId: string; gstStatus: "approved" }> => {
    await adminApi.decideGst(userId, "approve");
    return { userId, gstStatus: "approved" as const };
  },

  rejectGst: async (userId: string, reason: string): Promise<{ userId: string; gstStatus: "rejected"; reason: string }> => {
    if (!reason.trim()) throw new Error("A rejection reason is required");
    await adminApi.decideGst(userId, "reject", reason);
    return { userId, gstStatus: "rejected" as const, reason };
  },

  listWithdrawals: (): Promise<WithdrawalRequest[]> => adminApi.listWithdrawals(),

  approveWithdrawal: (id: string): Promise<{ id: string; status: "completed" }> => adminApi.approveWithdrawal(id),

  rejectWithdrawal: (id: string, reason: string): Promise<{ id: string; status: "rejected"; reason: string }> => {
    if (!reason.trim()) return Promise.reject(new Error("A rejection reason is required"));
    return adminApi.rejectWithdrawal(id, reason);
  },

  listExternalSaleFees: async (): Promise<ExternalSalePenalty[]> => {
    const rows = await http.get<PenaltyDto[] | { fees: PenaltyDto[] }>("/v1/admin/external-fees");
    return (Array.isArray(rows) ? rows : rows.fees).map(toPenalty);
  },

  decideExternalSaleFee: async (input: { id: string; approve: boolean; note?: string }): Promise<ExternalSalePenalty> => {
    await http.post(`/v1/admin/external-fees/${encodeURIComponent(input.id)}/decide`, { decision: input.approve ? "approved" : "waived", ...(input.note ? { note: input.note } : {}) });
    const all = await adminService.listExternalSaleFees();
    const found = all.find((p) => p.id === input.id);
    if (!found) throw new Error("Fee not found after decision");
    return found;
  },

  // --- account deactivation ------------------------------------------------
  // The artist asks from their settings page; this is the deciding end.
  // Approving suspends the account, which is what the Artists table already
  // renders — no second notion of "closed" is invented here.

  listDeactivationRequests: async (): Promise<DeactivationRequest[]> => {
    const { requests } = await http.get<{ requests: DeactivationDto[] }>("/v1/admin/deactivation");
    return requests.map(toDeactivation);
  },

  decideDeactivation: async (input: { id: string; approve: boolean; note?: string }): Promise<DeactivationRequest> => {
    const all = await adminService.listDeactivationRequests();
    const target = all.find((r) => r.id === input.id);
    if (!target) throw new Error("Request not found");
    await http.post(`/v1/admin/deactivation/${encodeURIComponent(target.userId)}/${input.approve ? "approve" : "reject"}`, input.note ? { note: input.note } : {});
    const after = await adminService.listDeactivationRequests();
    return after.find((r) => r.userId === target.userId) ?? { ...target, status: input.approve ? "approved" : "rejected" };
  },

  // --- catalog -------------------------------------------------------------
  // Public + admin-only sets combined: admin is the one view that sees every
  // artwork regardless of status.
  listAllArtworks: (): Promise<Artwork[]> => adminApi.listAllArtworks(),

  getArtworkAdmin: (id: string): Promise<Artwork | undefined> => adminApi.getArtwork(id),

  delistArtwork: (id: string): Promise<{ id: string; status: "returned" }> => adminApi.delistArtwork(id),

  activeHoldingFor: async (artworkId: string): Promise<AggregatorHolding | null> => {
    const { holding } = await http.get<{ holding: AdminHoldingDto | null }>(`/v1/admin/artworks/${encodeURIComponent(artworkId)}/holding`);
    return holding ? toAdminHolding(holding) : null;
  },

  // GalleryZone reclaiming a piece from an aggregator mid-placement. Distinct
  // from the aggregator returning it themselves: same end state for the
  // artwork, different question about the money.
  //
  // An unsold return costs the aggregator the delivery leg — the money-flow
  // sheet settles that only on a sale. But that rule describes an aggregator
  // who held the piece and did not sell it, not one whose piece was taken back
  // by GalleryZone partway through. Rather than guess which way the client
  // reads it, the admin decides per case, the same way they already decide an
  // off-platform sale fee. `reason` is required: an aggregator whose stock
  // disappears is owed an explanation.
  pullBackHolding: async (input: { holdingId: string; reason: string }): Promise<{ released: number; deliveryCharged: number }> => {
    if (!input.reason.trim()) throw new Error("Give the gallery a reason for the pull-back");
    const { holding } = await http.post<{ holding: AdminHoldingDto | null }>(`/v1/admin/holdings/${encodeURIComponent(input.holdingId)}/pull-back`);
    return { released: holding ? paiseToRupees(holding.advancePaise) : 0, deliveryCharged: holding?.deliveryDepositPaise ? paiseToRupees(holding.deliveryDepositPaise) : 0 };
  },

  // An aggregator asked to keep a piece past its window. Approving moves the
  // window on 30 days; declining lets it end and the piece go back on sale.
  decideExtension: async (input: { holdingId: string; decision: "approve" | "decline"; note?: string }): Promise<void> => {
    await http.post(`/v1/admin/holdings/${encodeURIComponent(input.holdingId)}/extension/${input.decision}`, input.note?.trim() ? { note: input.note.trim() } : {});
  },

  // GalleryZone ranks the work, the artist does not. The rank is written back
  // to whichever collection actually holds the piece — a work still awaiting
  // approval lives in pendingArtworksCol, and ranking it there is the point:
  // an admin reviewing a submission is exactly when they judge it.
  setArtworkRarity: (id: string, rarity: ArtworkRarity | null): Promise<Artwork> => adminApi.setArtworkRarity(id, rarity),

  setArtworkInsuranceStatus: (id: string, insuranceStatus: NonNullable<Artwork["insuranceStatus"]>): Promise<Artwork> => {
    if (insuranceStatus !== "approved" && insuranceStatus !== "rejected") return Promise.reject(new Error("Only approve or reject can be recorded"));
    return adminApi.setArtworkInsuranceStatus(id, insuranceStatus);
  },

  listCategories: (): Promise<Category[]> => adminApi.listCategories(),

  createCategory: (name: string): Promise<Category> => adminApi.createCategory(name),

  updateCategory: (id: string, name: string): Promise<Category> => adminApi.updateCategory(id, name),

  deleteCategory: (id: string): Promise<{ id: string }> => adminApi.deleteCategory(id),

  listUsers: (role?: UserRole): Promise<AdminUser[]> => adminApi.listUsers(role),

  getUser: (id: string): Promise<AdminUser | undefined> => adminApi.getUser(id),

  setUserStatus: (id: string, status: UserStatus): Promise<{ id: string; status: UserStatus }> => adminApi.setUserStatus(id, status),

  getArtistPortfolio: async (userId: string): Promise<{ user: AdminUser; profile: ArtistProfile | undefined; artworks: Artwork[] } | undefined> => {
    const user = await adminApi.getUser(userId);
    if (!user || user.role !== "artist") return undefined;
    const [profile, all] = await Promise.all([artistService.get(userId), adminApi.listAllArtworks()]);
    return { user, profile, artworks: all.filter((a) => a.artistId === userId) };
  },

  // Holdings aren't partitioned per aggregator in this mock (same shortcut
  // the original page took) — every current holding is shown against
  // whichever aggregator's detail page is open.
  getAggregatorPortfolio: async (userId: string): Promise<{ user: AdminUser; holdings: Awaited<ReturnType<typeof aggregatorService.listCollection>>; commissionPercent: number } | undefined> => {
    const user = await adminApi.getUser(userId);
    if (!user || user.role !== "aggregator") return undefined;
    const [{ holdings }, settings] = await Promise.all([
      http.get<{ holdings: AdminHoldingDto[] }>(`/v1/admin/aggregators/${encodeURIComponent(userId)}/holdings`),
      adminService.getSettings(),
    ]);
    return { user, holdings: holdings.map(toAdminHolding), commissionPercent: settings.aggregatorCommissionPercent };
  },

  // Orders aren't partitioned per customer in this mock either (mockOrders is
  // a single-customer sample) — same shortcut as the aggregator portfolio.
  getCustomerPortfolio: async (userId: string): Promise<{ user: AdminUser; orders: Order[]; addresses: Address[] } | undefined> => {
    const user = await adminApi.getUser(userId);
    if (!user || user.role !== "customer") return undefined;
    const orders = (await adminApi.listOrders()).filter((o) => o.customerId === userId);
    const addresses = (
      await Promise.all([...new Set(orders.map((o) => o.addressId))].map((id) => adminApi.getAddress(id)))
    ).filter((a): a is Address => a !== undefined);
    return { user, orders, addresses };
  },

  // --- commerce ------------------------------------------------------------
  listOrders: (): Promise<Order[]> => adminApi.listOrders(),

  getOrderAdmin: (id: string): Promise<Order | undefined> => adminApi.getOrder(id),

  getAddressAdmin: (id: string): Promise<Address | undefined> => adminApi.getAddress(id),

  getSettlementByOrder: async (orderId: string): Promise<Settlement | undefined> =>
    (await adminService.listSettlements()).find((s) => s.orderId === orderId),

  listSettlements: async (): Promise<Settlement[]> => {
    const rows = await http.get<SettlementDto[] | { settlements: SettlementDto[] }>("/v1/admin/settlements");
    return (Array.isArray(rows) ? rows : rows.settlements).map((s) => ({
      id: s.id,
      orderId: s.orderId ?? s.holdingId ?? "",
      artworkTitle: s.artworkTitle,
      artistName: s.artistName,
      artistAmount: paiseToRupees(s.artistAmountPaise),
      aggregatorCommission: paiseToRupees(s.aggregatorCommissionPaise ?? 0),
      platformRevenue: paiseToRupees(s.platformRevenuePaise),
      status: s.status,
      createdAt: s.createdAt,
      processedAt: s.processedAt,
      releaseAfter: s.releaseAfter,
    }));
  },

  retrySettlement: async (id: string): Promise<{ id: string; status: "processed" }> => {
    await http.post(`/v1/admin/settlements/${encodeURIComponent(id)}/retry`);
    return { id, status: "processed" };
  },

  // --- system --------------------------------------------------------------
  listAuditLog: (): Promise<AuditLogEntry[]> => adminApi.listAuditLog(),

  // Platform settings ARE the active rate config; edit them through the
  // pricing-rules panel (propose + approve), never here.
  getSettings: async (): Promise<PlatformSettings> => {
    const { rates } = await http.get<{ rates: Record<string, number> }>("/v1/admin/rate-config");
    return {
      markupPercent: Math.round((rates.platformMarkup ?? 0) * 100),
      gstPercent: Math.round((rates.gstRate ?? 0) * 100),
      minWithdrawalAmount: paiseToRupees(rates.minWithdrawalPaise ?? 0),
      // Insurance is recommended above this display price (MOU §10); a policy constant, not a rate.
      insuranceThreshold: 20000,
      aggregatorCommissionPercent: Math.round((rates.aggregatorCommissionRate ?? 0) * 100),
    };
  },

  updateSettings: async (_patch: Partial<PlatformSettings>): Promise<PlatformSettings> => {
    throw new Error("Pricing rules change through a proposed and approved version — use the Pricing rules panel above.");
  },

  // Generated reports aren't persisted on the API yet; each generation
  // returns live totals and is kept for this browser session only.
  listReports: async (): Promise<GeneratedReport[]> => sessionReports,

  generateReport: async (input: GenerateReportInput): Promise<GeneratedReport> => {
    const from = new Date(input.from);
    const to = new Date(input.to);
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) throw new Error("Enter a valid date range");
    if (to.getTime() < from.getTime()) throw new Error("The end date is before the start date");
    const apiType = input.type === "artist_payouts" ? "settlements" : input.type === "aggregator_commission" ? "settlements" : input.type;
    const row = await http.post<{ type: string; totalOrders: number; totalGstPaise: number; totalSettledPaise: number }>("/v1/admin/reports", { type: apiType });
    const label = { sales: "Marketplace sales", settlements: "Settlement register", artist_payouts: "Artist payouts", aggregator_commission: "Aggregator commission", gst: "GST summary" }[input.type];
    const report: GeneratedReport = {
      id: `rpt-${Date.now().toString(36)}`,
      type: input.type,
      label: `${label} · ${row.totalOrders} orders · GST ₹${paiseToRupees(row.totalGstPaise).toLocaleString("en-IN")} · settled ₹${paiseToRupees(row.totalSettledPaise).toLocaleString("en-IN")}`,
      from: input.from,
      to: input.to,
      generatedAt: new Date().toISOString(),
      generatedBy: "you",
      rowCount: row.totalOrders,
      status: "ready",
    };
    sessionReports = [report, ...sessionReports];
    return report;
  },

};
