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
}
