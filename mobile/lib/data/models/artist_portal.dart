import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_portal.freezed.dart';
part 'artist_portal.g.dart';

/// Artist-portal shapes: `features/dashboard/dashboard-data.ts`,
/// `types/message.ts`, `types/admin.ts`'s `Settlement` and
/// `types/aggregator.ts`'s `AggregatorHolding`.

/// Activity entries are persisted, so they carry a `kind` string rather than
/// an icon — an icon isn't JSON-serializable, and the feed maps kind to a
/// glyph at render time.
enum ActivityKind {
  @JsonValue('artwork_approved')
  artworkApproved,
  @JsonValue('artwork_submitted')
  artworkSubmitted,
  settlement,
  verification,
  withdrawal,
}

@freezed
abstract class ActivityEntry with _$ActivityEntry {
  const factory ActivityEntry({
    required String id,
    required ActivityKind kind,
    required String title,
    required String detail,
    required String time,
  }) = _ActivityEntry;

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => _$ActivityEntryFromJson(json);
}

enum AadhaarStatus { verified, pending, unverified }

/// The artist's own KYC/payout record. Distinct from [ArtistProfile] in
/// `artist.dart`, which is the *public* profile a collector sees — this one
/// carries bank and Aadhaar detail that never leaves the artist's own
/// screens.
@freezed
abstract class ArtistProfileDetails with _$ArtistProfileDetails {
  const factory ArtistProfileDetails({
    required String fullName,
    required String email,
    required String phone,
    required String bio,
    required String instagram,
    required String website,
    required String bankAccountMasked,
    required String ifsc,
    required AadhaarStatus aadhaarStatus,
    required String aadhaarMasked,

    /// Optional. Validated for shape only when one is entered — there is no
    /// GST portal integration, which the business deliberately does not want.
    String? gstin,
  }) = _ArtistProfileDetails;

  factory ArtistProfileDetails.fromJson(Map<String, dynamic> json) =>
      _$ArtistProfileDetailsFromJson(json);
}

@freezed
abstract class ArtistSettings with _$ArtistSettings {
  const factory ArtistSettings({
    required bool notifyArtworkApproved,
    required bool notifyNewSale,
    required bool notifyWithdrawalProcessed,
    required bool notifyNewMessage,
  }) = _ArtistSettings;

  factory ArtistSettings.fromJson(Map<String, dynamic> json) => _$ArtistSettingsFromJson(json);
}

/// An artist's acceptance of one version of the MOU. Versioned so a later
/// revision asks again rather than inheriting an acceptance of wording the
/// artist never saw.
@freezed
abstract class MouAcceptance with _$MouAcceptance {
  const factory MouAcceptance({
    required String version,
    required String acceptedAt,
  }) = _MouAcceptance;

  factory MouAcceptance.fromJson(Map<String, dynamic> json) =>
      _$MouAcceptanceFromJson(json);
}

enum SettlementStatus { pending, processed, failed }

@freezed
abstract class Settlement with _$Settlement {
  const factory Settlement({
    required String id,
    required String orderId,
    required String artworkTitle,
    required String artistName,
    required double artistAmount,
    required double aggregatorCommission,
    required double platformRevenue,
    required SettlementStatus status,
    required String createdAt,
    String? processedAt,
  }) = _Settlement;

  factory Settlement.fromJson(Map<String, dynamic> json) => _$SettlementFromJson(json);
}

@freezed
abstract class MessageThread with _$MessageThread {
  const factory MessageThread({
    required String id,
    required String from,
    required String subject,
    required String preview,
    required String body,
    required bool unread,
    required String receivedAt,
  }) = _MessageThread;

  factory MessageThread.fromJson(Map<String, dynamic> json) => _$MessageThreadFromJson(json);
}

enum HoldingStatus {
  reserved,
  @JsonValue('sold_pending_settlement')
  soldPendingSettlement,
}

enum AssignmentSource {
  @JsonValue('self_reserved')
  selfReserved,
  @JsonValue('gz_assigned')
  gzAssigned,
}

/// An artwork physically placed with an aggregator. The artist sees these on
/// Gallery Spaces; the aggregator portal (Phase 6) writes them.
@freezed
abstract class AggregatorHolding with _$AggregatorHolding {
  const factory AggregatorHolding({
    required String id,
    required String artworkId,
    required int advancePercent, // 5 or 3, per the SAD's reservation schema
    required double advanceAmount,
    required double displayPrice,
    required String assignedAt,
    required String expiresAt, // assignedAt + 30 days
    required HoldingStatus status,
    required AssignmentSource assignmentSource,
  }) = _AggregatorHolding;

  factory AggregatorHolding.fromJson(Map<String, dynamic> json) =>
      _$AggregatorHoldingFromJson(json);
}

@freezed
abstract class RevenuePoint with _$RevenuePoint {
  const factory RevenuePoint({required String month, required double amount}) = _RevenuePoint;

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => _$RevenuePointFromJson(json);
}

enum VerificationTierStatus { complete, active, locked }

/// The 3-tier ladder to the Gold ✦ Verified badge. Static in this phase —
/// nothing in the app advances a tier yet.
class VerificationTier {
  const VerificationTier({
    required this.tier,
    required this.title,
    required this.description,
    required this.detail,
    required this.status,
    this.completedOn,
  });

  final int tier;
  final String title;
  final String description;
  final String detail;
  final VerificationTierStatus status;
  final String? completedOn;
}

/// A dashboard headline figure. Derived on read from the wallet and the
/// artist's own artworks — never persisted, so it can't go stale.
class ArtistKpi {
  const ArtistKpi({
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
  });

  final String label;
  final String value;
  final String delta;
  final bool positive;
}
