/// Mirrors `ArtworkFilters` in `types/artwork.ts`.
enum ArtworkSortBy { newest, priceAsc, priceDesc }

class ArtworkFilters {
  const ArtworkFilters({this.category, this.minPrice, this.maxPrice, this.medium, this.query, this.sortBy});

  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? medium;
  final String? query;
  final ArtworkSortBy? sortBy;

  ArtworkFilters copyWith({
    Object? category = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    Object? medium = _unset,
    Object? query = _unset,
    Object? sortBy = _unset,
  }) {
    return ArtworkFilters(
      category: category == _unset ? this.category : category as String?,
      minPrice: minPrice == _unset ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _unset ? this.maxPrice : maxPrice as double?,
      medium: medium == _unset ? this.medium : medium as String?,
      query: query == _unset ? this.query : query as String?,
      sortBy: sortBy == _unset ? this.sortBy : sortBy as ArtworkSortBy?,
    );
  }

  // Value equality matters here beyond tidiness: this type is a Riverpod
  // family argument, and without it every rebuild would key a *new* provider
  // instance and refetch.
  @override
  bool operator ==(Object other) =>
      other is ArtworkFilters &&
      other.category == category &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.medium == medium &&
      other.query == query &&
      other.sortBy == sortBy;

  @override
  int get hashCode => Object.hash(category, minPrice, maxPrice, medium, query, sortBy);
}

/// Sentinel so [ArtworkFilters.copyWith] can tell "leave this alone" apart
/// from "clear this filter" — every field here is nullable and clearing one
/// is the common case (`All categories`, an emptied price box).
const _unset = Object();
