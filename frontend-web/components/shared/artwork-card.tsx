"use client";

import "@/lib/motion-config";
import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import {
  BookmarkCheck,
  CircleCheckBig,
  Heart,
  Lock,
  ShieldCheck,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useWishlistStore } from "@/store/useWishlistStore";
import { PriceTag } from "@/components/shared/price-tag";
import { VerifiedBadge } from "@/components/shared/verified-badge";
import { RarityBadge } from "@/components/shared/rarity-badge";
import type { ArtworkStatus, ArtworkSummary } from "@/types/artwork";

function titleCase(value: string): string {
  return value.replace(/\b\w/g, (char) => char.toUpperCase());
}

interface ArtworkCardProps {
  artwork: ArtworkSummary;
  className?: string;
}

// Only "reserved" and "sold" ever occur as a live status on a marketplace
// fixture (see lib/mock-data/artworks.ts) — every other ArtworkStatus value
// exists only as a statusHistory entry, never as the artwork's *current*
// status. The fallback below keeps this honest and non-broken if that ever
// changes rather than assuming only two statuses are possible.
const STATUS_BADGE: Partial<
  Record<ArtworkStatus, { label: string; icon: LucideIcon }>
> = {
  reserved: { label: "Reserved", icon: BookmarkCheck },
  sold: { label: "Sold", icon: CircleCheckBig },
};

// ArtworkSummary only carries a boolean `verifiedArtist`, not the artist's
// full ArtistVerificationState (that lives on ArtistProfile, one level up,
// which the card grid doesn't fetch). A confirmed-true boolean means "at
// least tier 1" by construction (see mock-data/artworks.ts:
// verifiedArtist = verifiedTierCount(artist.verification) > 0), so this is
// a faithful lower bound, not invented data — it will never render the Gold
// treatment from a boolean alone, only ever the subtler tier-1 "Verified"
// mark. The real tier count (and possible Gold badge) renders correctly
// wherever the full ArtistProfile is available, e.g. the Artist Profile
// page.
const MINIMUM_VERIFICATION = {
  tier1SocialMedia: true,
  tier2ActivePlan: false,
  tier3FirstSale: false,
} as const;

export function ArtworkCard({ artwork, className }: ArtworkCardProps) {
  const isWishlisted = useWishlistStore((state) => state.has(artwork.id));
  const toggleWishlist = useWishlistStore((state) => state.toggle);

  const isAvailable = artwork.status === "marketplace";
  const statusBadge = isAvailable
    ? null
    : (STATUS_BADGE[artwork.status] ?? { label: "Unavailable", icon: Lock });
  const StatusIcon = statusBadge?.icon;

  return (
    <Link
      href={`/marketplace/${artwork.id}`}
      className={cn(
        "group relative flex flex-col overflow-hidden rounded-xl border border-border bg-card transition-all duration-300 ease-out hover:-translate-y-1 hover:border-gold/50 hover:shadow-lg active:scale-[0.99] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
        className,
      )}
    >
      <div className="relative flex aspect-[4/5] w-full items-center justify-center bg-muted/30 p-2.5 sm:p-5">
        <div className="relative h-full w-full overflow-hidden rounded-md border border-border/50 bg-muted shadow-sm transition-transform duration-500 ease-out group-hover:scale-[1.02]">
          <Image
            src={artwork.thumbnailUrl}
            alt={artwork.title}
            fill
            sizes="(min-width: 1024px) 25vw, (min-width: 640px) 33vw, 50vw"
            className={cn(
              "object-cover",
              !isAvailable && "opacity-75 grayscale-[55%]",
            )}
          />
        </div>

        <div className="absolute top-3 left-3 z-10 flex flex-col items-start gap-1.5">
          {statusBadge && StatusIcon && (
            <span className="inline-flex items-center gap-1.5 rounded-full border border-border bg-background/90 px-2.5 py-1 text-xs font-medium text-foreground backdrop-blur-sm">
              <StatusIcon className="size-3" strokeWidth={2} />
              {statusBadge.label}
            </span>
          )}
          <RarityBadge rarity={artwork.rarityType} variant="stamp" />
        </div>

        <motion.button
          type="button"
          whileTap={{ scale: 0.85 }}
          transition={{ type: "spring", stiffness: 400, damping: 15 }}
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            toggleWishlist(artwork.id);
          }}
          aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
          aria-pressed={isWishlisted}
          className="absolute top-2 right-2 z-10 flex size-10 items-center justify-center rounded-full border border-border/50 bg-background/90 text-foreground/75 backdrop-blur-sm transition-colors hover:text-foreground hover:border-border focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
        >
          <Heart
            className={cn(
              "size-4.5 transition-colors",
              isWishlisted && "fill-gold-bright text-gold-bright",
            )}
            strokeWidth={1.75}
          />
        </motion.button>

        {artwork.insured && (
          <span className="absolute bottom-3 left-3 inline-flex items-center gap-1 rounded-full border border-gold/40 bg-background/90 px-2.5 py-1 text-[11px] font-medium text-gold-bright backdrop-blur-sm shadow-sm">
            <ShieldCheck className="size-3" strokeWidth={2} />
            Insured
          </span>
        )}
      </div>

      <div className="flex flex-1 flex-col gap-2 p-3 sm:p-4">
        <h3 className="line-clamp-2 font-display text-sm leading-snug font-semibold text-foreground">
          {artwork.title}
        </h3>
        <div className="flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground">
          <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-gold/15 text-[10px] font-semibold text-gold-bright">
            {artwork.artistName.charAt(0).toUpperCase()}
          </span>
          <span className="truncate">{artwork.artistName}</span>
          {artwork.verifiedArtist && (
            <VerifiedBadge verification={MINIMUM_VERIFICATION} size="sm" />
          )}
        </div>
        <p className="truncate text-xs text-muted-foreground">
          {titleCase(artwork.category)} &middot; {artwork.medium}
        </p>

        <div className="mt-auto flex flex-wrap items-center justify-between gap-x-2 gap-y-1 border-t border-border/50 pt-3">
          <div className="flex flex-col gap-0.5">
            <PriceTag amount={artwork.customerPrice} className="text-base font-semibold" />
          </div>
          {isAvailable ? (
            <span className="flex shrink-0 items-center gap-1 text-[11px] font-medium text-emerald-600 dark:text-emerald-400">
              <span
                className="size-1.5 rounded-full bg-emerald-500"
                aria-hidden="true"
              />
              Available
            </span>
          ) : (
            <span className="flex shrink-0 items-center gap-1 text-[11px] font-medium text-muted-foreground">
              Unavailable
            </span>
          )}
        </div>
        <div className="absolute inset-0 z-0 flex items-center justify-center bg-foreground/5 opacity-0 transition-opacity duration-300 group-hover:opacity-100 pointer-events-none" />
      </div>
    </Link>
  );
}

// The list-view row: same fields as ArtworkCard, laid out horizontally
// instead of as a tile — for the grid/list toggle on the marketplace page.
export function ArtworkListRow({ artwork, className }: ArtworkCardProps) {
  const isWishlisted = useWishlistStore((state) => state.has(artwork.id));
  const toggleWishlist = useWishlistStore((state) => state.toggle);

  const isAvailable = artwork.status === "marketplace";
  const statusBadge = isAvailable
    ? null
    : (STATUS_BADGE[artwork.status] ?? { label: "Unavailable", icon: Lock });
  const StatusIcon = statusBadge?.icon;

  return (
    <Link
      href={`/marketplace/${artwork.id}`}
      className={cn(
        "group relative flex items-stretch gap-4 rounded-xl border border-border bg-card p-3 transition-colors duration-200 ease-out hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
        className,
      )}
    >
      {/* Left: Image */}
      <div className="relative w-28 shrink-0 overflow-hidden rounded-lg bg-muted sm:w-32">
        <Image
          src={artwork.thumbnailUrl}
          alt={artwork.title}
          fill
          sizes="128px"
          className={cn(
            "object-cover",
            !isAvailable && "opacity-75 grayscale-[55%]",
          )}
        />
        <RarityBadge
          rarity={artwork.rarityType}
          variant="stamp"
          className="absolute top-1.5 left-1.5"
        />
      </div>

      {/* Right: Content */}
      <div className="flex min-w-0 flex-1 flex-col py-0.5">
        <div className="flex items-start justify-between gap-3">
          <h3 className="line-clamp-2 font-display text-sm font-semibold leading-snug text-foreground sm:text-base">
            {artwork.title}
          </h3>
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              toggleWishlist(artwork.id);
            }}
            aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
            aria-pressed={isWishlisted}
            className="flex shrink-0 items-center justify-center rounded-full text-foreground/75 transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <Heart
              className={cn(
                "size-4.5 transition-colors",
                isWishlisted && "fill-gold-bright text-gold-bright",
              )}
              strokeWidth={1.75}
            />
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

        <p className="mt-1 line-clamp-2 text-xs leading-relaxed text-muted-foreground/80">
          {titleCase(artwork.category)} &middot; {artwork.medium}
        </p>

        <div className="mt-3 flex items-center gap-2">
          <PriceTag amount={artwork.customerPrice} className="text-sm font-semibold" />
          <span className="text-[10px] text-muted-foreground">Incl. GST</span>
        </div>

        <div className="mt-2 flex items-center gap-2">
          {isAvailable ? (
            <span className="inline-flex items-center rounded-full bg-emerald-500/10 px-2 py-0.5 text-[10px] font-medium text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              Available
            </span>
          ) : (
            statusBadge && StatusIcon && (
              <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-[10px] font-medium text-muted-foreground">
                <StatusIcon className="size-3" strokeWidth={1.75} />
                {statusBadge.label}
              </span>
            )
          )}
        </div>
      </div>
    </Link>
  );
}
