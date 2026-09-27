"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ShieldCheck, PackageSearch, FileSignature, Heart, LayoutGrid, List } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { EmptyState } from "@/components/shared/empty-state";
import { PriceTag } from "@/components/shared/price-tag";
import { VerifiedBadge } from "@/components/shared/verified-badge";
import { useReservableInventory } from "@/hooks/useAggregatorInventory";
import { AGGREGATOR_CYCLE_MONTHS } from "@/lib/pricing";
import { formatINR, cn } from "@/lib/utils";
import type { ReservableArtwork } from "@/services/aggregatorService";
import { useAggregatorProfile } from "@/hooks/useAggregatorProfile";
import { CycleStepper } from "./cycle-stepper";

// Same lower-bound verification treatment ArtworkCard uses -- ArtworkSummary
// only carries a boolean verifiedArtist, not the full tier count, so this is
// the honest ceiling for what can render here (see components/shared/
// artwork-card.tsx's identical comment).
const MINIMUM_VERIFICATION = {
  tier1SocialMedia: true,
  tier2ActivePlan: false,
  tier3FirstSale: false,
} as const;

export function ReservableInventoryGrid() {
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const { data: profile } = useAggregatorProfile();
  // undefined while loading — only `false` should disable anything, so a slow
  // profile fetch never blocks a signed aggregator mid-session.
  const mouSigned = profile ? Boolean(profile.mouAcceptance) : undefined;
  const { data, isPending, isError } = useReservableInventory();

  if (isPending) {
    return (
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <div
            key={i}
            className="flex flex-col gap-3 rounded-lg border border-border p-3.5"
          >
            <Skeleton className="aspect-[4/5] w-full rounded-md" />
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-3 w-1/2" />
            <Skeleton className="h-8 w-full" />
          </div>
        ))}
      </div>
    );
  }

  if (isError) {
    return (
      <EmptyState
        icon={PackageSearch}
        title="Couldn't load inventory"
        description="Something went wrong loading reservable artworks. Try refreshing the page."
      />
    );
  }

  if (!data || data.length === 0) {
    return (
      <EmptyState
        icon={PackageSearch}
        title="No reservable artworks right now"
        description="Every marketplace-and-aggregator artwork is already claimed. Check back soon as new work is listed."
      />
    );
  }

  return (
    <>
      {/* The service refuses a reservation without a signed MOU. Say so here
          rather than letting someone pick a piece and hit the wall in the
          confirm dialog. */}
      {mouSigned === false && (
        <div className="mb-5 flex flex-col gap-3 rounded-lg border border-gold/40 bg-gold/5 p-4 sm:flex-row sm:items-center">
          <div className="flex items-start gap-3 sm:flex-1 sm:items-center">
            <FileSignature
              className="mt-0.5 size-4 shrink-0 text-gold-bright sm:mt-0"
              strokeWidth={1.75}
            />
            <p className="text-sm text-muted-foreground">
              <span className="font-medium text-foreground">
                Sign your Aggregator MOU to reserve artwork.
              </span>{" "}
              It covers custody, pricing and settlement — GalleryZone can&rsquo;t
              place a piece with you until it&rsquo;s signed.
            </p>
          </div>
          <Link
            href="/aggregator/profile"
            className="inline-flex shrink-0 items-center justify-center gap-1.5 rounded-md border border-gold/60 px-4 py-2 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
          >
            Go to My Profile
          </Link>
        </div>
      )}

      {/* Artworks count and Sort control */}
      <div className="mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <p className="text-sm font-medium text-foreground">
          {data.length} artworks available
        </p>
        <div className="flex items-center justify-between sm:justify-end gap-3 w-full sm:w-auto">
          <Select defaultValue="newest">
            <SelectTrigger
              aria-label="Sort artworks"
              className="h-9 flex-1 gap-2 border-border bg-muted/20 px-3 text-[13px] font-medium shadow-none hover:bg-muted focus:ring-0 sm:w-auto sm:min-w-[170px] sm:flex-none"
            >
              <div className="flex items-center gap-1.5">
                <span className="font-normal text-muted-foreground">Sort:</span>
                <SelectValue />
              </div>
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="newest">Newest</SelectItem>
              <SelectItem value="price_asc">Price: Low to High</SelectItem>
              <SelectItem value="price_desc">Price: High to Low</SelectItem>
            </SelectContent>
          </Select>

          {/* View toggle */}
          <div className="flex items-center rounded-lg border border-border bg-card p-0.5 shrink-0">
            <button
              type="button"
              onClick={() => setViewMode("grid")}
              aria-label="Grid view"
              aria-pressed={viewMode === "grid"}
              className={cn(
                "flex size-8 items-center justify-center rounded-md transition-colors",
                viewMode === "grid"
                  ? "bg-muted text-foreground"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              <LayoutGrid className="size-4" strokeWidth={1.75} />
            </button>
            <button
              type="button"
              onClick={() => setViewMode("list")}
              aria-label="List view"
              aria-pressed={viewMode === "list"}
              className={cn(
                "flex size-8 items-center justify-center rounded-md transition-colors",
                viewMode === "list"
                  ? "bg-muted text-foreground"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              <List className="size-4" strokeWidth={1.75} />
            </button>
          </div>
        </div>
      </div>

      <div
        className={
          viewMode === "grid"
            ? "grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
            : "flex flex-col gap-4"
        }
      >
        {data.map((artwork) =>
          viewMode === "grid" ? (
            <InventoryArtworkCard
              key={artwork.id}
              artwork={artwork}
              disabled={mouSigned === false}
            />
          ) : (
            <InventoryArtworkListRow
              key={artwork.id}
              artwork={artwork}
              disabled={mouSigned === false}
            />
          )
        )}
      </div>
    </>
  );
}

function InventoryArtworkCard({
  artwork,
  disabled = false,
}: {
  artwork: ReservableArtwork;
  disabled?: boolean;
}) {
  const { offer } = artwork;
  return (
    <div className="group relative flex flex-col overflow-hidden rounded-xl border border-border bg-card transition-all duration-300 ease-out hover:-translate-y-1 hover:border-gold/50 hover:shadow-lg active:scale-[0.99]">
      <Link
        href={`/marketplace/${artwork.id}`}
        target="_blank"
        className="relative flex aspect-[4/5] w-full items-center justify-center bg-muted/30 p-4 sm:p-5 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      >
        <div className="relative h-full w-full overflow-hidden rounded-md border border-border/50 bg-muted shadow-sm transition-transform duration-500 ease-out group-hover:scale-[1.02]">
          <Image
            src={artwork.thumbnailUrl}
            alt={artwork.title}
            fill
            sizes="(min-width: 1280px) 22vw, (min-width: 1024px) 30vw, (min-width: 640px) 45vw, 100vw"
            className="object-cover"
          />
        </div>
        
        {/* Wishlist Heart Icon */}
        <button className="absolute top-2 right-2 z-10 flex size-10 items-center justify-center rounded-full border border-border/50 bg-background/90 text-foreground/75 backdrop-blur-sm transition-colors hover:text-foreground hover:border-border">
          <Heart className="size-4.5 transition-colors" strokeWidth={1.75} />
        </button>

        {artwork.insured && (
          <span className="absolute bottom-3 left-3 z-10 inline-flex items-center gap-1 rounded-full border border-gold/40 bg-background/90 px-2.5 py-1 text-[11px] font-medium text-gold-bright backdrop-blur-sm shadow-sm">
            <ShieldCheck className="size-3" strokeWidth={2} />
            Insured
          </span>
        )}
      </Link>

      <div className="flex flex-1 flex-col p-4">
        <Link
          href={`/marketplace/${artwork.id}`}
          target="_blank"
          className="-my-1 line-clamp-2 py-1 font-display text-base leading-snug font-semibold text-foreground hover:text-gold-bright transition-colors"
        >
          {artwork.title}
        </Link>
        <div className="mt-1.5 flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
          <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-gold/15 text-[10px] font-semibold text-gold-bright">
            {artwork.artistName.charAt(0).toUpperCase()}
          </span>
          <span className="truncate">{artwork.artistName}</span>
          {artwork.verifiedArtist && (
            <VerifiedBadge verification={MINIMUM_VERIFICATION} size="sm" />
          )}
        </div>
        <p className="mt-1 line-clamp-1 text-xs text-muted-foreground">
          {artwork.medium}
        </p>

        <PriceTag amount={offer.offerPrice} className="mt-4 text-lg font-bold text-foreground" />

        <div className="mt-3 rounded-lg bg-muted/40 p-3 border border-border/50">
          <CycleStepper
            currentMonth={offer.month}
            size="sm"
          />
          <p className="mt-2 text-[11px] font-medium text-muted-foreground text-center">
            Month {offer.month} of {AGGREGATOR_CYCLE_MONTHS} &middot; ₹{offer.monthlyReduction.toLocaleString("en-IN")} off since month 1
          </p>
        </div>

        <Button
          nativeButton={disabled}
          render={
            disabled ? undefined : (
              <Link href={`/aggregator/inventory/${artwork.id}/reserve`} />
            )
          }
          disabled={disabled}
          title={disabled ? "Sign your Aggregator MOU first" : undefined}
          className="mt-4 h-11 w-full rounded-xl bg-primary text-[13px] font-semibold text-primary-foreground hover:bg-gold-deep shadow-sm"
        >
          Reserve Artwork
        </Button>
      </div>
    </div>
  );
}

function InventoryArtworkListRow({
  artwork,
  disabled = false,
}: {
  artwork: ReservableArtwork;
  disabled?: boolean;
}) {
  const { offer } = artwork;
  return (
    <div className="group relative flex items-stretch gap-4 rounded-xl border border-border bg-card p-3 transition-colors duration-200 ease-out hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50">
      {/* Left: Image */}
      <Link
        href={`/marketplace/${artwork.id}`}
        target="_blank"
        className="relative w-28 shrink-0 overflow-hidden rounded-lg bg-muted sm:w-32 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      >
        <Image
          src={artwork.thumbnailUrl}
          alt={artwork.title}
          fill
          sizes="128px"
          className="object-cover"
        />
        {artwork.insured && (
          <span className="absolute bottom-1.5 left-1.5 z-10 inline-flex items-center gap-1 rounded-full border border-gold/40 bg-background/90 px-1.5 py-0.5 text-[9px] font-medium text-gold-bright backdrop-blur-sm shadow-sm">
            <ShieldCheck className="size-2.5" strokeWidth={2} />
            Insured
          </span>
        )}
      </Link>

      {/* Right: Content */}
      <div className="flex min-w-0 flex-1 flex-col py-0.5">
        <div className="flex items-start justify-between gap-3">
          <Link
            href={`/marketplace/${artwork.id}`}
            target="_blank"
            className="line-clamp-2 font-display text-sm font-semibold leading-snug text-foreground sm:text-base hover:text-gold-bright transition-colors"
          >
            {artwork.title}
          </Link>
          <button className="flex shrink-0 items-center justify-center rounded-full text-foreground/75 transition-colors hover:text-foreground">
            <Heart className="size-4.5 transition-colors" strokeWidth={1.75} />
          </button>
        </div>

        <div className="mt-1.5 flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
          <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-gold/15 text-[10px] font-semibold text-gold-bright">
            {artwork.artistName.charAt(0).toUpperCase()}
          </span>
          <span className="truncate">{artwork.artistName}</span>
          {artwork.verifiedArtist && (
            <VerifiedBadge verification={MINIMUM_VERIFICATION} size="sm" />
          )}
        </div>

        <p className="mt-1 line-clamp-1 text-xs text-muted-foreground/80">
          {artwork.medium}
        </p>

        <PriceTag amount={offer.offerPrice} className="mt-2 text-sm font-semibold" />

        <div className="mt-3 flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="flex-1 rounded-lg bg-muted/40 p-2.5 border border-border/50">
            <CycleStepper
              currentMonth={offer.month}
              size="sm"
            />
            <p className="mt-1.5 text-[10px] font-medium text-muted-foreground text-center">
              Month {offer.month} of {AGGREGATOR_CYCLE_MONTHS} &middot; ₹{offer.monthlyReduction.toLocaleString("en-IN")} off since mo 1
            </p>
          </div>
          <Button
            nativeButton={disabled}
            render={
              disabled ? undefined : (
                <Link href={`/aggregator/inventory/${artwork.id}/reserve`} />
              )
            }
            disabled={disabled}
            title={disabled ? "Sign your Aggregator MOU first" : undefined}
            className="h-10 w-full sm:w-auto sm:px-6 rounded-xl bg-primary text-[13px] font-semibold text-primary-foreground hover:bg-gold-deep shadow-sm shrink-0"
          >
            Reserve
          </Button>
        </div>
      </div>
    </div>
  );
}
