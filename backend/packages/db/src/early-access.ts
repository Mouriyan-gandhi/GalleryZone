// The Early Artist Program's free period. Nothing here is stored per artist:
// the end date is worked out on read from when the artist joined and whether
// their email is on the survey list (earlyAccessEmails/{email}). Adding emails
// to the list later therefore upgrades accounts that already exist, with no
// backfill. Nothing bills artists yet; when subscription billing is built it
// should ask freeAccessFor() whether the artist is still inside the free period.

import type { Firestore } from "firebase-admin/firestore";
import { earlyAccessEndsAt, EARLY_ACCESS_MONTHS, EARLY_ACCESS_SURVEY_MONTHS } from "@galleryzone/domain";
import { Collections } from "./collections.ts";

export interface FreeAccess {
  /** When the free period ends, ISO. */
  until: string;
  months: number;
  /** On the survey list, so a full year instead of six months. */
  surveyRespondent: boolean;
  /** Still inside the free period right now. */
  active: boolean;
}

const normalize = (email: string) => email.trim().toLowerCase();

/** Artists only; every other role has no free-access period. */
export async function freeAccessFor(
  db: Firestore,
  who: { email: string; role: string; joinedAt: Date },
  now = new Date(),
): Promise<FreeAccess | null> {
  if (who.role !== "artist") return null;
  const surveyRespondent = (await db.collection(Collections.earlyAccessEmails).doc(normalize(who.email)).get()).exists;
  const until = earlyAccessEndsAt(who.joinedAt, surveyRespondent);
  return {
    until: until.toISOString(),
    months: surveyRespondent ? EARLY_ACCESS_SURVEY_MONTHS : EARLY_ACCESS_MONTHS,
    surveyRespondent,
    active: until.getTime() > now.getTime(),
  };
}

/** Adds emails to the survey list (idempotent). At most 500 at a time: one Firestore batch. */
export async function addSurveyRespondents(db: Firestore, emails: string[]): Promise<{ added: number; alreadyListed: number }> {
  const unique = [...new Set(emails.map(normalize).filter(Boolean))];
  const refs = unique.map((email) => db.collection(Collections.earlyAccessEmails).doc(email));
  const existing = refs.length ? await db.getAll(...refs) : [];
  const alreadyListed = existing.filter((snap) => snap.exists).length;

  const batch = db.batch();
  refs.forEach((ref, i) => {
    if (!existing[i]?.exists) batch.set(ref, { email: unique[i], addedAt: new Date() });
  });
  await batch.commit();
  return { added: unique.length - alreadyListed, alreadyListed };
}

export async function listSurveyRespondents(db: Firestore): Promise<string[]> {
  const snap = await db.collection(Collections.earlyAccessEmails).get();
  return snap.docs.map((doc) => doc.id).sort();
}
