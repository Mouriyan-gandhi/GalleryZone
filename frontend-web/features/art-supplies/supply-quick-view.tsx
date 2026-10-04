"use client";

import { useState } from "react";
import Image from "next/image";
import { ArrowUpRight, X } from "lucide-react";
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { amazonImageAt, type AffiliateProduct } from "@/types/affiliate";
import { AFFILIATE_REL } from "./supply-card";

export function SupplyQuickView({
  product,
  onClose,
}: {
  product: AffiliateProduct | null;
  onClose: () => void;
}) {
  return (
    <Dialog open={product !== null} onOpenChange={(open) => !open && onClose()}>
      <DialogContent showCloseButton={false} className="max-h-[92dvh] gap-0 overflow-y-auto p-0 sm:max-w-3xl">
        {/* The built-in close button is pale and vanishes over a white product photo. */}
        <DialogClose
          aria-label="Close"
          className="absolute top-3 right-3 z-10 flex size-9 items-center justify-center rounded-full bg-[#171310]/80 text-white transition-[background-color,transform] duration-150 hover:bg-[#171310] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-95"
        >
          <X className="size-4" strokeWidth={2} />
        </DialogClose>
        {/* Keyed so the gallery starts on the cover for each product. */}
        {product && <QuickViewBody key={product.id} product={product} />}
      </DialogContent>
    </Dialog>
  );
}

function QuickViewBody({ product }: { product: AffiliateProduct }) {
  const [active, setActive] = useState(0);
  const image = product.images[active] ?? product.images[0];

  return (
    <div className="grid md:grid-cols-[1.1fr_1fr]">
      <div className="flex flex-col gap-3 bg-white p-4 md:rounded-l-xl">
        <div className="relative h-[34dvh] md:aspect-square md:h-auto">
          {image && (
            <Image
              src={amazonImageAt(image, 800)}
              alt={product.title}
              fill
              unoptimized
              sizes="(min-width: 768px) 420px, 92vw"
              className="object-contain"
            />
          )}
        </div>
        {product.images.length > 1 && (
          <div className="flex gap-2 overflow-x-auto pb-1 [scrollbar-width:none]">
            {product.images.map((src, i) => (
              <button
                key={src}
                type="button"
                onClick={() => setActive(i)}
                aria-label={`Photo ${i + 1} of ${product.images.length}`}
                aria-pressed={i === active}
                className={cn(
                  "relative size-14 shrink-0 overflow-hidden rounded-md border-2 bg-white transition-colors focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
                  i === active ? "border-gold" : "border-transparent hover:border-[#d9d4cc]",
                )}
              >
                <Image src={amazonImageAt(src, 100)} alt="" fill unoptimized sizes="56px" className="object-contain p-1" />
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="flex flex-col p-5 sm:p-6">
        {product.brand && (
          <p className="text-[11px] font-medium tracking-[0.16em] text-muted-foreground uppercase">{product.brand}</p>
        )}
        <DialogTitle className="mt-1.5 font-display text-lg leading-snug font-semibold text-pretty text-foreground sm:text-xl">
          {product.title}
        </DialogTitle>
        <span className="mt-3 w-fit rounded-full border border-gold/40 px-2.5 py-0.5 text-xs text-gold-bright">
          {product.category}
        </span>
        <DialogDescription className="mt-4 text-sm leading-relaxed text-muted-foreground">
          Chosen by GalleryZone for working artists. The price, delivery date and reviews are on
          Amazon, and you check out there.
        </DialogDescription>

        <div className="mt-6 md:mt-auto md:pt-6">
          <a
            href={product.url}
            target="_blank"
            rel={AFFILIATE_REL}
            className="flex h-11 w-full items-center justify-center gap-2 rounded-full bg-foreground text-sm font-semibold text-background transition-transform duration-150 ease-out active:scale-[0.98] focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-gold-bright dark:text-[#171310]"
          >
            Buy on Amazon
            <ArrowUpRight className="size-4" strokeWidth={2} />
          </a>
          <p className="mt-3 text-center text-[11px] text-muted-foreground">
            As an Amazon Associate, GalleryZone earns from qualifying purchases.
          </p>
        </div>
      </div>
    </div>
  );
}
