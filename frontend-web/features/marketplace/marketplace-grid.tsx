"use client";

import { useState, useMemo } from "react";
import "@/lib/motion-config";
import { motion } from "framer-motion";
import {
  LayoutGrid,
  List,
  SearchX,
  TriangleAlert,
  X,
  Filter,
  ArrowUpDown,
  Check,
} from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ArtworkCard, ArtworkListRow } from "@/components/shared/artwork-card";
import { ArtworkCardSkeleton } from "@/components/shared/artwork-card-skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ContinuousPagination } from "@/components/shared/continuous-pagination";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { useArtworks } from "@/hooks/useArtworks";
import type { ArtworkFilters } from "@/types/artwork";

function titleCase(value: string): string {
  return value.replace(/\b\w/g, (char) => char.toUpperCase());
}

const GRID_CLASS =
  "grid grid-cols-2 gap-3 sm:gap-5 lg:grid-cols-3 lg:gap-6";

const GRID_CLASS_COMPACT =
  "grid grid-cols-2 gap-3 sm:gap-5 lg:grid-cols-4 lg:gap-6";

const SORT_OPTIONS: {
  value: NonNullable<ArtworkFilters["sortBy"]>;
  label: string;
}[] = [
  { value: "newest", label: "Newest" },
  { value: "price_asc", label: "Price: Low to High" },
  { value: "price_desc", label: "Price: High to Low" },
];

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
  const artworks = page?.artworks;
  // Default to list on mobile, grid on larger screens (controlled purely via class, not state)
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [sortOpen, setSortOpen] = useState(false);

  const activeChips = useMemo(() => {
    const chips: { key: string; label: string; onRemove: () => void }[] = [];
    for (const value of filters.category ?? []) {
      chips.push({
        key: `category-${value}`,
        label: titleCase(value),
        onRemove: () => {
          const next = (filters.category ?? []).filter((c) => c !== value);
          onChange({ ...filters, category: next.length ? next : undefined });
        },
      });
    }
    for (const value of filters.medium ?? []) {
      chips.push({
        key: `medium-${value}`,
        label: titleCase(value),
        onRemove: () => {
          const next = (filters.medium ?? []).filter((m) => m !== value);
          onChange({ ...filters, medium: next.length ? next : undefined });
        },
      });
    }
    if (filters.size) {
      chips.push({ key: "size", label: titleCase(filters.size), onRemove: () => onChange({ ...filters, size: undefined }) });
    }
    if (filters.rarity) {
      chips.push({ key: "rarity", label: `Rank: ${filters.rarity}`, onRemove: () => onChange({ ...filters, rarity: undefined }) });
    }
    if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
      const min = filters.minPrice ?? 0;
      const max = filters.maxPrice;
      chips.push({ key: "price", label: max === undefined ? `From ₹${Math.floor(min / 1000)}k` : `₹${Math.floor(min / 1000)}k – ₹${Math.floor(max / 1000)}k`, onRemove: () => onChange({ ...filters, minPrice: undefined, maxPrice: undefined }) });
    }
    if (filters.query) {
      chips.push({ key: "query", label: `"${filters.query}"`, onRemove: () => onChange({ ...filters, query: undefined }) });
    }
    return chips;
  }, [filters, onChange]);


  if (isPending) {
    return (
      <div
        className={GRID_CLASS}
        aria-busy="true"
        aria-label="Loading artworks"
      >
        {Array.from({ length: 6 }).map((_, index) => (
          <ArtworkCardSkeleton key={index} />
        ))}
      </div>
    );
  }

  if (isError || !artworks || !page) {
    return (
      <EmptyState
        icon={TriangleAlert}
        title="Something went wrong"
        description="We couldn't load the marketplace right now. Please try again in a moment."
      />
    );
  }

  if (artworks.length === 0) {
    return (
      <EmptyState
        icon={SearchX}
        title="No artworks found"
        description="Try adjusting your filters or search with different keywords."
        action={
          <button
            type="button"
            onClick={onClearFilters}
            className="inline-flex items-center rounded-xl border border-gold/50 bg-gold/5 px-5 py-2.5 text-sm font-semibold text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
          >
            Clear all filters
          </button>
        }
      />
    );
  }

  return (
    <div>
      {/* Active filter chips */}
      {activeChips.length > 0 && (
        <div className="mb-3 flex flex-wrap items-center gap-2">
          {activeChips.map((chip) => (
            <button
              key={chip.key}
              onClick={chip.onRemove}
              className="inline-flex items-center gap-1.5 rounded-full border border-border bg-card/60 px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted"
            >
              {chip.label}
              <X className="size-3 text-muted-foreground" />
            </button>
          ))}
          <button
            onClick={onClearFilters}
            className="ml-1 text-xs font-medium text-gold-bright hover:underline"
          >
            Clear all
          </button>
        </div>
      )}

      {/* Toolbar */}
      <div className="mb-4 flex items-center justify-between gap-3">
        {/* Left: count + filter toggles */}
        <div className="flex items-center gap-2">
          {/* Desktop filter toggle */}
          {onToggleFilters && (
            <button
              onClick={onToggleFilters}
              className="hidden items-center gap-2 rounded-lg border border-border bg-card px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground lg:flex"
            >
              <Filter className="size-4" strokeWidth={1.75} />
              {showFilters ? "Hide Filters" : "Filters"}
            </button>
          )}
          {/* Mobile filter button */}
          {onOpenMobileFilters && (
            <button
              onClick={onOpenMobileFilters}
              className="flex items-center gap-2 rounded-lg border border-border bg-card px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground lg:hidden"
            >
              <Filter className="size-4" strokeWidth={1.75} />
              Filters
              {activeChips.length > 0 && (
                <span className="flex size-5 items-center justify-center rounded-full bg-gold-bright text-[10px] font-bold text-[#171310]">
                  {activeChips.length}
                </span>
              )}
            </button>
          )}
          <p className="hidden text-sm text-muted-foreground sm:block" role="status">
            <strong className="font-semibold text-foreground">{page.total}</strong>{" "}
            {page.total === 1 ? "artwork" : "artworks"} found
          </p>
        </div>

        {/* Right: sort + view toggle */}
        <div className="flex items-center gap-2">
          {/* Mobile sort button */}
          <button
            type="button"
            onClick={() => setSortOpen(true)}
            className="flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground lg:hidden"
          >
            <ArrowUpDown className="size-3.5" strokeWidth={1.75} />
            Sort
          </button>

          {/* Desktop sort select */}
          <div className="hidden lg:block">
            <Select
              value={filters.sortBy ?? "newest"}
              onValueChange={(value) =>
                onChange({
                  ...filters,
                  sortBy: (value as ArtworkFilters["sortBy"]) ?? "newest",
                })
              }
            >
              <SelectTrigger
                aria-label="Sort artworks"
                className="h-9 w-auto min-w-[160px] gap-2 border-border bg-card px-3 font-medium shadow-none hover:bg-muted focus:ring-0"
              >
                <div className="flex items-center gap-1.5">
                  <span className="font-normal text-muted-foreground">Sort:</span>
                  <SelectValue />
                </div>
              </SelectTrigger>
              <SelectContent>
                {SORT_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* View toggle */}
          <div className="flex items-center rounded-lg border border-border bg-card p-0.5">
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
      {/* Phones: the count gets its own line so the toolbar fits a 320px screen. */}
      <p className="-mt-1 mb-3 text-xs text-muted-foreground sm:hidden" role="status">
        <strong className="font-semibold text-foreground">{page.total}</strong>{" "}
        {page.total === 1 ? "artwork" : "artworks"} found
      </p>

      {/* Results */}
      <div
        className={
          viewMode === "grid"
            ? showFilters
              ? GRID_CLASS
              : GRID_CLASS_COMPACT
            : "flex flex-col gap-3"
        }
      >
        {artworks.map((artwork, index) => (
          <motion.div
            key={artwork.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{
              duration: 0.35,
              ease: "easeOut",
              delay: Math.min(index, 10) * 0.03,
            }}
          >
            {viewMode === "grid" ? (
              <ArtworkCard artwork={artwork} />
            ) : (
              <ArtworkListRow artwork={artwork} />
            )}
          </motion.div>
        ))}
      </div>

      <ContinuousPagination
        page={page.page}
        pageCount={Math.max(1, Math.ceil(page.total / page.pageSize))}
        onPage={(next) => {
          onChange({ ...filters, page: next > 1 ? next : undefined });
          if (typeof window !== "undefined") window.scrollTo({ top: 0, behavior: "smooth" });
        }}
      />

      {/* Mobile sort bottom sheet */}
      <MobileSortSheet
        open={sortOpen}
        onClose={() => setSortOpen(false)}
        value={filters.sortBy ?? "newest"}
        onChange={(v) => {
          onChange({ ...filters, sortBy: v });
          setSortOpen(false);
        }}
      />
    </div>
  );
}

function MobileSortSheet({
  open,
  onClose,
  value,
  onChange,
}: {
  open: boolean;
  onClose: () => void;
  value: string;
  onChange: (v: NonNullable<ArtworkFilters["sortBy"]>) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        showCloseButton={false}
        className="bottom-0 top-auto left-0 right-0 max-h-[50dvh] w-full max-w-none translate-x-0 translate-y-0 overflow-hidden rounded-t-2xl rounded-b-none p-0 data-open:slide-in-from-bottom data-closed:slide-out-to-bottom"
      >
        <DialogTitle className="sr-only">Sort artworks</DialogTitle>
        <div className="flex justify-center pt-3 pb-1">
          <div className="h-1 w-10 rounded-full bg-border" />
        </div>
        <div className="px-5 py-3 border-b border-border">
          <h2 className="font-display text-base font-semibold">Sort By</h2>
        </div>
        <nav className="flex flex-col gap-1 px-4 py-3">
          {SORT_OPTIONS.map((option) => (
            <button
              key={option.value}
              type="button"
              onClick={() => onChange(option.value)}
              className={cn(
                "flex items-center justify-between rounded-xl px-4 py-3.5 text-sm font-medium transition-colors",
                value === option.value
                  ? "bg-gold/10 text-gold-bright"
                  : "text-foreground hover:bg-muted",
              )}
            >
              {option.label}
              {value === option.value && (
                <Check className="size-4 text-gold-bright" strokeWidth={2} />
              )}
            </button>
          ))}
        </nav>
        <div className="px-5 pb-5">
          <button
            type="button"
            onClick={onClose}
            className="w-full rounded-xl bg-gold-bright py-3 text-sm font-semibold text-[#171310]"
          >
            Apply
          </button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
