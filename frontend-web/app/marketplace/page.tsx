"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { RotateCcw, X } from "lucide-react";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import {
  MarketplaceFilters,
  DEFAULT_MARKETPLACE_FILTERS,
} from "@/features/marketplace/marketplace-filters";
import { MarketplaceGrid } from "@/features/marketplace/marketplace-grid";
import { MarketplaceHero } from "@/features/marketplace/marketplace-hero";
import { PassportBand } from "@/features/marketplace/passport-band";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { cn } from "@/lib/utils";
import type { ArtworkFilters } from "@/types/artwork";
import { useMarketplaceOverview } from "@/hooks/useArtworks";

export default function MarketplacePage() {
  return (
    <Suspense fallback={<MarketplaceFallback />}>
      <MarketplacePageContent />
    </Suspense>
  );
}

function MarketplaceFallback() {
  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col" />
      <SiteFooter />
    </>
  );
}

function MarketplacePageContent() {
  const searchParams = useSearchParams();
  const [filters, setFilters] = useState<ArtworkFilters>(() => ({
    ...DEFAULT_MARKETPLACE_FILTERS,
    category: searchParams.get("category") ? [searchParams.get("category")!] : undefined,
    query: searchParams.get("q") ?? undefined,
  }));
  const [showFilters, setShowFilters] = useState(true);
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);

  // The unfiltered first page, newest first: its facets feed the hero's
  // category pills, and it picks the real certificate the passport band shows
  // (a piece with a photo, when there is one).
  const overview = useMarketplaceOverview().data;
  const artworks = overview?.artworks ?? [];
  const passportPiece =
    artworks.find((a) => a.coaCertificateNumber && !isPlaceholderImage(a.thumbnailUrl)) ??
    artworks.find((a) => a.coaCertificateNumber);

  // Pills act like tabs: one category at a time, or All. The sidebar still
  // allows several at once.
  function selectCategory(value: string | null) {
    setFilters((f) => {
      const alreadyOnly = f.category?.length === 1 && f.category[0] === value;
      return { ...f, category: value && !alreadyOnly ? [value] : undefined, page: undefined };
    });
  }

  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <MarketplaceHero
          query={filters.query ?? ""}
          onQueryChange={(query) =>
            setFilters((f) => ({ ...f, query: query || undefined, page: undefined }))
          }
          categories={overview?.facets.categories ?? []}
          selected={filters.category}
          onSelectCategory={selectCategory}
          artworks={artworks}
        />

        <div className="mx-auto w-full max-w-[1440px] px-5 sm:px-6 lg:px-10">
          <section
            id="catalog"
            aria-label="All works"
            className="scroll-mt-24 py-10 lg:py-12"
          >
            {/* The sidebar column animates its width to 0 rather than
                unmounting; overflow-clip (not hidden) keeps its sticky
                panel working. */}
            <div
              className={cn(
                "grid w-full gap-y-8 transition-[grid-template-columns,column-gap] duration-300 ease-[cubic-bezier(0.23,1,0.32,1)] motion-reduce:transition-none",
                showFilters
                  ? "lg:grid-cols-[250px_minmax(0,1fr)] lg:gap-x-8"
                  : "lg:grid-cols-[0px_minmax(0,1fr)] lg:gap-x-0",
              )}
            >
              <div
                inert={!showFilters}
                className={cn(
                  "hidden overflow-clip transition-opacity duration-200 lg:block",
                  showFilters ? "lg:border-r lg:border-border/60 lg:pr-6" : "opacity-0",
                )}
              >
                <MarketplaceFilters
                  filters={filters}
                  onChange={setFilters}
                  onCollapse={() => setShowFilters(false)}
                  className="w-[226px]"
                />
              </div>
              <div className="min-w-0">
                <MarketplaceGrid
                  filters={filters}
                  onChange={setFilters}
                  onClearFilters={() => setFilters(DEFAULT_MARKETPLACE_FILTERS)}
                  showFilters={showFilters}
                  onToggleFilters={() => setShowFilters((s) => !s)}
                  onOpenMobileFilters={() => setMobileFiltersOpen(true)}
                />
              </div>
            </div>
          </section>
        </div>

        <PassportBand artwork={passportPiece} />

        <MarketplaceMobileFilterSheet
          open={mobileFiltersOpen}
          onClose={() => setMobileFiltersOpen(false)}
          filters={filters}
          onChange={setFilters}
        />
      </main>
      <SiteFooter />
    </>
  );
}

function MarketplaceMobileFilterSheet({
  open,
  onClose,
  filters,
  onChange,
}: {
  open: boolean;
  onClose: () => void;
  filters: ArtworkFilters;
  onChange: (f: ArtworkFilters) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        showCloseButton={false}
        className="top-auto right-0 bottom-0 left-0 max-h-[92dvh] w-full max-w-none translate-x-0 translate-y-0 overflow-hidden rounded-t-2xl rounded-b-none p-0 data-open:slide-in-from-bottom data-closed:slide-out-to-bottom"
      >
        <DialogTitle className="sr-only">Filter artworks</DialogTitle>
        <div className="flex justify-center pt-3 pb-1">
          <div className="h-1 w-10 rounded-full bg-border" />
        </div>
        <div className="flex items-center justify-between border-b border-border px-5 py-3">
          <h2 className="font-display text-base font-semibold text-foreground">Filters</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close filters"
            className="rounded-md p-1.5 text-muted-foreground hover:text-foreground"
          >
            <X className="size-5" />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-4">
          <MarketplaceFilters filters={filters} onChange={onChange} bare />
        </div>
        <div className="flex items-center gap-3 border-t border-border bg-background px-5 py-4">
          <button
            type="button"
            onClick={() => onChange({ ...DEFAULT_MARKETPLACE_FILTERS, query: filters.query })}
            className="flex flex-1 items-center justify-center gap-2 rounded-full border border-border py-3 text-sm font-medium text-foreground transition-colors hover:bg-muted"
          >
            <RotateCcw className="size-4" strokeWidth={1.75} />
            Reset
          </button>
          <button
            type="button"
            onClick={onClose}
            className="flex-[2] rounded-full bg-foreground py-3 text-sm font-semibold text-background transition-transform active:scale-[0.97] dark:bg-gold-bright dark:text-[#171310]"
          >
            Show results
          </button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
