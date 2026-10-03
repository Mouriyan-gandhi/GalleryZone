import '../../core/format.dart';
import '../../data/models/artwork.dart';
import '../../data/models/artwork_filters.dart';
import '../../data/models/marketplace.dart';

/// What the marketplace starts as, and what "Reset" returns to.
const defaultMarketplaceFilters = ArtworkFilters(sortBy: ArtworkSortBy.newest);

/// A rupee band in the filter sheet's Price group. A band maps straight onto
/// the API's min / max price, so picking one replaces any other price filter.
class PriceBand {
  const PriceBand({this.min, this.max});

  final double? min;
  final double? max;

  /// `Under ₹10,000`, `₹10,000 – ₹25,000`, `Above ₹1,00,000`.
  String get label {
    final low = min;
    final high = max;
    if (low == null && high != null) return 'Under ${formatInr(high)}';
    if (high == null && low != null) return 'Above ${formatInr(low)}';
    return '${formatInr(low ?? 0)} – ${formatInr(high ?? 0)}';
  }

  bool contains(double price) => (min == null || price >= min!) && (max == null || price < max!);

  bool matches(double? minPrice, double? maxPrice) => minPrice == min && maxPrice == max;
}

const priceBands = [
  PriceBand(max: 10000),
  PriceBand(min: 10000, max: 25000),
  PriceBand(min: 25000, max: 50000),
  PriceBand(min: 50000, max: 100000),
  PriceBand(min: 100000),
];

/// How many live pieces each filter option would leave.
///
/// Tallied on the phone from the first, largest page — so, like the website,
/// only while the whole marketplace fits on that page. Past that the counts
/// would be wrong rather than just incomplete, so [from] returns null and the
/// sheet shows the options without them.
class FilterCounts {
  const FilterCounts({
    this.category = const {},
    this.medium = const {},
    this.size = const {},
    this.artist = const {},
    this.location = const {},
    this.price = const [],
  });

  final Map<String, int> category;
  final Map<String, int> medium;
  final Map<ArtworkSizeBand, int> size;
  final Map<String, int> artist;
  final Map<String, int> location;

  /// One count per entry of [priceBands].
  final List<int> price;

  static FilterCounts? from(MarketplacePage overview) {
    if (overview.total > overview.artworks.length) return null;
    final pieces = overview.artworks;

    Map<K, int> tally<K>(K? Function(Artwork) key) {
      final counts = <K, int>{};
      for (final piece in pieces) {
        final value = key(piece);
        if (value != null) counts[value] = (counts[value] ?? 0) + 1;
      }
      return counts;
    }

    String? text(String? value) => (value == null || value.isEmpty) ? null : value;

    return FilterCounts(
      category: tally((a) => text(a.category)),
      medium: tally((a) => text(a.medium)),
      size: tally((a) => a.sizeBand),
      artist: tally((a) => text(a.artistId)),
      location: tally((a) => text(a.artistLocation)),
      price: [for (final band in priceBands) pieces.where((a) => band.contains(a.customerPrice)).length],
    );
  }
}

/// The word on a rank's filter row and in the rank guide.
String rankLabel(ArtworkRarity rank) => artworkRarityLabel[rank]!;
