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

enum SocialProofPlatform { instagram, youtube, x, tiktok }

@freezed
abstract class ArtworkImage with _$ArtworkImage {
  const factory ArtworkImage({
    required String url,
    required String thumbnailUrl,
    required int sortOrder,
    required String altText,
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
    required String coaCertificateNumber,
    required String coaIssueDate,
    required List<SocialProofLink> socialProofLinks,
    required List<ArtworkStatusEvent> statusHistory,
    String? nfcTagId,

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
  }) = _OwnershipTransfer;

  factory OwnershipTransfer.fromJson(Map<String, dynamic> json) =>
      _$OwnershipTransferFromJson(json);
}

@freezed
abstract class ExternalSalePenalty with _$ExternalSalePenalty {
  const factory ExternalSalePenalty({
    required String id,
    required String artworkId,
    required String artworkTitle,
    required double amount,
    required String createdAt,
    String? settledAt,
  }) = _ExternalSalePenalty;

  factory ExternalSalePenalty.fromJson(Map<String, dynamic> json) =>
      _$ExternalSalePenaltyFromJson(json);
}

/// Artist-scoped view of an [Artwork] with the private asking price
/// attached. Only ever constructed by artist-scoped repository methods
/// (mirrors `Array<Artwork & {artistPrice}>` in `artistDashboardService.ts`)
/// — never by `ArtworkRepository`'s customer/public-facing methods.
@freezed
abstract class ArtistArtwork with _$ArtistArtwork {
  const factory ArtistArtwork({required Artwork artwork, required double artistPrice}) =
      _ArtistArtwork;
}
