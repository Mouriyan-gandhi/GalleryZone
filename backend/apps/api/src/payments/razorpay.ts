// Razorpay adapter: create a gateway order, verify the checkout callback,
// verify a webhook. Plain fetch + HMAC — the official SDK adds nothing we
// need and pulls in its own axios. Amounts are paise (Razorpay's unit for
// INR too, so no conversion). Disabled (null client) when the keys aren't
// set; the controller answers 503 in that case.

import { createHmac, timingSafeEqual } from "node:crypto";
import { Inject, Injectable, Logger, ServiceUnavailableException } from "@nestjs/common";
import type { AppEnv } from "@galleryzone/config";
import { ENV } from "../db.module.ts";

export interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
  receipt: string | null;
  status: string;
}

@Injectable()
export class Razorpay {
  private readonly logger = new Logger(Razorpay.name);
  readonly keyId: string | null;
  private readonly keySecret: string | null;
  private readonly webhookSecret: string | null;

  constructor(@Inject(ENV) env: AppEnv) {
    this.keyId = env.razorpayKeyId;
    this.keySecret = env.razorpayKeySecret;
    this.webhookSecret = env.razorpayWebhookSecret;
    if (!this.keyId || !this.keySecret) this.logger.warn("RAZORPAY_KEY_ID/SECRET not set — gateway checkout unavailable");
  }

  get enabled(): boolean {
    return Boolean(this.keyId && this.keySecret);
  }

  private require(): { keyId: string; keySecret: string } {
    if (!this.keyId || !this.keySecret) {
      throw new ServiceUnavailableException({ type: "about:blank", title: "Payments are not configured", status: 503, code: "payments_unavailable" });
    }
    return { keyId: this.keyId, keySecret: this.keySecret };
  }

  /** POST /v1/orders on Razorpay. `receipt` is our order id; `notes` carries it too so a webhook can find us without the receipt. */
  createOrder(input: { orderId: string; amountPaise: number; customerId: string }): Promise<RazorpayOrder> {
    return this.post({ receipt: input.orderId, amountPaise: input.amountPaise, notes: { gzOrderId: input.orderId, gzCustomerId: input.customerId } });
  }

  /** The same, for an aggregator adding money to their wallet. The notes carry the top-up id for the webhook. */
  createTopupOrder(input: { topupId: string; amountPaise: number; userId: string }): Promise<RazorpayOrder> {
    return this.post({ receipt: input.topupId, amountPaise: input.amountPaise, notes: { gzTopupId: input.topupId, gzUserId: input.userId } });
  }

  private async post(input: { receipt: string; amountPaise: number; notes: Record<string, string> }): Promise<RazorpayOrder> {
    const { keyId, keySecret } = this.require();
    const res = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${Buffer.from(`${keyId}:${keySecret}`).toString("base64")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ amount: input.amountPaise, currency: "INR", receipt: input.receipt.slice(0, 40), notes: input.notes }),
    });
    const body = (await res.json()) as RazorpayOrder & { error?: { description?: string } };
    if (!res.ok) {
      this.logger.error(`razorpay order create failed: ${res.status} ${body.error?.description ?? ""}`);
      throw new ServiceUnavailableException({ type: "about:blank", title: "Could not start the payment", status: 503, code: "gateway_error" });
    }
    return body;
  }

  /** Checkout.js hands back order_id, payment_id, signature = HMAC_SHA256(order_id|payment_id, key_secret). */
  verifyCheckoutSignature(input: { razorpayOrderId: string; razorpayPaymentId: string; signature: string }): boolean {
    const { keySecret } = this.require();
    const expected = createHmac("sha256", keySecret).update(`${input.razorpayOrderId}|${input.razorpayPaymentId}`).digest("hex");
    return safeEqual(expected, input.signature);
  }

  /** Webhook: X-Razorpay-Signature = HMAC_SHA256(raw body, webhook secret). Needs the RAW body bytes, not re-serialised JSON. */
  verifyWebhookSignature(rawBody: Buffer | string, signature: string | undefined): boolean {
    if (!this.webhookSecret || !signature) return false;
    const expected = createHmac("sha256", this.webhookSecret).update(rawBody).digest("hex");
    return safeEqual(expected, signature);
  }
}

function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}
