"use client";

import { useEffect, useState } from "react";
import { Heart } from "lucide-react";
import Link from "next/link";
import { useWishlistStore } from "@/store/useWishlistStore";
import { useQueries } from "@tanstack/react-query";
import { artworkService } from "@/services/artworkService";
import { toSummary } from "@/lib/artwork-summary";
import { ArtworkCard } from "@/components/shared/artwork-card";
import { EmptyState } from "@/components/shared/empty-state";
import { ArtworkCardSkeleton } from "@/components/shared/artwork-card-skeleton";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { useMounted } from "@/hooks/useMounted";

export default function WishlistPage() {
  const mounted = useMounted();
  const ids = useWishlistStore((state) => state.ids);

  // Saved ids live in the browser; each piece is read from the API so a
  // sold or delisted artwork simply drops out of the list.
  const results = useQueries({
    queries: ids.map((id) => ({ queryKey: ["artwork", id], queryFn: () => artworkService.get(id), staleTime: 60_000 })),
  });
  const loading = mounted && results.some((r) => r.isPending);
  const artworks = results
    .map((r) => r.data)
    .filter((artwork) => artwork !== undefined && artwork !== null)
    .map(toSummary);

  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col py-6 px-5 sm:py-8 sm:px-8 lg:py-10 lg:px-10 max-w-[1500px] mx-auto w-full gap-6 sm:gap-8">
        <div>
          <h1 className="font-display text-3xl font-semibold text-foreground">
            Your Wishlist
          </h1>
          <p className="mt-2 text-base text-muted-foreground">
            Artworks you&rsquo;ve saved for later, all in one place.
          </p>
        </div>

        {!mounted || loading ? (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <ArtworkCardSkeleton key={i} />
            ))}
          </div>
        ) : artworks.length === 0 ? (
          <EmptyState
            icon={Heart}
            title="Nothing saved yet"
            description="Browse the marketplace and tap the heart on anything you like to save it here."
            action={
              <Link
                href="/marketplace"
                className="inline-flex items-center gap-2 rounded-md border border-gold/60 px-4 py-2 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10"
              >
                Browse the marketplace
              </Link>
            }
          />
        ) : (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
            {artworks.map((artwork) => (
              <ArtworkCard key={artwork.id} artwork={artwork} />
            ))}
          </div>
        )}
      </main>
      <SiteFooter />
    </>
  );
}
