"use client";

import Image from "next/image";
import { ArrowUpRight, Expand } from "lucide-react";
import { cn } from "@/lib/utils";
import { amazonImageAt, type AffiliateProduct } from "@/types/affiliate";

/** Amazon requires affiliate links to be marked as paid; nofollow keeps them out of ranking. */
export const AFFILIATE_REL = "sponsored nofollow noopener";

const FOCUS = "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50";

export function SupplyCard({ product, onQuickView }: { product: AffiliateProduct; onQuickView: () => void }) {
  const [cover, second] = product.images;

  return (
    <article className="group flex flex-col rounded-lg border border-border bg-card p-2 transition-colors duration-200 hover:border-gold/40">
      <button
        type="button"
        onClick={onQuickView}
        aria-label={`Quick view: ${product.title}`}
        className={cn("relative aspect-square overflow-hidden rounded-md bg-white", FOCUS)}
      >
        {cover && (
          <Image
            src={amazonImageAt(cover, 400)}
            alt={product.title}
            fill
            unoptimized
            sizes="(min-width: 1280px) 18vw, (min-width: 768px) 30vw, 48vw"
            className={cn(
              "object-contain p-4 transition-[opacity,transform] duration-300 ease-out group-hover:scale-[1.03]",
              second && "group-hover:opacity-0",
            )}
          />
        )}
        {second && (
          <Image
            src={amazonImageAt(second, 400)}
            alt=""
            fill
            unoptimized
            sizes="(min-width: 1280px) 18vw, (min-width: 768px) 30vw, 48vw"
            className="object-contain p-4 opacity-0 transition-opacity duration-300 ease-out group-hover:opacity-100"
          />
        )}
        <span className="pointer-events-none absolute right-2 bottom-2 hidden items-center gap-1 rounded-full bg-[#171310]/80 px-2.5 py-1 text-[11px] font-medium text-white opacity-0 transition-opacity duration-200 group-hover:opacity-100 sm:flex">
          <Expand className="size-3" strokeWidth={2} />
          Quick view
        </span>
      </button>

      <div className="flex flex-1 flex-col px-1.5 pt-3 pb-1">
        {product.brand && (
          <p className="truncate text-[11px] font-medium tracking-[0.14em] text-muted-foreground uppercase">
            {product.brand}
          </p>
        )}
        <h3 className="mt-1 line-clamp-2 text-sm leading-snug font-medium text-foreground" title={product.title}>
          {product.title}
        </h3>
        <p className="mt-1.5 truncate text-xs text-gold-bright">{product.category}</p>
        <div className="mt-auto pt-3">
          <a
            href={product.url}
            target="_blank"
            rel={AFFILIATE_REL}
            className={cn(
              "flex h-9 items-center justify-center gap-1.5 rounded-md border border-gold/50 text-sm font-medium text-gold-bright transition-[background-color,transform] duration-150 ease-out hover:bg-gold/10 active:scale-[0.98]",
              FOCUS,
            )}
          >
            View on Amazon
            <ArrowUpRight className="size-3.5" strokeWidth={2} />
          </a>
        </div>
      </div>
    </article>
  );
}
