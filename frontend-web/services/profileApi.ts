// The signed-in account's own profile on the API (GET/PATCH /v1/me/profile)
// — shared by the artist KYC form, the collector settings page and the
// aggregator profile. Bank account numbers are write-only: the API keeps
// the full number in a doc no read route returns and hands back a mask.

import { http } from "@/lib/api";

export interface OwnProfileDto {
  uid: string;
  fullName: string;
  email: string;
  phone: string | null;
  role: "artist" | "aggregator" | "customer" | "admin";
  status: string;
  createdAt: string;
  bio: string | null;
  profileImageUrl: string | null;
  headline: string | null;
  location: string | null;
  instagram: string | null;
  website: string | null;
  pan: string | null;
  gstin: string | null;
  gstStatus: "not_submitted" | "submitted" | "approved" | "rejected";
  aadhaarStatus: "not_submitted" | "submitted" | "approved" | "rejected";
  aadhaarMasked: string | null;
  bankAccountMasked: string | null;
  ifsc: string | null;
  pickupLine1: string | null;
  pickupLine2: string | null;
  pickupCity: string | null;
  pickupState: string | null;
  pickupPincode: string | null;
  earningsAbove5L: boolean;
  socialProofVideoUrl: string | null;
  companyName: string | null;
  /** Artists only: the Early Artist Program's free period. Null for every other role. */
  freeAccess?: FreeAccess | null;
}

export interface FreeAccess {
  /** When the free period ends, ISO. */
  until: string;
  months: number;
  /** On the survey list: a full year instead of six months. */
  surveyRespondent: boolean;
  active: boolean;
}

export type OwnProfilePatch = Partial<{
  fullName: string;
  phone: string | null;
  headline: string | null;
  bio: string | null;
  location: string | null;
  instagram: string | null;
  website: string | null;
  socialProofVideoUrl: string | null;
  pan: string | null;
  gstin: string | null;
  companyName: string | null;
  bankAccountNumber: string | null;
  ifsc: string | null;
  pickupLine1: string | null;
  pickupLine2: string | null;
  pickupCity: string | null;
  pickupState: string | null;
  pickupPincode: string | null;
}>;

export const profileApi = {
  get: () => http.get<OwnProfileDto>("/v1/me/profile"),
  update: (patch: OwnProfilePatch) => http.patch<OwnProfileDto>("/v1/me/profile", patch),
};
