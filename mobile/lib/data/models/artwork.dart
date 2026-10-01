import 'package:freezed_annotation/freezed_annotation.dart';

part 'artwork.freezed.dart';
part 'artwork.g.dart';

/// Mirrors `types/artwork.ts` field-for-field. `ArtworkStatus`/`ListingType`
/// values are the exact snake_case strings the mock services already use,
/// so seed fixtures ported from `lib/mock-data/artworks.ts` decode as-is.
enum ArtworkStatus {
  draft,
  @JsonValue('pending_approval')
  pendingApproval,
  marketplace,
  reserved,
  @JsonValue('preparing_dispatch')
  preparingDispatch,
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('with_aggregator')
  withAggregator,
  sold,
  @JsonValue('settlement_complete')
  settlementComplete,
  delivered,
  completed,
  returned,

  /// The artist sold the piece somewhere else and marked it here — it leaves
  /// every GalleryZone sales channel at once (see
  /// `ArtistRepository.markSoldElsewhere`).
  @JsonValue('sold_externally')
  soldExternally,
}

/// The artist picks the sales channel(s) a piece is listed through.
/// Marketplace (GalleryZone's own online store) and Aggregator (partner
/// premises that hold and display the physical work) are independent
/// channels; [marketplaceAndAggregator] is the union of the two, not a
/// third channel.
enum ListingType {
  @JsonValue('marketplace_only')
  marketplaceOnly,
  @JsonValue('aggregator_only')
  aggregatorOnly,
  @JsonValue('marketplace_and_aggregator')
  marketplaceAndAggregator,
}

const listingTypeLabel = {
  ListingType.marketplaceOnly: 'Marketplace only',
  ListingType.aggregatorOnly: 'Aggregator only',
  ListingType.marketplaceAndAggregator: 'Marketplace + Aggregator',
};

/// Always ask these two rather than comparing against a literal: adding a
/// channel later shouldn't mean hunting down every
/// `== ListingType.marketplaceAndAggregator` in the codebase again.
bool isMarketplaceListed(ListingType type) => type != ListingType.aggregatorOnly;

bool isAggregatorListed(ListingType type) => type != ListingType.marketplaceOnly;

/// GalleryZone's rank for a piece — Rare / Unique / Original / Standard —
/// shown as a badge over the artwork. It is GalleryZone's call, never the
/// artist's: an admin sets it when approving a piece, it can be changed
/// later but never cleared, so every listed piece carries one.
///
/// "Standard" (S) was "Normal" (N) until 30 Sep 2026. Saved data and old API
/// rows may still say `N`; [ArtworkRarityConverter] reads it as Standard.
enum ArtworkRarity {
  @JsonValue('R')
  rare,
  @JsonValue('U')
  unique,
  @JsonValue('O')
  original,
  @JsonValue('S')
  standard,
}

const artworkRarityCode = {
  ArtworkRarity.rare: 'R',
  ArtworkRarity.unique: 'U',
  ArtworkRarity.original: 'O',
  ArtworkRarity.standard: 'S',
};

const artworkRarityLabel = {
  ArtworkRarity.rare: 'Rare',
  ArtworkRarity.unique: 'Unique',
  ArtworkRarity.original: 'Original',
  ArtworkRarity.standard: 'Standard',
};

const artworkRarityDescription = {
  ArtworkRarity.rare: 'Limited or one-of-a-kind with exceptional provenance.',
  ArtworkRarity.unique: 'Singular piece — the only one in existence.',
  ArtworkRarity.original: 'Hand-made original by the artist.',
  ArtworkRarity.standard: 'Open edition or standard listing.',
};

/// Reads a rank from the API or from saved data: `S`, or the retired `N`.
/// Anything unrecognised is "unranked" (null) rather than a crash.
ArtworkRarity? artworkRarityFromCode(String? code) => switch (code) {
  'R' => ArtworkRarity.rare,
  'U' => ArtworkRarity.unique,
  'O' => ArtworkRarity.original,
  'S' || 'N' => ArtworkRarity.standard,
  _ => null,
};

class ArtworkRarityConverter implements JsonConverter<ArtworkRarity?, String?> {
  const ArtworkRarityConverter();

  @override
  ArtworkRarity? fromJson(String? json) => artworkRarityFromCode(json);

  @override
  String? toJson(ArtworkRarity? object) => object == null ? null : artworkRarityCode[object];
}

/// Rough size band the API derives from a piece's stored dimensions.
enum ArtworkSizeBand { small, medium, large }

const artworkSizeBandLabel = {
  ArtworkSizeBand.small: 'Small',
  ArtworkSizeBand.medium: 'Medium',
  ArtworkSizeBand.large: 'Large',
};

/// The four-value review vocabulary shared by every admin-reviewed fact:
/// insurance, GST number, KYC/Aadhaar. Same words, different domains — a
/// person can be approved on one and rejected on another.
enum ReviewStatus {
  @JsonValue('not_submitted')
  notSubmitted,
  submitted,
  approved,
  rejected,
}

const reviewStatusLabel = {
  ReviewStatus.notSubmitted: 'Not submitted',
  ReviewStatus.submitted: 'Under review',
  ReviewStatus.approved: 'Approved',
  ReviewStatus.rejected: 'Rejected',
};

ReviewStatus reviewStatusFromCode(String? code) => switch (code) {
  'submitted' => ReviewStatus.submitted,
  'approved' => ReviewStatus.approved,
  'rejected' => ReviewStatus.rejected,
  _ => ReviewStatus.notSubmitted,
};

enum SocialProofPlatform { instagram, youtube, x, tiktok }

@freezed
abstract class ArtworkImage with _$ArtworkImage {
  const factory ArtworkImage({
    required String url,
    required String thumbnailUrl,
    required int sortOrder,
    required String altText,

    /// Server id — present on the artist's own views, where it is what lets
    /// a photo be deleted or reordered. Public views carry none.
    String? id,
  }) = _ArtworkImage;

  factory ArtworkImage.fromJson(Map<String, dynamic> json) => _$ArtworkImageFromJson(json);
}

@freezed
abstract class SocialProofLink with _$SocialProofLink {
  const factory SocialProofLink({required SocialProofPlatform platform, required String url}) =
      _SocialProofLink;

  factory SocialProofLink.fromJson(Map<String, dynamic> json) => _$SocialProofLinkFromJson(json);
}

@freezed
abstract class ArtworkStatusEvent with _$ArtworkStatusEvent {
  const factory ArtworkStatusEvent({
    required ArtworkStatus status,
    required String changedAt, // ISO date, kept as String like the web model
  }) = _ArtworkStatusEvent;

  factory ArtworkStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$ArtworkStatusEventFromJson(json);
}

/// The customer/public-facing shape — deliberately has no `artistPrice`
/// field anywhere on this type. That's not an oversight: SAD §8.7 requires
/// the artist's private asking price to never appear in any customer- or
/// public-facing payload, enforced structurally, not by the UI choosing not
/// to render a field that's present anyway. See [ArtistArtwork].
@freezed
abstract class Artwork with _$Artwork {
  const factory Artwork({
    required String id,
    required String title,
    required String artistId,
    required String artistName,
    required bool verifiedArtist,
    required String category,
    required String medium,
    required double customerPrice,
    required String thumbnailUrl,
    required bool insured,
    required ArtworkStatus status,
    required ListingType listingType,
    required String description,
    String? dimensions,
    int? yearCreated,
    required List<ArtworkImage> images,

    /// The certificate belongs to the owner's, artist's and passport views —
    /// the public marketplace no longer carries it (1 Oct 2026), so these are
    /// empty on a listing and must not be formatted without checking.
    @Default('') String coaCertificateNumber,
    @Default('') String coaIssueDate,
    required List<SocialProofLink> socialProofLinks,
    required List<ArtworkStatusEvent> statusHistory,
    String? nfcTagId,

    /// GalleryZone's rank (R / U / O / S). Null until an admin has ranked the
    /// piece, and on fixtures that predate the field.
    @ArtworkRarityConverter() ArtworkRarity? rarityType,

    /// GZ000004-style product code printed on the tag and the passport.
    String? productCode,

    /// Original / limited edition / open edition / study / commission / other.
    String? artworkType,

    /// Which of the world painting traditions this is — only for paintings.
    String? paintingStyle,

    /// Policy number the artist pasted back from the insurer, and the admin's
    /// verdict on it. Only meaningful when [insured] is true.
    String? insuranceNumber,
    @Default(ReviewStatus.notSubmitted) ReviewStatus insuranceStatus,

    /// The artist's public location; an artwork has none of its own.
    String? artistLocation,
    ArtworkSizeBand? sizeBand,

    /// Weight, framing and packing. Nullable because the fixture records
    /// predate the fields; the submit form collects them and requires them
    /// once the aggregator channel is picked.
    ArtworkPhysical? physical,

    /// Ownership, physical custody and location are three independent
    /// states, never one "owner" field — a piece can be legally owned by
    /// GalleryZone, physically held by an aggregator, and located in a third
    /// city all at once. Nullable so the seeded fixtures don't need a value:
    /// [resolveCustody] derives one from `status` when it's absent.
    ArtworkCustody? custody,
  }) = _Artwork;

  factory Artwork.fromJson(Map<String, dynamic> json) => _$ArtworkFromJson(json);
}

// --- Physical details -------------------------------------------------------

/// How the piece arrives. MOU §12 requires work sent for aggregator display
/// to be either professionally stretched on canvas or properly framed, so
/// those two are the compliant options and the rest are flagged in the form.
enum FramingState {
  framed,
  @JsonValue('stretched_canvas')
  stretchedCanvas,
  @JsonValue('unframed_rolled')
  unframedRolled,
  @JsonValue('mounted_board')
  mountedBoard,
  freestanding,
}

const framingLabel = {
  FramingState.framed: 'Framed',
  FramingState.stretchedCanvas: 'Stretched on canvas',
  FramingState.unframedRolled: 'Unframed / rolled',
  FramingState.mountedBoard: 'Mounted on board',
  FramingState.freestanding: 'Freestanding (sculpture)',
};

/// MOU §12: only these two are acceptable for a piece going to an aggregator.
const aggregatorReadyFraming = {FramingState.framed, FramingState.stretchedCanvas};

@freezed
abstract class ArtworkPhysical with _$ArtworkPhysical {
  const factory ArtworkPhysical({
    double? weightKg,
    FramingState? framing,

    /// Surface or format — canvas, paper, board, panel, bronze.
    String? format,

    /// MOU §12: hangers must ship with the artwork.
    @Default(false) bool hangingHardwareIncluded,

    /// Artist has confirmed packing to GalleryZone's shipping standard.
    @Default(false) bool packagingConfirmed,
  }) = _ArtworkPhysical;

  factory ArtworkPhysical.fromJson(Map<String, dynamic> json) =>
      _$ArtworkPhysicalFromJson(json);
}

/// What is still missing before this piece can go to an aggregator, in words
/// the artist can act on. Empty means ready.
///
/// One function, read by the form and by anything else that needs to know —
/// the web learned this the hard way with the insurance rule.
List<String> missingForAggregator(ArtworkPhysical? physical) => [
  if ((physical?.weightKg ?? 0) <= 0) 'weight',
  if (physical?.framing == null)
    'framing'
  else if (!aggregatorReadyFraming.contains(physical!.framing))
    'framed or stretched-canvas presentation',
  if ((physical?.format ?? '').isEmpty) 'artwork format',
  if (!(physical?.hangingHardwareIncluded ?? false)) 'hangers included',
  if (!(physical?.packagingConfirmed ?? false)) 'packing confirmation',
];

// --- Ownership / custody / location -----------------------------------------

enum CustodyParty { artist, galleryzone, aggregator, customer }

const custodyPartyLabel = {
  CustodyParty.artist: 'Artist',
  CustodyParty.galleryzone: 'GalleryZone',
  CustodyParty.aggregator: 'Aggregator',
  CustodyParty.customer: 'Collector',
};

@freezed
abstract class ArtworkCustody with _$ArtworkCustody {
  const factory ArtworkCustody({
    required CustodyParty legalOwner,

    /// Named owner once a transfer has been accepted (the buyer's own name).
    String? legalOwnerName,
    required CustodyParty custodian,
    required String locationLabel,
  }) = _ArtworkCustody;

  factory ArtworkCustody.fromJson(Map<String, dynamic> json) => _$ArtworkCustodyFromJson(json);
}

/// Fallback custody for a record that doesn't carry an explicit one yet.
/// Deriving from status is a stopgap for the mock phase only — once
/// transfers are recorded as real events, `custody` is written on every
/// transition and this map stops being consulted.
const _derivedCustody = {
  ArtworkStatus.draft: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Artist studio',
  ),
  ArtworkStatus.pendingApproval: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Artist studio',
  ),
  ArtworkStatus.marketplace: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Artist studio',
  ),
  ArtworkStatus.reserved: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Artist studio',
  ),
  ArtworkStatus.preparingDispatch: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Awaiting pickup',
  ),
  ArtworkStatus.inTransit: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.galleryzone,
    locationLabel: 'In transit',
  ),
  ArtworkStatus.withAggregator: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.aggregator,
    locationLabel: 'Aggregator premises',
  ),
  ArtworkStatus.sold: ArtworkCustody(
    legalOwner: CustodyParty.customer,
    custodian: CustodyParty.galleryzone,
    locationLabel: 'Awaiting delivery',
  ),
  ArtworkStatus.settlementComplete: ArtworkCustody(
    legalOwner: CustodyParty.customer,
    custodian: CustodyParty.galleryzone,
    locationLabel: 'Awaiting delivery',
  ),
  ArtworkStatus.delivered: ArtworkCustody(
    legalOwner: CustodyParty.customer,
    custodian: CustodyParty.customer,
    locationLabel: 'With the collector',
  ),
  ArtworkStatus.completed: ArtworkCustody(
    legalOwner: CustodyParty.customer,
    custodian: CustodyParty.customer,
    locationLabel: 'With the collector',
  ),
  ArtworkStatus.returned: ArtworkCustody(
    legalOwner: CustodyParty.artist,
    custodian: CustodyParty.artist,
    locationLabel: 'Returned to artist',
  ),
  ArtworkStatus.soldExternally: ArtworkCustody(
    legalOwner: CustodyParty.customer,
    custodian: CustodyParty.customer,
    locationLabel: 'Sold outside GalleryZone',
  ),
};

ArtworkCustody resolveCustody(Artwork artwork) =>
    artwork.custody ?? _derivedCustody[artwork.status]!;

// --- Edit window -------------------------------------------------------------

const artworkEditWindowDays = 7;

/// A purchase or claim ends the edit window immediately, however many of the
/// 7 days are left.
const _purchaseLockedStatuses = {
  ArtworkStatus.reserved,
  ArtworkStatus.preparingDispatch,
  ArtworkStatus.inTransit,
  ArtworkStatus.sold,
  ArtworkStatus.settlementComplete,
  ArtworkStatus.delivered,
  ArtworkStatus.completed,
  ArtworkStatus.soldExternally,
};

enum ArtworkEditReason { draft, withinWindow, purchased, windowClosed }

class ArtworkEditState {
  const ArtworkEditState({required this.editable, required this.reason, required this.daysLeft});

  final bool editable;
  final ArtworkEditReason reason;
  final int daysLeft;
}

/// 7 days from first listing OR until the piece is bought/claimed —
/// whichever comes first. Drafts aren't listed yet, so they stay editable
/// indefinitely.
ArtworkEditState artworkEditState(Artwork artwork, {DateTime? now}) {
  if (artwork.status == ArtworkStatus.draft) {
    return const ArtworkEditState(
      editable: true,
      reason: ArtworkEditReason.draft,
      daysLeft: artworkEditWindowDays,
    );
  }
  if (_purchaseLockedStatuses.contains(artwork.status)) {
    return const ArtworkEditState(
      editable: false,
      reason: ArtworkEditReason.purchased,
      daysLeft: 0,
    );
  }

  if (artwork.statusHistory.isEmpty) {
    return const ArtworkEditState(
      editable: true,
      reason: ArtworkEditReason.withinWindow,
      daysLeft: artworkEditWindowDays,
    );
  }

  final listedAt = DateTime.parse(artwork.statusHistory.first.changedAt);
  final elapsedDays =
      (now ?? DateTime.now()).difference(listedAt).inMilliseconds / Duration.millisecondsPerDay;
  final daysLeft = (artworkEditWindowDays - elapsedDays).ceil();
  return daysLeft > 0
      ? ArtworkEditState(editable: true, reason: ArtworkEditReason.withinWindow, daysLeft: daysLeft)
      : const ArtworkEditState(
          editable: false,
          reason: ArtworkEditReason.windowClosed,
          daysLeft: 0,
        );
}

// --- Selling outside GalleryZone ---------------------------------------------

/// Charged on the artist's NEXT listing when they mark a piece sold
/// elsewhere, as a fraction of that piece's listed price.
const externalSalePenaltyRate = 0.01;

/// An artist can withdraw a piece as "sold elsewhere" only while GalleryZone
/// has no claim on it. One set, read by both the portal UI and the
/// repository guard, so the button and the rule can never disagree.
const withdrawableStatuses = {
  ArtworkStatus.draft,
  ArtworkStatus.pendingApproval,
  ArtworkStatus.marketplace,
};

// --- Physical Certificate of Authenticity -----------------------------------

/// MOU §12: after a sale a buyer may ask for the COA on paper. The artist
/// prints it, signs it by hand and dispatches it through the portal — this
/// record is that request and its fulfilment.
enum PhysicalCoaStatus { requested, dispatched }

@freezed
abstract class PhysicalCoaRequest with _$PhysicalCoaRequest {
  const factory PhysicalCoaRequest({
    required String id,
    required String artworkId,
    required String artworkTitle,
    required String coaCertificateNumber,
    required String requestedByName,
    required String requestedAt,
    required String deliveryAddress,
    required PhysicalCoaStatus status,
    String? dispatchedAt,
    String? courierRef,
  }) = _PhysicalCoaRequest;

  factory PhysicalCoaRequest.fromJson(Map<String, dynamic> json) =>
      _$PhysicalCoaRequestFromJson(json);
}

// --- Ownership transfer (NFC passport hand-over) ----------------------------

/// A hand-over of the digital ownership record from the current owner to a
/// named buyer: the owner starts it, the buyer accepts through a link, and
/// the artwork's custody plus this list update together. The same flow runs
/// again on every resale, which is what keeps provenance continuous.
enum TransferStatus { pending, accepted, cancelled }

/// Art travels to be shown, and the piece that goes on a gallery wall for a
/// month has not changed hands. So a transfer is one of two things: a
/// permanent hand-over of ownership, or a time-boxed hand-over of display
/// rights that leaves the owner exactly where they were.
enum TransferKind { ownership, display }

const transferKindLabel = {
  TransferKind.ownership: 'Ownership',
  TransferKind.display: 'Display rights',
};

@freezed
abstract class OwnershipTransfer with _$OwnershipTransfer {
  const factory OwnershipTransfer({
    required String id,
    required String artworkId,
    required String artworkTitle,
    required String fromName,
    required String toName,
    required String toEmail,
    required String initiatedAt,
    String? acceptedAt,
    String? cancelledAt,
    required TransferStatus status,

    /// Null on records written before display rights existed — those are all
    /// ownership hand-overs. Read it through [transferKindOf].
    TransferKind? kind,

    /// Display transfers only: the date the display period runs to.
    String? displayEndsAt,

    /// Display transfers only: set when the owner pulls the piece back early.
    String? displayEndedAt,
  }) = _OwnershipTransfer;

  factory OwnershipTransfer.fromJson(Map<String, dynamic> json) =>
      _$OwnershipTransferFromJson(json);
}

TransferKind transferKindOf(OwnershipTransfer transfer) =>
    transfer.kind ?? TransferKind.ownership;

/// A display transfer ends by its own date. Nothing runs to make that happen —
/// every screen compares the date to now, so the display simply stops being
/// active when the day passes, exactly as it stops when the owner ends it
/// early.
bool isDisplayActive(OwnershipTransfer transfer, {DateTime? now}) {
  if (transferKindOf(transfer) != TransferKind.display) return false;
  if (transfer.status != TransferStatus.accepted) return false;
  if (transfer.displayEndedAt != null) return false;
  final endsAt = transfer.displayEndsAt;
  if (endsAt == null) return false;
  return DateTime.parse(endsAt).isAfter(now ?? DateTime.now());
}

/// The one display transfer currently in force for a piece, if any.
OwnershipTransfer? activeDisplayTransfer(
  List<OwnershipTransfer> transfers, {
  DateTime? now,
}) {
  for (final transfer in transfers) {
    if (isDisplayActive(transfer, now: now)) return transfer;
  }
  return null;
}

/// The off-platform sale fee is proposed, not imposed. Selling elsewhere can
/// be perfectly reasonable — a piece promised to a gallery before listing, a
/// commission that fell through — so an admin decides case by case whether it
/// is actually charged. Only an approved fee is ever collected.
enum PenaltyStatus {
  @JsonValue('pending_review')
  pendingReview,
  approved,
  waived,
}

const penaltyStatusLabel = {
  PenaltyStatus.pendingReview: 'Awaiting review',
  PenaltyStatus.approved: 'Approved',
  PenaltyStatus.waived: 'Waived',
};

@freezed
abstract class ExternalSalePenalty with _$ExternalSalePenalty {
  const factory ExternalSalePenalty({
    required String id,
    required String artworkId,
    required String artworkTitle,
    required double amount,
    required String createdAt,
    String? settledAt,

    /// Null on records written before the fee became reviewable — those were
    /// charged automatically, so they read as already approved.
    PenaltyStatus? status,
    String? decidedAt,

    /// The admin's note, shown back to the artist.
    String? decisionNote,
  }) = _ExternalSalePenalty;

  factory ExternalSalePenalty.fromJson(Map<String, dynamic> json) =>
      _$ExternalSalePenaltyFromJson(json);
}

PenaltyStatus penaltyStatusOf(ExternalSalePenalty penalty) =>
    penalty.status ?? PenaltyStatus.approved;

/// Only an approved, uncollected fee is ever taken from a wallet.
bool isPenaltyCollectable(ExternalSalePenalty penalty) =>
    penaltyStatusOf(penalty) == PenaltyStatus.approved &&
    penalty.settledAt == null;

/// Artist-scoped view of an [Artwork] with the private asking price
/// attached. Only ever constructed by artist-scoped repository methods
/// (mirrors `Array<Artwork & {artistPrice}>` in `artistDashboardService.ts`)
/// — never by `ArtworkRepository`'s customer/public-facing methods.
@freezed
abstract class ArtistArtwork with _$ArtistArtwork {
  const factory ArtistArtwork({
    required Artwork artwork,
    required double artistPrice,

    /// What the artist would take home, per channel, at today's rates — the
    /// API works it out (listing fee, TDS, service charges); the app only
    /// shows it. Zero on the offline mock, which has no rate sheet.
    @Default(0) double artistNetMarketplace,
    @Default(0) double artistNetAggregator,

    /// When the 7-day edit window closes (ISO). Null for a draft, which has none.
    String? editableUntil,

    /// Whether the artist opted into transit insurance, as opposed to it
    /// merely being required by the channel.
    @Default(false) bool insuranceOpted,
  }) = _ArtistArtwork;
}
