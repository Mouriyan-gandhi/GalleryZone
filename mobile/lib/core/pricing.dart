/// Every rupee figure in GalleryZone comes from here. Dart port of
/// `frontend-web/lib/pricing.ts` — same constants, same function names, same
/// rounding, so the two clients can never quote different numbers for the
/// same artwork.
///
/// Source: the client's handwritten "How the money flows" sheets (21 Aug
/// 2026) plus their answers of 25 Aug, which supersede both the August
/// meeting notes and the signed MOUs wherever the three disagree. The worked
/// example those sheets carry, which every function below reproduces exactly:
///
///     MARKETPLACE                          AGGREGATOR
///     Artist price      1,00,000           Artist price        1,00,000
///     + 30% markup      1,30,000           + 30% markup        1,30,000
///     + 5% GST (inside) 1,36,500  DISPLAY  aggregator uplift   1,50,000
///     + delivery            2,500          + 5% GST (inside)   1,57,500  DISPLAY
///     ----------------------------         + delivery              2,500
///     Customer pays     1,39,000           ----------------------------
///     Artist gets       1,00,000           Customer pays       1,60,000
///     GalleryZone keeps    30,000          Artist gets            95,500
///                                          Aggregator gets        20,000
///                                          GalleryZone keeps      42,000
///
/// GST sits INSIDE the displayed price — it is not added at checkout. That is
/// the single biggest departure from how this app used to work.
///
/// `test/pricing_test.dart` replays the client's worked example and fails
/// loudly if any of it drifts.
library;

import 'dart:math' as math;

// --- Rates ------------------------------------------------------------------

/// Confirmed by the client (25 Aug): 5% is the current HSN 9701 rate. The 12%
/// figure is the 2025 one and no longer applies. Changing this number
/// re-prices every listing in the app.
///
/// GST is charged on the price of the GOODS and on nothing else. Delivery is
/// not taxed, commission is not taxed, and no party invoices another for GST.
/// Every "and GST on top of that too" question has the same answer: no.
/// [checkoutTotal] and [aggregatorCommissionOf] are where this is enforced.
const gstRate = 0.05;

/// GalleryZone's margin over the artist's price, before GST.
const platformMarkup = 0.3;

/// Free to list today; 1% of listing value (or a subscription) later. Kept as
/// a rate rather than a boolean so switching it on is a value change, not a
/// code change.
const artistListingFeeRate = 0.0;

/// Aggregator MOU §7 — security deposit paid before taking possession.
const aggregatorAdvanceRate = 0.05;

/// Aggregator MOU §8 — 20% of (selling price − artist price).
const aggregatorCommissionRate = 0.2;

/// Deducted from the artist's settlement on aggregator sales only. Confirmed
/// by the client (25 Aug): "in the marketplace we pay 100% of the artist
/// quoted price" — marketplace sales take nothing off.
const artistConvenienceRate = 0.02;

/// Charged to the customer at checkout. Zero during the launch period.
const customerConvenienceFee = 0.0;

/// The client wants delivery quoted LIVE by Shiprocket, off the weight and
/// both parties' addresses, falling back to bands only if that cannot be made
/// to work. Live rates need a server, so [estimateDelivery] below reproduces
/// Shiprocket's own model — billable weight x distance zone — as the seam
/// their rate API drops into.
///
/// This flat figure is only the last-resort fallback, used when an artwork
/// has no weight recorded or no destination is known yet.
const deliveryCharge = 2500.0;

/// Confirmed by Yash: the artist is paid within 7 days of delivery.
const artistPayoutDaysAfterDelivery = 7;

// --- Price ladder -----------------------------------------------------------

/// Artist's price to GalleryZone's price before GST. 1,00,000 -> 1,30,000.
double basePriceOf(double artistPrice) =>
    (artistPrice * (1 + platformMarkup)).round().toDouble();

/// Artist's price to the number shown in the app, GST included.
/// 1,00,000 -> 1,36,500. This is what `Artwork.customerPrice` holds.
double displayPriceOf(double artistPrice) => withGst(basePriceOf(artistPrice));

/// Adds GST to a pre-tax figure. 1,30,000 -> 1,36,500.
double withGst(double preTax) => (preTax * (1 + gstRate)).round().toDouble();

/// Strips GST back out of a displayed price. 1,36,500 -> 1,30,000.
double exGst(double displayPrice) =>
    (displayPrice / (1 + gstRate)).round().toDouble();

/// The GST already contained in a displayed price. 1,36,500 -> 6,500.
double gstIncludedIn(double displayPrice) => displayPrice - exGst(displayPrice);

/// Works the ladder backwards. Needed because most fixture artworks carry a
/// `customerPrice` with no stored artist price behind it, and the
/// aggregator's commission is defined against the artist's price.
double artistPriceFrom(double displayPrice) =>
    (exGst(displayPrice) / (1 + platformMarkup)).round().toDouble();

/// The listing fee an artist owes for putting a piece up. ₹0 today.
double listingFeeOf(double artistPrice) =>
    (artistPrice * artistListingFeeRate).round().toDouble();

// --- Checkout ---------------------------------------------------------------

class CheckoutTotal {
  const CheckoutTotal({
    required this.displayPrice,
    required this.gstIncluded,
    required this.deliveryCharge,
    required this.convenienceFee,
    required this.total,
  });

  /// The artwork's displayed price, GST already inside it.
  final double displayPrice;

  /// The GST portion of [displayPrice], shown for information only.
  final double gstIncluded;
  final double deliveryCharge;
  final double convenienceFee;

  /// What the customer actually pays.
  final double total;
}

/// Never add [CheckoutTotal.gstIncluded] to the total — it is already part of
/// the display price. Splitting it out here, rather than at each call site,
/// is what stops it being double-counted, which is exactly what the old
/// add-on-top code did.
CheckoutTotal checkoutTotal(double displayPrice, {double? delivery}) {
  final shipping = delivery ?? deliveryCharge;
  return CheckoutTotal(
    displayPrice: displayPrice,
    gstIncluded: gstIncludedIn(displayPrice),
    deliveryCharge: shipping,
    convenienceFee: customerConvenienceFee,
    total: displayPrice + shipping + customerConvenienceFee,
  );
}

// --- Settlements ------------------------------------------------------------

/// Which side of the business a sale came through.
enum SaleChannel { marketplace, aggregator }

class ArtistSettlement {
  const ArtistSettlement({
    required this.gross,
    required this.deliveryDeduction,
    required this.convenienceDeduction,
    required this.net,
  });

  final double gross;
  final double deliveryDeduction;
  final double convenienceDeduction;
  final double net;
}

/// Marketplace: the artist is paid their asking price in full — GalleryZone's
/// entire take is the markup the customer paid on top. Aggregator: the sheet
/// deducts the artist-to-aggregator delivery leg and 2% convenience, which is
/// also what settles the contradiction between artist MOU §10 (artist pays
/// the placement leg) and aggregator MOU §7 (aggregator pays it) — the artist
/// does.
ArtistSettlement artistSettlementOf(double artistPrice, SaleChannel channel) {
  if (channel == SaleChannel.marketplace) {
    return ArtistSettlement(
      gross: artistPrice,
      deliveryDeduction: 0,
      convenienceDeduction: 0,
      net: artistPrice,
    );
  }
  final convenience = (artistPrice * artistConvenienceRate).round().toDouble();
  return ArtistSettlement(
    gross: artistPrice,
    deliveryDeduction: deliveryCharge,
    convenienceDeduction: convenience,
    net: artistPrice - deliveryCharge - convenience,
  );
}

/// Aggregator MOU §8. Both prices are compared before GST, because the
/// aggregator sets a pre-tax price and GST is applied to it afterwards.
double aggregatorCommissionOf(double displayPrice, double artistPrice) {
  final markup = math.max(0.0, exGst(displayPrice) - artistPrice);
  return (markup * aggregatorCommissionRate).round().toDouble();
}

/// Aggregator MOU §7 — 5% of the price the piece is being displayed at.
double aggregatorAdvanceOf(double displayPrice) =>
    (displayPrice * aggregatorAdvanceRate).round().toDouble();

// --- The aggregator cycle ---------------------------------------------------
//
// A piece that does not sell moves on rather than sitting still: it is
// offered to a DIFFERENT aggregator each month, up to five of them. The sixth
// month is not a placement — it is deliberately left free for transit and for
// anything that goes wrong along the way, which is why both tables below stop
// at five.
//
// Two things change from month to month, and they change independently:
//
//   Month  Offered to the aggregator at   Advance
//   1      1,30,000                       5% of the DISPLAY price
//   2      1,28,000                       5% or 3% of the ARTIST price
//   3      1,26,000                       3% of the artist price
//   4      1,24,000                       3% of the artist price
//   5      1,22,000                       3% of the artist price
//
// Every month also carries the delivery charge alongside the advance.

const aggregatorCycleMonths = 5;

/// Artist MOU §18 — the whole listing runs 180 days and then the piece goes
/// home.
const aggregatorListingDays = 180;

/// One aggregator's display window.
const aggregatorPlacementDays = 30;

/// When the artwork must be back with the artist, whatever has happened
/// since.
DateTime listingEndsAt(DateTime cycleStartedAt) =>
    cycleStartedAt.add(const Duration(days: aggregatorListingDays));

int daysLeftInListing(DateTime cycleStartedAt, {DateTime? now}) {
  final end = listingEndsAt(cycleStartedAt);
  final from = now ?? DateTime.now();
  return math.max(0, (end.difference(from).inSeconds / 86400).ceil());
}

/// Whether there is room to hand the piece to ANOTHER aggregator. A stub of
/// fewer than thirty days is not a placement — nobody is shipped a painting
/// for a fortnight — so the remainder goes to whoever already has it.
bool canPlaceWithAnotherAggregator({
  required DateTime? cycleStartedAt,
  required int placementsSoFar,
  DateTime? now,
}) {
  // Nothing placed yet — the clock hasn't started.
  if (cycleStartedAt == null) return true;
  if (placementsSoFar >= aggregatorCycleMonths) return false;
  return daysLeftInListing(cycleStartedAt, now: now) >= aggregatorPlacementDays;
}

class PlacementWindow {
  const PlacementWindow({required this.expiresAt, required this.extended});

  final DateTime expiresAt;

  /// True when this aggregator keeps the piece past the usual thirty days
  /// because the leftover was too short to place with anyone else.
  final bool extended;
}

/// A placement runs thirty days — unless doing so would leave a stub shorter
/// than another placement, in which case this aggregator holds it through to
/// the end of the 180 days rather than the piece making a pointless extra
/// journey.
PlacementWindow placementWindow({
  required DateTime cycleStartedAt,
  required DateTime assignedAt,
}) {
  final listingEnd = listingEndsAt(cycleStartedAt);
  final naturalEnd = assignedAt.add(const Duration(days: aggregatorPlacementDays));
  final leftover = listingEnd.difference(naturalEnd);

  if (leftover < const Duration(days: aggregatorPlacementDays)) {
    return PlacementWindow(
      expiresAt: listingEnd,
      extended: leftover > Duration.zero,
    );
  }
  return PlacementWindow(expiresAt: naturalEnd, extended: false);
}

/// The reduction is a percentage of the ARTIST's price, taken off the price
/// GalleryZone offers the next aggregator. It comes out of GalleryZone's own
/// margin: the artist is still paid their full price, and the marketplace
/// listing never moves. Confirmed by the client (25 Aug): "the effect is only
/// on aggregator price only, no implications on market prices".
const aggregatorMonthlyDiscountRates = [0.0, 0.02, 0.04, 0.06, 0.08];

/// Clamps a cycle month into the 1..5 table. Month 6+ holds at month 5.
int _cycleIndex(int month) {
  if (month < 1) return 0;
  return math.min(month, aggregatorCycleMonths) - 1;
}

double aggregatorDiscountRateOf(int month) =>
    aggregatorMonthlyDiscountRates[_cycleIndex(month)];

/// What GalleryZone offers the aggregator in a given month of the cycle,
/// before that aggregator adds their own uplift. A 1,00,000 artist price
/// gives 1,30,000 in month 1 and 1,22,000 in month 5.
double aggregatorOfferPriceOf(double artistPrice, int month) {
  final reduction =
      (artistPrice * aggregatorDiscountRateOf(month)).round().toDouble();
  return basePriceOf(artistPrice) - reduction;
}

/// Whether this month's aggregator may set the selling price.
///
/// Only the first one can. From month two the price is GalleryZone's
/// calculated figure and the aggregator takes it as offered — because from
/// month two they are also getting the piece at a 3% advance on the artist
/// price instead of 5% on the display price. Cheaper to hold, but not theirs
/// to re-price; the client called it "a double down offer" and did not want
/// both halves given away.
bool canSetDisplayPrice(int month) => month <= 1;

/// What the rate is applied to — display price in month 1, artist price after.
enum AdvanceBasis { displayPrice, artistPrice }

class AggregatorAdvance {
  const AggregatorAdvance({
    required this.month,
    required this.rate,
    required this.base,
    required this.basis,
    required this.advance,
    required this.deliveryCharge,
    required this.payable,
  });

  final int month;
  final double rate;
  final double base;
  final AdvanceBasis basis;
  final double advance;
  final double deliveryCharge;

  /// Advance plus delivery — what is actually locked from the wallet.
  final double payable;
}

/// Month 1 is charged on the display price; every later month is charged on
/// the artist price. Month 2 is the only month whose RATE can vary: it stays
/// at 5% when the previous aggregator exercised their one price change, and
/// drops to 3% when they did not. Months 3 onward are always 3%.
AggregatorAdvance aggregatorAdvanceForMonth({
  required int month,
  required double displayPrice,
  required double artistPrice,
  bool previousAggregatorChangedPrice = false,
  double? delivery,
}) {
  final firstMonth = month <= 1;
  final rate = firstMonth || (month == 2 && previousAggregatorChangedPrice)
      ? aggregatorAdvanceRate
      : 0.03;
  final base = firstMonth ? displayPrice : artistPrice;
  final advance = (base * rate).round().toDouble();
  final shipping = delivery ?? deliveryCharge;

  return AggregatorAdvance(
    month: month,
    rate: rate,
    base: base,
    basis: firstMonth ? AdvanceBasis.displayPrice : AdvanceBasis.artistPrice,
    advance: advance,
    deliveryCharge: shipping,
    payable: advance + shipping,
  );
}

// --- Delivery ---------------------------------------------------------------
//
// The client's preference is a live Shiprocket quote, off the weight and both
// parties' addresses. That needs a server, so this reproduces Shiprocket's
// own pricing shape and is the single function their rate API replaces.
//
// TWO things drive a courier's price, and the second is the one that is
// easily forgotten: WEIGHT, where the greater of actual and volumetric weight
// is billed, and DISTANCE, as a zone between the two pincodes. Quoting on
// size alone is wrong by a wide margin on a long haul.

enum DeliveryZone { local, regional, metro, national, remote }

const deliveryZoneLabel = {
  DeliveryZone.local: 'Same city',
  DeliveryZone.regional: 'Nearby',
  DeliveryZone.metro: 'Same region',
  DeliveryZone.national: 'Rest of India',
  DeliveryZone.remote: 'Remote area',
};

/// The first slab covers 5kg, because boxed artwork is never lighter than
/// that once volumetric weight is applied; every additional kilo is charged
/// on top. Shaped after Shiprocket's surface rate card.
const _zoneRates = {
  DeliveryZone.local: (base: 400.0, perExtraKg: 55.0),
  DeliveryZone.regional: (base: 620.0, perExtraKg: 80.0),
  DeliveryZone.metro: (base: 780.0, perExtraKg: 95.0),
  DeliveryZone.national: (base: 950.0, perExtraKg: 120.0),
  DeliveryZone.remote: (base: 1400.0, perExtraKg: 175.0),
};

const _baseSlabKg = 5.0;

/// Jammu & Kashmir, Himachal and the North East cost materially more to reach
/// and every courier treats them as a surcharge zone.
const _remotePrefixes = ['18', '19', '78', '79'];

String _digitsOf(String pincode) => pincode.replaceAll(RegExp(r'[^0-9]'), '');

/// Zone between two Indian pincodes, read off the postal numbering geography.
///
/// Indian pincodes are geographic: the first digit is a postal region, the
/// first two a circle, the first three a sorting district. Sharing more
/// leading digits means being closer, which is all a zone needs to
/// approximate. A real Shiprocket quote replaces this with their own zone
/// matrix.
DeliveryZone deliveryZoneBetween(String from, String to) {
  final a = _digitsOf(from);
  final b = _digitsOf(to);
  if (a.length < 6 || b.length < 6) return DeliveryZone.national;
  if (_remotePrefixes.contains(a.substring(0, 2)) ||
      _remotePrefixes.contains(b.substring(0, 2))) {
    return DeliveryZone.remote;
  }
  if (a.substring(0, 3) == b.substring(0, 3)) return DeliveryZone.local;
  if (a.substring(0, 2) == b.substring(0, 2)) return DeliveryZone.regional;
  if (a.substring(0, 1) == b.substring(0, 1)) return DeliveryZone.metro;
  return DeliveryZone.national;
}

/// Billable weight: couriers charge the greater of what a parcel weighs and
/// what it occupies. For artwork the volumetric figure almost always wins — a
/// 4kg framed canvas in a 100x70x12cm box bills as 16.8kg.
double billableWeightKg({
  required double actualKg,
  double? lengthCm,
  double? breadthCm,
  double? heightCm,
}) {
  if (lengthCm == null ||
      breadthCm == null ||
      heightCm == null ||
      lengthCm <= 0 ||
      breadthCm <= 0 ||
      heightCm <= 0) {
    return actualKg;
  }
  final volumetric = (lengthCm * breadthCm * heightCm) / 5000;
  return math.max(actualKg, (volumetric * 10).round() / 10);
}

class DeliveryEstimate {
  const DeliveryEstimate({
    required this.zone,
    required this.billableKg,
    required this.charge,
    required this.estimated,
  });

  final DeliveryZone zone;
  final double billableKg;
  final double charge;

  /// False when there wasn't enough to go on and the flat fallback was used.
  final bool estimated;
}

DeliveryEstimate estimateDelivery({
  double? billableKg,
  String? fromPincode,
  String? toPincode,
}) {
  if (billableKg == null ||
      billableKg <= 0 ||
      fromPincode == null ||
      fromPincode.isEmpty ||
      toPincode == null ||
      toPincode.isEmpty) {
    return DeliveryEstimate(
      zone: DeliveryZone.national,
      billableKg: billableKg ?? 0,
      charge: deliveryCharge,
      estimated: false,
    );
  }

  final zone = deliveryZoneBetween(fromPincode, toPincode);
  final rates = _zoneRates[zone]!;
  final extraKg = math.max(0, (billableKg - _baseSlabKg).ceil());
  // Rounded to the nearest ten rupees — a courier quote to the paisa reads as
  // false precision on a figure that is an estimate either way.
  final charge =
      ((rates.base + extraKg * rates.perExtraKg) / 10).round() * 10.0;

  return DeliveryEstimate(
    zone: zone,
    billableKg: billableKg,
    charge: charge,
    estimated: true,
  );
}

// --- Payout timing ----------------------------------------------------------

/// The artist's money is released 7 days after the piece is delivered.
DateTime payoutReleaseDate(DateTime deliveredAt) =>
    deliveredAt.add(const Duration(days: artistPayoutDaysAfterDelivery));

bool isPayoutDue(DateTime deliveredAt, {DateTime? now}) =>
    !payoutReleaseDate(deliveredAt).isAfter(now ?? DateTime.now());
