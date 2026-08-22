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
  }) = _CustomerProfile;

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

/// Ownership isn't a separately-modeled event: a delivered order **is**
/// ownership (the Onboarding Guide's Stage 9 "sale & ownership transfer"
/// collapses into the order reaching `delivered`). So a collection entry is
/// just that order joined to the live artwork record, for COA/NFC/provenance.
/// Not persisted — derived on read, same as the web.
class CollectionItem {
  const CollectionItem({required this.order, required this.artwork});

  final Order order;
  final Artwork artwork;
}
