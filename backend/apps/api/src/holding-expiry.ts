// Ends aggregator placements when their window runs out (client, 30 Sep 2026:
// "on day 31 in the wallet"). Nothing else ever does it: the window used to
// pass in silence until the aggregator remembered to return the piece.
//
// A timer inside the API process, like ListingBackfill's boot-time job, so
// there is nothing extra to deploy. It runs once at boot and then every 15
// minutes. Two instances sweeping at once are safe: a return is idempotent
// (the state machine and the ledger's create() both refuse a second one).
// Turn it off with HOLDING_EXPIRY_SWEEP=false.

import { Inject, Injectable, Logger, type OnApplicationBootstrap, type OnModuleDestroy } from "@nestjs/common";
import { expireDueHoldings, type Db } from "@galleryzone/db";
import { DB } from "./db.module.ts";
import { Emails } from "./mail/emails.ts";
import { ReadCache } from "./read-cache.ts";

const EVERY_MS = 15 * 60_000;

@Injectable()
export class HoldingExpirySweep implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(HoldingExpirySweep.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
    private readonly emails: Emails,
  ) {}

  onApplicationBootstrap(): void {
    if (process.env.HOLDING_EXPIRY_SWEEP === "false") return;
    void this.sweep();
    this.timer = setInterval(() => void this.sweep(), EVERY_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async sweep(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      const { expired, failed } = await expireDueHoldings(this.db);
      for (const f of failed) this.logger.error(`could not end holding ${f.holdingId}: ${f.error}`);
      if (!expired.length) return;
      this.logger.log(`ended ${expired.length} placement(s) whose window ran out`);
      // The pieces are back on the marketplace and open to the next aggregator.
      this.cache.clear();
      for (const e of expired) {
        void this.emails.holdingPeriodEnded(e).catch(this.emails.swallow("holding period ended mail"));
      }
    } catch (error) {
      this.logger.error(`holding expiry sweep failed: ${String(error)}`);
    } finally {
      this.running = false;
    }
  }
}
