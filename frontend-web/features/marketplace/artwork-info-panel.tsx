"use client";

import { useState } from "react";
import Link from "next/link";
import {
  BadgeCheck,
  Heart,
  Info,
  ScrollText,
  ShieldCheck,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useWishlistStore } from "@/store/useWishlistStore";
import { PriceTag } from "@/components/shared/price-tag";
import { VerifiedBadge } from "@/components/shared/verified-badge";
import {
  InstagramGlyph,
  TiktokGlyph,
  XGlyph,
  YoutubeGlyph,
} from "@/components/social-icons";
import type { ArtistVerificationState } from "@/types/artist";
import type { Artwork, SocialProofLink } from "@/types/artwork";

const SOCIAL_ICON: Record<SocialProofLink["platform"], typeof InstagramGlyph> =
  {
    instagram: InstagramGlyph,
    youtube: YoutubeGlyph,
    x: XGlyph,
    tiktok: TiktokGlyph,
  };

const SOCIAL_LABEL: Record<SocialProofLink["platform"], string> = {
  instagram: "Instagram",
  youtube: "YouTube",
  x: "X",
  tiktok: "TikTok",
};

interface ArtworkInfoPanelProps {
  artwork: Artwork;
  verification: ArtistVerificationState;
}

// The single client "island" holding every interactive affordance on the
// Artwork Detail page (wishlist toggle, insurance explainer disclosure) —
// per SAD §5.6, static content (title, metadata, description) renders
// through this same component for simplicity (the page is small enough that
// splitting it further would be more files than the situation warrants),
// but nothing here depends on client-only state except the two toggles.
export function ArtworkInfoPanel({
  artwork,
  verification,
}: ArtworkInfoPanelProps) {
  const [insuranceOpen, setInsuranceOpen] = useState(false);
  const isWishlisted = useWishlistStore((state) => state.has(artwork.id));
  const toggleWishlist = useWishlistStore((state) => state.toggle);

  const isAvailable = artwork.status === "marketplace";
  const buyLabel =
    artwork.status === "reserved"
      ? "Reserved"
      : artwork.status === "sold"
        ? "Sold"
        : "No longer available";

  return (
    <div className="flex flex-col gap-7">
      <div>
        <p className="text-xs font-medium tracking-[0.14em] text-gold-bright uppercase">
          {artwork.category}
        </p>
        <h1 className="mt-2 text-balance font-display text-3xl leading-[1.15] font-semibold sm:text-4xl">
          {artwork.title}
        </h1>

        <div className="mt-3 flex items-center gap-2 text-sm">
          <Link
            href={`/artists/${artwork.artistId}`}
            className="font-medium text-foreground/90 transition-colors hover:text-gold-bright"
          >
            {artwork.artistName}
          </Link>
          <VerifiedBadge verification={verification} size="sm" />
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div>
          <PriceTag amount={artwork.customerPrice} className="text-3xl" />
          <p className="mt-1 text-xs text-muted-foreground">incl. GST</p>
        </div>

        {artwork.insured && (
          <div className="relative">
            <button
              type="button"
              onClick={() => setInsuranceOpen((open) => !open)}
              aria-expanded={insuranceOpen}
              className="inline-flex items-center gap-1.5 rounded-full border border-gold/40 bg-card px-3 py-1.5 text-xs font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
            >
              <ShieldCheck className="size-3.5" strokeWidth={2} />
              Insured
              <Info className="size-3" strokeWidth={2} />
            </button>

            {insuranceOpen && (
              <div className="absolute top-full left-0 z-20 mt-2 w-64 rounded-md border border-border bg-popover p-3 text-xs leading-relaxed text-popover-foreground shadow-lg">
                Transit insurance is recommended for artworks valued above
                ₹20,000, in partnership with HDFC ERGO. This piece qualifies and
                ships fully covered.
              </div>
            )}
          </div>
        )}
      </div>

      {/* Buying sits with the price: at the end of the panel it was a screen and a half below the fold on phones. */}
      <div className="flex flex-col gap-3 sm:flex-row">
        {isAvailable ? (
          <Link
            href={`/checkout?artworkId=${artwork.id}`}
            className="inline-flex flex-1 items-center justify-center rounded-md bg-gold-bright px-6 py-3 text-sm font-semibold text-background transition-colors hover:bg-gold"
          >
            Buy Now
          </Link>
        ) : (
          <button
            type="button"
            disabled
            className="inline-flex flex-1 cursor-not-allowed items-center justify-center rounded-md border border-border bg-muted px-6 py-3 text-sm font-semibold text-muted-foreground"
          >
            {buyLabel}
          </button>
        )}

        <button
          type="button"
          onClick={() => toggleWishlist(artwork.id)}
          aria-pressed={isWishlisted}
          className={cn(
            "inline-flex items-center justify-center gap-2 rounded-md border px-5 py-3 text-sm font-medium transition-colors",
            isWishlisted
              ? "border-gold/50 bg-gold/10 text-gold-bright"
              : "border-border text-foreground/85 hover:border-gold/40 hover:text-gold-bright",
          )}
        >
          <Heart
            className={cn("size-4", isWishlisted && "fill-gold-bright")}
            strokeWidth={1.75}
          />
          {isWishlisted ? "Wishlisted" : "Wishlist"}
        </button>
      </div>

      {artwork.verifiedArtist && (
        <p className="-mt-4 flex items-center gap-1.5 text-xs text-muted-foreground">
          <BadgeCheck className="size-3.5 text-gold-bright" strokeWidth={2} />
          Sold by a verified GalleryZone artist.
        </p>
      )}

      <dl className="grid grid-cols-2 gap-x-6 gap-y-3 border-y border-border py-5 text-sm sm:grid-cols-4">
        <div>
          <dt className="text-xs text-muted-foreground">Category</dt>
          <dd className="mt-0.5 font-medium text-foreground capitalize">
            {artwork.category}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Medium</dt>
          <dd className="mt-0.5 font-medium text-foreground">
            {artwork.medium}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Dimensions</dt>
          <dd className="mt-0.5 font-medium text-foreground">
            {artwork.dimensions ?? "Not specified"}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Year</dt>
          <dd className="mt-0.5 font-medium text-foreground">
            {artwork.yearCreated ?? "Not specified"}
          </dd>
        </div>
      </dl>

      <p className="text-balance text-sm leading-relaxed text-muted-foreground">
        {artwork.description}
      </p>

      <Link
        href={`/verify/${artwork.id}`}
        className="inline-flex w-fit items-center gap-1.5 text-xs font-medium text-gold-bright hover:underline"
      >
        <ScrollText className="size-3.5" strokeWidth={1.75} />
        View this artwork&rsquo;s digital passport
      </Link>

      {artwork.socialProofLinks.length > 0 && (
        <div>
          <p className="text-xs text-muted-foreground">
            Process &amp; provenance
          </p>
          <div className="mt-2 flex items-center gap-2">
            {artwork.socialProofLinks.map((link) => {
              const Icon = SOCIAL_ICON[link.platform];
              return (
                <a
                  key={link.url}
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={`View on ${SOCIAL_LABEL[link.platform]}`}
                  className="flex size-9 items-center justify-center rounded-md border border-border text-foreground/80 transition-colors hover:border-gold/50 hover:text-gold-bright"
                >
                  <Icon className="size-4" />
                </a>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
