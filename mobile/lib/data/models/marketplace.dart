import 'artist.dart';
import 'artwork.dart';

/// The marketplace listing pages in twenties — the same as the website.
const marketplacePageSize = 20;

/// An artist offered as a filter choice.
class FacetArtist {
  const FacetArtist({required this.id, required this.name});

  final String id;
  final String name;
}

/// The filter choices that exist *right now*, across the whole live
/// marketplace rather than just the page in hand — so the filter sheet has
/// nothing hard-coded, and a rank with no works can say "none yet".
class MarketplaceFacets {
  const MarketplaceFacets({
    this.categories = const [],
    this.mediums = const [],
    this.locations = const [],
    this.artists = const [],
    this.rarityCounts = const {},
    this.priceMin,
    this.priceMax,
  });

  final List<String> categories;
  final List<String> mediums;
  final List<String> locations;
  final List<FacetArtist> artists;

  /// Live pieces per rank.
  final Map<ArtworkRarity, int> rarityCounts;

  /// Rupees. Null when the marketplace is empty.
  final double? priceMin;
  final double? priceMax;

  static const empty = MarketplaceFacets();
}

/// One page of the marketplace listing plus what it takes to page on.
class MarketplacePage {
  const MarketplacePage({
    required this.artworks,
    required this.total,
    required this.page,
    required this.pageSize,
    this.facets = MarketplaceFacets.empty,
  });

  final List<Artwork> artworks;

  /// How many pieces match the filters, across every page.
  final int total;
  final int page;
  final int pageSize;
  final MarketplaceFacets facets;

  bool get hasMore => page * pageSize < total;

  static const empty = MarketplacePage(artworks: [], total: 0, page: 1, pageSize: 20);
}

/// A row in the artists directory: the public profile plus the figures the
/// listing is built from.
class ArtistCard {
  const ArtistCard({required this.profile, required this.artworkCount, this.coverImageUrl});

  final ArtistProfile profile;
  final int artworkCount;
  final String? coverImageUrl;
}
