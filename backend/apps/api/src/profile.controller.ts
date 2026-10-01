// The signed-in account's own profile, for every role:
//   GET   /v1/me/profile     identity + private facts + compliance states
//   PATCH /v1/me/profile     partial update; validation in packages/db/profiles.ts
// One route pair rather than one per role — the body schema is a superset
// and the db layer ignores what doesn't apply (a customer has no GSTIN).

import { BadRequestException, Body, Controller, Get, Inject, NotFoundException, Patch, Req } from "@nestjs/common";
import { z } from "zod";
import { freeAccessFor, getOwnProfile, updateOwnProfile, ProfileUpdateError, refreshArtistListings, type Db, type OwnProfile } from "@galleryzone/db";
import { Roles } from "./auth/roles.decorator.ts";
import type { AuthenticatedRequest } from "./auth/roles.guard.ts";
import { DB } from "./db.module.ts";
import { ReadCache } from "./read-cache.ts";
import { Emails } from "./mail/emails.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const nullableText = (max: number) => z.string().trim().max(max).nullable().optional();

const patchSchema = z
  .object({
    fullName: z.string().trim().min(2).max(120).optional(),
    phone: nullableText(20),
    headline: nullableText(120),
    bio: nullableText(2000),
    location: nullableText(80),
    instagram: nullableText(120),
    website: nullableText(200),
    socialProofVideoUrl: nullableText(300),
    pan: nullableText(10),
    gstin: nullableText(15),
    companyName: nullableText(120),
    bankAccountNumber: nullableText(24),
    ifsc: nullableText(11),
    pickupLine1: nullableText(120),
    pickupLine2: nullableText(120),
    pickupCity: nullableText(80),
    pickupState: nullableText(80),
    pickupPincode: nullableText(6),
  })
  .strict();
type PatchBody = z.infer<typeof patchSchema>;

@Controller("v1/me")
export class ProfileController {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly cache: ReadCache,
    private readonly emails: Emails,
  ) {}

  /** The profile plus the artist's free-access period (null for every other role). */
  private async withFreeAccess(profile: OwnProfile) {
    const freeAccess = await freeAccessFor(this.db, { email: profile.email, role: profile.role, joinedAt: new Date(profile.createdAt) });
    return { ...profile, freeAccess };
  }

  @Roles("customer", "artist", "aggregator", "admin")
  @Get("profile")
  async get(@Req() req: AuthenticatedRequest) {
    const profile = await getOwnProfile(this.db, req.authUser.uid);
    if (!profile) throw new NotFoundException({ type: "about:blank", title: "Not found", status: 404, code: "not_found" });
    return this.withFreeAccess(profile);
  }

  @Roles("customer", "artist", "aggregator", "admin")
  @Patch("profile")
  async patch(@Req() req: AuthenticatedRequest, @Body(new ZodValidationPipe(patchSchema)) body: PatchBody) {
    try {
      const profile = await updateOwnProfile(this.db, req.authUser.uid, body);
      // A changed payout destination is the classic account-takeover payload,
      // so the owner is always told — including when it wasn't them.
      if (body.bankAccountNumber !== undefined) {
        void this.emails
          .bankAccountChanged({ userId: req.authUser.uid, maskedAccount: profile.bankAccountMasked ?? null })
          .catch(this.emails.swallow("bank change mail"));
      }
      // A renamed or relocated artist changes every one of their listing rows.
      if (profile.role === "artist" && (body.fullName !== undefined || body.location !== undefined)) {
        await refreshArtistListings(this.db, req.authUser.uid);
        this.cache.clear();
      }
      return this.withFreeAccess(profile);
    } catch (error) {
      if (error instanceof ProfileUpdateError) {
        throw new BadRequestException({ type: "about:blank", title: error.message, status: 400, code: "profile_rejected" });
      }
      throw error;
    }
  }
}
