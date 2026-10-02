import { Body, Controller, Delete, Get, Inject, Logger, Param, Patch, Post, Query } from "@nestjs/common";
import { z } from "zod";
import { NotFoundException } from "@nestjs/common";
import { FirestoreRateConfigStore, addSurveyRespondents, listSurveyRespondents, suggestEarningsAbove5L, adminKpis, listCategories, createCategory, updateCategory, deleteCategory, getUserForAdmin, listModerationQueue, listUsersForAdmin, listWithdrawalsForAdmin, setUserStatus, userRoleValues, userStatusValues, type Db, type UserRole } from "@galleryzone/db";
import { loadActiveRates } from "@galleryzone/config";
import { Roles } from "./auth/roles.decorator.ts";
import { Emails } from "./mail/emails.ts";
import { DB } from "./db.module.ts";
import { ZodValidationPipe } from "./zod-validation.pipe.ts";

const nameSchema = z.object({ name: z.string().min(1), slug: z.string().min(1).optional() }).strict();
type NameBody = z.infer<typeof nameSchema>;

const statusSchema = z.object({ status: z.enum([...userStatusValues]) }).strict();
type StatusBody = z.infer<typeof statusSchema>;

// 500 is one Firestore batch; send a longer list in several calls.
const surveyEmailsSchema = z.object({ emails: z.array(z.string().trim().email()).min(1).max(500) }).strict();
type SurveyEmailsBody = z.infer<typeof surveyEmailsSchema>;

@Controller("v1/admin")
export class AdminController {
  private readonly logger = new Logger(AdminController.name);

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly emails: Emails,
  ) {}

  @Roles("admin")
  @Get("kpis")
  kpis() {
    return adminKpis(this.db);
  }

  @Roles("admin")
  @Get("withdrawals")
  async withdrawals() {
    return { withdrawals: await listWithdrawalsForAdmin(this.db) };
  }

  @Roles("admin")
  @Get("moderation/gst")
  async gstQueue() {
    return { users: await listModerationQueue(this.db, "gst") };
  }

  @Roles("admin")
  @Get("moderation/kyc")
  async kycQueue() {
    return { users: await listModerationQueue(this.db, "kyc") };
  }

  /** Artists on this list get a year of free access instead of six months, counted from when they joined. */
  @Roles("admin")
  @Post("early-access/survey-emails")
  addSurveyEmails(@Body(new ZodValidationPipe(surveyEmailsSchema)) body: SurveyEmailsBody) {
    return addSurveyRespondents(this.db, body.emails);
  }

  @Roles("admin")
  @Get("early-access/survey-emails")
  async surveyEmails() {
    return { emails: await listSurveyRespondents(this.db) };
  }

  @Roles("admin")
  @Get("categories")
  categories() {
    return listCategories(this.db);
  }

  @Roles("admin")
  @Post("categories")
  createCategory(@Body(new ZodValidationPipe(nameSchema)) body: NameBody) {
    return createCategory(this.db, body.name, body.slug ?? body.name.toLowerCase().replace(/\s+/g, "-"));
  }

  @Roles("admin")
  @Patch("categories/:id")
  updateCategory(@Param("id") id: string, @Body(new ZodValidationPipe(nameSchema)) body: NameBody) {
    return updateCategory(this.db, id, body.name);
  }

  @Roles("admin")
  @Delete("categories/:id")
  deleteCategory(@Param("id") id: string) {
    return deleteCategory(this.db, id);
  }

  @Roles("admin")
  @Get("users")
  async users(@Query("role") role?: string) {
    const parsedRole = role && (userRoleValues as readonly string[]).includes(role) ? (role as UserRole) : undefined;
    return { users: await listUsersForAdmin(this.db, parsedRole) };
  }

  @Roles("admin")
  @Get("users/:id")
  async user(@Param("id") id: string) {
    const user = await getUserForAdmin(this.db, id);
    if (!user) throw new NotFoundException({ type: "about:blank", title: "User not found", status: 404, code: "not_found" });
    // The §194-O flag is toggled by hand (PATCH users/:id/earnings-above-5l),
    // and until now the admin doing it had no figure to go on — the
    // suggestion was computed by a function nothing called. Advisory only:
    // crossing the threshold changes what is withheld from an artist, so a
    // person still confirms it.
    if (user.role !== "artist") return { ...user, earningsAbove5LSuggested: false };
    // Advisory: if it can't be computed, the page still has to render. It took
    // this whole route down once already by depending on a Firestore index.
    const suggested = await this.earningsSuggestion(id);
    return { ...user, earningsAbove5LSuggested: suggested };
  }

  private async earningsSuggestion(userId: string): Promise<boolean | null> {
    try {
      const rates = await loadActiveRates(new FirestoreRateConfigStore(this.db));
      return await suggestEarningsAbove5L(this.db, userId, rates);
    } catch (error) {
      this.logger.warn(`earnings suggestion for ${userId} unavailable: ${String(error)}`);
      return null;
    }
  }

  @Roles("admin")
  @Patch("users/:id/status")
  async setUserStatus(@Param("id") id: string, @Body(new ZodValidationPipe(statusSchema)) body: StatusBody) {
    const result = await setUserStatus(this.db, id, body.status);
    // Being locked out with no explanation is the worst version of this.
    void this.emails.accountStatusChanged({ userId: id, status: body.status }).catch(this.emails.swallow("account status mail"));
    return result;
  }
}
