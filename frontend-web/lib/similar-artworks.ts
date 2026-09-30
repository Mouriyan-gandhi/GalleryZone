import type { ArtworkSummary } from "@/types/artwork";

// "Suggestions: same type of paintings show to him" (client, 30 Sep 2026),
// matched on style or category, similar price and similar size. Plain scoring
// over a list that is already small; nothing here needs a ranking model.

/** Within a quarter of each other is "similar" in price. */
const SIMILAR_PRICE_RATIO = 0.75;

/** 3 = category alone, or price and size together. Below that is not the same type. */
const MIN_SCORE = 3;

export function similarityScore(a: ArtworkSummary, b: ArtworkSummary): number {
  let score = 0;
  if (a.category && a.category === b.category) score += 3;
  if (a.customerPrice > 0 && b.customerPrice > 0) {
    const ratio = Math.min(a.customerPrice, b.customerPrice) / Math.max(a.customerPrice, b.customerPrice);
    if (ratio >= SIMILAR_PRICE_RATIO) score += 2;
  }
  if (a.sizeBand && a.sizeBand === b.sizeBand) score += 1;
  return score;
}

/**
 * The candidates most like any of `references`, best first. A piece is never
 * suggested against itself or against another reference.
 */
export function similarTo<T extends ArtworkSummary>(references: readonly ArtworkSummary[], candidates: readonly T[], limit = 4): T[] {
  const referenceIds = new Set(references.map((r) => r.id));
  return candidates
    .filter((c) => !referenceIds.has(c.id))
    .map((c) => ({ candidate: c, score: Math.max(0, ...references.map((r) => similarityScore(r, c))) }))
    .filter(({ score }) => score >= MIN_SCORE)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ candidate }) => candidate);
}
