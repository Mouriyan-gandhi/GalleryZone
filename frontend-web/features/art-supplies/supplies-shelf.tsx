"use client";

import { useMemo, useState } from "react";
import Image from "next/image";
import { PackageSearch, RotateCcw, Search, X } from "lucide-react";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAffiliateProducts } from "@/hooks/useAffiliateProducts";
import { cn } from "@/lib/utils";
import { amazonImageAt, type AffiliateProduct } from "@/types/affiliate";
import { SupplyCard } from "./supply-card";
import { SupplyQuickView } from "./supply-quick-view";

const GRID = "grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5";

function matches(product: AffiliateProduct, query: string): boolean {
  const haystack = `${product.title} ${product.brand ?? ""} ${product.category}`.toLowerCase();
  return query.toLowerCase().split(/\s+/).filter(Boolean).every((word) => haystack.includes(word));
}

export function SuppliesShelf() {
  const { data: products, isPending, isError, refetch } = useAffiliateProducts();
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [quickView, setQuickView] = useState<AffiliateProduct | null>(null);

  // Largest category first, so the pills lead with what the shelf holds most of.
  const categories = useMemo(() => {
    const counts = new Map<string, number>();
    for (const p of products ?? []) counts.set(p.category, (counts.get(p.category) ?? 0) + 1);
    return [...counts].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  }, [products]);

  const visible = (products ?? []).filter(
    (p) => (!category || p.category === category) && (!query.trim() || matches(p, query)),
  );

  return (
    <>
      <section className="relative overflow-hidden border-b border-border/60">
        <ShelfCollage products={products ?? []} />
        <div className="relative mx-auto flex max-w-[1440px] flex-col px-5 py-10 sm:px-6 lg:min-h-[420px] lg:justify-center lg:px-10 lg:py-14">
          <div className="flex max-w-[36rem] flex-col">
            <p className="text-[11px] font-medium tracking-[0.16em] text-gold-bright uppercase sm:tracking-[0.22em]">
              The artist&apos;s supply shelf
            </p>
            <h1 className="mt-4 font-display text-4xl leading-[1.08] font-semibold tracking-tight text-balance text-foreground sm:text-5xl">
              Art supplies we recommend
            </h1>
            <p className="mt-4 max-w-md text-base leading-relaxed text-pretty text-muted-foreground">
              Brushes, paints, canvases and tools, picked by GalleryZone for working artists.
              Each one opens on Amazon, where you buy it.
            </p>

            <label className="relative mt-7 block w-full">
              <span className="sr-only">Search art supplies</span>
              <Search className="pointer-events-none absolute top-1/2 left-4 size-4 -translate-y-1/2 text-muted-foreground" strokeWidth={1.75} />
              <input
                type="search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search brushes, acrylics, canvas…"
                className="h-12 w-full rounded-full border border-border bg-background pr-11 pl-11 text-base text-foreground shadow-sm transition-[border-color,box-shadow] outline-none placeholder:text-muted-foreground focus-visible:border-gold/60 focus-visible:ring-3 focus-visible:ring-ring/30 sm:text-sm [&::-webkit-search-cancel-button]:hidden"
              />
              {query && (
                <button
                  type="button"
                  onClick={() => setQuery("")}
                  aria-label="Clear search"
                  className="absolute top-1/2 right-3 flex size-7 -translate-y-1/2 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                >
                  <X className="size-4" />
                </button>
              )}
            </label>

            <p className="mt-4 text-xs text-muted-foreground">
              As an Amazon Associate, GalleryZone earns from qualifying purchases. It costs you nothing extra.
            </p>
          </div>
        </div>
      </section>

      <div className="mx-auto w-full max-w-[1440px] px-5 py-8 sm:px-6 lg:px-10 lg:py-10">
        {categories.length > 1 && (
          <div className="-mx-5 flex gap-2 overflow-x-auto px-5 pb-1 [scrollbar-width:none] sm:mx-0 sm:flex-wrap sm:overflow-visible sm:px-0">
            <Pill active={category === null} onClick={() => setCategory(null)} count={products?.length ?? 0}>
              All
            </Pill>
            {categories.map(([name, count]) => (
              <Pill key={name} active={category === name} onClick={() => setCategory(category === name ? null : name)} count={count}>
                {name}
              </Pill>
            ))}
          </div>
        )}

        {isPending ? (
          <div className={cn(GRID, "mt-6")} aria-busy="true" aria-label="Loading art supplies">
            {Array.from({ length: 10 }, (_, i) => (
              <div key={i} className="rounded-lg border border-border p-2">
                <Skeleton className="aspect-square w-full rounded-md" />
                <Skeleton className="mt-3 h-3 w-1/3" />
                <Skeleton className="mt-2 h-4 w-full" />
                <Skeleton className="mt-1.5 h-4 w-2/3" />
                <Skeleton className="mt-4 h-9 w-full" />
              </div>
            ))}
          </div>
        ) : isError ? (
          <EmptyState
            className="mt-6"
            icon={PackageSearch}
            title="The shelf didn't load"
            description="We couldn't reach GalleryZone just now. Try again in a moment."
            action={
              <Button variant="outline" onClick={() => refetch()}>
                <RotateCcw className="size-4" />
                Try again
              </Button>
            }
          />
        ) : visible.length === 0 ? (
          <EmptyState
            className="mt-6"
            icon={PackageSearch}
            title={products?.length ? "Nothing matches that" : "The shelf is being stocked"}
            description={
              products?.length
                ? "Try a shorter search, or look through every category."
                : "Our recommended supplies will appear here soon."
            }
            action={
              products?.length ? (
                <Button
                  variant="outline"
                  onClick={() => {
                    setQuery("");
                    setCategory(null);
                  }}
                >
                  Show everything
                </Button>
              ) : undefined
            }
          />
        ) : (
          <>
            <p className="mt-6 text-sm text-muted-foreground" aria-live="polite">
              {visible.length === products?.length
                ? `${visible.length} products`
                : `${visible.length} of ${products?.length} products`}
            </p>
            <div className={cn(GRID, "mt-3")}>
              {visible.map((product) => (
                <SupplyCard key={product.id} product={product} onQuickView={() => setQuickView(product)} />
              ))}
            </div>
          </>
        )}
      </div>

      <SupplyQuickView product={quickView} onClose={() => setQuickView(null)} />
    </>
  );
}

function Pill({
  active,
  onClick,
  count,
  children,
}: {
  active: boolean;
  onClick: () => void;
  count: number;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={cn(
        "flex h-10 shrink-0 items-center gap-1.5 rounded-full border px-4 text-sm font-medium transition-[background-color,border-color,color,transform] duration-150 ease-out focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97] sm:h-9",
        active
          ? "border-transparent bg-gold text-[#171310] dark:bg-gold-bright"
          : "border-border text-foreground/80 hover:border-gold/50 hover:text-foreground",
      )}
    >
      {children}
      <span className={cn("text-xs tabular-nums", active ? "text-[#171310]/70" : "text-muted-foreground")}>{count}</span>
    </button>
  );
}

// Six product photos on white tiles, stepped like a shop window. Desktop only:
// on a phone the products themselves are one scroll away.
function ShelfCollage({ products }: { products: AffiliateProduct[] }) {
  const covers = products.flatMap((p) => p.images.slice(0, 1)).slice(0, 6);
  if (covers.length < 6) return null;
  return (
    <div aria-hidden className="absolute inset-y-0 right-0 hidden w-[46%] items-center justify-center lg:flex">
      <div className="grid grid-cols-3 gap-4 xl:gap-5">
        {covers.map((src, i) => (
          <div
            key={src}
            className={cn(
              "relative size-[132px] overflow-hidden rounded-xl bg-white shadow-[0_24px_40px_-22px_rgb(0_0_0/0.55)] ring-1 ring-foreground/10 xl:size-[156px]",
              i % 3 === 1 && "translate-y-8",
            )}
          >
            <Image src={amazonImageAt(src, 400)} alt="" fill unoptimized sizes="160px" className="object-contain p-3" />
          </div>
        ))}
      </div>
    </div>
  );
}
