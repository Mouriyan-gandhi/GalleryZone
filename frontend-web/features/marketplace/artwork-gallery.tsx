"use client";

import { useState } from "react";
import Image from "next/image";
import { Expand } from "lucide-react";
import { cn } from "@/lib/utils";
import { isPlaceholderImage } from "@/lib/api-mappers";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { ArtworkImagePlaceholder } from "@/components/shared/artwork-image-placeholder";
import type { ArtworkImage } from "@/types/artwork";

interface ArtworkGalleryProps {
  images: ArtworkImage[];
  title: string;
}

// Hero + thumbnail-strip gallery with click-to-expand zoom (Dialog), per
// Task 15 Step 1 — a full-bleed lightbox rather than hover-zoom, since the
// certificate-grade images here reward a proper look rather than a cursor
// trick that only works on desktop.
export function ArtworkGallery({ images, title }: ArtworkGalleryProps) {
  const sorted = [...images].sort((a, b) => a.sortOrder - b.sortOrder);
  const [activeIndex, setActiveIndex] = useState(0);
  const [zoomOpen, setZoomOpen] = useState(false);
  const active = sorted[activeIndex] ?? sorted[0];

  if (!active) return null;

  const isPlaceholder = isPlaceholderImage(active.url);

  return (
    <div className="flex flex-col gap-3">
      <Dialog open={zoomOpen} onOpenChange={isPlaceholder ? undefined : setZoomOpen}>
        <button
          type="button"
          disabled={isPlaceholder}
          onClick={() => setZoomOpen(true)}
          className="group relative aspect-[4/5] w-full overflow-hidden rounded-lg border border-border bg-muted focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-default"
        >
          {isPlaceholder ? (
            <ArtworkImagePlaceholder />
          ) : (
            <>
              <Image
                src={active.url}
                alt={active.altText}
                fill
                priority
                sizes="(min-width: 1024px) 50vw, 100vw"
                className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.03]"
              />
              <span className="absolute right-3 bottom-3 flex items-center gap-1.5 rounded-full border border-border bg-background/90 px-3 py-1.5 text-xs font-medium text-foreground opacity-0 backdrop-blur-sm transition-opacity duration-200 group-hover:opacity-100">
                <Expand className="size-3.5" strokeWidth={1.75} />
                View full size
              </span>
            </>
          )}
        </button>

        <DialogContent className="max-w-3xl border-none bg-transparent p-0 shadow-none ring-0 sm:max-w-3xl">
          <DialogTitle className="sr-only">
            Full size view of {title}
          </DialogTitle>
          <div className="relative aspect-square w-full overflow-hidden rounded-lg bg-black/40">
            <Image
              src={active.url}
              alt={active.altText}
              fill
              sizes="90vw"
              className="object-contain"
            />
          </div>
        </DialogContent>
      </Dialog>

      {sorted.length > 1 && (
        <div
          className="flex gap-2.5 overflow-x-auto pb-1"
          role="list"
          aria-label="Artwork images"
        >
          {sorted.map((image, index) => (
            <button
              key={`${image.url}-${image.sortOrder}`}
              type="button"
              role="listitem"
              onClick={() => setActiveIndex(index)}
              aria-current={index === activeIndex}
              aria-label={`View ${image.altText}`}
              className={cn(
                "relative size-16 shrink-0 overflow-hidden rounded-md border transition-colors sm:size-[72px]",
                index === activeIndex
                  ? "border-gold-bright ring-1 ring-gold-bright"
                  : "border-border hover:border-gold/50",
              )}
            >
              <Image
                src={image.thumbnailUrl}
                alt=""
                fill
                sizes="72px"
                className="object-cover"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
