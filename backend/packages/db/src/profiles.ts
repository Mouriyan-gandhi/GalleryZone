// The account's own profile — read and edit. Three docs make up a
// profile and this module is the only place that knows the split:
//   users/{uid}                 identity (name, email, phone) — the guard reads it
//   users/{uid}/profile/data    private facts (PAN, GSTIN, bank mask, pickup address, socials)
//   publicProfiles/{uid}        what the artist page shows (headline, bio, location)
// Bank account numbers go to users/{uid}/financial/data, which no read
// route ever returns; the profile keeps only the masked tail.
//
// Compliance states move one way from here: saving a GSTIN puts gstStatus
// at "submitted" (an admin decides from there, moderation.ts); saving a
// different GSTIN after a decision resets it to "submitted".

import type { Firestore } from "firebase-admin/firestore";
import {
  Collections,
  userFinancialCol,
  userProfileCol,
  type FinancialDoc,
  type ProfileDoc,
  type PublicProfileDoc,
  type UserDoc,
} from "./collections.ts";
import { DbError } from "./errors.ts";

export class ProfileUpdateError extends DbError {}

export const PAN_RE = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
export const GSTIN_RE = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/;
export const IFSC_RE = /^[A-Z]{4}0[A-Z0-9]{6}$/;
export const PINCODE_RE = /^[1-9][0-9]{5}$/;

const EMPTY_PROFILE: ProfileDoc = {
  bio: null,
  profileImageUrl: null,
  headline: null,
  location: null,
  instagram: null,
  website: null,
  pan: null,
  gstin: null,
  gstStatus: "not_submitted",
  aadhaarStatus: "not_submitted",
  aadhaarMasked: null,
  bankAccountMasked: null,
  ifsc: null,
  pickupLine1: null,
  pickupLine2: null,
  pickupCity: null,
  pickupState: null,
  pickupPincode: null,
  earningsAbove5L: false,
  socialProofVideoUrl: null,
  companyName: null,
};

export interface OwnProfile extends ProfileDoc {
  uid: string;
  fullName: string;
  email: string;
  phone: string | null;
  role: UserDoc["role"];
  status: UserDoc["status"];
  createdAt: string;
}

export async function getOwnProfile(db: Firestore, uid: string): Promise<OwnProfile | null> {
  const [userSnap, profileSnap] = await Promise.all([
    db.collection(Collections.users).doc(uid).get(),
    db.collection(userProfileCol(uid)).doc("data").get(),
  ]);
  const user = userSnap.data() as UserDoc | undefined;
  if (!user) return null;
  const profile = { ...EMPTY_PROFILE, ...((profileSnap.data() as Partial<ProfileDoc> | undefined) ?? {}) };
  return {
    ...profile,
    uid,
    fullName: user.name,
    email: user.email,
    phone: user.phone ?? null,
    role: user.role,
    status: user.status,
    createdAt: user.createdAt?.toDate().toISOString() ?? new Date(0).toISOString(),
  };
}

export interface ProfilePatch {
  fullName?: string | undefined;
  phone?: string | null | undefined;
  headline?: string | null | undefined;
  bio?: string | null | undefined;
  location?: string | null | undefined;
  instagram?: string | null | undefined;
  website?: string | null | undefined;
  socialProofVideoUrl?: string | null | undefined;
  pan?: string | null | undefined;
  gstin?: string | null | undefined;
  companyName?: string | null | undefined;
  /** Full account number — stored in the financial doc, masked on the profile. */
  bankAccountNumber?: string | null | undefined;
  ifsc?: string | null | undefined;
  pickupLine1?: string | null | undefined;
  pickupLine2?: string | null | undefined;
  pickupCity?: string | null | undefined;
  pickupState?: string | null | undefined;
  pickupPincode?: string | null | undefined;
}

const clean = (v: string | null | undefined): string | null => {
  if (v === undefined || v === null) return null;
  const t = v.trim();
  return t.length ? t : null;
};

export async function updateOwnProfile(db: Firestore, uid: string, patch: ProfilePatch): Promise<OwnProfile> {
  const userRef = db.collection(Collections.users).doc(uid);
  const profileRef = db.collection(userProfileCol(uid)).doc("data");
  const publicRef = db.collection(Collections.publicProfiles).doc(uid);
  const financialRef = db.collection(userFinancialCol(uid)).doc("data");

  const [userSnap, profileSnap] = await Promise.all([userRef.get(), profileRef.get()]);
  const user = userSnap.data() as UserDoc | undefined;
  if (!user) throw new ProfileUpdateError(`No user ${uid}`);
  const current = { ...EMPTY_PROFILE, ...((profileSnap.data() as Partial<ProfileDoc> | undefined) ?? {}) };

  const userUpdate: Partial<UserDoc> = {};
  if (patch.fullName !== undefined) {
    const name = patch.fullName.trim();
    if (name.length < 2) throw new ProfileUpdateError("Name is too short");
    userUpdate.name = name;
  }
  if (patch.phone !== undefined) {
    const phone = clean(patch.phone)?.replace(/[\s-]/g, "") ?? null;
    if (phone && !/^(\+91)?[6-9]\d{9}$/.test(phone)) throw new ProfileUpdateError("Enter a 10-digit Indian mobile number");
    userUpdate.phone = phone ? phone.replace(/^\+91/, "") : null;
  }

  const profileUpdate: Partial<ProfileDoc> = {};
  const set = <K extends keyof ProfileDoc>(key: K, value: ProfileDoc[K]) => {
    profileUpdate[key] = value;
  };
  if (patch.headline !== undefined) set("headline", clean(patch.headline)?.slice(0, 120) ?? null);
  if (patch.bio !== undefined) set("bio", clean(patch.bio)?.slice(0, 2000) ?? null);
  if (patch.location !== undefined) set("location", clean(patch.location)?.slice(0, 80) ?? null);
  if (patch.instagram !== undefined) set("instagram", clean(patch.instagram)?.replace(/^@/, "").replace(/^https?:\/\/(www\.)?instagram\.com\//, "").replace(/\/$/, "") ?? null);
  if (patch.website !== undefined) set("website", clean(patch.website)?.replace(/^https?:\/\//, "").replace(/\/$/, "") ?? null);
  if (patch.socialProofVideoUrl !== undefined) set("socialProofVideoUrl", clean(patch.socialProofVideoUrl));
  if (patch.companyName !== undefined) set("companyName", clean(patch.companyName)?.slice(0, 120) ?? null);
  if (patch.pan !== undefined) {
    const pan = clean(patch.pan)?.toUpperCase() ?? null;
    if (pan && !PAN_RE.test(pan)) throw new ProfileUpdateError("PAN must look like ABCDE1234F");
    set("pan", pan);
  }
  if (patch.gstin !== undefined) {
    const gstin = clean(patch.gstin)?.toUpperCase() ?? null;
    if (gstin && !GSTIN_RE.test(gstin)) throw new ProfileUpdateError("GSTIN must be the 15-character registration number");
    set("gstin", gstin);
    if (gstin !== current.gstin) set("gstStatus", gstin ? "submitted" : "not_submitted");
  }
  if (patch.ifsc !== undefined) {
    const ifsc = clean(patch.ifsc)?.toUpperCase() ?? null;
    if (ifsc && !IFSC_RE.test(ifsc)) throw new ProfileUpdateError("IFSC must look like HDFC0001234");
    set("ifsc", ifsc);
  }
  if (patch.pickupPincode !== undefined) {
    const pin = clean(patch.pickupPincode);
    if (pin && !PINCODE_RE.test(pin)) throw new ProfileUpdateError("Pincode must be 6 digits");
    set("pickupPincode", pin);
  }
  for (const key of ["pickupLine1", "pickupLine2", "pickupCity", "pickupState"] as const) {
    if (patch[key] !== undefined) set(key, clean(patch[key])?.slice(0, 120) ?? null);
  }

  let financialUpdate: Partial<FinancialDoc> | null = null;
  if (patch.bankAccountNumber !== undefined) {
    const acct = clean(patch.bankAccountNumber)?.replace(/\s/g, "") ?? null;
    if (acct && !/^\d{9,18}$/.test(acct)) throw new ProfileUpdateError("Bank account number should be 9–18 digits");
    // The same guards the form applies, enforced here too: repeated digits or a straight run are test entries, not accounts.
    if (acct && (/^(\d)\1+$/.test(acct) || "01234567890123456789".includes(acct) || "98765432109876543210".includes(acct))) {
      throw new ProfileUpdateError("That doesn't look like a real account number");
    }
    financialUpdate = { bankAccountEncrypted: acct };
    set("bankAccountMasked", acct ? `•••• ${acct.slice(-4)}` : null);
  }

  const batch = db.batch();
  if (Object.keys(userUpdate).length) batch.update(userRef, userUpdate);
  if (Object.keys(profileUpdate).length) batch.set(profileRef, { ...current, ...profileUpdate }, { merge: true });
  if (financialUpdate) batch.set(financialRef, financialUpdate, { merge: true });
  if (user.role === "artist" || user.role === "aggregator") {
    const pub: Partial<PublicProfileDoc> = {};
    if (userUpdate.name) pub.name = userUpdate.name;
    if (profileUpdate.headline !== undefined) pub.headline = profileUpdate.headline;
    if (profileUpdate.bio !== undefined) pub.bio = profileUpdate.bio;
    if (profileUpdate.location !== undefined) pub.location = profileUpdate.location;
    if (Object.keys(pub).length) batch.set(publicRef, pub, { merge: true });
  }
  await batch.commit();

  const updated = await getOwnProfile(db, uid);
  if (!updated) throw new ProfileUpdateError(`No user ${uid}`);
  return updated;
}

/**
 * Whether this user's GSTIN has been approved by an admin, not merely typed
 * in. An aggregator needs it before they can reserve anything (client, 30 Sep
 * 2026); for an artist it is optional and only earns better access to the sales
 * channels. It no longer decides TDS: that follows the year's sales
 * (artist-sales.ts).
 */
export async function hasApprovedGst(db: Firestore, uid: string): Promise<boolean> {
  if (!uid) return false;
  const snap = await db.collection(userProfileCol(uid)).doc("data").get();
  return (snap.data() as Partial<ProfileDoc> | undefined)?.gstStatus === "approved";
}
