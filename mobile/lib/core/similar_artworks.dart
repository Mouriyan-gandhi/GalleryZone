import 'dart:math' as math;

import '../data/models/artwork.dart';

/// "Suggestions: same type of paintings show to him" (client, 30 Sep 2026),
/// matched on category, similar price and similar size. Port of the web's
/// `lib/similar-artworks.ts`: plain scoring over a list that is already small.

/// Within a quarter of each other is "similar" in price.
const _similarPriceRatio = 0.75;

/// 3 = category alone, or price and size together. Below that is not the same type.
const _minScore = 3;

int similarityScore(Artwork a, Artwork b) {
  var score = 0;
  if (a.category.isNotEmpty && a.category == b.category) score += 3;
  if (a.customerPrice > 0 && b.customerPrice > 0) {
    final ratio = math.min(a.customerPrice, b.customerPrice) / math.max(a.customerPrice, b.customerPrice);
    if (ratio >= _similarPriceRatio) score += 2;
  }
  if (a.sizeBand != null && a.sizeBand == b.sizeBand) score += 1;
  return score;
}

/// The candidates most like any of [references], best first (ties keep their
/// order). A piece is never suggested against itself or against another
/// reference. [artworkOf] lets the caller hand over wrappers - a reservable
/// piece, a holding - without this file knowing about them.
List<T> similarTo<T>(
  Iterable<Artwork> references,
  Iterable<T> candidates,
  Artwork Function(T) artworkOf, {
  int limit = 4,
}) {
  final referenceIds = {for (final reference in references) reference.id};
  final scored = <({T candidate, int score, int index})>[];
  var index = 0;
  for (final candidate in candidates) {
    final artwork = artworkOf(candidate);
    if (referenceIds.contains(artwork.id)) continue;
    var best = 0;
    for (final reference in references) {
      best = math.max(best, similarityScore(reference, artwork));
    }
    if (best >= _minScore) scored.add((candidate: candidate, score: best, index: index++));
  }
  // Dart's sort is not stable; the index puts equal scores back in list order.
  scored.sort((a, b) => b.score != a.score ? b.score.compareTo(a.score) : a.index.compareTo(b.index));
  return [for (final entry in scored.take(limit)) entry.candidate];
}
