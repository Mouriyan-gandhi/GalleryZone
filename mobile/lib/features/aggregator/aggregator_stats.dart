import '../../data/models/aggregator.dart';
import '../../data/models/artist_portal.dart';
import '../../data/models/customer.dart';

/// The partner business at a glance: what they are holding, what they have sold,
/// and what they owe. Port of the website's `AggregatorStats`
/// (`services/profileStatsService.ts`).
///
/// It leads with obligations as well as earnings because an aggregator collects on
/// GalleryZone's behalf: money in their till is not income, and a summary that
/// mixed the two would invite exactly the netting-off the MOU forbids.
class AggregatorStats {
  const AggregatorStats({
    required this.onDisplay,
    required this.piecesSold,
    required this.returned,
    required this.commissionEarned,
    required this.heldAgainstReservations,
    required this.owedToGalleryZone,
    required this.gallerySpaces,
    required this.displayCapacity,
    required this.cities,
    required this.distinctBuyers,
    this.mouSignedAt,
  });

  /// Pieces currently reserved - on display now.
  final int onDisplay;
  final int piecesSold;

  /// Pieces that went back to GalleryZone unsold.
  final int returned;

  /// What recorded sales have earned this aggregator. The website's tile is a fixed
  /// 0; this is the ledger's figure.
  final double commissionEarned;

  /// Advances and delivery set aside for the pieces they hold.
  final double heldAgainstReservations;

  /// Cash taken at the counter and not yet paid in to GalleryZone.
  final double owedToGalleryZone;

  final int gallerySpaces;
  final int displayCapacity;

  /// Where their spaces are, most spaces first.
  final List<String> cities;

  final int distinctBuyers;

  /// When the current agreement was signed; null while it is unsigned.
  final String? mouSignedAt;
}

/// Values by how often they occur, most first, ties in alphabetical order, blanks
/// dropped. `["Pune", "Goa", "Pune"]` is `["Pune", "Goa"]`.
List<String> byFrequency(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    final key = value.trim();
    if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.toLowerCase().compareTo(b.toLowerCase());
    });
  return keys;
}

AggregatorStats aggregatorStatsOf({
  required List<AggregatorHoldingView> holdings,
  required List<AggregatorSale> sales,
  required List<GallerySpace> spaces,
  required WalletSummary wallet,
  required AggregatorProfile profile,
  required Map<String, double> commissions,
}) {
  int count(HoldingStatus status) => holdings.where((view) => view.holding.status == status).length;

  return AggregatorStats(
    onDisplay: count(HoldingStatus.reserved),
    piecesSold: count(HoldingStatus.soldPendingSettlement),
    returned: count(HoldingStatus.returned),
    commissionEarned: commissions.values.fold(0.0, (sum, amount) => sum + amount),
    heldAgainstReservations: wallet.lockedBalance,
    owedToGalleryZone: sales
        .where((sale) => sale.paymentRoute == PaymentRoute.cashAtPremises && sale.remittedAt == null)
        .fold(0.0, (sum, sale) => sum + sale.soldPrice),
    gallerySpaces: spaces.length,
    displayCapacity: spaces.fold(0, (sum, space) => sum + space.capacity),
    cities: byFrequency(spaces.map((space) => space.city)),
    distinctBuyers: sales.map((sale) => sale.buyerEmail).toSet().length,
    mouSignedAt: profile.mouAcceptance?.acceptedAt,
  );
}
