import 'dart:math' as math;

import '../models/aggregator.dart';
import '../models/artist_portal.dart';
import '../models/artwork.dart';
import '../models/customer.dart';

/// Business rules, stated once here and applied everywhere this repository
/// is the source of truth: the reserve preview, the reserve write, dashboard
/// KPI math, the sales table, the wallet credit and the settlement row.

/// Advance-percent rule for reservations made *in the app*. SAD §2.7 fixes
/// the value at 5.00 or 3.00 but says nothing about which applies when, and
/// the seeded holdings mix both without a price threshold (real terms
/// probably depend on factors this mock doesn't model). One simple rule, so
/// the app behaves predictably: 5% under ₹25,000, 3% at or above.
const advanceThreshold = 25000.0;

int advancePercentFor(double customerPrice) => customerPrice < advanceThreshold ? 5 : 3;

double advanceAmountFor(double customerPrice, int advancePercent) =>
    (advancePercent / 100 * customerPrice).round().toDouble();

/// **Provisional — do not treat this figure as the real commission.** The
/// payout split is an unresolved product decision: the mocked code, the
/// business requirement and the SAD's schema disagree three ways. Until
/// that's settled, this ports the web's formula verbatim so the two clients
/// agree with each other, and every screen that shows the number labels it
/// provisional.
///
/// The MOU's rule is 20% × (listed price − artist price), but the artist's
/// private price never reaches this layer by design (SAD §8.7), so the
/// markup base is the aggregator's own raise over the customer-price floor.
/// A piece sold at exactly the floor yields ₹0 — the honest output of this
/// formula, not a bug.
double aggregatorCommissionFor({required double displayPrice, required double customerPrice}) =>
    (0.2 * math.max(0, displayPrice - customerPrice)).round().toDouble();

/// The display window a reservation opens, per SAD §2.7.
const holdingWindow = Duration(days: 30);

/// Minimum a withdrawal request is allowed to be. Same floor as the artist
/// wallet — this is earned commission, not refund credit.
const aggregatorMinimumWithdrawal = 1000.0;

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
  });

  final String artworkId;
  final double soldPrice;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final DeliveryAddress deliveryAddress;
  final DeliveryMode deliveryMode;
}

/// The aggregator portal (SAD §3.5 Aggregator & Order Service). Mirrors
/// `aggregatorService.ts` + `aggregatorSalesService.ts` plus the aggregator
/// slices of the messages/support/profile/settings services — one interface,
/// not six: the web splits those per file out of TypeScript module habit,
/// not because they are separate seams.
abstract class AggregatorRepository {
  Future<AggregatorDashboardSummary> getDashboardSummary();

  /// Eligible for aggregator display, still on the open marketplace, and not
  /// already claimed by a holding. Checked against the live collection, so a
  /// just-reserved piece can never be reserved twice.
  Future<List<Artwork>> listReservableInventory();

  /// [simulateConflict] mirrors the documented 409 race (SAD §3.5, "lost the
  /// race to another aggregator") rather than an invented error path.
  Future<AggregatorHolding> reserve(String artworkId, {bool simulateConflict});

  Future<List<AggregatorHoldingView>> listCollection();

  /// Raise-only: the artwork's `customerPrice` is the floor (SAD §2.7).
  Future<AggregatorHolding> updateDisplayPrice(String holdingId, double displayPrice);

  Future<AggregatorSale> recordSale(RecordSaleInput input);
  Future<List<AggregatorSale>> listSales();
  Future<List<AggregatorCustomer>> listCustomers();

  /// preparing → dispatched → delivered, one step per call.
  Future<AggregatorSale> advanceShipment(String saleId);

  Future<List<GallerySpace>> listGallerySpaces();

  Future<WalletSummary> getWallet();
  Future<List<WalletTransaction>> listWalletTransactions();
  Future<WalletTransaction> requestWithdrawal(double amount);

  Future<List<Settlement>> listSettlements();

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
