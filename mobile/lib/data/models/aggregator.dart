import 'package:freezed_annotation/freezed_annotation.dart';

import 'artist_portal.dart';
import 'artwork.dart';

part 'aggregator.freezed.dart';
part 'aggregator.g.dart';

/// Aggregator-portal shapes: `types/aggregator.ts` plus the aggregator's own
/// profile/settings collections in `lib/mock-collections.ts`.
///
/// [AggregatorHolding] itself already lives in `artist_portal.dart` — the
/// artist side reads holdings (Gallery Spaces), this side writes them.

enum DeliveryMode {
  courier,
  @JsonValue('self_pickup')
  selfPickup,
}

enum ShipmentStatus { preparing, dispatched, delivered }

/// The aggregator collects "on behalf of GalleryZone", never for themselves.
/// Either the buyer paid GalleryZone directly (transfer or UPI, using the
/// details on the checkout screen), or the aggregator took cash — in which
/// case they owe GalleryZone the WHOLE sale price and their commission is
/// settled separately afterwards. They never net it off at the counter.
enum PaymentRoute {
  @JsonValue('direct_to_galleryzone')
  directToGalleryZone,
  @JsonValue('cash_at_premises')
  cashAtPremises,
}

const paymentRouteLabel = {
  PaymentRoute.directToGalleryZone: 'Buyer paid GalleryZone directly',
  PaymentRoute.cashAtPremises: 'Cash taken at the gallery',
};

/// The buyer's address as the aggregator records it at the counter. Distinct
/// from `order.dart`'s `Address`, which is a saved, reusable address-book
/// entry with an id and a default flag — this one is captured once, on one
/// sale, and never reused.
@freezed
abstract class DeliveryAddress with _$DeliveryAddress {
  const factory DeliveryAddress({
    required String line1,
    required String city,
    required String state,
    required String pincode,
  }) = _DeliveryAddress;

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      _$DeliveryAddressFromJson(json);
}

/// Persisted result of `recordSale()` — the buyer/price/delivery detail the
/// Orders, Customers, Shipping, Wallet and Settlements screens all read.
@freezed
abstract class AggregatorSale with _$AggregatorSale {
  const factory AggregatorSale({
    required String id,
    required String holdingId,
    required String artworkId,
    required double soldPrice,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required DeliveryAddress deliveryAddress,
    required DeliveryMode deliveryMode,
    required String soldAt,
    required ShipmentStatus shipmentStatus,
    String? dispatchedAt,
    String? deliveredAt,

    /// How the buyer's money reached GalleryZone.
    @Default(PaymentRoute.directToGalleryZone) PaymentRoute paymentRoute,

    /// Set when the aggregator has transferred cash they collected. Null
    /// while the money is still sitting in their till.
    String? remittedAt,

    /// Null when [deliveryMode] is [DeliveryMode.selfPickup].
    String? courierRef,
  }) = _AggregatorSale;

  factory AggregatorSale.fromJson(Map<String, dynamic> json) =>
      _$AggregatorSaleFromJson(json);
}

/// The aggregator's own physical premises. Not the artist portal's "Gallery
/// Spaces" screen, which lists artworks placed *at* an aggregator — same
/// label, opposite direction, different actor.
@freezed
abstract class GallerySpace with _$GallerySpace {
  const factory GallerySpace({
    required String id,
    required String name,
    required String addressLine1,
    required String city,
    required String state,
    required String pincode,

    /// Max pieces this location can display at once.
    required int capacity,

    /// MOU §10: "nominate one Galleryzone coordinator".
    required String coordinatorName,
  }) = _GallerySpace;

  factory GallerySpace.fromJson(Map<String, dynamic> json) =>
      _$GallerySpaceFromJson(json);
}

@freezed
abstract class AggregatorProfile with _$AggregatorProfile {
  const factory AggregatorProfile({
    required String companyName,
    required String contactPerson,
    required String avatar,
    required String gstNumber,
    required String phone,
    required String addressLine1,
    required String bankAccountMasked,
    required String ifsc,
    required String securityDepositStatus,

    /// Signed once from the aggregator's profile screen — the partner
    /// agreement, separate from the artist MOU. Null until they sign it, and
    /// reserving is refused until they do: an unsigned aggregator has no
    /// agreement covering custody, pricing or settlement, so they cannot take
    /// possession of anyone's artwork.
    MouAcceptance? mouAcceptance,
  }) = _AggregatorProfile;

  factory AggregatorProfile.fromJson(Map<String, dynamic> json) =>
      _$AggregatorProfileFromJson(json);
}

@freezed
abstract class AggregatorSettings with _$AggregatorSettings {
  const factory AggregatorSettings({
    required bool notifyNewAssignment,
    required bool notifySaleRecorded,
    required bool notifySettlementProcessed,
    required bool notifyExpiryReminder,
  }) = _AggregatorSettings;

  factory AggregatorSettings.fromJson(Map<String, dynamic> json) =>
      _$AggregatorSettingsFromJson(json);
}

/// A holding joined to the artwork it points at. Derived on read, never
/// persisted — the holding record itself carries only an `artworkId`.
class AggregatorHoldingView {
  const AggregatorHoldingView({required this.holding, required this.artwork});

  final AggregatorHolding holding;
  final Artwork artwork;
}

/// Buyers rolled up from recorded sales, keyed by email. Derived, not a
/// stored customer record — this portal never owns a customer table.
class AggregatorCustomer {
  const AggregatorCustomer({
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.orderCount,
    required this.totalSpend,
  });

  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final int orderCount;
  final double totalSpend;
}

/// The three dashboard headline figures.
class AggregatorDashboardSummary {
  const AggregatorDashboardSummary({
    required this.activeReservations,
    required this.commissionEarned,
    required this.pendingSettlements,
  });

  final int activeReservations;
  final double commissionEarned;
  final int pendingSettlements;
}

class AggregatorAnalyticsSummary {
  const AggregatorAnalyticsSummary({
    required this.salesCount,
    required this.totalRevenue,
    required this.commissionPending,
    required this.commissionAvailable,
    required this.customerCount,
    required this.activeReservations,
    required this.averageSoldPrice,
    required this.averageDisplayMarkup,
  });

  final int salesCount;
  final double totalRevenue;
  final double commissionPending;
  final double commissionAvailable;
  final int customerCount;
  final int activeReservations;
  final double averageSoldPrice;
  final double averageDisplayMarkup;
}

/// Revenue by artwork category, derived from recorded sales.
class CategoryPerformance {
  const CategoryPerformance({
    required this.category,
    required this.revenue,
    required this.orders,
  });

  final String category;
  final double revenue;
  final int orders;
}
