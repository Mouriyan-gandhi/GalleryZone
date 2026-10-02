// Memorandum of Understanding acceptance — the signed record behind the
// artist and aggregator MOU screens. One doc per (user, version) under
// users/{uid}/mouAcceptances/{version}; the server clock is the time of
// signing, never the browser's.
//
// The text of each version lives in docs/legal/<party>-mou-<version>.txt
// (transcribed from the company's PDF) and is rendered by the website. What
// this module owns is everything that fills the document's blanks: the
// party block ("Artist Name: ____", "GST No.: ____"), the Galleryzone
// signatory and the date. Those are built from the signer's profile by ONE
// function (mouPartyDetails), used both for the unsigned preview and for the
// record, so what a person sees before signing is what gets recorded. At
// signing they are snapshotted into the acceptance: editing the profile
// later never rewrites a signed agreement.

import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { DbError } from "./errors.ts";
import { getOwnProfile, type OwnProfile } from "./profiles.ts";
import { Collections } from "./collections.ts";

export class MouError extends DbError {}

export type MouParty = "artist" | "aggregator";

/**
 * The version each party must have signed. Publishing a new text means a new
 * docs/legal file, regenerating the website's MOU data (frontend-web
 * scripts/gen-mou.mjs), and bumping the matching version here — every signer
 * then has to sign again, and an aggregator can't reserve until they do.
 */
export const CURRENT_MOU_VERSION: Record<MouParty, string> = { artist: "2026.3", aggregator: "2026.2" };

/** The counterparty's blanks. Null where the profile has nothing to fill it with. */
export interface MouPartyDetails {
  name: string | null;
  businessName: string | null;
  address: string | null;
  mobile: string | null;
  email: string | null;
  governmentId: string | null;
  gstNo: string | null;
}

/** Who signs for Galleryzone (MOU_SIGNATORY_NAME / _DESIGNATION). Null until configured. */
export interface MouSignatory {
  name: string | null;
  designation: string | null;
}

export interface MouParties {
  party: MouPartyDetails;
  company: MouSignatory;
}

/** The blanks a party must be able to fill before signing. GST No. is not one: not every aggregator is registered. */
export const REQUIRED_MOU_DETAILS: Record<MouParty, (keyof MouPartyDetails)[]> = {
  artist: ["name", "address", "mobile", "email", "governmentId"],
  aggregator: ["name", "businessName", "address", "mobile"],
};

const MOU_DETAIL_LABEL: Record<keyof MouPartyDetails, string> = {
  name: "full name",
  businessName: "business name",
  address: "address (line 1, city, state and pincode)",
  mobile: "mobile number",
  email: "email",
  governmentId: "PAN",
  gstNo: "GST number",
};

type ProfileFacts = Pick<
  OwnProfile,
  "fullName" | "email" | "phone" | "pan" | "aadhaarMasked" | "gstin" | "companyName" | "pickupLine1" | "pickupLine2" | "pickupCity" | "pickupState" | "pickupPincode"
>;

const text = (v: string | null | undefined): string | null => (v && v.trim() ? v.trim() : null);

/** Fills the party block from a profile, and lists what is missing. Pure. */
export function mouPartyDetails(profile: ProfileFacts, party: MouParty): { details: MouPartyDetails; missing: (keyof MouPartyDetails)[] } {
  const [line1, line2, city, state, pincode] = [profile.pickupLine1, profile.pickupLine2, profile.pickupCity, profile.pickupState, profile.pickupPincode].map(text);
  const address = line1 && city && state && pincode ? [line1, line2, city, `${state} ${pincode}`].filter(Boolean).join(", ") : null;
  const phone = text(profile.phone);
  // Stored as the bare 10 digits (profiles.ts); written the way it is read aloud.
  const mobile = phone ? (/^\d{10}$/.test(phone) ? `+91 ${phone.slice(0, 5)} ${phone.slice(5)}` : phone) : null;
  // PAN identifies the signer for tax (Clause 37) and is already required to
  // list. An Aadhaar number only ever appears masked, never in full.
  const pan = text(profile.pan);
  const aadhaar = text(profile.aadhaarMasked);
  const governmentId = pan ? `PAN ${pan}` : aadhaar ? `Aadhaar ${aadhaar}` : null;

  const details: MouPartyDetails = {
    name: text(profile.fullName),
    businessName: party === "aggregator" ? text(profile.companyName) : null,
    address,
    mobile,
    email: text(profile.email),
    governmentId: party === "artist" ? governmentId : null,
    gstNo: party === "aggregator" ? text(profile.gstin) : null,
  };
  return { details, missing: REQUIRED_MOU_DETAILS[party].filter((key) => !details[key]) };
}

export function describeMissingMouDetails(missing: (keyof MouPartyDetails)[]): string {
  const labels = missing.map((key) => MOU_DETAIL_LABEL[key]);
  const list = labels.length > 1 ? `${labels.slice(0, -1).join(", ")} and ${labels.at(-1)}` : labels[0];
  return `Add your ${list} to your profile before signing`;
}

/** What the unsigned document shows right now: the current version, its blanks filled, and what is still missing. */
export async function getMouDraft(db: Firestore, uid: string, party: MouParty, signatory: MouSignatory) {
  const profile = await getOwnProfile(db, uid);
  if (!profile) throw new MouError(`No user ${uid}`);
  const { details, missing } = mouPartyDetails(profile, party);
  return { version: CURRENT_MOU_VERSION[party], parties: { party: details, company: signatory } satisfies MouParties, missing, asOf: new Date() };
}

export interface MouAcceptanceDoc {
  party: MouParty;
  version: string;
  signatureName: string;
  /** PNG data URL of the drawn signature. Null only on records from before the pad existed. */
  signatureDataUrl: string | null;
  acceptedAt: FirebaseFirestore.Timestamp;
  /** The filled blanks as signed. Absent on records from before they were recorded. */
  parties?: MouParties;
  /** Clause 34.2 / 24.2 audit information. Never returned by the API. */
  ip?: string | null;
  userAgent?: string | null;
}

export interface MouAcceptance {
  party: MouParty;
  version: string;
  signatureName: string;
  signatureDataUrl: string | null;
  acceptedAt: Date;
  parties: MouParties | null;
}

export const mouAcceptancesCol = (uid: string) => `${Collections.users}/${uid}/mouAcceptances`;

// A drawn signature is a small PNG; anything near Firestore's 1 MiB doc
// limit is not a signature.
const MAX_SIGNATURE_BYTES = 300_000;

export async function recordMouAcceptance(
  db: Firestore,
  input: {
    uid: string;
    party: MouParty;
    version: string;
    signatureName: string;
    signatureDataUrl: string;
    signatory: MouSignatory;
    ip?: string | null | undefined;
    userAgent?: string | null | undefined;
  },
): Promise<MouAcceptance> {
  if (input.version !== CURRENT_MOU_VERSION[input.party]) {
    throw new MouError("This agreement has been updated. Reload the page to read and sign the current version");
  }
  const profile = await getOwnProfile(db, input.uid);
  if (!profile) throw new MouError(`No user ${input.uid}`);

  const signatureName = input.signatureName.trim();
  if (!signatureName) throw new MouError("Type your full name to sign");
  if (signatureName.toLowerCase() !== profile.fullName.trim().toLowerCase()) {
    throw new MouError("The signature must match the name on your profile");
  }
  if (!input.signatureDataUrl.startsWith("data:image/png;base64,") || input.signatureDataUrl.length > MAX_SIGNATURE_BYTES) {
    throw new MouError("Draw your signature to sign");
  }

  const ref = db.collection(mouAcceptancesCol(input.uid)).doc(input.version);
  // Re-signing the same version keeps the ORIGINAL record — a signature isn't
  // something you refresh.
  const existing = await ref.get();
  if (existing.exists) return toAcceptance(existing.data() as MouAcceptanceDoc);

  const { details, missing } = mouPartyDetails(profile, input.party);
  if (missing.length) throw new MouError(describeMissingMouDetails(missing));

  const doc: MouAcceptanceDoc = {
    party: input.party,
    version: input.version,
    signatureName,
    signatureDataUrl: input.signatureDataUrl,
    acceptedAt: FieldValue.serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
    parties: { party: details, company: input.signatory },
    ip: input.ip ?? null,
    userAgent: input.userAgent?.slice(0, 300) ?? null,
  };
  await ref.set(doc);
  return toAcceptance((await ref.get()).data() as MouAcceptanceDoc);
}

/** The most recent acceptance for this party (any version), or null. */
export async function getLatestMouAcceptance(db: Firestore, uid: string, party: MouParty): Promise<MouAcceptance | null> {
  const snap = await db.collection(mouAcceptancesCol(uid)).where("party", "==", party).get();
  const docs = snap.docs.map((d) => toAcceptance(d.data() as MouAcceptanceDoc)).sort((a, b) => b.acceptedAt.getTime() - a.acceptedAt.getTime());
  return docs[0] ?? null;
}

/** True when the person has signed the version currently in force. */
export async function hasSignedCurrentMou(db: Firestore, uid: string, party: MouParty): Promise<boolean> {
  return (await db.collection(mouAcceptancesCol(uid)).doc(CURRENT_MOU_VERSION[party]).get()).exists;
}

function toAcceptance(doc: MouAcceptanceDoc): MouAcceptance {
  return {
    party: doc.party,
    version: doc.version,
    signatureName: doc.signatureName,
    signatureDataUrl: doc.signatureDataUrl,
    acceptedAt: doc.acceptedAt?.toDate() ?? new Date(0),
    parties: doc.parties ?? null,
  };
}
