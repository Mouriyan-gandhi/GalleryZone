// The admin console on the real API. adminService delegates the methods
// listed here; the rest of that file is still fixture-backed and shrinks
// as routes land.

import type { Artwork, ArtworkRarity } from "@/types/artwork";
import type { Order } from "@/types/order";
import type { Address } from "@/types/customer";
import type { AdminKpis, AdminUser, AuditLogEntry, GstStatus, KycStatus, UserRole, UserStatus, WithdrawalRequest } from "@/types/admin";
import { http, isApiError } from "@/lib/api";
import { paiseToRupees, toAddress, toOrder, type AddressDto, type OrderDto } from "@/lib/api-mappers";
import { toOwnerArtwork, type OwnerArtworkDto } from "@/services/artistArtworkApi";

interface AdminArtworkDto extends OwnerArtworkDto {
  artistEmail: string | null;
  nfcShipmentGateOverrideAt: string | null;
  nfcShipmentGateOverrideReason: string | null;
  nfcShipmentGateOverrideBy: string | null;
}

const toAdminArtwork = (dto: AdminArtworkDto): Artwork => ({
  ...toOwnerArtwork(dto),
  nfcShipmentGateOverrideAt: dto.nfcShipmentGateOverrideAt,
  nfcShipmentGateOverrideReason: dto.nfcShipmentGateOverrideReason,
});

interface AdminUserDto {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  role: UserRole;
  status: UserStatus;
  roleGrants: string[];
  createdAt: string;
  lastLoginAt: string | null;
  pan: string | null;
  gstin: string | null;
  gstStatus: string | null;
  aadhaarStatus: string | null;
  companyName: string | null;
  instagram: string | null;
  website: string | null;
  location: string | null;
  bankAccountMasked: string | null;
}

interface AdminWithdrawalDto {
  id: string;
  userId: string;
  userName: string;
  userRole: UserRole;
  amountPaise: number;
  bankAccountMasked: string | null;
  walletBalancePaise: number;
  status: WithdrawalRequest["status"];
  requestedAt: string;
  processedAt: string | null;
}

interface AdminKpiDto {
  totalUsers: number;
  totalArtworks: number;
  liveArtworks: number;
  pendingApprovalArtworks: number;
  pendingWithdrawals: number;
  pendingGst: number;
  pendingKyc: number;
  totalOrders: number;
  paidOrders: number;
  gmvPaise: number;
}

interface AuditLogDto {
  id: string;
  adminId: string;
  action: string;
  entityType: string;
  entityId: string;
  entityLabel: string | null;
  detail: unknown;
  createdAt: { _seconds: number } | string;
}

const KYC: Record<string, KycStatus> = { not_submitted: "pending", submitted: "submitted", approved: "approved", rejected: "rejected" };
const GST: Record<string, GstStatus> = { not_submitted: "not_submitted", submitted: "submitted", approved: "approved", rejected: "rejected" };

function toAdminUser(u: AdminUserDto): AdminUser {
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    phone: u.phone ?? "",
    role: u.role,
    status: u.status,
    createdAt: u.createdAt,
    lastLoginAt: u.lastLoginAt,
    ...(u.role === "artist" || u.role === "aggregator" ? { kycStatus: KYC[u.aadhaarStatus ?? "not_submitted"] ?? "pending" } : {}),
    ...(u.companyName ? { companyName: u.companyName } : {}),
    pan: u.pan,
    gstin: u.gstin,
    gstStatus: GST[u.gstStatus ?? "not_submitted"] ?? "not_submitted",
    instagramHandle: u.instagram,
  };
}

function toWithdrawal(w: AdminWithdrawalDto): WithdrawalRequest {
  return {
    id: w.id,
    userId: w.userId,
    userName: w.userName,
    userRole: w.userRole === "aggregator" ? "aggregator" : "artist",
    amount: paiseToRupees(w.amountPaise),
    bankAccountMasked: w.bankAccountMasked ?? "—",
    walletBalance: paiseToRupees(w.walletBalancePaise),
    status: w.status,
    requestedAt: w.requestedAt,
    processedAt: w.processedAt,
  };
}

function toAudit(a: AuditLogDto): AuditLogEntry {
  const createdAt = typeof a.createdAt === "string" ? a.createdAt : new Date(a.createdAt._seconds * 1000).toISOString();
  const detail = a.detail && typeof a.detail === "object" ? (a.detail as Record<string, unknown>) : null;
  return {
    id: a.id,
    adminName: a.adminId,
    action: a.action as AuditLogEntry["action"],
    entityType: a.entityType as AuditLogEntry["entityType"],
    entityId: a.entityId,
    entityLabel: a.entityLabel ?? a.entityId,
    ...(detail && typeof detail.reason === "string" ? { detail: detail.reason } : {}),
    createdAt,
  };
}

const ADMIN_ARTWORK = (id: string) => `/v1/admin/artworks/${encodeURIComponent(id)}`;

export const adminApi = {
  async getKpis(): Promise<AdminKpis> {
    const k = await http.get<AdminKpiDto>("/v1/admin/kpis");
    return {
      gmv: paiseToRupees(k.gmvPaise),
      // Revenue and payout splits need the settlement ledger aggregated; until then they are 0, not invented.
      platformRevenue: 0,
      artistPayouts: 0,
      totalOrders: k.paidOrders,
      activeArtworks: k.liveArtworks,
      totalUsers: k.totalUsers,
      pendingArtworkApprovals: k.pendingApprovalArtworks,
      pendingKyc: k.pendingKyc,
      pendingGst: k.pendingGst,
      pendingWithdrawals: k.pendingWithdrawals,
    };
  },

  async listAllArtworks(): Promise<Artwork[]> {
    const { artworks } = await http.get<{ artworks: AdminArtworkDto[] }>("/v1/admin/artworks");
    return artworks.map(toAdminArtwork);
  },

  async listPendingArtworks(): Promise<Artwork[]> {
    return (await adminApi.listAllArtworks()).filter((a) => a.status === "pending_approval");
  },

  async getArtwork(id: string): Promise<Artwork | undefined> {
    try {
      return toAdminArtwork(await http.get<AdminArtworkDto>(ADMIN_ARTWORK(id)));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  async approveArtwork(id: string, rarity: ArtworkRarity): Promise<{ id: string; status: "marketplace" }> {
    await http.post(`${ADMIN_ARTWORK(id)}/approve`, { rarity });
    return { id, status: "marketplace" };
  },

  async rejectArtwork(id: string, reason: string): Promise<{ id: string; status: "returned"; reason: string }> {
    await http.post(`${ADMIN_ARTWORK(id)}/reject`, { reason });
    return { id, status: "returned", reason };
  },

  async delistArtwork(id: string): Promise<{ id: string; status: "returned" }> {
    await http.post(`${ADMIN_ARTWORK(id)}/delist`);
    return { id, status: "returned" };
  },

  async setArtworkRarity(id: string, rarity: ArtworkRarity): Promise<Artwork> {
    await http.post(`${ADMIN_ARTWORK(id)}/rarity`, { rarity });
    const artwork = await adminApi.getArtwork(id);
    if (!artwork) throw new Error("Artwork not found");
    return artwork;
  },

  async setArtworkInsuranceStatus(id: string, decision: "approved" | "rejected", reason?: string): Promise<Artwork> {
    await http.post(`/v1/artworks/${encodeURIComponent(id)}/insurance/${decision === "approved" ? "approve" : "reject"}`, reason ? { reason } : {});
    const artwork = await adminApi.getArtwork(id);
    if (!artwork) throw new Error("Artwork not found");
    return artwork;
  },

  async listUsers(role?: UserRole): Promise<AdminUser[]> {
    const { users } = await http.get<{ users: AdminUserDto[] }>("/v1/admin/users", { params: role ? { role } : {} });
    return users.map(toAdminUser);
  },

  async getUser(id: string): Promise<AdminUser | undefined> {
    try {
      return toAdminUser(await http.get<AdminUserDto>(`/v1/admin/users/${encodeURIComponent(id)}`));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  async setUserStatus(id: string, status: UserStatus): Promise<{ id: string; status: UserStatus }> {
    await http.patch(`/v1/admin/users/${encodeURIComponent(id)}/status`, { status });
    return { id, status };
  },

  async listKycQueue(): Promise<AdminUser[]> {
    const { users } = await http.get<{ users: AdminUserDto[] }>("/v1/admin/moderation/kyc");
    return users.map(toAdminUser);
  },

  async listGstQueue(): Promise<AdminUser[]> {
    const { users } = await http.get<{ users: AdminUserDto[] }>("/v1/admin/moderation/gst");
    return users.map(toAdminUser);
  },

  async decideKyc(userId: string, decision: "approve" | "reject", reason?: string): Promise<void> {
    await http.post(`/v1/moderation/kyc/${encodeURIComponent(userId)}/${decision}`, reason ? { reason } : {});
  },

  async decideGst(userId: string, decision: "approve" | "reject", reason?: string): Promise<void> {
    await http.post(`/v1/moderation/gst/${encodeURIComponent(userId)}/${decision}`, reason ? { reason } : {});
  },

  async listWithdrawals(): Promise<WithdrawalRequest[]> {
    const { withdrawals } = await http.get<{ withdrawals: AdminWithdrawalDto[] }>("/v1/admin/withdrawals");
    return withdrawals.map(toWithdrawal);
  },

  async approveWithdrawal(id: string): Promise<{ id: string; status: "completed" }> {
    await http.post(`/v1/admin/withdrawals/${encodeURIComponent(id)}/approve`);
    return { id, status: "completed" };
  },

  async rejectWithdrawal(id: string, reason: string): Promise<{ id: string; status: "rejected"; reason: string }> {
    await http.post(`/v1/admin/withdrawals/${encodeURIComponent(id)}/reject`, { reason });
    return { id, status: "rejected", reason };
  },

  async listOrders(): Promise<Order[]> {
    const orders = await http.get<OrderDto[] | { orders: OrderDto[] }>("/v1/admin/orders");
    const rows = Array.isArray(orders) ? orders : orders.orders;
    return rows.map(toOrder).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },

  async getOrder(id: string): Promise<Order | undefined> {
    try {
      return toOrder(await http.get<OrderDto>(`/v1/admin/orders/${encodeURIComponent(id)}`));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  async getAddress(id: string): Promise<Address | undefined> {
    try {
      return toAddress(await http.get<AddressDto>(`/v1/admin/addresses/${encodeURIComponent(id)}`));
    } catch (error) {
      if (isApiError(error, 404)) return undefined;
      throw error;
    }
  },

  async listAuditLog(): Promise<AuditLogEntry[]> {
    const rows = await http.get<AuditLogDto[] | { entries: AuditLogDto[] }>("/v1/admin/audit-log");
    return (Array.isArray(rows) ? rows : rows.entries).map(toAudit);
  },

  async listCategories(): Promise<{ id: string; name: string; slug: string; artworkCount: number }[]> {
    const rows = await http.get<{ id: string; name: string; slug: string }[]>("/v1/admin/categories");
    return rows.map((c) => ({ ...c, artworkCount: 0 }));
  },

  async createCategory(name: string): Promise<{ id: string; name: string; slug: string; artworkCount: number }> {
    const slug = name.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    const { id } = await http.post<{ id: string }>("/v1/admin/categories", { name, slug });
    return { id, name, slug, artworkCount: 0 };
  },

  async updateCategory(id: string, name: string): Promise<{ id: string; name: string; slug: string; artworkCount: number }> {
    await http.patch(`/v1/admin/categories/${encodeURIComponent(id)}`, { name });
    const rows = await adminApi.listCategories();
    return rows.find((c) => c.id === id) ?? { id, name, slug: name, artworkCount: 0 };
  },

  async deleteCategory(id: string): Promise<{ id: string }> {
    await http.delete(`/v1/admin/categories/${encodeURIComponent(id)}`);
    return { id };
  },
};
