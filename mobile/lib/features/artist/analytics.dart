import 'package:intl/intl.dart';

import '../../data/models/artwork.dart';
import '../../data/models/customer.dart';
import '../../data/models/order.dart';
import '../../data/repositories/artist_repository.dart';

/// The numbers behind the artist's Analytics page. Port of
/// `features/dashboard/artist-analytics-view.tsx` and `useArtistRevenueSeries`,
/// kept apart from the screen so they can be tested without building one.

/// One month of settled earnings.
typedef RevenuePoint = ({String month, double amount});

/// Monthly settlement income for the last [months] months, ending with the
/// current one, from the wallet's real transactions. Months with no sales are
/// zero, never invented.
List<RevenuePoint> revenueSeries(
  List<WalletTransaction> transactions, {
  DateTime? now,
  int months = 6,
}) {
  final current = now ?? DateTime.now();
  final buckets = [
    for (var i = months - 1; i >= 0; i--) DateTime(current.year, current.month - i),
  ];
  final amounts = List<double>.filled(months, 0);
  for (final transaction in transactions) {
    if (transaction.type != WalletTransactionType.settlement ||
        transaction.status != WalletTransactionStatus.completed) {
      continue;
    }
    final date = DateTime.tryParse(transaction.date)?.toLocal();
    if (date == null) continue;
    final index = buckets.indexWhere((b) => b.year == date.year && b.month == date.month);
    if (index >= 0 && transaction.amount > 0) amounts[index] += transaction.amount;
  }
  return [
    for (var i = 0; i < months; i++) (month: DateFormat('MMM').format(buckets[i]), amount: amounts[i]),
  ];
}

/// Revenue and order count for one category.
typedef CategoryPerformance = ({String category, double revenue, int orders});

const _settled = {ArtworkStatus.sold, ArtworkStatus.settlementComplete, ArtworkStatus.delivered, ArtworkStatus.completed};

/// The artist's own settled sales by category, highest first. A category that
/// has sold nothing yet is left out: a bar of nothing says nothing.
List<CategoryPerformance> categoryPerformance(List<ArtistArtwork> artworks) {
  final byCategory = <String, ({double revenue, int orders})>{};
  for (final entry in artworks) {
    final artwork = entry.artwork;
    if (!_settled.contains(artwork.status)) continue;
    final current = byCategory[artwork.category] ?? (revenue: 0, orders: 0);
    byCategory[artwork.category] = (revenue: current.revenue + artwork.customerPrice, orders: current.orders + 1);
  }
  return [
    for (final entry in byCategory.entries) (category: entry.key, revenue: entry.value.revenue, orders: entry.value.orders),
  ]..sort((a, b) => b.revenue.compareTo(a.revenue));
}

/// A stage of the artwork pipeline and how many pieces are in it.
typedef FunnelStage = ({String stage, int count});

/// Where the artist's pieces sit right now: drafts, work awaiting review, work
/// that is live (in circulation: listed, reserved, on its way or with an
/// aggregator), and work sold. A piece returned to the artist, or sold
/// elsewhere, is in none of them - the website files those under "Live", which
/// overstates it.
List<FunnelStage> artworkFunnel(List<ArtistArtwork> artworks) {
  const live = {
    ArtworkStatus.marketplace,
    ArtworkStatus.reserved,
    ArtworkStatus.preparingDispatch,
    ArtworkStatus.inTransit,
    ArtworkStatus.withAggregator,
  };
  int count(bool Function(ArtworkStatus) test) => artworks.where((a) => test(a.artwork.status)).length;
  return [
    (stage: 'Draft', count: count((s) => s == ArtworkStatus.draft)),
    (stage: 'Pending Approval', count: count((s) => s == ArtworkStatus.pendingApproval)),
    (stage: 'Live', count: count(live.contains)),
    (stage: 'Sold', count: count(_settled.contains)),
  ];
}

/// The four figures at the top of the page.
typedef AnalyticsSummary = ({int artworks, int sales, double revenue, double averageSale});

/// Sales are orders that were actually paid for; what the artist took home is
/// their payout, not what the buyer paid.
AnalyticsSummary analyticsSummary({required List<ArtistArtwork> artworks, required List<ArtistOrder> orders}) {
  final paid = orders.where(
    (entry) => entry.order.status != OrderStatus.pending && entry.order.status != OrderStatus.cancelled,
  );
  final revenue = paid.fold<double>(0, (sum, entry) => sum + entry.artistPayout);
  final sales = paid.length;
  return (
    artworks: artworks.length,
    sales: sales,
    revenue: revenue,
    averageSale: sales > 0 ? (revenue / sales).roundToDouble() : 0,
  );
}

String _trim(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble() ? rounded.round().toString() : rounded.toString();
}

/// `₹45k`, `₹1.2L`, `₹3Cr` - the shortening the website's charts use for axis
/// ticks and bar labels.
String formatCompactInr(double value) {
  if (!value.isFinite) return '';
  final sign = value < 0 ? '-' : '';
  final n = value.abs();
  if (n >= 10000000) return '$sign₹${_trim(n / 10000000)}Cr';
  if (n >= 100000) return '$sign₹${_trim(n / 100000)}L';
  if (n >= 1000) return '$sign₹${_trim(n / 1000)}k';
  return '$sign₹${n.round()}';
}

/// The same shortening for plain counts.
String formatCompactCount(double value) {
  if (!value.isFinite) return '';
  final sign = value < 0 ? '-' : '';
  final n = value.abs();
  if (n >= 10000000) return '$sign${_trim(n / 10000000)}Cr';
  if (n >= 100000) return '$sign${_trim(n / 100000)}L';
  if (n >= 1000) return '$sign${_trim(n / 1000)}k';
  return '$sign${n.round()}';
}
