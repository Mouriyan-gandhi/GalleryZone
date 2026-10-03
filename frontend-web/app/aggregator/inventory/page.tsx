import type { Metadata } from "next";
import { Search, SlidersHorizontal } from "lucide-react";
import { ReservableInventoryGrid } from "@/features/aggregator/reservable-inventory-grid";

export const metadata: Metadata = {
  title: "Browse GalleryZone | Aggregator Portal",
};

const CATEGORIES = [
  "All",
  "Painting",
  "Sculpture",
  "Textile Art",
  "Printmaking",
];

export default function AggregatorInventoryPage() {
  return (
    <div className="flex flex-col gap-5">
      <div>
        <h2 className="font-display text-2xl font-bold text-foreground sm:text-3xl">
          Browse GalleryZone
        </h2>
        <p className="mt-1.5 text-[13px] text-muted-foreground sm:text-sm">
          Browse artworks available for aggregator display.<br className="hidden sm:block" />
          Reserving pays the advance and moves a piece into your Collection.
        </p>
      </div>

      {/* Mobile-first Search & Filter Bar */}
      <div className="flex flex-col gap-4">
        <div className="flex items-center gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search artworks, artists, or styles..."
              className="w-full rounded-lg border border-border bg-muted/30 py-2.5 pl-9 pr-4 text-base outline-none placeholder:text-muted-foreground focus:border-gold/50 focus:ring-1 focus:ring-gold/50 transition-all sm:text-sm"
            />
          </div>
          <button className="flex shrink-0 items-center justify-center gap-2 rounded-lg border border-border bg-muted/30 px-4 py-2.5 text-sm font-medium transition-colors hover:bg-muted">
            <SlidersHorizontal className="size-4" />
            <span>Filters</span>
          </button>
        </div>

        {/* Category Chips - Horizontally scrollable, with a fade so the row
            reads as scrollable instead of just cut off mid-word on mobile. */}
        <div className="relative -mx-4 sm:mx-0">
          <div className="flex items-center gap-2 overflow-x-auto hide-scrollbar px-4 pb-2 sm:px-0 sm:pb-0">
            {CATEGORIES.map((cat, i) => (
              <button
                key={cat}
                className={`shrink-0 rounded-md border px-3 py-1.5 text-[13px] font-medium transition-colors ${
                  i === 0
                    ? "border-gold bg-gold/90 text-gold-950"
                    : "border-border bg-muted/20 text-foreground hover:bg-muted/50"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-y-0 right-0 w-8 bg-gradient-to-l from-background to-transparent sm:hidden"
          />
        </div>
      </div>

      <ReservableInventoryGrid />
    </div>
  );
}
