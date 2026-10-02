"use client";

import { Gift } from "lucide-react";
import { useArtistAccountProfile } from "@/hooks/useArtistAccount";

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat("en-IN", { day: "numeric", month: "long", year: "numeric" }).format(new Date(iso));
}

// The Early Artist Program's free period, from the profile: six months from
// joining, a full year for artists who filled in the survey. Silent once it has
// ended, rather than promising anything about what comes after.
export function FreeAccessNote() {
  const { data: profile } = useArtistAccountProfile();
  const access = profile?.freeAccess;
  if (!access?.active) return null;

  return (
    <div className="flex items-start gap-3 rounded-lg border border-gold/30 bg-gold/5 px-4 py-3 text-sm">
      <Gift className="mt-0.5 size-4 shrink-0 text-gold-bright" strokeWidth={1.75} />
      <p className="text-foreground/90">
        {access.surveyRespondent
          ? "A full year of free access to every premium feature, because you filled in our survey. "
          : "Free access to every premium feature, for your first six months. "}
        <span className="text-muted-foreground">It runs until {formatDate(access.until)}.</span>
      </p>
    </div>
  );
}
