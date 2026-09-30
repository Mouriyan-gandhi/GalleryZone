// Sales, shipments, remittances, wallet, gallery spaces and analytics for
// the aggregator portal — on the API. Timestamps arrive as Firestore
// {_seconds} objects or ISO strings; money as paise.

import type { AggregatorSale, GallerySpace } from "@/types/aggregator";
import type { Settlement } from "@/types/admin";
import type { WalletTransaction } from "@/features/dashboard/dashboard-data";
import { http } from "@/lib/api";
import { paiseToRupees } from "@/lib/api-mappers";
import { openRazorpayCheckout, type RazorpaySession } from "@/lib/razorpay-checkout";
import { aggregatorService } from "./aggregatorService";

export interface AggregatorCustomer {
  buyerName: string;
  buyerEmail: string;
  buyerPhone: string;
  orderCount: number;
  totalSpend: number;
}

/** Shipment-relevant projection of AggregatorSale for the outbound table. */
export interface AggregatorShipment {
  id: string;
  artworkId: string;
  holdingId: string;
  buyerName: string;
  deliveryMode: AggregatorSale["deliveryMode"];
  deliveryAddress: AggregatorSale["deliveryAddress"];
  shipmentStatus: AggregatorSale["shipmentStatus"];
  soldAt: string;
  dispatchedAt: string | null;
  deliveredAt: string | null;
  courierRef: string | null;
}

export interface AggregatorAnalyticsSummary {
  salesCount: number;
  totalRevenue: number;
  totalCommissionPending: number;
  totalCommissionAvailable: number;
  customerCount: number;
  activeReservations: number;
  averageSoldPrice: number;
  averageDisplayMarkup: number;
}

type Ts = { _seconds: number } | string | null | undefined;
const iso = (t: Ts): string | null => (typeof t === "string" ? t : t ? new Date(t._seconds * 1000).toISOString() : null);

interface SaleDto {
  id: string;
  holdingId: string;
  artworkId: string;
  soldPricePaise: number;
  buyerName: string;
  buyerEmail: string;
  buyerPhone: string | null;
  deliveryAddress: string | null;
  deliveryMode: "courier" | "self_pickup";
  paymentRoute: "direct_to_galleryzone" | "cash_at_premises";
  remittedAt: Ts;
  remitDueAt?: Ts;
  remittedVia?: "wallet" | "bank" | null;
  shipmentStatus: "preparing" | "dispatched" | "delivered";
  dispatchedAt: Ts;
  deliveredAt: Ts;
  courierRef: string | null;
  soldAt: Ts;
}

function parseAddress(line: string | null): AggregatorSale["deliveryAddress"] {
  const parts = (line ?? "").split(",").map((p) => p.trim()).filter(Boolean);
  return { line1: parts[0] ?? "", city: parts[1] ?? "", state: parts[2] ?? "", pincode: parts[3] ?? "" };
}

function toSale(s: SaleDto): AggregatorSale {
  return {
    id: s.id,
    holdingId: s.holdingId,
    artworkId: s.artworkId,
    soldPrice: paiseToRupees(s.soldPricePaise),
    buyerName: s.buyerName,
    buyerEmail: s.buyerEmail,
    buyerPhone: s.buyerPhone ?? "",
    deliveryAddress: parseAddress(s.deliveryAddress),
    deliveryMode: s.deliveryMode,
    paymentRoute: s.paymentRoute,
    remittedAt: iso(s.remittedAt),
    remitDueAt: iso(s.remitDueAt),
    remittedVia: s.remittedVia ?? null,
    soldAt: iso(s.soldAt) ?? new Date(0).toISOString(),
    shipmentStatus: s.shipmentStatus,
    dispatchedAt: iso(s.dispatchedAt),
    deliveredAt: iso(s.deliveredAt),
    courierRef: s.courierRef,
  };
}

const toShipment = (s: AggregatorSale): AggregatorShipment => ({
  id: s.id,
  artworkId: s.artworkId,
  holdingId: s.holdingId,
  buyerName: s.buyerName,
  deliveryMode: s.deliveryMode,
  deliveryAddress: s.deliveryAddress,
  shipmentStatus: s.shipmentStatus,
  soldAt: s.soldAt,
  dispatchedAt: s.dispatchedAt ?? null,
  deliveredAt: s.deliveredAt ?? null,
  courierRef: s.courierRef ?? null,
});

async function sales(): Promise<AggregatorSale[]> {
  const rows = await http.get<SaleDto[]>("/v1/aggregator/sales");
  return rows.map(toSale).sort((a, b) => b.soldAt.localeCompare(a.soldAt));
}

// What each ledger entry on the wallet is called. The API sends the reason.
const WALLET_ENTRY: Record<string, { label: string; type: WalletTransaction["type"] }> = {
  wallet_topup: { label: "Added to wallet", type: "adjustment" },
  reservation_hold: { label: "Held for reservation", type: "adjustment" },
  advance_returned_to_wallet: { label: "Advance returned", type: "refund" },
  hold_returned_to_wallet: { label: "Held amount returned after sale", type: "refund" },
  aggregator_commission: { label: "Commission on sale", type: "commission" },
};

export const aggregatorSalesService = {
  listSales: (): Promise<AggregatorSale[]> => sales(),

  listCustomers: async (): Promise<AggregatorCustomer[]> => {
    const byEmail = new Map<string, AggregatorCustomer>();
    for (const s of await sales()) {
      const row = byEmail.get(s.buyerEmail) ?? { buyerName: s.buyerName, buyerEmail: s.buyerEmail, buyerPhone: s.buyerPhone, orderCount: 0, totalSpend: 0 };
      row.orderCount += 1;
      row.totalSpend += s.soldPrice;
      byEmail.set(s.buyerEmail, row);
    }
    return [...byEmail.values()].sort((a, b) => b.totalSpend - a.totalSpend);
  },

  listShipments: async (): Promise<AggregatorShipment[]> => (await sales()).map(toShipment),

  advanceShipment: async (saleId: string, courierRef?: string): Promise<AggregatorSale> => {
    const current = (await sales()).find((s) => s.id === saleId);
    if (!current) throw new Error("Sale not found");
    const to = current.shipmentStatus === "preparing" ? "dispatched" : current.shipmentStatus === "dispatched" ? "delivered" : null;
    if (!to) throw new Error("Shipment is already delivered");
    await http.patch(`/v1/aggregator/sales/${encodeURIComponent(saleId)}/shipment`, { saleId, to, ...(courierRef ? { courierRef } : {}) });
    const updated = (await sales()).find((s) => s.id === saleId);
    if (!updated) throw new Error("Sale not found");
    return updated;
  },

  listGallerySpaces: async (): Promise<GallerySpace[]> => {
    const rows = await http.get<(GallerySpace & { capacity: number | null; coordinatorName: string | null })[]>("/v1/aggregator/gallery-spaces");
    return rows.map((r) => ({ ...r, capacity: r.capacity ?? 0, coordinatorName: r.coordinatorName ?? "" }));
  },

  addGallerySpace: async (input: Omit<GallerySpace, "id">): Promise<GallerySpace> => {
    const { id } = await http.post<{ id: string }>("/v1/aggregator/gallery-spaces", {
      name: input.name,
      addressLine1: input.addressLine1,
      city: input.city,
      state: input.state,
      pincode: input.pincode,
      ...(input.capacity ? { capacity: input.capacity } : {}),
      ...(input.coordinatorName ? { coordinatorName: input.coordinatorName } : {}),
    });
    return { id, ...input };
  },

  // Money the aggregator added, less what is set aside for pieces they hold.
  // The API sends the spendable part and the held part separately; the page
  // wants a total and a locked part (free = balance − locked), so it is put back
  // together here.
  listWallet: async (): Promise<{ balance: number; pendingBalance: number; lockedBalance: number }> => {
    const w = await http.get<{ balancePaise: number; heldPaise: number }>("/v1/aggregator/wallet");
    return { balance: paiseToRupees(w.balancePaise + w.heldPaise), pendingBalance: 0, lockedBalance: paiseToRupees(w.heldPaise) };
  },

  listWalletTransactions: async (): Promise<WalletTransaction[]> => {
    const [{ transactions }, holdings] = await Promise.all([
      http.get<{ transactions: { id: string; amountPaise: number; reason: string; holdingId: string | null; at: string }[] }>("/v1/aggregator/wallet/transactions"),
      aggregatorService.listCollection(),
    ]);
    const titleOf = new Map(holdings.map((h) => [h.id, h.artwork.title]));
    return transactions
      .map((t): WalletTransaction => {
        const kind = WALLET_ENTRY[t.reason] ?? { label: "Wallet adjustment", type: "adjustment" as const };
        const title = t.holdingId ? titleOf.get(t.holdingId) : undefined;
        return { id: t.id, type: kind.type, label: title ? `${kind.label} · ${title}` : kind.label, amount: paiseToRupees(t.amountPaise), date: t.at, status: "completed" };
      })
      .sort((a, b) => b.date.localeCompare(a.date));
  },

  // Money comes in from the aggregator's own bank account through Razorpay
  // (client, 30 Sep 2026). The API opens the gateway order; the browser only
  // ever gets the public key and that order id. The wallet is credited once the
  // API has verified the payment (the webhook does the same, idempotently).
  // With PAYMENTS_MODE=simulated on the API there is no gateway and no money.
  addFunds: async (amount: number): Promise<void> => {
    const session = await http.post<{ mode: "simulated"; topupId: string } | (RazorpaySession & { topupId: string })>("/v1/aggregator/wallet/topups", {
      amountPaise: Math.round(amount * 100),
    });
    const base = `/v1/aggregator/wallet/topups/${encodeURIComponent(session.topupId)}`;
    if (session.mode === "razorpay") {
      const paid = await openRazorpayCheckout(session);
      await http.post(`${base}/verify`, {
        razorpayOrderId: paid.razorpay_order_id,
        razorpayPaymentId: paid.razorpay_payment_id,
        signature: paid.razorpay_signature,
      });
    } else {
      await http.post(`${base}/simulate`);
    }
  },

  // Aggregators are agents, not principals: no withdrawal route by design (plan §3.4).
  requestWithdrawal: async (_amount: number): Promise<WalletTransaction> => {
    throw new Error("Withdrawals from the wallet aren't open yet. Contact GalleryZone to have unused money returned to your bank account.");
  },

  listRemittancesDue: async (): Promise<AggregatorSale[]> => {
    const rows = await http.get<SaleDto[]>("/v1/aggregator/sales/remittances-due");
    return rows.map(toSale);
  },

  // Cash is GalleryZone's money, due in full within 2 days (client, 30 Sep 2026):
  // "wallet" takes it from the free balance here, "bank" is the aggregator saying
  // they transferred it to GalleryZone's account.
  markRemitted: async (saleId: string, via: "wallet" | "bank"): Promise<AggregatorSale> => {
    await http.post(`/v1/aggregator/sales/${encodeURIComponent(saleId)}/remit`, { via });
    const updated = (await sales()).find((s) => s.id === saleId);
    if (!updated) throw new Error("Sale not found");
    return updated;
  },

  // Settlements are run by GalleryZone (admin console); this view derives
  // them from sold holdings so the aggregator sees what is owed.
  listSettlements: async (): Promise<Settlement[]> => {
    const [all, holdings] = await Promise.all([sales(), aggregatorService.listCollection()]);
    return all.map((s) => {
      const h = holdings.find((x) => x.id === s.holdingId);
      return {
        id: `stl-${s.id}`,
        orderId: s.id,
        artworkTitle: h?.artwork.title ?? s.artworkId,
        artistName: h?.artwork.artistName ?? "",
        artistAmount: 0,
        aggregatorCommission: Math.max(0, s.soldPrice - (h?.displayPrice ?? s.soldPrice)),
        platformRevenue: 0,
        status: s.remittedAt || s.paymentRoute === "direct_to_galleryzone" ? "processed" : "pending",
        createdAt: s.soldAt,
        processedAt: s.remittedAt ?? null,
      } satisfies Settlement;
    });
  },

  processSettlement: async (_saleId: string): Promise<Settlement> => {
    throw new Error("Settlements are processed by GalleryZone after delivery.");
  },

  getAnalytics: async (): Promise<AggregatorAnalyticsSummary> => {
    const [all, holdings] = await Promise.all([sales(), aggregatorService.listCollection()]);
    const revenue = all.reduce((sum, s) => sum + s.soldPrice, 0);
    const markups = all.map((s) => {
      const h = holdings.find((x) => x.id === s.holdingId);
      return h && h.displayPrice > 0 ? (s.soldPrice - h.displayPrice) / h.displayPrice : 0;
    });
    return {
      salesCount: all.length,
      totalRevenue: revenue,
      totalCommissionPending: 0,
      totalCommissionAvailable: 0,
      customerCount: new Set(all.map((s) => s.buyerEmail)).size,
      activeReservations: holdings.filter((h) => h.status === "reserved").length,
      averageSoldPrice: all.length ? Math.round(revenue / all.length) : 0,
      averageDisplayMarkup: markups.length ? markups.reduce((a, b) => a + b, 0) / markups.length : 0,
    };
  },
};
