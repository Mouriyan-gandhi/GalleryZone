"use client";

import { useCurrentUser } from "@/hooks/useCurrentUser";

import Link from "next/link";
import {
  ChevronRight,
  CircleCheckBig,
  Clock,
  FileEdit,
  Frame,
  Landmark,
  MapPin,
  Star,
  Store,
} from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { formatINR } from "@/lib/utils";
import {
  useArtistPrivateStats,
  useArtistPublicStats,
} from "@/hooks/useProfileStats";

// The artist's own profile at a glance: both halves, side by side, which is
// the one place they legitimately appear together.
//
// The split is deliberate and labelled on screen. The left column is what any
// visitor to their public page can see; the right is what only they can. An
// artist who cannot tell which is which will either under-share or assume we
// are publishing their earnings — and the second is the one that loses trust.

function joinedLabel(iso: string): string {
  const date = new Date(iso);
  if (!iso || Number.isNaN(date.getTime())) return "—";
  return date.toLocaleDateString("en-IN", {
    month: "long",
    year: "numeric",
  });
}

export function ArtistProfileSummary({ location }: { location?: string }) {
  const artistId = useCurrentUser().data?.uid ?? "";
  const { data: pub, isPending: pubPending, isError: pubError, refetch: refetchPub } = useArtistPublicStats(artistId);
  const { data: mine, isPending: minePending, isError: mineError, refetch: refetchMine } = useArtistPrivateStats(artistId);

  // A failed request must not leave a skeleton on the page indefinitely —
  // that reads as a blank gap. Say so, and offer a retry.
  if (pubError || mineError) {
    return (
      <div className="flex flex-col items-start gap-2 rounded-lg border border-border bg-card p-5 text-sm sm:p-6 lg:col-span-2">
        <p className="text-foreground">Your profile figures couldn&rsquo;t be loaded just now.</p>
        <button
          type="button"
          onClick={() => {
            void refetchPub();
            void refetchMine();
          }}
          className="text-xs font-medium text-gold-bright hover:underline"
        >
          Try again
        </button>
      </div>
    );
  }

  if (pubPending || minePending || !pub || !mine) {
    return <Skeleton className="h-56 w-full rounded-lg lg:col-span-2" />;
  }

  const publicCells = [
    { key: "listed", label: "Listed", value: String(pub.artworksListed), icon: Frame },
    { key: "sold", label: "Sold", value: String(pub.worksSold), icon: CircleCheckBig },
    { key: "display", label: "At galleries", value: String(pub.onDisplay), icon: Store },
    {
      key: "rating",
      label: "Rating",
      value: pub.rating.count === 0 ? "—" : pub.rating.average.toFixed(1),
      icon: Star,
    },
  ];

  const privateCells = [
    { key: "earned", label: "Withdrawable", value: formatINR(mine.lifetimeEarnings), icon: Landmark },
    { key: "pending", label: "On the way", value: formatINR(mine.pendingEarnings), icon: Clock },
    {
      key: "average",
      label: "Average per sale",
      value: mine.averageSalePrice === 0 ? "—" : formatINR(mine.averageSalePrice),
      icon: Landmark,
    },
    { key: "drafts", label: "Drafts", value: String(mine.drafts + mine.awaitingReview), icon: FileEdit },
  ];

  return (
    // Collapsible like the signed MOU card (features/mou/mou-agreement.tsx):
    // a native <details> so the artist can shorten this on a small screen and
    // see the cards below without scrolling past it — open by default since,
    // unlike a signed legal doc, these stats are the point of the page.
    <details
      open
      className="group rounded-lg border border-border bg-card p-5 sm:p-6 lg:col-span-2"
    >
      <summary className="flex cursor-pointer list-none flex-wrap items-baseline justify-between gap-2">
        <span className="flex items-center gap-2">
          <ChevronRight
            className="size-4 shrink-0 text-muted-foreground transition-transform group-open:rotate-90"
            strokeWidth={1.75}
          />
          <h2 className="font-display text-lg font-semibold text-foreground">
            Your profile
          </h2>
        </span>
        <p className="flex flex-wrap items-center gap-x-3 text-sm text-muted-foreground">
          {location && (
            <span className="flex items-center gap-1.5">
              <MapPin className="size-3.5" strokeWidth={1.75} />
              {location}
            </span>
          )}
          <span>Since {joinedLabel(pub.joinedAt)}</span>
        </p>
      </summary>

      <div className="mt-5 grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div>
          <h3 className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            What collectors see
          </h3>
          {/* 2 columns below lg, not 4 — at 4-wide, narrow labels like "At
              galleries" wrap to a second line while their neighbors don't,
              so the value underneath lands at a different height per column
              (each cell is its own flex-col, so nothing re-aligns the dd's
              across cells). Confirmed by measuring the rendered card. */}
          <dl className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-4">
            {publicCells.map((cell) => (
              <div key={cell.key} className="flex flex-col gap-1">
                <dt className="flex items-center gap-1 text-[11px] text-muted-foreground">
                  <cell.icon className="size-3" strokeWidth={1.75} />
                  {cell.label}
                </dt>
                <dd className="font-display text-lg font-semibold tabular-nums text-foreground">
                  {cell.value}
                </dd>
              </div>
            ))}
          </dl>
          <Link
            href={`/artists/${artistId}`}
            className="mt-3 inline-block text-xs text-gold-bright underline-offset-4 hover:underline"
          >
            View your public profile
          </Link>
        </div>

        <div className="sm:border-l sm:border-border sm:pl-6">
          <h3 className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            Only you see this
          </h3>
          <dl className="mt-3 grid grid-cols-2 gap-3 lg:grid-cols-4">
            {privateCells.map((cell) => (
              <div key={cell.key} className="flex flex-col gap-1">
                <dt className="flex items-center gap-1 text-[11px] text-muted-foreground">
                  <cell.icon className="size-3" strokeWidth={1.75} />
                  {cell.label}
                </dt>
                <dd className="font-display text-lg font-semibold tabular-nums text-foreground">
                  {cell.value}
                </dd>
              </div>
            ))}
          </dl>
          <p className="mt-3 text-[11px] leading-relaxed text-muted-foreground">
            Your prices and earnings are never shown on your public page.
          </p>
        </div>
      </div>
    </details>
  );
}
