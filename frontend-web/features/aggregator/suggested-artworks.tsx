"use client";

import Image from "next/image";
import Link from "next/link";
import { PriceTag } from "@/components/shared/price-tag";
import { useReservableInventory } from "@/hooks/useAggregatorInventory";
import { cn } from "@/lib/utils";
import { similarTo } from "@/lib/similar-artworks";
import type { ArtworkSummary } from "@/types/artwork";

// "Suggestions: same type of paintings show to him" (client, 30 Sep 2026):
// pieces still open for reservation that are like `references` in category,
// price and size. Shown on the reserve screen (like the piece being reserved),
// on a holding (like the piece held) and at the top of the inventory list (like
// everything this aggregator holds).
export function SuggestedArtworks({
  references,
  title,
  limit = 4,
  className,
}: {
  references: readonly ArtworkSummary[];
  title: string;
  limit?: number;
  className?: string;
}) {
  const { data } = useReservableInventory();
  const suggestions = similarTo(references, data ?? [], limit);

  if (suggestions.length === 0) return null;

  return (
    <section className={cn("flex flex-col gap-3", className)}>
      <h2 className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
        {title}
      </h2>
      <div className="grid grid-cols-[repeat(auto-fill,minmax(8.5rem,1fr))] gap-3">
        {suggestions.map((artwork) => (
          <Link
            key={artwork.id}
            href={`/aggregator/inventory/${artwork.id}/reserve`}
            className="flex flex-col gap-1.5 rounded-lg border border-border bg-card p-2 transition-colors hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          >
            <div className="relative aspect-[4/5] w-full overflow-hidden rounded-md bg-muted">
              <Image
                src={artwork.thumbnailUrl}
                alt={artwork.title}
                fill
                sizes="(min-width: 640px) 20vw, 45vw"
                className="object-cover"
              />
            </div>
            <p className="truncate text-xs font-medium text-foreground">
              {artwork.title}
            </p>
            <PriceTag
              amount={artwork.offer.offerPrice}
              className="text-xs font-medium text-muted-foreground"
            />
          </Link>
        ))}
      </div>
    </section>
  );
}
