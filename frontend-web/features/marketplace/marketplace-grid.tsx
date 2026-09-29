"use client";

import { useMemo } from "react";
import { SearchX, SlidersHorizontal, TriangleAlert, X } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ArtworkCard } from "@/components/shared/artwork-card";
import { ArtworkCardSkeleton } from "@/components/shared/artwork-card-skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ContinuousPagination } from "@/components/shared/continuous-pagination";
import { priceLabel } from "@/features/marketplace/marketplace-filters";
import { cn, humanize } from "@/lib/utils";
import { useArtworks, useMarketplaceFacets } from "@/hooks/useArtworks";
import { ARTWORK_RARITY_LABEL, type ArtworkFilters } from "@/types/artwork";

// 20 per page divides evenly into both: 4 across beside the filters, 5 with
// them collapsed.
const GRID_WITH_FILTERS = "grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 xl:grid-cols-4";
const GRID_FULL = "grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5";

const SORT_OPTIONS: { value: NonNullable<ArtworkFilters["sortBy"]>; label: string }[] = [
  { value: "newest", label: "Newest" },
  { value: "price_asc", label: "Price: Low to High" },
  { value: "price_desc", label: "Price: High to Low" },
];

const CONTROL =
  "inline-flex h-10 items-center gap-2 rounded-lg border border-border bg-card px-3.5 text-sm font-medium text-foreground/85 transition-colors hover:border-gold/50 hover:text-foreground";

interface MarketplaceGridProps {
  filters: ArtworkFilters;
  onChange: (filters: ArtworkFilters) => void;
  onClearFilters: () => void;
  showFilters?: boolean;
  onToggleFilters?: () => void;
  onOpenMobileFilters?: () => void;
}

export function MarketplaceGrid({
  filters,
  onChange,
  onClearFilters,
  showFilters,
  onToggleFilters,
  onOpenMobileFilters,
}: MarketplaceGridProps) {
  const { data: page, isPending, isError } = useArtworks(filters);
  const facets = useMarketplaceFacets();
  const artworks = page?.artworks;
  const gridClass = showFilters ? GRID_WITH_FILTERS : GRID_FULL;

  const activeChips = useMemo(() => {
    const chips: { key: string; label: string; clear: Partial<ArtworkFilters> }[] = [];
    for (const value of filters.category ?? []) {
      const next = filters.category!.filter((c) => c !== value);
      chips.push({ key: `category-${value}`, label: humanize(value), clear: { category: next.length ? next : undefined } });
    }
    for (const value of filters.medium ?? []) {
      const next = filters.medium!.filter((m) => m !== value);
      chips.push({ key: `medium-${value}`, label: humanize(value), clear: { medium: next.length ? next : undefined } });
    }
    if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
      chips.push({
        key: "price",
        label: priceLabel({ min: filters.minPrice, max: filters.maxPrice }),
        clear: { minPrice: undefined, maxPrice: undefined },
      });
    }
    if (filters.size) {
      chips.push({ key: "size", label: humanize(filters.size), clear: { size: undefined } });
    }
    if (filters.artistId) {
      const name = facets.artists.find((a) => a.id === filters.artistId)?.name ?? "Artist";
      chips.push({ key: "artist", label: name, clear: { artistId: undefined } });
    }
    if (filters.location) {
      chips.push({ key: "location", label: filters.location, clear: { location: undefined } });
    }
    if (filters.rarity) {
      chips.push({ key: "rarity", label: ARTWORK_RARITY_LABEL[filters.rarity], clear: { rarity: undefined } });
    }
    if (filters.query) {
      chips.push({ key: "query", label: `“${filters.query}”`, clear: { query: undefined } });
    }
    return chips;
  }, [filters, facets.artists]);

  if (isPending) {
    return (
      <div className={gridClass} aria-busy="true" aria-label="Loading artworks">
        {Array.from({ length: 8 }).map((_, index) => (
          <ArtworkCardSkeleton key={index} />
        ))}
      </div>
    );
  }

  if (isError || !artworks || !page) {
    return (
      <EmptyState
        icon={TriangleAlert}
        title="The marketplace didn't load"
        description="Check your connection and refresh the page to try again."
      />
    );
  }

  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <div className="flex min-w-0 flex-wrap items-center gap-2">
          <h2
            className="mr-1 font-display text-lg font-semibold whitespace-nowrap text-foreground"
            role="status"
          >
            {page.total} {page.total === 1 ? "artwork" : "artworks"}
          </h2>
          {activeChips.map((chip) => (
            <button
              key={chip.key}
              type="button"
              onClick={() => onChange({ ...filters, ...chip.clear, page: undefined })}
              aria-label={`Remove filter ${chip.label}`}
              className="inline-flex h-7 items-center gap-1.5 rounded-full border border-border bg-card px-2.5 text-xs font-medium text-foreground transition-colors hover:border-gold/50"
            >
              {chip.label}
              <X className="size-3 text-muted-foreground" />
            </button>
          ))}
          {activeChips.length > 0 && (
            <button
              type="button"
              onClick={onClearFilters}
              className="ml-1 text-xs font-medium text-gold-bright hover:underline"
            >
              Clear all
            </button>
          )}
        </div>

        <div className="flex items-center gap-2">
          {onToggleFilters && (
            <button
              type="button"
              onClick={onToggleFilters}
              aria-pressed={showFilters}
              className={cn(CONTROL, "hidden lg:inline-flex")}
            >
              <SlidersHorizontal className="size-4" strokeWidth={1.75} />
              Filters
            </button>
          )}
          {onOpenMobileFilters && (
            <button type="button" onClick={onOpenMobileFilters} className={cn(CONTROL, "lg:hidden")}>
              <SlidersHorizontal className="size-4" strokeWidth={1.75} />
              Filters
              {activeChips.length > 0 && (
                <span className="flex size-5 items-center justify-center rounded-full bg-gold text-[10px] font-bold text-[#171310] dark:bg-gold-bright">
                  {activeChips.length}
                </span>
              )}
            </button>
          )}
          <Select
            value={filters.sortBy ?? "newest"}
            onValueChange={(value) =>
              onChange({
                ...filters,
                sortBy: (value as ArtworkFilters["sortBy"]) ?? "newest",
                page: undefined,
              })
            }
          >
            <SelectTrigger
              aria-label="Sort artworks"
              className="h-10 w-auto min-w-[180px] gap-2 rounded-lg border-border bg-card px-3.5 text-sm font-medium shadow-none hover:border-gold/50"
            >
              <span className="font-normal text-muted-foreground">Sort:</span>
              <SelectValue>
                {(value: string) => SORT_OPTIONS.find((o) => o.value === value)?.label ?? "Newest"}
              </SelectValue>
            </SelectTrigger>
            <SelectContent alignItemWithTrigger={false} align="end" sideOffset={6}>
              {SORT_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {artworks.length === 0 ? (
        <EmptyState
          icon={SearchX}
          title="No artworks match these filters"
          description="Remove a filter or search with different words to see more work."
          action={
            <button
              type="button"
              onClick={onClearFilters}
              className="inline-flex items-center rounded-full border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:bg-gold/10"
            >
              Clear all filters
            </button>
          }
        />
      ) : (
        <div className={gridClass}>
          {artworks.map((artwork) => (
            <ArtworkCard key={artwork.id} artwork={artwork} />
          ))}
        </div>
      )}

      <ContinuousPagination
        page={page.page}
        pageCount={Math.max(1, Math.ceil(page.total / page.pageSize))}
        onPage={(next) => {
          onChange({ ...filters, page: next > 1 ? next : undefined });
          document.getElementById("catalog")?.scrollIntoView({ behavior: "smooth" });
        }}
      />
    </div>
  );
}
