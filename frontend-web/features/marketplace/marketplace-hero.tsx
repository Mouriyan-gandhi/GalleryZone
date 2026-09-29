"use client";

import Image from "next/image";
import { cn, humanize } from "@/lib/utils";
import { MarketplaceSearchBar } from "@/features/marketplace/marketplace-search-bar";

export function MarketplaceHero({
  query,
  onQueryChange,
  categories,
  selected,
  onSelectCategory,
}: {
  query: string;
  onQueryChange: (query: string) => void;
  /** Categories live in the marketplace right now (facets). */
  categories: string[];
  selected?: string[];
  /** null = "All". */
  onSelectCategory: (category: string | null) => void;
}) {
  return (
    <section className="relative overflow-hidden border-b border-border/60">
      <GalleryScene />

      <div className="relative mx-auto flex max-w-[1440px] flex-col px-5 py-10 sm:px-6 lg:min-h-[520px] lg:justify-center lg:px-10 lg:py-16">
        <div className="flex max-w-[38rem] flex-col">
          <p className="text-[11px] font-medium tracking-[0.16em] text-gold-bright uppercase sm:tracking-[0.22em]">
            Original art. Real people. Meaningful stories.
          </p>
          <h1 className="mt-4 font-display text-4xl leading-[1.08] font-semibold tracking-tight text-balance text-foreground sm:text-5xl xl:text-[3.25rem]">
            Discover original art from independent artists
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-pretty text-muted-foreground">
            Explore unique paintings, sculptures, photography and more from
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

// A painting under a gallery picture light, fading into the page on its left
// so the copy stays readable. Decorative brand imagery, not a listing.
function GalleryScene() {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute inset-y-0 right-0 hidden w-[48%] lg:block xl:w-[52%]"
    >
      <div className="absolute inset-0 animate-in bg-[radial-gradient(50%_62%_at_55%_14%,color-mix(in_oklab,var(--gold-bright)_17%,transparent),transparent_75%)] duration-1000 fade-in fill-mode-both motion-reduce:animate-none" />
      <div className="absolute top-[8%] left-[55%] h-1.5 w-28 -translate-x-1/2 rounded-full bg-gradient-to-b from-gold-bright to-gold-deep shadow-[0_6px_20px_color-mix(in_oklab,var(--gold-bright)_50%,transparent)]" />
      <div className="absolute top-[13%] left-[55%] aspect-[4/5] h-[72%] -translate-x-1/2 border-[10px] border-[#1b140c] shadow-[0_40px_60px_-20px_rgb(0_0_0/0.75)] after:absolute after:inset-0 after:ring-1 after:ring-[#e9c57a]/30 after:ring-inset after:content-['']">
        <Image
          src="/artworks/hero-original-art.png"
          alt=""
          fill
          priority
          sizes="(min-width: 1280px) 26vw, 32vw"
          className="object-cover"
        />
      </div>
      <div className="absolute top-1/2 right-10 hidden -translate-y-1/2 text-right xl:block">
        <p className="font-display text-sm leading-[2.2] tracking-[0.35em] text-foreground/70 uppercase italic">
          Art
          <br />
          lives
          <br />
          brighter
          <br />
          together
        </p>
        <span className="mt-4 ml-auto block h-px w-10 bg-gold/70" />
      </div>
      <div className="absolute inset-y-0 left-0 w-2/5 bg-gradient-to-r from-background to-transparent" />
    </div>
  );
}
