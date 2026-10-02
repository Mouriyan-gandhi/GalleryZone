import { ARTWORK_RARITY_LABEL, type ArtworkRarity } from "@/types/artwork";
import { cn } from "@/lib/utils";

// Solid, per-rank colors for the "stamp" variant — a rank has to read at a
// glance over a busy photo, which a shared translucent gold pill (the "pill"
// variant, used everywhere else) can't do across four different ranks.
export const STAMP_TONE: Record<ArtworkRarity, string> = {
  R: "bg-destructive text-white",
  U: "bg-emerald-600 text-white",
  O: "bg-gold-deep text-white",
  S: "bg-muted-foreground text-background",
};

// The rarity mark that sits over an artwork image. It spells the word rather
// than showing a bare letter: "R" means nothing to someone seeing it for the
// first time.
export function RarityBadge({
  rarity,
  variant = "pill",
  className,
}: {
  rarity: ArtworkRarity | null | undefined;
  /** "pill": translucent gold outline, used everywhere. "stamp": solid,
   * per-rank color for the marketplace card corner, where four ranks need to
   * be tellable apart at a glance. */
  variant?: "pill" | "stamp";
  className?: string;
}) {
  if (!rarity) return null;

  if (variant === "stamp") {
    return (
      <span
        className={cn(
          "inline-flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-bold tracking-[0.04em] uppercase shadow-sm",
          STAMP_TONE[rarity],
          className,
        )}
      >
        {rarity}
      </span>
    );
  }

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full border border-gold/50 bg-background/85 px-2 py-0.5 text-[10px] font-semibold tracking-[0.08em] text-gold-bright uppercase backdrop-blur-sm",
        className,
      )}
    >
      <span className="font-bold">{rarity}</span>
      {ARTWORK_RARITY_LABEL[rarity]}
    </span>
  );
}
