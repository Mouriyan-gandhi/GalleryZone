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
}

enum ListingType {
  @JsonValue('marketplace_only')
  marketplaceOnly,
  @JsonValue('marketplace_and_aggregator')
  marketplaceAndAggregator,
}

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
  const factory SocialProofLink({
    required SocialProofPlatform platform,
    required String url,
  }) = _SocialProofLink;

  factory SocialProofLink.fromJson(Map<String, dynamic> json) => _$SocialProofLinkFromJson(json);
}

@freezed
abstract class ArtworkStatusEvent with _$ArtworkStatusEvent {
  const factory ArtworkStatusEvent({
    required ArtworkStatus status,
    required String changedAt, // ISO date, kept as String like the web model
  }) = _ArtworkStatusEvent;

  factory ArtworkStatusEvent.fromJson(Map<String, dynamic> json) => _$ArtworkStatusEventFromJson(json);
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
  }) = _Artwork;

  factory Artwork.fromJson(Map<String, dynamic> json) => _$ArtworkFromJson(json);
}

/// Artist-scoped view of an [Artwork] with the private asking price
/// attached. Only ever constructed by artist-scoped repository methods
/// (mirrors `Array<Artwork & {artistPrice}>` in `artistDashboardService.ts`)
/// — never by `ArtworkRepository`'s customer/public-facing methods.
@freezed
abstract class ArtistArtwork with _$ArtistArtwork {
  const factory ArtistArtwork({
    required Artwork artwork,
    required double artistPrice,
  }) = _ArtistArtwork;
}
