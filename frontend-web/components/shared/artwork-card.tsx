"use client";

import Image from "next/image";
import Link from "next/link";
import { Heart, ShoppingBag } from "lucide-react";
import { cn, humanize } from "@/lib/utils";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { useWishlistStore } from "@/store/useWishlistStore";
import { PriceTag } from "@/components/shared/price-tag";
import { VerifiedBadge } from "@/components/shared/verified-badge";
import { RarityBadge } from "@/components/shared/rarity-badge";
import { ArtworkImagePlaceholder } from "@/components/shared/artwork-image-placeholder";
import type { ArtworkStatus, ArtworkSummary } from "@/types/artwork";

interface ArtworkCardProps {
  artwork: ArtworkSummary;
  className?: string;
}

// Only "reserved" and "sold" occur as the live status of a listed piece; any
// other off-market status falls back to "Unavailable" rather than breaking.
const STATUS_LABEL: Partial<Record<ArtworkStatus, string>> = {
  reserved: "Reserved",
  sold: "Sold",
};

// ArtworkSummary only carries a boolean `verifiedArtist`, not the artist's
// full ArtistVerificationState (that lives on ArtistProfile, which the card
// grid doesn't fetch). A confirmed-true boolean means "at least tier 1" by
// construction, so this is a faithful lower bound: it only ever renders the
// subtler tier-1 "Verified" mark, never the Gold treatment.
const MINIMUM_VERIFICATION = {
  tier1SocialMedia: true,
  tier2ActivePlan: false,
  tier3FirstSale: false,
} as const;

const PILL = "inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-medium leading-tight";

// Icon-sized controls keep a 44px hit area via an invisible ::before.
const HIT_AREA = "before:absolute before:-inset-1.5 before:content-['']";

function WishlistButton({ artworkId, className }: { artworkId: string; className?: string }) {
  const isWishlisted = useWishlistStore((state) => state.has(artworkId));
  const toggleWishlist = useWishlistStore((state) => state.toggle);

  return (
    <button
      type="button"
      onClick={() => toggleWishlist(artworkId)}
      aria-label={isWishlisted ? "Remove from wishlist" : "Add to wishlist"}
      aria-pressed={isWishlisted}
      className={cn(
        "flex size-8 items-center justify-center rounded-full bg-background/75 text-foreground/80 backdrop-blur-sm transition-[color,transform] duration-150 ease-out hover:text-foreground focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-90",
        HIT_AREA,
        className,
      )}
    >
      <Heart
        className={cn("size-4", isWishlisted && "fill-gold-bright text-gold-bright")}
        strokeWidth={1.75}
      />
    </button>
  );
}

export function ArtworkCard({ artwork, className }: ArtworkCardProps) {
  const isAvailable = artwork.status === "marketplace";
  const status = isAvailable ? null : (STATUS_LABEL[artwork.status] ?? "Unavailable");
  const details = [humanize(artwork.medium), artwork.yearCreated].filter(Boolean).join(", ");
  const size = artwork.dimensions?.replace(/\s+x\s+/gi, " × ");

  return (
    <article
      className={cn(
        "group relative flex flex-col rounded-lg border border-border bg-card p-2 transition-colors duration-200 hover:border-gold/40",
        className,
      )}
    >
      <Link
        href={`/marketplace/${artwork.id}`}
        className="flex flex-1 flex-col rounded-md focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      >
        <div className="relative aspect-[4/5] overflow-hidden rounded-md bg-muted">
          {isPlaceholderImage(artwork.thumbnailUrl) ? (
            <ArtworkImagePlaceholder />
          ) : (
            <Image
              src={artwork.thumbnailUrl}
              alt={artwork.title}
              fill
              sizes="(min-width: 1280px) 20vw, (min-width: 768px) 30vw, 48vw"
              className={cn(
                "object-cover transition-transform duration-500 ease-[cubic-bezier(0.23,1,0.32,1)] group-hover:scale-[1.03]",
                !isAvailable && "opacity-75 grayscale-[45%]",
              )}
            />
          )}
        </div>

        <div className="flex flex-1 flex-col px-1.5 pt-3">
          <h3 className="truncate font-display text-[0.95rem] font-semibold text-foreground">
            {artwork.title}
          </h3>
          <p className="mt-0.5 flex min-w-0 items-center gap-1 text-sm text-foreground/80">
            <span className="truncate">{artwork.artistName}</span>
            {artwork.verifiedArtist && (
              <VerifiedBadge verification={MINIMUM_VERIFICATION} size="sm" />
            )}
          </p>
          <p className="mt-1.5 truncate text-xs text-muted-foreground">{details}</p>
          {size && <p className="truncate text-xs text-muted-foreground">{size}</p>}
          <p className="mt-2 flex items-baseline gap-2">
            <PriceTag amount={artwork.customerPrice} className="text-base" />
            {status && <span className="text-xs text-muted-foreground">{status}</span>}
          </p>
          <div className="mt-auto flex flex-wrap gap-1.5 pt-3 pr-10 pb-1">
            {artwork.coaCertificateNumber && (
              <span className={cn(PILL, "border-gold/50 text-gold-bright")}>COA</span>
            )}
            <span className={cn(PILL, "border-border text-foreground/75")}>Digital Passport</span>
            {artwork.insured && (
              <span className={cn(PILL, "border-gold/50 text-gold-bright")}>Insured</span>
            )}
          </div>
        </div>
      </Link>

      <RarityBadge
        rarity={artwork.rarityType}
        variant="stamp"
        className="pointer-events-none absolute top-4 left-4"
      />
      <WishlistButton artworkId={artwork.id} className="absolute top-3.5 right-3.5" />
      {isAvailable && (
        <Link
          href={`/checkout?artworkId=${artwork.id}`}
          aria-label={`Buy ${artwork.title}`}
          className={cn(
            "absolute right-3.5 bottom-3.5 flex size-8 items-center justify-center rounded-md border border-gold/50 text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-95",
            HIT_AREA,
          )}
        >
          <ShoppingBag className="size-4" strokeWidth={1.75} />
        </Link>
      )}
    </article>
  );
}
