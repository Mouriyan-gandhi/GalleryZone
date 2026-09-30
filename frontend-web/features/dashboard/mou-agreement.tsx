"use client";

import {
  useArtistAccountProfile,
  useAcceptMouMutation,
} from "@/hooks/useArtistAccount";
import { MouAgreement as MouAgreementView } from "@/features/mou/mou-agreement";
import { ARTIST_MOU } from "./mou-data";

// The artist's side of the shared MOU surface — the aggregator portal has its
// own wrapper around the same component with its own document.
export function MouAgreement() {
  const { data: profile } = useArtistAccountProfile();
  const acceptMutation = useAcceptMouMutation();

  if (!profile) {
    return (
      <div className="h-40 animate-pulse rounded-lg border border-border bg-card" />
    );
  }

  return (
    <MouAgreementView
      document={ARTIST_MOU}
      signerName={profile.fullName}
      acceptance={profile.mouAcceptance}
      draft={profile.mouDraft}
      onSign={(input) => acceptMutation.mutate(input)}
      isPending={acceptMutation.isPending}
      error={acceptMutation.error}
      isSuccess={acceptMutation.isSuccess}
    />
  );
}
