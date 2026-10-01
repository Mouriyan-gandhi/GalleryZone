import '../../core/pricing.dart';
import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';
import '../models/mou.dart';

/// Business rules, stated once here and applied everywhere this repository is
/// the source of truth: the reserve preview, the reserve write, dashboard KPI
/// math, the sales table, the wallet credit and the settlement row.
///
/// Every rupee figure comes from `core/pricing.dart` — the port of the web's
/// `lib/pricing.ts`. Nothing in this layer invents one.

/// Advance percent, as a whole number for the holding record.
///
/// Aggregator MOU §7, confirmed by the money-flow sheets: 5% in the first
/// month of an artwork's cycle, 3% from the second onwards. The older "5%
/// under ₹25,000, 3% above" split was this mock's own invention, made before
/// the sheets existed — it depended on the price, which the sheets never do.
/// Seeded fixture holdings still carry both values, which is why the field
/// stays an int.
int advancePercentFor(int cycleMonth) => canSetDisplayPrice(cycleMonth) ? 5 : 3;

/// Aggregator MOU §8: 20% × (selling price − ARTIST price), both compared
/// before GST.
///
/// The old version compared against `artwork.customerPrice` — GalleryZone's
/// price to the aggregator — which on the client's own worked example pays
/// ₹4,000 instead of ₹10,000. The artist price is recoverable from the listed
/// price (`artistPriceOf`), so the substitution is no longer needed.
double aggregatorCommissionFor({
  required double displayPrice,
  required double artistPrice,
}) =>
    aggregatorCommissionOf(displayPrice, artistPrice);

/// The display window a reservation opens. Thirty days, unless the leftover
/// afterwards would be too short to place with anyone else — see
/// [placementWindow].
const holdingWindow = Duration(days: aggregatorPlacementDays);

/// Minimum a withdrawal request is allowed to be. Same floor as the artist
/// wallet — this is earned commission, not refund credit.
const aggregatorMinimumWithdrawal = 1000.0;

/// This month's terms for one artwork: what GalleryZone offers it at, what
/// advance that carries, and whether this aggregator may re-price it.
///
/// Attached to every reservable artwork so the inventory grid and the reserve
/// sheet read the cycle rules from one place instead of each re-deriving them.
class AggregatorOffer {
  const AggregatorOffer({
    required this.artworkId,
    required this.month,
    required this.offerPrice,
    required this.marketplacePrice,
    required this.advance,
    required this.advanceRate,
    required this.advanceBase,
    required this.advanceBasis,
    required this.canSetPrice,
    required this.daysLeftInListing,
    required this.deliveryCharge,
    required this.payable,
    this.previousAggregatorChangedPrice = false,
    this.sellingPrice = 0,
    this.standardPrice = 0,
    this.monthlyReduction = 0,
    this.gstRate = 0.05,
    this.priceWarnFrom,
  });

  final String artworkId;

  /// Which month of the artwork's five-month cycle this placement would be.
  final int month;

  /// GalleryZone's price to the aggregator this month, before their uplift.
  final double offerPrice;

  /// What the marketplace shows — unaffected by the cycle.
  final double marketplacePrice;

  final double advance;
  final double advanceRate;

  /// The figure the rate was applied to, so the UI can show the working.
  final double advanceBase;
  final AdvanceBasis advanceBasis;

  /// Only the first aggregator may set the selling price.
  final bool canSetPrice;

  /// Days left on the artwork's 180-day listing.
  final int daysLeftInListing;

  final double deliveryCharge;

  /// Advance plus delivery — the amount locked from the wallet on reserve.
  final double payable;

  /// Whether the previous aggregator used their one price change. (The
  /// server no longer reports this — it shifts the ladder itself.)
  final bool previousAggregatorChangedPrice;

  /// GalleryZone's price this month BEFORE GST: the floor in month 1 (the
  /// aggregator may choose higher), fixed after. [offerPrice] is the same
  /// with GST — what a customer sees if GalleryZone's price is kept.
  final double sellingPrice;

  /// Month 1's price before any monthly reduction — the ladder's top rung.
  final double standardPrice;

  /// How much this month's reduction has cut off [standardPrice]; 0 in month 1.
  final double monthlyReduction;

  /// The artwork GST rate in force, as a fraction.
  final double gstRate;

  /// Month 1: the price before GST at or above which GalleryZone is warned
  /// (never blocked). Null when no warning applies.
  final double? priceWarnFrom;
}

/// A reservable artwork with this month's terms attached.
class ReservableArtwork {
  const ReservableArtwork({required this.artwork, required this.offer});

  final Artwork artwork;
  final AggregatorOffer offer;
}

/// What [AggregatorRepository.releaseHolding] gives back: the advance comes
/// back, the delivery leg does not.
class HoldingRelease {
  const HoldingRelease({required this.refunded, required this.deliveryLost});

  final double refunded;
  final double deliveryLost;
}

/// Fields match `POST /aggregators/sale` (SAD §3.5) one-for-one.
class RecordSaleInput {
  const RecordSaleInput({
    required this.artworkId,
    required this.soldPrice,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.deliveryAddress,
    required this.deliveryMode,
    this.paymentRoute = PaymentRoute.directToGalleryZone,
  });

  final String artworkId;
  final double soldPrice;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final DeliveryAddress deliveryAddress;
  final DeliveryMode deliveryMode;

  /// Whether the buyer paid GalleryZone directly or handed the aggregator
  /// cash. Cash means the aggregator owes GalleryZone the WHOLE sale price
  /// and their commission is settled separately afterwards.
  final PaymentRoute paymentRoute;
}

/// The aggregator portal (SAD §3.5 Aggregator & Order Service). Mirrors
/// `aggregatorService.ts` + `aggregatorSalesService.ts` plus the aggregator
/// slices of the messages/support/profile/settings services — one interface,
/// not six: the web splits those per file out of TypeScript module habit,
/// not because they are separate seams.
abstract class AggregatorRepository {
  Future<AggregatorDashboardSummary> getDashboardSummary();

  /// Eligible for aggregator display, still on the open marketplace, not
  /// already claimed by a live holding, and still inside its 180-day listing.
  /// Checked against the live collection, so a just-reserved piece can never
  /// be reserved twice.
  Future<List<ReservableArtwork>> listReservableInventory();

  /// [sellingPrice] is the price BEFORE GST the aggregator chooses — month 1
  /// only, never below GalleryZone's offer; omitted takes GalleryZone's
  /// price. Once reserved it cannot be changed. The offline mock ignores it
  /// (it still lets the price be raised afterwards).
  ///
  /// [simulateConflict] mirrors the documented 409 race (SAD §3.5, "lost the
  /// race to another aggregator") rather than an invented error path.
  Future<AggregatorHolding> reserve(
    String artworkId, {
    double? sellingPrice,
    bool simulateConflict,
  });

  /// Asks GalleryZone to let the aggregator keep a piece past its thirty
  /// days, with a written assurance (10-1000 characters) that it will sell.
  /// GalleryZone decides each time.
  Future<AggregatorHolding> requestExtension(String holdingId, String assurance);

  Future<List<AggregatorHoldingView>> listCollection();

  /// The piece did not sell and goes back to GalleryZone. The advance is
  /// released; the delivery leg is not — the money-flow sheet settles that
  /// only on a sale. Frees the artwork for the next aggregator in the cycle.
  Future<HoldingRelease> releaseHolding(String holdingId);

  /// Raise-only, and only the FIRST aggregator of a cycle may do it at all
  /// (MOU §6). The month's offer price is the floor. The real API has no such
  /// call any more — the price is set once, when reserving.
  Future<AggregatorHolding> updateDisplayPrice(String holdingId, double displayPrice);

  /// Signs the partner agreement. An aggregator cannot take possession of
  /// anyone's artwork until this is done.
  Future<AggregatorProfile> acceptMou({
    required String signatureName,
    required String version,
    String signatureDataUrl = '',
  });

  /// The agreement's signed state: the signature on the version in force (if
  /// any) and the draft with its blanks filled from the profile.
  Future<MouState> getMouState();

  Future<AggregatorSale> recordSale(RecordSaleInput input);
  Future<List<AggregatorSale>> listSales();
  Future<List<AggregatorCustomer>> listCustomers();

  /// preparing → dispatched → delivered, one step per call. [courierRef] is
  /// the courier's tracking reference, given when dispatching a courier sale.
  Future<AggregatorSale> advanceShipment(String saleId, {String? courierRef});

  Future<List<GallerySpace>> listGallerySpaces();

  /// Adds premises the aggregator can display pieces at. The id is assigned by
  /// whoever stores it, so the one passed in is ignored.
  Future<GallerySpace> addGallerySpace(GallerySpace space);

  Future<WalletSummary> getWallet();
  Future<List<WalletTransaction>> listWalletTransactions();

  /// Reserving artwork LOCKS money from this wallet rather than charging a
  /// fresh payment each time, so the aggregator tops it up once and every
  /// placement holds what it needs. Simulated, like the checkout payment.
  Future<WalletTransaction> addFunds(double amount);

  /// Money held against an active reservation is not theirs to take out, so
  /// the ceiling is balance minus [WalletSummary.lockedBalance].
  Future<WalletTransaction> requestWithdrawal(double amount);

  Future<List<Settlement>> listSettlements();

  /// Sales where the aggregator took cash and still owes GalleryZone the
  /// WHOLE sale price. Their commission is settled separately — they never
  /// net it off at the counter.
  Future<List<AggregatorSale>> listRemittancesDue();

  /// Records that the cash from [saleId] has been paid in to GalleryZone:
  /// taken from the wallet, or declared as a bank transfer.
  Future<AggregatorSale> markRemitted(String saleId, {RemitVia via = RemitVia.wallet});

  /// Manual "simulate settlement": moves this sale's pending commission into
  /// the available balance and writes a settlement row. No background timer
  /// — nothing in this app should move money without someone pressing it.
  Future<Settlement> processSettlement(String saleId);

  Future<AggregatorAnalyticsSummary> getAnalytics();
  Future<List<CategoryPerformance>> getCategoryPerformance();

  Future<AggregatorProfile> getProfile();
  Future<AggregatorProfile> updateProfile(AggregatorProfile profile);
  Future<AggregatorProfile> updateBankDetails({
    required String accountNumber,
    required String ifsc,
  });

  Future<AggregatorSettings> getSettings();
  Future<AggregatorSettings> updateSettings(AggregatorSettings settings);

  Future<List<MessageThread>> listMessages();
  Future<MessageThread> markMessageRead(String id);

  Future<List<SupportTicket>> listSupportTickets();
  Future<SupportTicket> submitSupportTicket({
    required String subject,
    required String message,
  });
}
