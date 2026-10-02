// The MOU as data, and how its blanks are filled. Shared by the on-screen
// agreement (mou-agreement.tsx) and the signed PDF (mou-pdf.ts) so the two
// can never fill a blank differently.
//
// The text comes from docs/legal via scripts/gen-mou.mjs. The values come
// from the API: the draft (the signer's profile right now) before signing,
// the snapshot recorded with the signature after.

export type MouParty = "artist" | "aggregator";

export type MouFieldKey =
  | "party.name"
  | "party.businessName"
  | "party.address"
  | "party.mobile"
  | "party.email"
  | "party.governmentId"
  | "party.gstNo"
  | "party.effectiveDate"
  | "party.signature"
  | "party.date"
  | "company.signatory"
  | "company.name"
  | "company.designation"
  | "company.signature"
  | "company.date";

export type MouBlock =
  | { type: "title"; text: string }
  | { type: "heading"; text: string; center?: boolean }
  | { type: "subheading"; text: string }
  | { type: "paragraph"; text: string; center?: boolean }
  | { type: "item"; marker: string; text: string }
  /** "FOR GALLERYZONE PRIVATE LIMITED", "ARTIST": the heading over a signature block. */
  | { type: "signer"; text: string }
  | { type: "field"; label: string; key: MouFieldKey }
  | { type: "note"; text: string };

export interface MouDocument {
  party: MouParty;
  version: string;
  /** How the profile page names it — not part of the document text. */
  title: string;
  intro: string;
  /** The running footer of the source PDF, repeated on every page of ours. */
  footer: string;
  blocks: MouBlock[];
}

/** Mirrors MouPartyDetails in backend/packages/db/src/mou.ts. */
export interface MouPartyDetails {
  name: string | null;
  businessName: string | null;
  address: string | null;
  mobile: string | null;
  email: string | null;
  governmentId: string | null;
  gstNo: string | null;
}

export interface MouParties {
  party: MouPartyDetails;
  company: { name: string | null; designation: string | null };
}

export type MouDetailKey = keyof MouPartyDetails;

/** The current version with its blanks filled from the profile, as the API would record them now. */
export interface MouDraft {
  version: string;
  parties: MouParties;
  /** Required blanks the profile can't fill yet — signing is refused until they are empty. */
  missing: MouDetailKey[];
  /** The server's "now": the date the document will carry if signed today. */
  asOf: string;
}

export interface MouAcceptanceRecord {
  acceptedAt: string;
  signatureName: string;
  version: string;
  /** PNG data URL of the drawn signature. */
  signatureDataUrl: string | null;
  /** The blanks as signed. Null on records from before they were recorded. */
  parties: MouParties | null;
}

/** Everything a blank can be filled from, at one moment: before signing or as signed. */
export interface MouFill {
  parties: MouParties;
  /** The signing date: the acceptance time once signed, the server's today before. */
  date: string;
  signed: boolean;
  signatureName: string | null;
  signatureDataUrl: string | null;
}

export type MouFieldValue =
  | { kind: "text"; text: string }
  | { kind: "signature"; name: string; image: string | null }
  | { kind: "pending"; text: string }
  | { kind: "missing" }
  | { kind: "blank" };

// Dates on the document are Indian dates, whatever the reader's time zone:
// an MOU signed at 00:30 IST is dated that day, not the day before.
const IST = "Asia/Kolkata";

function datePart(iso: string, part: "day" | "month" | "year"): string {
  return new Intl.DateTimeFormat("en-IN", { timeZone: IST, [part]: part === "year" ? "numeric" : "2-digit" }).format(new Date(iso));
}

/** "29/09/2026" */
export function mouDate(iso: string): string {
  return `${datePart(iso, "day")}/${datePart(iso, "month")}/${datePart(iso, "year")}`;
}

/** "29 September 2026 at 6:45 pm IST" */
export function mouDateTime(iso: string): string {
  const when = new Intl.DateTimeFormat("en-IN", {
    timeZone: IST,
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(new Date(iso));
  return `${when} IST`;
}

const REQUIRED: Record<MouParty, MouDetailKey[]> = {
  artist: ["name", "address", "mobile", "email", "governmentId"],
  aggregator: ["name", "businessName", "address", "mobile"],
};

/** What one blank reads, at this moment. */
export function mouFieldValue(key: MouFieldKey, fill: MouFill, party: MouParty): MouFieldValue {
  const { company } = fill.parties;
  // Galleryzone signs through its configured signatory. Without one, its
  // lines stay blank rather than showing a name nobody gave.
  const companySigns = Boolean(company.name);

  switch (key) {
    case "party.signature":
      if (fill.signed && fill.signatureName) return { kind: "signature", name: fill.signatureName, image: fill.signatureDataUrl };
      return { kind: "pending", text: "Signed below" };
    case "party.date":
      return fill.signed ? { kind: "text", text: mouDate(fill.date) } : { kind: "pending", text: mouDate(fill.date) };
    case "party.effectiveDate": {
      const text = mouDate(fill.date).replaceAll("/", " / ");
      return fill.signed ? { kind: "text", text } : { kind: "pending", text };
    }
    case "company.signatory":
    case "company.name":
      return company.name ? { kind: "text", text: company.name } : { kind: "blank" };
    case "company.designation":
      return company.designation ? { kind: "text", text: company.designation } : { kind: "blank" };
    case "company.signature":
      if (!companySigns) return { kind: "blank" };
      return fill.signed ? { kind: "text", text: "Signed electronically" } : { kind: "pending", text: "Signed electronically when you sign" };
    case "company.date":
      if (!companySigns) return { kind: "blank" };
      return fill.signed ? { kind: "text", text: mouDate(fill.date) } : { kind: "pending", text: mouDate(fill.date) };
    default: {
      const detail = key.slice("party.".length) as MouDetailKey;
      const value = fill.parties.party[detail];
      if (value) return { kind: "text", text: value };
      return REQUIRED[party].includes(detail) ? { kind: "missing" } : { kind: "blank" };
    }
  }
}

/** How the profile page names a missing detail. */
export const MOU_DETAIL_LABEL: Record<MouDetailKey, string> = {
  name: "Full name",
  businessName: "Business name",
  address: "Address (line 1, city, state and pincode)",
  mobile: "Mobile number",
  email: "Email",
  governmentId: "PAN",
  gstNo: "GST number",
};
