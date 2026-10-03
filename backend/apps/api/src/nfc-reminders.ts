// Reminds artists to lock a tag they linked and walked away from
// (NFC_IMPLEMENTATION.md §13): one mail at 48 hours, one at 7 days.
//
// A timer inside the API process, like HoldingExpirySweep, so there is nothing
// extra to deploy: it runs at boot and then hourly. Two instances sweeping at
// once are harmless — the mail's idempotency key carries the artwork, the stage
// and the link time, so the provider drops the second one.
// Turn it off with NFC_REMINDER_SWEEP=false.

import { Inject, Injectable, Logger, type OnApplicationBootstrap, type OnModuleDestroy } from "@nestjs/common";
import { dueNfcReminders, markNfcReminderSent, type Db } from "@galleryzone/db";
import { DB } from "./db.module.ts";
import { Emails } from "./mail/emails.ts";

const EVERY_MS = 60 * 60_000;

@Injectable()
export class NfcReminderSweep implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(NfcReminderSweep.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly emails: Emails,
  ) {}

  onApplicationBootstrap(): void {
    if (process.env.NFC_REMINDER_SWEEP === "false") return;
    // Give the app a minute to settle before the first read.
    const first = setTimeout(() => void this.sweep(), 60_000);
    first.unref();
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
      const due = await dueNfcReminders(this.db);
      for (const d of due) {
        try {
          await this.emails.nfcLockReminder(d);
          await markNfcReminderSent(this.db, d.artworkId, d.stage);
        } catch (error) {
          this.logger.error(`NFC lock reminder (${d.stage}) for ${d.artworkId} failed: ${String(error)}`);
        }
      }
      if (due.length) this.logger.log(`sent ${due.length} NFC lock reminder(s)`);
    } catch (error) {
      this.logger.error(`NFC reminder sweep failed: ${String(error)}`);
    } finally {
      this.running = false;
    }
  }
}
