"use client";

import {
  useAggregatorProfile,
  useAcceptAggregatorMouMutation,
} from "@/hooks/useAggregatorProfile";
import { MouAgreement } from "@/features/mou/mou-agreement";
import { AGGREGATOR_MOU } from "./aggregator-mou-data";

// The aggregator's partner agreement, on the same signing surface the artist
// MOU uses. Signed by the contact person (the account's name), whose name the
// signature has to match; the business name and address come from the profile.
export function AggregatorMouAgreement() {
  const { data: profile } = useAggregatorProfile();
  const acceptMutation = useAcceptAggregatorMouMutation();

  if (!profile) {
    return (
      <div className="h-40 animate-pulse rounded-lg border border-border bg-card" />
    );
  }

  // Unsigned, this is the most important thing on the page — nothing can be
  // reserved until it is done, so it sits above the profile form. Signed, it is
  // a receipt: still here to re-read, but no longer the first thing between the
  // aggregator and their own details. CSS order rather than a reshuffle in the
  // page, so the page stays a server component and this stays the one file that
  // knows whether it has been signed.
  return (
    <div className={profile.mouAcceptance ? "order-last" : undefined}>
      <MouAgreement
        document={AGGREGATOR_MOU}
        signerName={profile.contactPerson}
        acceptance={profile.mouAcceptance}
        draft={profile.mouDraft}
        onSign={(input) => acceptMutation.mutate(input)}
        isPending={acceptMutation.isPending}
        error={acceptMutation.error}
        isSuccess={acceptMutation.isSuccess}
      />
    </div>
  );
}
