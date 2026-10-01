/// What the artist's upload form and the fee explainers quote from — the
/// published commercial terms, served by `GET /v1/pricing-rules`. An approved
/// rate change therefore moves every screen at once, with no release.
///
/// Rates are fractions (`0.05` = 5%); absolute amounts are rupees (the API
/// sends paise and the mapper converts).
class PricingRules {
  const PricingRules({
    required this.gstRate,
    required this.platformMarkup,
    required this.artistListingFeeRate,
    required this.serviceGstRate,
    required this.artistTdsRate,
    required this.artistConvenienceRate,
    required this.aggregatorCommissionRate,
    required this.aggregatorAdvanceRate,
    required this.nfcTagCharge,
    required this.subscriptionFee,
    required this.deliveryCharge,
    required this.insuranceThreshold,
    this.artistTechnologyRate = 0,
    this.aggregatorPriceWarnRate = 1,
  });

  /// GST on the artwork itself (HSN 9701), inside the displayed price.
  final double gstRate;

  /// GalleryZone's margin over the artist's price, before GST.
  final double platformMarkup;

  /// Listing charge, as a fraction of the artist's price (plus service GST).
  final double artistListingFeeRate;

  /// GST on GalleryZone's own service charges — always separate from
  /// [gstRate], which taxes the artwork.
  final double serviceGstRate;

  /// Income-tax TDS (§194-O) withheld once an artist's financial-year sales
  /// pass ₹5 lakh.
  final double artistTdsRate;
  final double artistConvenienceRate;
  final double artistTechnologyRate;
  final double aggregatorCommissionRate;
  final double aggregatorAdvanceRate;
  final double aggregatorPriceWarnRate;

  /// One-off charge when an NFC tag is issued for a piece, before service GST.
  final double nfcTagCharge;
  final double subscriptionFee;

  /// The flat fallback delivery charge.
  final double deliveryCharge;

  /// Artwork price at or above which transit insurance is recommended.
  final double insuranceThreshold;
}
