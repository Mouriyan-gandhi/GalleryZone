import 'package:freezed_annotation/freezed_annotation.dart';

import 'artwork.dart';
import 'order.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// Mirrors `types/customer.ts`, `types/resale.ts`, `types/support.ts` and the
/// wallet shape in `features/dashboard/dashboard-data.ts` — the collector's
/// own data, kept in one file because no screen needs one without the others.
@freezed
abstract class CustomerProfile with _$CustomerProfile {
  const factory CustomerProfile({
    required String name,
    required String email,
    required String phone,

    /// Optional, and never blocks anything — a collector who wants GST
    /// invoices for a business or office collection can add one.
    String? gstin,

    /// Where a refund or resale payout is sent. This balance is the
    /// collector's own money, not store credit: a refund on a ₹1,36,500
    /// painting that can only be spent back on the same site is not a refund.
    /// Optional, because most buyers only ever pay in and never need it.
    @Default('') String bankAccountName,
    @Default('') String bankAccountNumber,
    @Default('') String bankIfsc,

    /// Collecting on GalleryZone since (ISO). Empty when the API doesn't say.
    @Default('') String joinedAt,
  }) = _CustomerProfile;

  const CustomerProfile._();

  /// Enough to send money to.
  bool get hasBankDetails =>
      bankAccountName.trim().isNotEmpty &&
      bankAccountNumber.trim().isNotEmpty &&
      bankIfsc.trim().isNotEmpty;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);
}

@freezed
abstract class WalletSummary with _$WalletSummary {
  const factory WalletSummary({
    required double balance,
    required double pendingBalance,
    required double lockedBalance,
  }) = _WalletSummary;

  factory WalletSummary.fromJson(Map<String, dynamic> json) =>
      _$WalletSummaryFromJson(json);
}

enum WalletTransactionType { settlement, withdrawal, commission, refund, adjustment }

enum WalletTransactionStatus { completed, pending, failed }

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required WalletTransactionType type,
    required String label,
    required double amount,
    required String date,
    required WalletTransactionStatus status,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
}

enum ResaleListingStatus { active, sold, withdrawn }

@freezed
abstract class ResaleListing with _$ResaleListing {
  const factory ResaleListing({
    required String id,
    required String artworkId,
    required double listedPrice,
    required ResaleListingStatus status,
    required String listedAt,
  }) = _ResaleListing;

  factory ResaleListing.fromJson(Map<String, dynamic> json) =>
      _$ResaleListingFromJson(json);
}

enum SupportTicketStatus { open, answered, closed }

@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String subject,
    required String message,
    required SupportTicketStatus status,
    required String createdAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}

/// How a piece came to be in a collection.
enum CollectionSource {
  /// Bought on the marketplace — there is an order behind it.
  marketplaceOrder,

  /// Handed over by its previous owner (or bought from an aggregator in
  /// person) — there is no GalleryZone order to point at.
  transfer,
}

/// What a collector owns right now.
///
/// Ownership is the provenance ledger's call, not the order's: title passes on
/// *payment*, a piece received by transfer has no order at all, and a resold
/// piece has an order but is no longer theirs. So an entry is the live artwork
/// plus — when one exists — the order that brought it here.
class CollectionItem {
  const CollectionItem({
    required this.artwork,
    this.order,
    this.source = CollectionSource.marketplaceOrder,
    this.acquiredAt,
    this.fromName = '',
  });

  final Artwork artwork;

  /// Null for a piece received by transfer.
  final Order? order;
  final CollectionSource source;

  /// When ownership arrived (ISO). Null on the offline mock, which only knows
  /// the order's own dates.
  final String? acquiredAt;

  /// Who it came from.
  final String fromName;

  /// What was paid, GST and delivery included; zero for a transfer.
  double get paidPrice => order?.total ?? 0;
}
