// The aggregator (partner gallery) portal on the API. Offer terms come
// from the server (GET /v1/aggregator/inventory) so the card, the reserve
// page and the ledger all agree; holdings carry the public artwork.
// Money is paise on the wire and rupees here.

import type { AggregatorHolding, HoldingExtensionRequest, RecordSalePayload } from "@/types/aggregator";
import type { Artwork, ArtworkSummary } from "@/types/artwork";
import { http, isApiError } from "@/lib/api";
import { paiseToRupees, toArtwork, toArtworkSummary, type ArtworkDto } from "@/lib/api-mappers";

export interface AggregatorOffer {
  artworkId: string;
  month: number;
  /** GalleryZone's price this month before GST: the floor in month 1, the fixed price after. */
  sellingPrice: number;
  /** The same with GST: what a customer sees if the aggregator keeps GalleryZone's price. */
  offerPrice: number;
  /** Month 1's price, before any monthly reduction — the ladder's top rung. */
  standardPrice: number;
  /** How much month `month`'s reduction has cut off standardPrice. 0 in month 1. */
  monthlyReduction: number;
  /** What the marketplace shows — unaffected by the cycle. */
  marketplacePrice: number;
  /** Only month 1 lets the aggregator set their own price. */
  canSetPrice: boolean;
  gstRate: number;
  /** Month 1: the price before GST at or above which GalleryZone is warned. */
  priceWarnFrom: number | null;
  /** The advance at GalleryZone's price. In month 1 it grows with the price the aggregator chooses. */
  advance: number;
  advanceRate: number;
  advanceBase: number;
  advanceBasis: "selling_price" | "artist_price";
  daysLeftInListing: number;
  deliveryCharge: number;
  /** Advance plus delivery, at GalleryZone's price. */
  payable: number;
}

export type ReservableArtwork = ArtworkSummary & { offer: AggregatorOffer };

interface OfferDto {
  artworkId: string;
  month: number;
  sellingPricePaise: number;
  offerPricePaise: number;
  standardPricePaise: number;
  monthlyReductionPaise: number;
  marketplacePricePaise: number;
  canSetPrice: boolean;
  gstRate: number;
  priceWarnFromPaise: number | null;
  advancePaise: number;
  advanceRate: number;
  advanceBasePaise: number;
  advanceBasis: "selling_price" | "artist_price";
  daysLeftInListing: number;
  deliveryChargePaise: number;
  payablePaise: number;
}

interface HoldingDto {
  id: string;
  artworkId: string;
  /** The public piece plus whether its NFC tag is linked and locked (never the chip's ID). */
  artwork: (ArtworkDto & { nfcLinkedAt?: string | null; nfcLockedAt?: string | null }) | null;
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

function toOffer(o: OfferDto): AggregatorOffer {
  return {
    artworkId: o.artworkId,
    month: o.month,
    sellingPrice: paiseToRupees(o.sellingPricePaise),
    offerPrice: paiseToRupees(o.offerPricePaise),
    standardPrice: paiseToRupees(o.standardPricePaise),
    monthlyReduction: paiseToRupees(o.monthlyReductionPaise),
    marketplacePrice: paiseToRupees(o.marketplacePricePaise),
    canSetPrice: o.canSetPrice,
    gstRate: o.gstRate,
    priceWarnFrom: o.priceWarnFromPaise === null ? null : paiseToRupees(o.priceWarnFromPaise),
    advance: paiseToRupees(o.advancePaise),
    advanceRate: o.advanceRate,
    advanceBase: paiseToRupees(o.advanceBasePaise),
    advanceBasis: o.advanceBasis,
    daysLeftInListing: o.daysLeftInListing,
    deliveryCharge: paiseToRupees(o.deliveryChargePaise),
    payable: paiseToRupees(o.payablePaise),
  };
}

function toHolding(h: HoldingDto): AggregatorHolding {
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
  };
}

const withArtwork = (h: HoldingDto) => ({ ...toHolding(h), artwork: h.artwork ? toArtworkSummary(h.artwork) : placeholderSummary(h.artworkId) });

function placeholderSummary(id: string): ArtworkSummary {
  return { id, title: "Artwork", artistId: "", artistName: "", verifiedArtist: false, category: "", medium: "", customerPrice: 0, thumbnailUrl: "/artworks/framed-painting.png", insured: false, status: "marketplace", listingType: "marketplace_and_aggregator" };
}

async function holdings(): Promise<HoldingDto[]> {
  const { holdings } = await http.get<{ holdings: HoldingDto[] }>("/v1/aggregator/holdings");
  return holdings;
}

export const aggregatorService = {
  async listReservableInventory(): Promise<ReservableArtwork[]> {
    const { artworks } = await http.get<{ artworks: (ArtworkDto & { offer: OfferDto })[] }>("/v1/aggregator/inventory");
    return artworks.map((a) => ({ ...toArtworkSummary(a), offer: toOffer(a.offer) }));
  },

  async getReservableArtwork(artworkId: string): Promise<ReservableArtwork | null> {
    const all = await aggregatorService.listReservableInventory();
    return all.find((a) => a.id === artworkId) ?? null;
  },

  /**
   * `sellingPrice` is what the aggregator sells at, before GST, in rupees. Month 1
   * only; leave it out to take GalleryZone's price. It can't be changed once reserved.
   */
  async reserve(artworkId: string, sellingPrice?: number): Promise<AggregatorHolding> {
    const h = await http.post<HoldingDto>("/v1/aggregator/holdings", {
      artworkId,
      ...(sellingPrice === undefined ? {} : { sellingPricePaise: Math.round(sellingPrice * 100) }),
    });
    return toHolding(h);
  },

  /** Ask GalleryZone to let the aggregator keep a piece past its window, with an assurance that it will sell. */
  async requestExtension(holdingId: string, assurance: string): Promise<AggregatorHolding> {
    const h = await http.post<HoldingDto>(`/v1/aggregator/holdings/${encodeURIComponent(holdingId)}/extension`, { assurance });
    return toHolding(h);
  },

  async releaseHolding(holdingId: string): Promise<{ refunded: number; deliveryLost: number }> {
    const h = await http.post<HoldingDto>(`/v1/aggregator/holdings/${encodeURIComponent(holdingId)}/return`);
    return { refunded: paiseToRupees(h.advancePaise), deliveryLost: h.deliveryDepositPaise ? paiseToRupees(h.deliveryDepositPaise) : 0 };
  },

  async listCollection(): Promise<Array<AggregatorHolding & { artwork: ArtworkSummary }>> {
    return (await holdings()).map(withArtwork);
  },

  async recordSale(payload: RecordSalePayload): Promise<AggregatorHolding> {
    const all = await holdings();
    const active = all.find((h) => h.artworkId === payload.artworkId && h.status === "reserved");
    if (!active) throw new Error("No active reservation found for this artwork");
    const address = [payload.deliveryAddress.line1, payload.deliveryAddress.city, payload.deliveryAddress.state, payload.deliveryAddress.pincode].filter(Boolean).join(", ");
    await http.post(`/v1/aggregator/holdings/${encodeURIComponent(active.id)}/sale`, {
      soldPricePaise: Math.round(payload.soldPrice * 100),
      buyerName: payload.buyerName,
      buyerEmail: payload.buyerEmail,
      ...(payload.buyerPhone ? { buyerPhone: payload.buyerPhone } : {}),
      deliveryMode: payload.deliveryMode,
      paymentRoute: payload.paymentRoute,
      ...(address ? { deliveryAddress: address } : {}),
    });
    const updated = await http.get<HoldingDto>(`/v1/aggregator/holdings/${encodeURIComponent(active.id)}`);
    return toHolding(updated);
  },

  async dashboardSummary(): Promise<{ activeReservations: number; commissionEarned: number; pendingSettlements: number; conversionRate: number | null }> {
    const all = await holdings();
    const active = all.filter((h) => h.status === "reserved").length;
    const sold = all.filter((h) => h.status === "sold_pending_settlement");
    const returned = all.filter((h) => h.status === "returned").length;
    const finished = sold.length + returned;
    return {
      activeReservations: active,
      // Commission is settled by GalleryZone after the sale; the wallet shows the credited amount.
      commissionEarned: 0,
      pendingSettlements: sold.length,
      conversionRate: finished ? Math.round((sold.length / finished) * 100) : null,
    };
  },

  async getHolding(holdingId: string): Promise<(AggregatorHolding & { artwork: Artwork }) | null> {
    try {
      const h = await http.get<HoldingDto>(`/v1/aggregator/holdings/${encodeURIComponent(holdingId)}`);
      if (!h.artwork) return null;
      return { ...toHolding(h), artwork: { ...toArtwork(h.artwork), nfcLinkedAt: h.artwork.nfcLinkedAt ?? null, nfcLockedAt: h.artwork.nfcLockedAt ?? null } };
    } catch (error) {
      if (isApiError(error, 404)) return null;
      throw error;
    }
  },

  async debugSkipAheadDays(_holdingId: string, _days?: number): Promise<AggregatorHolding> {
    throw new Error("Placement windows run on the real clock");
  },
};
