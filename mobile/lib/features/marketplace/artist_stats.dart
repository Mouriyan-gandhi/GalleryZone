import 'package:intl/intl.dart';

import '../../data/models/artist.dart';
import '../../data/models/artwork.dart';

/// The numbers a collector wants before reading a bio, derived on read from
/// what the public API already shows — nothing here is stored, so none of it
/// can drift from the thing it counts. Port of `artistPublic()` in the
/// website's `profileStatsService`.
///
/// Everything is a count, a date or the *listed* price (the figure already on
/// every card). What an artist is paid is confidential and never reaches this.
class ArtistPublicStats {
  const ArtistPublicStats({
    required this.artworksListed,
    required this.mediums,
    required this.priceLow,
    required this.priceHigh,
    required this.joinedAt,
  });

  factory ArtistPublicStats.of(ArtistProfile artist, List<Artwork> listed) {
    final prices = [for (final a in listed) a.customerPrice];
    return ArtistPublicStats(
      artworksListed: listed.length,
      mediums: byFrequency([for (final a in listed) a.medium]),
      priceLow: prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b),
      priceHigh: prices.isEmpty ? null : prices.reduce((a, b) => a > b ? a : b),
      joinedAt: artist.joinedAt,
    );
  }

  final int artworksListed;

  /// Most-used first, so what they mostly make reads off the front.
  final List<String> mediums;

  /// Listed price, GST included. Null when nothing is listed.
  final double? priceLow;
  final double? priceHigh;
  final String joinedAt;

  /// "Works sold" and "on display" need the artist's own list, which the
  /// public API does not show - the website shows 0 for both, and so does this.
  int get worksSold => 0;

  /// `October 2026`, or `—` while the API sends no join date.
  String get joinedLabel {
    final date = DateTime.tryParse(joinedAt);
    return date == null ? '—' : DateFormat('MMMM y').format(date.toLocal());
  }

  static List<String> byFrequency(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final key = value.trim();
      if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return [for (final entry in entries) entry.key];
  }
}
