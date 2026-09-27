"use client";

import Image from "next/image";
import { motion } from "framer-motion";

export type ArtworkAnchor = {
  src: string;
  alt: string;
  /** Position as a percentage of the hero container, anchored at image center. */
  leftPct: number;
  topPct: number;
  width: number;
  height: number;
  /** Seconds after mount before this piece animates in. */
  delay: number;
  /** Subtle rotation for a hand-placed, non-grid feel. */
  rotate: number;
};

export function HeroArtwork({ artwork }: { artwork: ArtworkAnchor }) {
  const { delay, rotate } = artwork;

  return (
    <motion.div
      className="absolute rounded-sm shadow-[0_18px_40px_-12px_rgba(0,0,0,0.6)] ring-1 ring-foreground/10"
      style={{
        left: `${artwork.leftPct}%`,
        top: `${artwork.topPct}%`,
        width: artwork.width,
        height: artwork.height,
        translateX: "-50%",
        translateY: "-50%",
      }}
      initial={{ opacity: 0, scale: 0.75, y: 28 }}
      animate={{ opacity: 1, scale: 1, y: 0, rotate }}
      transition={{ delay, duration: 0.9, ease: "easeOut" }}
    >
      <Image
        src={artwork.src}
        alt={artwork.alt}
        fill
        sizes={`${artwork.width}px`}
        className="rounded-sm object-cover"
        priority
      />
    </motion.div>
  );
}
