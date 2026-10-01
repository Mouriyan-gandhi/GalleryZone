"use client";

import "@/lib/motion-config";
import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useMarketplaceOverview } from "@/hooks/useArtworks";

// A small, deliberately varied slice of the fixture set (one painting, one
// sculpture, one photograph, one textile piece) so the rotating showcase
// reads as "the breadth of what's on GalleryZone", not four near-identical
// canvases. Falls back gracefully (renders fewer frames) if any of these
// specific ids ever moves in lib/mock-data/artworks.ts.
// The showcase rotates through the newest live listings.
const SHOWCASE_COUNT = 4;

const ROTATE_INTERVAL_MS = 5000;

export function AuthLayoutPanel() {
  return (
    <aside className="relative hidden shrink-0 flex-col overflow-hidden border-r border-sidebar-border bg-sidebar px-14 py-12 lg:sticky lg:top-0 lg:flex lg:h-[100dvh] lg:w-[44%] lg:justify-between">
      <PanelGlow />

      <div className="relative z-10 flex flex-col gap-4">
        <Wordmark />
        {/* Tagline — always visible right under the logo */}
        <div>
          <p className="font-display text-2xl font-medium italic text-sidebar-foreground/90">
            Art, that Connects.{" "}
            <span className="text-gold-bright not-italic">
              Culture that inspires.
            </span>
          </p>
          <span className="mt-3 block h-px w-8 bg-gold/50" />
        </div>
      </div>

      <div className="relative z-10 mt-8 flex flex-1 min-h-0">
        <RotatingShowcase />
      </div>
    </aside>
  );
}

function Wordmark() {
  return (
    <Link href="/" className="flex items-center gap-3">
      <Image
        src="/brand/gz-logo.png"
        alt="GalleryZone"
        width={822}
        height={560}
        priority
        className="h-14 w-auto shrink-0"
      />
      <div className="flex flex-col gap-0.5">
        <span className="text-sm font-medium tracking-[0.18em] text-sidebar-foreground">
          GALLERYZONE
        </span>
        <span className="text-[10px] font-semibold tracking-[0.28em] text-gold/70 uppercase">
          Art Connects
        </span>
      </div>
    </Link>
  );
}

function RotatingShowcase() {
  const [activeIndex, setActiveIndex] = useState(0);
  const prefersReducedMotion = useReducedMotion();
  const SHOWCASE_ARTWORKS = (useMarketplaceOverview().data?.artworks ?? []).slice(0, SHOWCASE_COUNT);

  useEffect(() => {
    if (prefersReducedMotion || SHOWCASE_ARTWORKS.length < 2) return;
    const id = setInterval(() => {
      setActiveIndex((current) => (current + 1) % SHOWCASE_ARTWORKS.length);
    }, ROTATE_INTERVAL_MS);
    return () => clearInterval(id);
  }, [prefersReducedMotion, SHOWCASE_ARTWORKS.length]);

  const active = SHOWCASE_ARTWORKS[activeIndex];
  if (!active) return null;

  return (
    <div className="flex w-full flex-col gap-4">
      <div className="relative aspect-[4/5] w-full max-w-[22rem] overflow-hidden rounded-xl ring-1 ring-gold/15">
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={prefersReducedMotion ? "static" : active.id}
            initial={prefersReducedMotion ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={prefersReducedMotion ? undefined : { opacity: 0 }}
            transition={{ duration: 0.9, ease: [0.77, 0, 0.175, 1] }}
            className="absolute inset-0"
          >
            <Image
              src={active.thumbnailUrl}
              alt={active.title}
              fill
              sizes="352px"
              priority={activeIndex === 0}
              className="object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-sidebar/90 via-transparent to-transparent" />
          </motion.div>
        </AnimatePresence>

        <div className="absolute right-0 bottom-0 left-0 flex items-end justify-between gap-3 p-4">
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-sidebar-foreground">
              {active.title}
            </p>
            <p className="truncate text-xs text-sidebar-foreground/70">
              {active.artistName}
            </p>
          </div>
        </div>
      </div>

      {SHOWCASE_ARTWORKS.length > 1 && (
        <div className="flex items-center gap-1.5" aria-hidden="true">
          {SHOWCASE_ARTWORKS.map((artwork, index) => (
            <span
              key={artwork.id}
              className={`h-1 rounded-full transition-all duration-500 ${
                index === activeIndex
                  ? "w-6 bg-gold-bright"
                  : "w-1.5 bg-sidebar-foreground/25"
              }`}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function PanelGlow() {
  return (
    <div
      className="pointer-events-none absolute inset-0 overflow-hidden"
      aria-hidden="true"
    >
      <div
        className="absolute inset-0 opacity-[0.04]"
        style={{
          backgroundImage:
            "radial-gradient(circle, rgba(255,255,255,0.9) 1px, transparent 1px)",
          backgroundSize: "3px 3px",
        }}
      />
      <div className="absolute -top-24 -left-24 size-[420px] rounded-full bg-gold/10 blur-[120px]" />
    </div>
  );
}
