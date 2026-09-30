// Gateway checkout for an order.
//
//   POST /v1/orders/:id/payment/session   customer (own order)
//        → { mode: "simulated" }  while PAYMENTS_MODE=simulated
//        → { mode: "razorpay", keyId, razorpayOrderId, amountPaise, currency, name, description, prefill }
//   POST /v1/orders/:id/payment/verify    customer — the Checkout.js callback
//        { razorpayOrderId, razorpayPaymentId, signature } → marks paid on a valid HMAC
//   POST /v1/payments/razorpay/webhook    public — Razorpay's server → ours
//        payment.captured / order.paid → paid; payment.failed → recorded
//
// An aggregator's wallet top-up is the same shape (client, 30 Sep 2026: money
// comes in "from his bank account like Razorpay"):
//   POST /v1/aggregator/wallet/topups             aggregator — { amountPaise } → the same session shape
//   POST /v1/aggregator/wallet/topups/:id/verify  aggregator — the Checkout.js callback → credits the wallet
//   POST /v1/aggregator/wallet/topups/:id/simulate  aggregator — PAYMENTS_MODE=simulated only
// The webhook routes a payment to a top-up by the gzTopupId note on its order.
//
// Both the verify callback and the webhook can mark the same order paid;
// markOrderPaid is idempotent so whichever arrives second is a no-op. The
// webhook is the source of truth (it arrives even if the buyer closes the
// tab); the verify call just makes the success screen instant.

import { BadRequestException, Body, Controller, ForbiddenException, Headers, HttpCode, Inject, NotFoundException, Param, Post, Req } from "@nestjs/common";
import { SkipThrottle } from "@nestjs/throttler";
import type { Request } from "express";
import { z } from "zod";
import {
  CheckoutError,
  WalletTopupError,
  attachProviderOrder,
  attachTopupProviderOrder,
  createWalletTopup,
  getCurrentUser,
  getOrder,
  getWalletTopup,
  markOrderPaid,
  markPaymentFailed,
  markTopupFailed,
  markTopupPaid,
  orderIdForProviderOrder,
  topupIdForProviderOrder,
  Collections,
  type Db,
  type ArtworkDoc,
} from "@galleryzone/db";
import {
  startWalletTopupInputSchema,
  verifyWalletTopupInputSchema,
  type StartWalletTopupInput,
  type VerifyWalletTopupInput,
} from "@galleryzone/contracts";
import type { AppEnv } from "@galleryzone/config";
import { Public, Roles } from "../auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "../auth/roles.guard.ts";
import { DB, ENV } from "../db.module.ts";
import { Emails } from "../mail/emails.ts";
import { ReadCache } from "../read-cache.ts";
import { ZodValidationPipe } from "../zod-validation.pipe.ts";
import { Razorpay } from "./razorpay.ts";

const verifySchema = z
  .object({
    razorpayOrderId: z.string().min(1).max(100),
    razorpayPaymentId: z.string().min(1).max(100),
    signature: z.string().min(1).max(200),
  })
  .strict();
type VerifyBody = z.infer<typeof verifySchema>;

const notFound = () => new NotFoundException({ type: "about:blank", title: "Order not found", status: 404, code: "not_found" });

interface WebhookEvent {
  event: string;
  payload?: {
    payment?: { entity?: { id?: string; order_id?: string; method?: string; notes?: Record<string, string> } };
    order?: { entity?: { id?: string; receipt?: string; notes?: Record<string, string> } };
  };
}

@Controller("v1")
export class PaymentsController {
  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(ENV) private readonly env: AppEnv,
    private readonly razorpay: Razorpay,
    private readonly emails: Emails,
    private readonly cache: ReadCache,
  ) {}

  private async ownOrder(req: AuthenticatedRequest, id: string) {
    const order = await getOrder(this.db, id);
    // 404, not 403: don't confirm to a stranger that the order id exists.
    if (!order || order.customerId !== req.authUser.uid) throw notFound();
    return order;
  }

  private async settle(orderId: string, capture: { method: string; providerPaymentId: string | null; rawWebhookPayload?: unknown }) {
    const result = await markOrderPaid(this.db, orderId, capture);
    this.cache.clear();
    void this.emails
      .orderPaid({ orderId, customerId: result.customerId, artistId: result.artistId, title: result.artworkTitle, totalPaise: result.totalPaise, artistNetPaise: result.artistNetPaise })
      .catch(this.emails.swallow("order mail"));
    return result;
  }

  @Roles("customer")
  @Post("orders/:id/payment/session")
  async session(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    const order = await this.ownOrder(req, id);
    if (order.status !== "pending") {
      throw new BadRequestException({ type: "about:blank", title: `Order is already ${order.status}`, status: 409, code: "order_not_pending" });
    }
    if (this.env.paymentsMode !== "razorpay") return { mode: "simulated" as const };

    const [user, artworkSnap] = await Promise.all([
      getCurrentUser(this.db, req.authUser.uid, { touchLogin: false }),
      this.db.collection(Collections.artworks).doc(order.artworkId).get(),
    ]);
    const artwork = artworkSnap.data() as ArtworkDoc | undefined;
    const gateway = await this.razorpay.createOrder({ orderId: id, amountPaise: order.totalPaise, customerId: req.authUser.uid });
    await attachProviderOrder(this.db, id, gateway.id);
    return {
      mode: "razorpay" as const,
      keyId: this.razorpay.keyId,
      razorpayOrderId: gateway.id,
      amountPaise: order.totalPaise,
      currency: "INR",
      name: "GalleryZone",
      description: artwork ? `${artwork.title} (${artwork.productCode})` : `Order ${id}`,
      prefill: { name: user?.name ?? "", email: user?.email ?? "", contact: user?.phone ?? "" },
    };
  }

  @Roles("customer")
  @Post("orders/:id/payment/verify")
  async verify(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(verifySchema)) body: VerifyBody) {
    await this.ownOrder(req, id);
    const ours = await orderIdForProviderOrder(this.db, body.razorpayOrderId);
    if (ours !== id || !this.razorpay.verifyCheckoutSignature(body)) {
      throw new BadRequestException({ type: "about:blank", title: "Payment signature does not match", status: 400, code: "bad_signature" });
    }
    try {
      const result = await this.settle(id, { method: "razorpay_checkout", providerPaymentId: body.razorpayPaymentId });
      return { status: "paid", transactionId: result.transactionId };
    } catch (error) {
      if (error instanceof CheckoutError) throw new BadRequestException({ type: "about:blank", title: error.message, status: 409, code: "checkout_rejected" });
      throw error;
    }
  }

  private async ownTopup(req: AuthenticatedRequest, id: string) {
    const topup = await getWalletTopup(this.db, id);
    // 404, not 403: don't confirm to a stranger that the id exists.
    if (!topup || topup.userId !== req.authUser.uid) throw new NotFoundException({ type: "about:blank", title: "Top-up not found", status: 404, code: "not_found" });
    return topup;
  }

  @Roles("aggregator")
  @Post("aggregator/wallet/topups")
  async startTopup(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(startWalletTopupInputSchema)) body: StartWalletTopupInput) {
    const { topupId } = await createWalletTopup(this.db, { userId: req.authUser.uid, amountPaise: body.amountPaise });
    if (this.env.paymentsMode !== "razorpay") return { mode: "simulated" as const, topupId, amountPaise: body.amountPaise };

    const [user, gateway] = await Promise.all([
      getCurrentUser(this.db, req.authUser.uid, { touchLogin: false }),
      this.razorpay.createTopupOrder({ topupId, amountPaise: body.amountPaise, userId: req.authUser.uid }),
    ]);
    await attachTopupProviderOrder(this.db, topupId, gateway.id);
    return {
      mode: "razorpay" as const,
      topupId,
      keyId: this.razorpay.keyId,
      razorpayOrderId: gateway.id,
      amountPaise: body.amountPaise,
      currency: "INR",
      name: "GalleryZone",
      description: "Add funds to your GalleryZone wallet",
      prefill: { name: user?.name ?? "", email: user?.email ?? "", contact: user?.phone ?? "" },
    };
  }

  @Roles("aggregator")
  @Post("aggregator/wallet/topups/:id/verify")
  async verifyTopup(@Req() req: AuthenticatedRequest, @Param("id") id: string, @Body(new ZodValidationPipe(verifyWalletTopupInputSchema)) body: VerifyWalletTopupInput) {
    const topup = await this.ownTopup(req, id);
    if (topup.providerOrderId !== body.razorpayOrderId || !this.razorpay.verifyCheckoutSignature(body)) {
      throw new BadRequestException({ type: "about:blank", title: "Payment signature does not match", status: 400, code: "bad_signature" });
    }
    const result = await markTopupPaid(this.db, id, { method: "razorpay_checkout", providerPaymentId: body.razorpayPaymentId });
    return { status: "paid", amountPaise: result.amountPaise };
  }

  /** The simulated gateway, for environments with no Razorpay keys. Refused the moment PAYMENTS_MODE is razorpay. */
  @Roles("aggregator")
  @Post("aggregator/wallet/topups/:id/simulate")
  async simulateTopup(@Req() req: AuthenticatedRequest, @Param("id") id: string) {
    if (this.env.paymentsMode !== "simulated") {
      throw new ForbiddenException({ type: "about:blank", title: "Simulated payment is disabled", status: 403, code: "payments_not_simulated" });
    }
    await this.ownTopup(req, id);
    const result = await markTopupPaid(this.db, id, { method: "simulated", providerPaymentId: null });
    return { status: "paid", amountPaise: result.amountPaise };
  }

  /** Razorpay → us. Always 200 once the signature checks out, so Razorpay stops retrying; unknown events are ignored. */
  @Public()
  @SkipThrottle()
  @Post("payments/razorpay/webhook")
  @HttpCode(200)
  async webhook(@Req() req: Request & { rawBody?: Buffer }, @Headers("x-razorpay-signature") signature: string | undefined) {
    const raw = req.rawBody ?? Buffer.from(JSON.stringify(req.body ?? {}));
    if (!this.razorpay.verifyWebhookSignature(raw, signature)) {
      throw new BadRequestException({ type: "about:blank", title: "Invalid webhook signature", status: 400, code: "bad_signature" });
    }
    const event = req.body as WebhookEvent;
    const payment = event.payload?.payment?.entity;
    const providerOrderId = payment?.order_id ?? event.payload?.order?.entity?.id ?? null;
    // A wallet top-up is told apart from an artwork order by its note (or its gateway order id).
    const topupId =
      payment?.notes?.gzTopupId ?? event.payload?.order?.entity?.notes?.gzTopupId ?? (providerOrderId ? await topupIdForProviderOrder(this.db, providerOrderId) : null);
    if (topupId) return this.topupWebhook(event.event, topupId, payment);

    const noteOrderId = payment?.notes?.gzOrderId ?? event.payload?.order?.entity?.notes?.gzOrderId ?? null;
    const orderId = noteOrderId ?? (providerOrderId ? await orderIdForProviderOrder(this.db, providerOrderId) : null);
    if (!orderId) return { received: true, matched: false };

    switch (event.event) {
      case "payment.captured":
      case "order.paid":
        try {
          await this.settle(orderId, { method: payment?.method ? `razorpay_${payment.method}` : "razorpay", providerPaymentId: payment?.id ?? null, rawWebhookPayload: event });
        } catch (error) {
          // A cancelled order that later gets a capture is an operator problem, not a retry loop.
          if (!(error instanceof CheckoutError)) throw error;
        }
        break;
      case "payment.failed": {
        await markPaymentFailed(this.db, orderId, { providerPaymentId: payment?.id ?? null, rawWebhookPayload: event });
        // The buyer reached the gateway and it declined. Saying nothing means
        // the cart simply dies; they often don't realise it didn't go through.
        const failed = await getOrder(this.db, orderId);
        if (failed) {
          void this.emails
            .paymentFailed({ orderId, customerId: failed.customerId, title: failed.artwork?.title ?? "your artwork", totalPaise: failed.totalPaise })
            .catch(this.emails.swallow("payment failed mail"));
        }
        break;
      }
      default:
        break;
    }
    return { received: true, matched: true };
  }

  private async topupWebhook(event: string, topupId: string, payment: { id?: string; method?: string } | undefined) {
    try {
      if (event === "payment.captured" || event === "order.paid") {
        await markTopupPaid(this.db, topupId, { method: payment?.method ? `razorpay_${payment.method}` : "razorpay", providerPaymentId: payment?.id ?? null });
      } else if (event === "payment.failed") {
        await markTopupFailed(this.db, topupId, { providerPaymentId: payment?.id ?? null });
      }
    } catch (error) {
      // An unknown top-up id is an operator problem, not a retry loop.
      if (!(error instanceof WalletTopupError)) throw error;
    }
    return { received: true, matched: true };
  }
}
