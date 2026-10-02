// MOU signing for artists and aggregators. GET returns the latest signed
// record plus the draft: the current version with its blanks filled from the
// signer's profile, so the unsigned document can show exactly what will be
// recorded. POST records a new acceptance with the server's clock as the
// signing time and the filled blanks snapshotted.

import { Body, ConflictException, Controller, Get, Inject, Post, Req } from "@nestjs/common";
import { z } from "zod";
import type { AppEnv } from "@galleryzone/config";
import { getLatestMouAcceptance, getMouDraft, MouError, recordMouAcceptance, type Db, type MouAcceptance, type MouParty } from "@galleryzone/db";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB, ENV } from "./db.module.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const acceptSchema = z
  .object({
    version: z.string().trim().min(1).max(40),
    signatureName: z.string().trim().min(1).max(120),
    signatureDataUrl: z.string().min(1).max(300_000),
  })
  .strict();
type AcceptBody = z.infer<typeof acceptSchema>;

// Field by field: the stored record also carries the signer's IP and user
// agent (the audit trail), which the API never hands back.
function toDto(a: MouAcceptance | null) {
  return a
    ? { party: a.party, version: a.version, signatureName: a.signatureName, signatureDataUrl: a.signatureDataUrl, acceptedAt: a.acceptedAt.toISOString(), parties: a.parties }
    : null;
}

function rejected(error: unknown): never {
  if (error instanceof MouError) throw new ConflictException({ type: "about:blank", title: error.message, status: 409, code: "mou_rejected" });
  throw error;
}

@Controller("v1")
export class MouController {
  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(ENV) private readonly env: AppEnv,
  ) {}

  private async latest(uid: string, party: MouParty) {
    const [acceptance, draft] = await Promise.all([getLatestMouAcceptance(this.db, uid, party), getMouDraft(this.db, uid, party, this.env.mouSignatory).catch(rejected)]);
    return { acceptance: toDto(acceptance), draft: { ...draft, asOf: draft.asOf.toISOString() } };
  }

  private async accept(req: AuthenticatedRequest, party: MouParty, body: AcceptBody) {
    try {
      const acceptance = await recordMouAcceptance(this.db, {
        uid: req.authUser.uid,
        party,
        version: body.version,
        signatureName: body.signatureName,
        signatureDataUrl: body.signatureDataUrl,
        signatory: this.env.mouSignatory,
        ip: req.ip ?? null,
        userAgent: req.header("user-agent") ?? null,
      });
      return toDto(acceptance);
    } catch (error) {
      rejected(error);
    }
  }

  @Roles("artist")
  @Get("artist/mou")
  artistLatest(@Req() req: AuthenticatedRequest) {
    return this.latest(req.authUser.uid, "artist");
  }

  @Roles("artist")
  @Post("artist/mou/accept")
  artistAccept(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(acceptSchema)) body: AcceptBody) {
    return this.accept(req, "artist", body);
  }

  @Roles("aggregator")
  @Get("aggregator/mou")
  aggregatorLatest(@Req() req: AuthenticatedRequest) {
    return this.latest(req.authUser.uid, "aggregator");
  }

  @Roles("aggregator")
  @Post("aggregator/mou/accept")
  aggregatorAccept(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(acceptSchema)) body: AcceptBody) {
    return this.accept(req, "aggregator", body);
  }
}
