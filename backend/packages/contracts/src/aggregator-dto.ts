// Aggregator/consignment request contracts — reserve, recordSale, release,
// ask to keep a piece, and GalleryZone's answer.

import { z } from "zod";
import { WALLET_TOPUP_MAX_PAISE, WALLET_TOPUP_MIN_PAISE } from "@galleryzone/domain";
import { firestoreId } from "./ids.ts";

/** Add money to the wallet through Razorpay (client, 30 Sep 2026). One payment at a time, within the bounds in the domain. */
export const startWalletTopupInputSchema = z
  .object({ amountPaise: z.number().int().min(WALLET_TOPUP_MIN_PAISE).max(WALLET_TOPUP_MAX_PAISE) })
  .strict();

export type StartWalletTopupInput = z.infer<typeof startWalletTopupInputSchema>;

/** How an aggregator pays in a cash sale's full price: from their wallet, or by transfer to GalleryZone's bank. */
export const remitSaleInputSchema = z.object({ via: z.enum(["wallet", "bank"]) }).strict();

export type RemitSaleInput = z.infer<typeof remitSaleInputSchema>;

/** What Checkout.js hands back once the aggregator has paid. */
export const verifyWalletTopupInputSchema = z
  .object({
    razorpayOrderId: z.string().min(1).max(100),
    razorpayPaymentId: z.string().min(1).max(100),
    signature: z.string().min(1).max(200),
  })
  .strict();

export type VerifyWalletTopupInput = z.infer<typeof verifyWalletTopupInputSchema>;

export const reserveHoldingInputSchema = z
  .object({
    artworkId: firestoreId,
    gallerySpaceId: firestoreId.optional(),
    /**
     * The price BEFORE GST the aggregator chooses. Month 1 only, never below
     * GalleryZone's offer; omitted means GalleryZone's offer.
     */
    sellingPricePaise: z.number().int().positive().optional(),
  })
  .strict();

export type ReserveHoldingInput = z.infer<typeof reserveHoldingInputSchema>;

/** Ask to keep a piece past its window, with the aggregator's assurance that it will sell. */
export const requestHoldingExtensionInputSchema = z
  .object({ assurance: z.string().trim().min(10, "Tell GalleryZone why this piece will sell").max(1000) })
  .strict();

export type RequestHoldingExtensionInput = z.infer<typeof requestHoldingExtensionInputSchema>;

/** GalleryZone's answer to a request; the note is optional and shown to the aggregator. */
export const decideHoldingExtensionInputSchema = z.object({ note: z.string().trim().max(500).optional() }).strict();

export type DecideHoldingExtensionInput = z.infer<typeof decideHoldingExtensionInputSchema>;

export const recordAggregatorSaleInputSchema = z
  .object({
    holdingId: firestoreId,
    soldPricePaise: z.number().int().positive(),
    buyerName: z.string().min(1),
    buyerEmail: z.string().email(),
    buyerPhone: z.string().min(6).optional(),
    deliveryMode: z.enum(["courier", "self_pickup"]),
    paymentRoute: z.enum(["direct_to_galleryzone", "cash_at_premises"]),
    deliveryAddress: z.string().min(1).optional(),
  })
  .strict();

export type RecordAggregatorSaleInput = z.infer<typeof recordAggregatorSaleInputSchema>;

export interface HoldingDto {
  id: string;
  artworkId: string;
  aggregatorId: string;
  cycleMonth: number;
  advanceAmountPaise: number;
  displayPricePaise: number;
  status: "reserved" | "sold_pending_settlement" | "returned";
  assignedAt: string;
  expiresAt: string;
  windowExtended: boolean;
}
