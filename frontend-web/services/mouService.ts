// The MOU on the API (mou.controller.ts), for both parties: the latest
// signature and the draft, which is the current version with its blanks
// filled from the signer's profile. An acceptance of an older version reads
// as unsigned, which is what makes a newly published MOU require a new
// signature.

import { http } from "@/lib/api";
import type { MouAcceptanceRecord, MouDraft, MouParty } from "@/features/mou/mou-document";
import { MOU_VERSION } from "@/features/dashboard/mou-data";
import { AGGREGATOR_MOU_VERSION } from "@/features/aggregator/aggregator-mou-data";

const CURRENT: Record<MouParty, string> = { artist: MOU_VERSION, aggregator: AGGREGATOR_MOU_VERSION };

interface MouAcceptanceDto extends MouAcceptanceRecord {
  party: MouParty;
}

export interface MouState {
  /** The signature of the version in force, or null. */
  acceptance: MouAcceptanceRecord | null;
  draft: MouDraft;
}

function current(party: MouParty, a: MouAcceptanceDto | null): MouAcceptanceRecord | null {
  if (!a || a.version !== CURRENT[party]) return null;
  return { acceptedAt: a.acceptedAt, signatureName: a.signatureName, version: a.version, signatureDataUrl: a.signatureDataUrl, parties: a.parties };
}

export const mouService = {
  get: async (party: MouParty): Promise<MouState> => {
    const { acceptance, draft } = await http.get<{ acceptance: MouAcceptanceDto | null; draft: MouDraft }>(`/v1/${party}/mou`);
    return { acceptance: current(party, acceptance), draft };
  },

  accept: async (party: MouParty, input: { signatureName: string; version: string; signatureDataUrl: string }): Promise<MouAcceptanceRecord> => {
    const signed = await http.post<MouAcceptanceDto>(`/v1/${party}/mou/accept`, {
      version: input.version,
      signatureName: input.signatureName.trim(),
      signatureDataUrl: input.signatureDataUrl,
    });
    return current(party, signed) ?? signed;
  },
};
