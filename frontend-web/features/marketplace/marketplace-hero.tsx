"use client";

import Image from "next/image";
import { ArcReel, type ArcReelItem } from "@/components/ui/arc-reel";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { cn, humanize } from "@/lib/utils";
import { MarketplaceSearchBar } from "@/features/marketplace/marketplace-search-bar";
import type { ArtworkSummary } from "@/types/artwork";

const REEL_CARDS = 8;

// Brand paintings that pad the reel when the catalogue has too few
// photographed listings, so it always holds REEL_CARDS distinct works.
const FALLBACK_REEL: ArcReelItem[] = [
  "hero-original-art",
  "landscape",
  "portrait-woman",
  "bird",
  "draped-figure",
  "collage-busts",
  "eye-pyramid",
  "framed-painting",
].map((name) => ({ src: `/artworks/${name}.png` }));

function reelItems(artworks: ArtworkSummary[]): ArcReelItem[] {
  const seen = new Set<string>();
  const items: ArcReelItem[] = [];
  for (const a of artworks) {
    if (isPlaceholderImage(a.thumbnailUrl) || seen.has(a.thumbnailUrl)) continue;
    seen.add(a.thumbnailUrl);
    items.push({ src: a.thumbnailUrl, alt: `${a.title} by ${a.artistName}` });
  }
  for (const f of FALLBACK_REEL) {
    if (items.length >= REEL_CARDS) break;
    if (!seen.has(f.src)) items.push(f);
  }
  return items.slice(0, REEL_CARDS);
}

export function MarketplaceHero({
  query,
  onQueryChange,
  categories,
  selected,
  onSelectCategory,
  artworks,
}: {
  query: string;
  onQueryChange: (query: string) => void;
  /** Categories live in the marketplace right now (facets). */
  categories: string[];
  selected?: string[];
  /** null = "All". */
  onSelectCategory: (category: string | null) => void;
  /** Listings whose photos ride the reel. */
  artworks: ArtworkSummary[];
}) {
  return (
    <section className="relative overflow-hidden border-b border-border/60">
      <ArtworkReel artworks={artworks} />

      <div className="relative mx-auto flex max-w-[1440px] flex-col px-5 py-10 sm:px-6 lg:min-h-[660px] lg:justify-center lg:px-10 lg:py-16">
        <div className="flex max-w-[38rem] flex-col">
          <p className="text-[11px] font-medium tracking-[0.16em] text-gold-bright uppercase sm:tracking-[0.22em]">
            Original art. Real people. Meaningful stories.
          </p>
          <h1 className="mt-4 font-display text-4xl leading-[1.08] font-semibold tracking-tight text-balance text-foreground sm:text-5xl xl:text-[3.25rem]">
            Discover original art from independent artists
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-pretty text-muted-foreground">
            Explore unique paintings, sculptures and more from
            talented artists across India and beyond.
          </p>

          <MarketplaceSearchBar value={query} onChange={onQueryChange} className="mt-7 w-full" />

          {categories.length > 0 && (
            <div className="-mx-5 mt-5 flex gap-2 overflow-x-auto px-5 pb-1 [scrollbar-width:none] sm:mx-0 sm:flex-wrap sm:overflow-visible sm:px-0">
              <CategoryPill active={!selected?.length} onClick={() => onSelectCategory(null)}>
                All
              </CategoryPill>
              {categories.map((category) => (
                <CategoryPill
                  key={category}
                  active={selected?.includes(category) ?? false}
                  onClick={() => onSelectCategory(category)}
                >
                  {humanize(category)}
                </CategoryPill>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}

function CategoryPill({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={cn(
        "h-10 shrink-0 rounded-full border px-4 text-sm font-medium transition-[background-color,border-color,color,transform] duration-150 ease-out focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97] sm:h-9",
        active
          ? "border-transparent bg-gold text-[#171310] dark:bg-gold-bright"
          : "border-border text-foreground/80 hover:border-gold/50 hover:text-foreground",
      )}
    >
      {children}
    </button>
  );
}

// The column zig-zags: the front card sits left, its neighbours above and below
// step right and fade out before the edges. The GalleryZone mark fills the gap
// beside the front card and stays still while the cards turn.
const REEL_ANCHOR = 0.42;
const REEL_BOW = 80;

function ArtworkReel({ artworks }: { artworks: ArtworkSummary[] }) {
  return (
    <div className="absolute inset-y-0 right-0 hidden w-[52%] lg:block">
      <ArcReel
        items={reelItems(artworks)}
        gap={28}
        bow={REEL_BOW}
        anchorRatio={REEL_ANCHOR}
        aria-label="Original artworks on GalleryZone"
      />
      {/* 124px clears the neighbours' right edge (bow + half their width) even mid-turn. */}
      <div
        aria-hidden
        style={{ left: `calc(${REEL_ANCHOR * 100}% + 124px)` }}
        className="pointer-events-none absolute top-1/2 hidden size-[168px] -translate-y-1/2 items-center justify-center overflow-hidden rounded-xl bg-white shadow-[0_24px_40px_-18px_rgb(0_0_0/0.7)] ring-1 ring-foreground/10 xl:flex"
      >
        <Image
          src="/brand/gz-logo.png"
          alt=""
          width={822}
          height={560}
          sizes="240px"
          className="h-full w-full scale-[1.35] object-contain"
        />
      </div>
    </div>
  );
}
