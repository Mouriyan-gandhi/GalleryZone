"use client";

import { useMemo } from "react";
import { PanelLeftClose } from "lucide-react";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Checkbox } from "@/components/ui/checkbox";
import { cn, formatINR, humanize } from "@/lib/utils";
import { useMarketplaceFacets, useMarketplaceOverview } from "@/hooks/useArtworks";
import {
  ARTWORK_RARITY_OPTIONS,
  type ArtworkFilters,
  type ArtworkRarity,
  type ArtworkSizeBand,
  type ArtworkSummary,
} from "@/types/artwork";

export const DEFAULT_MARKETPLACE_FILTERS: ArtworkFilters = { sortBy: "newest" };

type PriceRange = { min?: number; max?: number };

// Rupee bands for the Price group. A band maps straight onto the API's
// minPrice/maxPrice, so picking one replaces any other price filter.
const PRICE_BANDS: PriceRange[] = [
  { max: 10_000 },
  { min: 10_000, max: 25_000 },
  { min: 25_000, max: 50_000 },
  { min: 50_000, max: 100_000 },
  { min: 100_000 },
];

export function priceLabel({ min, max }: PriceRange): string {
  if (min === undefined && max !== undefined) return `Under ${formatINR(max)}`;
  if (max === undefined && min !== undefined) return `Above ${formatINR(min)}`;
  return `${formatINR(min ?? 0)} – ${formatINR(max ?? 0)}`;
}

const SIZE_OPTIONS: { value: ArtworkSizeBand; label: string }[] = [
  { value: "small", label: "Small" },
  { value: "medium", label: "Medium" },
  { value: "large", label: "Large" },
];

// Same solid per-rank colors as the card's corner stamp (rarity-badge.tsx):
// one rank language across the marketplace.
const RANK_TONE: Record<ArtworkRarity, string> = {
  R: "bg-destructive text-white",
  U: "bg-emerald-600 text-white",
  O: "bg-gold-deep text-white",
  N: "bg-muted-foreground text-background",
};

// Governs whether "Clear all" shows. `query` belongs to the search bar and
// `sortBy` to the results toolbar, so neither counts.
function hasActiveStructuredFilters(filters: ArtworkFilters): boolean {
  return Boolean(
    filters.category?.length ||
      filters.medium?.length ||
      filters.rarity ||
      filters.artistId ||
      filters.location ||
      filters.size ||
      typeof filters.minPrice === "number" ||
      typeof filters.maxPrice === "number",
  );
}

function countBy(artworks: ArtworkSummary[], key: (artwork: ArtworkSummary) => string | null | undefined) {
  const counts: Record<string, number> = {};
  for (const artwork of artworks) {
    const value = key(artwork);
    if (value) counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

function inBand(price: number, { min, max }: PriceRange): boolean {
  return (min === undefined || price >= min) && (max === undefined || price < max);
}

// ponytail: counts are tallied from the overview page (the API's max of 60),
// so they only show while the whole catalogue fits on it. Add per-option
// counts to the API's facets (like rarityCounts) once it outgrows that.
function useOptionCounts() {
  const overview = useMarketplaceOverview().data;
  return useMemo(() => {
    if (!overview || overview.total > overview.artworks.length) return null;
    const artworks = overview.artworks;
    return {
      category: countBy(artworks, (a) => a.category),
      medium: countBy(artworks, (a) => a.medium),
      size: countBy(artworks, (a) => a.sizeBand),
      artist: countBy(artworks, (a) => a.artistId),
      location: countBy(artworks, (a) => a.artistLocation),
      price: PRICE_BANDS.map((band) => artworks.filter((a) => inBand(a.customerPrice, band)).length),
    };
  }, [overview]);
}

function toggleIn(list: string[] | undefined, value: string): string[] | undefined {
  const current = list ?? [];
  const next = current.includes(value) ? current.filter((v) => v !== value) : [...current, value];
  return next.length ? next : undefined;
}

interface MarketplaceFiltersProps {
  filters: ArtworkFilters;
  onChange: (filters: ArtworkFilters) => void;
  className?: string;
  /** The mobile sheet already has its own title and Reset/Show footer. */
  bare?: boolean;
  /** Shows a collapse button in the header (desktop sidebar). */
  onCollapse?: () => void;
}

export function MarketplaceFilters({
  filters,
  onChange,
  className,
  bare = false,
  onCollapse,
}: MarketplaceFiltersProps) {
  // Every option comes from the live marketplace's facets, so none is a dead end.
  const facets = useMarketplaceFacets();
  const counts = useOptionCounts();

  function update(patch: Partial<ArtworkFilters>) {
    onChange({ ...filters, ...patch, page: undefined });
  }

  const priceOptions = PRICE_BANDS.map((band, i) => ({ band, count: counts?.price[i] })).filter(
    ({ count }) => count !== 0,
  );
  const sizeOptions = SIZE_OPTIONS.filter((option) => !counts || counts.size[option.value]);
  const rankOptions = ARTWORK_RARITY_OPTIONS.filter((option) => facets.rarityCounts[option.value]);

  return (
    <aside
      className={cn(
        "flex h-fit w-full flex-col",
        className,
      )}
    >
      {!bare && (
        <div className="flex items-center justify-between border-b border-border pb-4">
          <h2 className="font-display text-xl font-semibold text-foreground">Filters</h2>
          <div className="flex items-center gap-2">
            {hasActiveStructuredFilters(filters) && (
              <button
                type="button"
                onClick={() => onChange({ ...DEFAULT_MARKETPLACE_FILTERS, query: filters.query })}
                className="text-xs font-medium text-gold-bright hover:underline"
              >
                Clear all
              </button>
            )}
            {onCollapse && (
              <button
                type="button"
                onClick={onCollapse}
                aria-label="Collapse filters"
                title="Collapse filters"
                className="flex size-8 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
              >
                <PanelLeftClose className="size-4" strokeWidth={1.75} />
              </button>
            )}
          </div>
        </div>
      )}

      <Accordion multiple defaultValue={["category", "medium", "price"]}>
        {facets.categories.length > 0 && (
          <FilterGroup value="category" label="Category">
            {facets.categories.map((category) => (
              <OptionRow
                key={category}
                label={humanize(category)}
                count={counts?.category[category]}
                checked={filters.category?.includes(category) ?? false}
                onToggle={() => update({ category: toggleIn(filters.category, category) })}
              />
            ))}
          </FilterGroup>
        )}

        {facets.mediums.length > 0 && (
          <FilterGroup value="medium" label="Medium">
            {facets.mediums.map((medium) => (
              <OptionRow
                key={medium}
                label={humanize(medium)}
                count={counts?.medium[medium]}
                checked={filters.medium?.includes(medium) ?? false}
                onToggle={() => update({ medium: toggleIn(filters.medium, medium) })}
              />
            ))}
          </FilterGroup>
        )}

        {priceOptions.length > 0 && (
          <FilterGroup value="price" label="Price">
            {priceOptions.map(({ band, count }) => {
              const checked = filters.minPrice === band.min && filters.maxPrice === band.max;
              return (
                <OptionRow
                  key={priceLabel(band)}
                  label={priceLabel(band)}
                  count={count}
                  checked={checked}
                  onToggle={() =>
                    update(
                      checked
                        ? { minPrice: undefined, maxPrice: undefined }
                        : { minPrice: band.min, maxPrice: band.max },
                    )
                  }
                />
              );
            })}
          </FilterGroup>
        )}

        {sizeOptions.length > 0 && (
          <FilterGroup value="size" label="Size">
            {sizeOptions.map((option) => {
              const checked = filters.size === option.value;
              return (
                <OptionRow
                  key={option.value}
                  label={option.label}
                  count={counts?.size[option.value]}
                  checked={checked}
                  onToggle={() => update({ size: checked ? undefined : option.value })}
                />
              );
            })}
          </FilterGroup>
        )}

        {facets.artists.length > 0 && (
          <FilterGroup value="artist" label="Artist">
            {facets.artists.map((artist) => {
              const checked = filters.artistId === artist.id;
              return (
                <OptionRow
                  key={artist.id}
                  label={artist.name}
                  count={counts?.artist[artist.id]}
                  checked={checked}
                  onToggle={() => update({ artistId: checked ? undefined : artist.id })}
                />
              );
            })}
          </FilterGroup>
        )}

        {facets.locations.length > 0 && (
          <FilterGroup value="location" label="Location">
            {facets.locations.map((location) => {
              const checked = filters.location === location;
              return (
                <OptionRow
                  key={location}
                  label={location}
                  count={counts?.location[location]}
                  checked={checked}
                  onToggle={() => update({ location: checked ? undefined : location })}
                />
              );
            })}
          </FilterGroup>
        )}

        {rankOptions.length > 0 && (
          <FilterGroup value="rank" label="Rank">
            {rankOptions.map((option) => {
              const checked = filters.rarity === option.value;
              return (
                <OptionRow
                  key={option.value}
                  label={option.label}
                  count={facets.rarityCounts[option.value]}
                  checked={checked}
                  onToggle={() => update({ rarity: checked ? undefined : option.value })}
                  leading={
                    <span
                      className={cn(
                        "flex size-5 shrink-0 items-center justify-center rounded-full text-[10px] font-bold",
                        RANK_TONE[option.value],
                      )}
                    >
                      {option.value}
                    </span>
                  }
                />
              );
            })}
          </FilterGroup>
        )}
      </Accordion>
    </aside>
  );
}

function FilterGroup({
  value,
  label,
  children,
}: {
  value: string;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <AccordionItem value={value}>
      <AccordionTrigger className="py-3.5 font-semibold hover:no-underline">{label}</AccordionTrigger>
      <AccordionContent>
        <div className="flex flex-col pb-1">{children}</div>
      </AccordionContent>
    </AccordionItem>
  );
}

function OptionRow({
  label,
  count,
  checked,
  onToggle,
  leading,
}: {
  label: string;
  count?: number;
  checked: boolean;
  onToggle: () => void;
  leading?: React.ReactNode;
}) {
  return (
    <label className="flex cursor-pointer items-center gap-3 py-2 text-sm text-foreground/85 transition-colors hover:text-foreground lg:py-1.5">
      <Checkbox checked={checked} onCheckedChange={onToggle} />
      {leading}
      <span className="min-w-0 flex-1 truncate" title={label}>
        {label}
      </span>
      {count !== undefined && (
        <span className="text-xs text-muted-foreground tabular-nums">({count})</span>
      )}
    </label>
  );
}
