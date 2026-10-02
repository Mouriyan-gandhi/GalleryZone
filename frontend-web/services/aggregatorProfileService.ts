// The aggregator's own profile on the API (GET/PATCH /v1/me/profile) plus
// the partner MOU (GET/POST /v1/aggregator/mou): the signature of the version
// in force and the draft with its blanks filled from this profile. An
// acceptance of an older MOU version reads as unsigned, which forces a re-sign.

import { profileApi, type OwnProfileDto, type OwnProfilePatch } from "@/services/profileApi";
import { mouService, type MouState } from "@/services/mouService";
import type { MouAcceptanceRecord, MouDraft } from "@/features/mou/mou-document";

export interface AggregatorProfileView {
  companyName: string;
  contactPerson: string;
  avatar: string | null;
  gstNumber: string;
  /** An aggregator needs an approved GST number before they can reserve anything. */
  gstStatus: "not_submitted" | "submitted" | "approved" | "rejected";
  phone: string;
  email: string;
  country: string;
  /** The address as the MOU and GalleryZone's shipments need it: street line, city, state, PIN. */
  addressLine1: string;
  addressCity: string;
  addressState: string;
  addressPincode: string;
  bankAccountMasked: string;
  /** Write-only: never returned by the API. */
  bankAccountNumber?: string;
  ifsc: string;
  securityDepositStatus: "active" | "pending";
  aadhaarMasked: string | null;
  coordinatorDesignation: string;
  coordinatorPhone: string;
  coordinatorEmail: string;
  mouAcceptance: MouAcceptanceRecord | null;
  mouDraft: MouDraft;
}

function toView(p: OwnProfileDto, mou: MouState): AggregatorProfileView {
  return {
    companyName: p.companyName ?? p.fullName,
    contactPerson: p.fullName,
    avatar: p.profileImageUrl,
    gstNumber: p.gstin ?? "",
    gstStatus: p.gstStatus,
    phone: p.phone ?? "",
    email: p.email,
    country: "IN",
    addressLine1: p.pickupLine1 ?? "",
    addressCity: p.pickupCity ?? "",
    addressState: p.pickupState ?? "",
    addressPincode: p.pickupPincode ?? "",
    bankAccountMasked: p.bankAccountMasked ?? "",
    ifsc: p.ifsc ?? "",
    securityDepositStatus: "pending",
    aadhaarMasked: p.aadhaarMasked,
    coordinatorDesignation: p.headline ?? "",
    coordinatorPhone: p.phone ?? "",
    coordinatorEmail: p.email,
    mouAcceptance: mou.acceptance,
    mouDraft: mou.draft,
  };
}

export const aggregatorProfileService = {
  getProfile: async (): Promise<AggregatorProfileView> => {
    const [p, m] = await Promise.all([profileApi.get(), mouService.get("aggregator")]);
    return toView(p, m);
  },

  acceptMou: async (input: { signatureName: string; version: string; signatureDataUrl: string }): Promise<AggregatorProfileView> => {
    await mouService.accept("aggregator", input);
    return aggregatorProfileService.getProfile();
  },

  updateProfile: async (patch: Partial<AggregatorProfileView>): Promise<AggregatorProfileView> => {
    const body: OwnProfilePatch = {};
    if (patch.contactPerson !== undefined) body.fullName = patch.contactPerson;
    if (patch.companyName !== undefined) body.companyName = patch.companyName || null;
    if (patch.phone !== undefined) body.phone = patch.phone || null;
    if (patch.gstNumber !== undefined) body.gstin = patch.gstNumber || null;
    if (patch.addressLine1 !== undefined) body.pickupLine1 = patch.addressLine1 || null;
    if (patch.addressCity !== undefined) body.pickupCity = patch.addressCity || null;
    if (patch.addressState !== undefined) body.pickupState = patch.addressState || null;
    if (patch.addressPincode !== undefined) body.pickupPincode = patch.addressPincode || null;
    if (patch.ifsc !== undefined) body.ifsc = patch.ifsc || null;
    if (patch.bankAccountNumber !== undefined) body.bankAccountNumber = patch.bankAccountNumber || null;
    if (patch.coordinatorDesignation !== undefined) body.headline = patch.coordinatorDesignation || null;
    const p = await profileApi.update(body);
    return toView(p, await mouService.get("aggregator"));
  },
};
