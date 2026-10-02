import { Controller, Get, Inject, Req } from "@nestjs/common";
import { getWalletBalance, listWalletTransactions, listWithdrawalRequests, type Db } from "@galleryzone/db";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";

@Controller("v1/artist/wallet")
export class ArtistWalletController {
  constructor(@Inject(DB) private readonly db: Db) {}

  /** Ledger balance plus what is spoken for by withdrawal requests still pending admin approval. */
  @Roles("artist")
  @Get()
  async get(@Req() req: AuthenticatedRequest) {
    const [balance, withdrawals] = await Promise.all([
      getWalletBalance(this.db, "artist_payable", req.authUser.uid),
      listWithdrawalRequests(this.db, req.authUser.uid),
    ]);
    const lockedPaise = withdrawals.filter((w) => w.status === "pending").reduce((sum, w) => sum + w.amountPaise, 0);
    return { ...balance, lockedPaise, availablePaise: Math.max(0, balance.balancePaise - lockedPaise) };
  }

  /** Ledger entries and withdrawal requests, merged, newest first. */
  @Roles("artist")
  @Get("transactions")
  async transactions(@Req() req: AuthenticatedRequest) {
    const [entries, withdrawals] = await Promise.all([
      listWalletTransactions(this.db, "artist_payable", req.authUser.uid),
      listWithdrawalRequests(this.db, req.authUser.uid),
    ]);
    const rows = [
      ...entries.map((e) => ({ id: e.id, kind: "ledger" as const, amountPaise: e.amountPaise, reason: e.reason, status: "completed" as const, at: e.createdAt.toISOString() })),
      ...withdrawals
        // Approved withdrawals already appear as ledger entries.
        .filter((w) => w.status !== "completed")
        .map((w) => ({ id: w.id, kind: "withdrawal" as const, amountPaise: -w.amountPaise, reason: "withdrawal", status: w.status === "pending" ? ("pending" as const) : ("failed" as const), at: w.requestedAt.toISOString() })),
    ];
    return { transactions: rows.sort((a, b) => b.at.localeCompare(a.at)) };
  }
}

@Controller("v1/aggregator/wallet")
export class AggregatorWalletController {
  constructor(@Inject(DB) private readonly db: Db) {}

  // No withdrawal route here (plan.md §3.4: an aggregator is an agent, not a
  // principal). Money comes in by Razorpay top-up (payments.controller.ts) and
  // out through reservations and sales. `balancePaise` is what can be spent
  // now; `heldPaise` is set aside for pieces they hold.
  @Roles("aggregator")
  @Get()
  async get(@Req() req: AuthenticatedRequest) {
    const [balance, held] = await Promise.all([
      getWalletBalance(this.db, "aggregator_payable", req.authUser.uid),
      getWalletBalance(this.db, "aggregator_held", req.authUser.uid),
    ]);
    return { ...balance, heldPaise: held.balancePaise };
  }

  /** Top-ups, holds, returns and commission, oldest first. */
  @Roles("aggregator")
  @Get("transactions")
  async transactions(@Req() req: AuthenticatedRequest) {
    const entries = await listWalletTransactions(this.db, "aggregator_payable", req.authUser.uid);
    return {
      transactions: entries.map((e) => ({ id: e.id, amountPaise: e.amountPaise, reason: e.reason, holdingId: e.relatedHoldingId, at: e.createdAt.toISOString() })),
    };
  }
}

@Controller("v1/customer/wallet")
export class CustomerWalletController {
  constructor(@Inject(DB) private readonly db: Db) {}

  @Roles("customer")
  @Get()
  async get(@Req() req: AuthenticatedRequest) {
    return getWalletBalance(this.db, "customer_wallet", req.authUser.uid);
  }
}
