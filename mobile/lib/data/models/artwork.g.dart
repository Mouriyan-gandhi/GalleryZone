// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtworkImage _$ArtworkImageFromJson(Map<String, dynamic> json) =>
    _ArtworkImage(
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      altText: json['altText'] as String,
    );

Map<String, dynamic> _$ArtworkImageToJson(_ArtworkImage instance) =>
    <String, dynamic>{
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'sortOrder': instance.sortOrder,
      'altText': instance.altText,
    };

_SocialProofLink _$SocialProofLinkFromJson(Map<String, dynamic> json) =>
    _SocialProofLink(
      platform: $enumDecode(_$SocialProofPlatformEnumMap, json['platform']),
      url: json['url'] as String,
    );

Map<String, dynamic> _$SocialProofLinkToJson(_SocialProofLink instance) =>
    <String, dynamic>{
      'platform': _$SocialProofPlatformEnumMap[instance.platform]!,
      'url': instance.url,
    };

const _$SocialProofPlatformEnumMap = {
  SocialProofPlatform.instagram: 'instagram',
  SocialProofPlatform.youtube: 'youtube',
  SocialProofPlatform.x: 'x',
  SocialProofPlatform.tiktok: 'tiktok',
};

_ArtworkStatusEvent _$ArtworkStatusEventFromJson(Map<String, dynamic> json) =>
    _ArtworkStatusEvent(
      status: $enumDecode(_$ArtworkStatusEnumMap, json['status']),
      changedAt: json['changedAt'] as String,
    );

Map<String, dynamic> _$ArtworkStatusEventToJson(_ArtworkStatusEvent instance) =>
    <String, dynamic>{
      'status': _$ArtworkStatusEnumMap[instance.status]!,
      'changedAt': instance.changedAt,
    };

const _$ArtworkStatusEnumMap = {
  ArtworkStatus.draft: 'draft',
  ArtworkStatus.pendingApproval: 'pending_approval',
  ArtworkStatus.marketplace: 'marketplace',
  ArtworkStatus.reserved: 'reserved',
  ArtworkStatus.preparingDispatch: 'preparing_dispatch',
  ArtworkStatus.inTransit: 'in_transit',
  ArtworkStatus.withAggregator: 'with_aggregator',
  ArtworkStatus.sold: 'sold',
  ArtworkStatus.settlementComplete: 'settlement_complete',
  ArtworkStatus.delivered: 'delivered',
  ArtworkStatus.completed: 'completed',
  ArtworkStatus.returned: 'returned',
  ArtworkStatus.soldExternally: 'sold_externally',
};

_Artwork _$ArtworkFromJson(Map<String, dynamic> json) => _Artwork(
  id: json['id'] as String,
  title: json['title'] as String,
  artistId: json['artistId'] as String,
  artistName: json['artistName'] as String,
  verifiedArtist: json['verifiedArtist'] as bool,
  category: json['category'] as String,
  medium: json['medium'] as String,
  customerPrice: (json['customerPrice'] as num).toDouble(),
  thumbnailUrl: json['thumbnailUrl'] as String,
  insured: json['insured'] as bool,
  status: $enumDecode(_$ArtworkStatusEnumMap, json['status']),
  listingType: $enumDecode(_$ListingTypeEnumMap, json['listingType']),
  description: json['description'] as String,
  dimensions: json['dimensions'] as String?,
  yearCreated: (json['yearCreated'] as num?)?.toInt(),
  images: (json['images'] as List<dynamic>)
      .map((e) => ArtworkImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  coaCertificateNumber: json['coaCertificateNumber'] as String,
  coaIssueDate: json['coaIssueDate'] as String,
  socialProofLinks: (json['socialProofLinks'] as List<dynamic>)
      .map((e) => SocialProofLink.fromJson(e as Map<String, dynamic>))
      .toList(),
  statusHistory: (json['statusHistory'] as List<dynamic>)
      .map((e) => ArtworkStatusEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  nfcTagId: json['nfcTagId'] as String?,
  physical: json['physical'] == null
      ? null
      : ArtworkPhysical.fromJson(json['physical'] as Map<String, dynamic>),
  custody: json['custody'] == null
      ? null
      : ArtworkCustody.fromJson(json['custody'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ArtworkToJson(_Artwork instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artistId': instance.artistId,
  'artistName': instance.artistName,
  'verifiedArtist': instance.verifiedArtist,
  'category': instance.category,
  'medium': instance.medium,
  'customerPrice': instance.customerPrice,
  'thumbnailUrl': instance.thumbnailUrl,
  'insured': instance.insured,
  'status': _$ArtworkStatusEnumMap[instance.status]!,
  'listingType': _$ListingTypeEnumMap[instance.listingType]!,
  'description': instance.description,
  'dimensions': instance.dimensions,
  'yearCreated': instance.yearCreated,
  'images': instance.images,
  'coaCertificateNumber': instance.coaCertificateNumber,
  'coaIssueDate': instance.coaIssueDate,
  'socialProofLinks': instance.socialProofLinks,
  'statusHistory': instance.statusHistory,
  'nfcTagId': instance.nfcTagId,
  'physical': instance.physical,
  'custody': instance.custody,
};

const _$ListingTypeEnumMap = {
  ListingType.marketplaceOnly: 'marketplace_only',
  ListingType.aggregatorOnly: 'aggregator_only',
  ListingType.marketplaceAndAggregator: 'marketplace_and_aggregator',
};

_ArtworkPhysical _$ArtworkPhysicalFromJson(Map<String, dynamic> json) =>
    _ArtworkPhysical(
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      framing: $enumDecodeNullable(_$FramingStateEnumMap, json['framing']),
      format: json['format'] as String?,
      hangingHardwareIncluded:
          json['hangingHardwareIncluded'] as bool? ?? false,
      packagingConfirmed: json['packagingConfirmed'] as bool? ?? false,
    );

Map<String, dynamic> _$ArtworkPhysicalToJson(_ArtworkPhysical instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'framing': _$FramingStateEnumMap[instance.framing],
      'format': instance.format,
      'hangingHardwareIncluded': instance.hangingHardwareIncluded,
      'packagingConfirmed': instance.packagingConfirmed,
    };

const _$FramingStateEnumMap = {
  FramingState.framed: 'framed',
  FramingState.stretchedCanvas: 'stretched_canvas',
  FramingState.unframedRolled: 'unframed_rolled',
  FramingState.mountedBoard: 'mounted_board',
  FramingState.freestanding: 'freestanding',
};

_ArtworkCustody _$ArtworkCustodyFromJson(Map<String, dynamic> json) =>
    _ArtworkCustody(
      legalOwner: $enumDecode(_$CustodyPartyEnumMap, json['legalOwner']),
      legalOwnerName: json['legalOwnerName'] as String?,
      custodian: $enumDecode(_$CustodyPartyEnumMap, json['custodian']),
      locationLabel: json['locationLabel'] as String,
    );

Map<String, dynamic> _$ArtworkCustodyToJson(_ArtworkCustody instance) =>
    <String, dynamic>{
      'legalOwner': _$CustodyPartyEnumMap[instance.legalOwner]!,
      'legalOwnerName': instance.legalOwnerName,
      'custodian': _$CustodyPartyEnumMap[instance.custodian]!,
      'locationLabel': instance.locationLabel,
    };

const _$CustodyPartyEnumMap = {
  CustodyParty.artist: 'artist',
  CustodyParty.galleryzone: 'galleryzone',
  CustodyParty.aggregator: 'aggregator',
  CustodyParty.customer: 'customer',
};

_PhysicalCoaRequest _$PhysicalCoaRequestFromJson(Map<String, dynamic> json) =>
    _PhysicalCoaRequest(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      artworkTitle: json['artworkTitle'] as String,
      coaCertificateNumber: json['coaCertificateNumber'] as String,
      requestedByName: json['requestedByName'] as String,
      requestedAt: json['requestedAt'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      status: $enumDecode(_$PhysicalCoaStatusEnumMap, json['status']),
      dispatchedAt: json['dispatchedAt'] as String?,
      courierRef: json['courierRef'] as String?,
    );

Map<String, dynamic> _$PhysicalCoaRequestToJson(_PhysicalCoaRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artworkId': instance.artworkId,
      'artworkTitle': instance.artworkTitle,
      'coaCertificateNumber': instance.coaCertificateNumber,
      'requestedByName': instance.requestedByName,
      'requestedAt': instance.requestedAt,
      'deliveryAddress': instance.deliveryAddress,
      'status': _$PhysicalCoaStatusEnumMap[instance.status]!,
      'dispatchedAt': instance.dispatchedAt,
      'courierRef': instance.courierRef,
    };

const _$PhysicalCoaStatusEnumMap = {
  PhysicalCoaStatus.requested: 'requested',
  PhysicalCoaStatus.dispatched: 'dispatched',
};

_OwnershipTransfer _$OwnershipTransferFromJson(Map<String, dynamic> json) =>
    _OwnershipTransfer(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      artworkTitle: json['artworkTitle'] as String,
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
      toEmail: json['toEmail'] as String,
      initiatedAt: json['initiatedAt'] as String,
      acceptedAt: json['acceptedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      status: $enumDecode(_$TransferStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$OwnershipTransferToJson(_OwnershipTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'artworkId': instance.artworkId,
      'artworkTitle': instance.artworkTitle,
      'fromName': instance.fromName,
      'toName': instance.toName,
      'toEmail': instance.toEmail,
      'initiatedAt': instance.initiatedAt,
      'acceptedAt': instance.acceptedAt,
      'cancelledAt': instance.cancelledAt,
      'status': _$TransferStatusEnumMap[instance.status]!,
    };

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pending',
  TransferStatus.accepted: 'accepted',
  TransferStatus.cancelled: 'cancelled',
};

_ExternalSalePenalty _$ExternalSalePenaltyFromJson(Map<String, dynamic> json) =>
    _ExternalSalePenalty(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      artworkTitle: json['artworkTitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
      settledAt: json['settledAt'] as String?,
    );

Map<String, dynamic> _$ExternalSalePenaltyToJson(
  _ExternalSalePenalty instance,
) => <String, dynamic>{
  'id': instance.id,
  'artworkId': instance.artworkId,
  'artworkTitle': instance.artworkTitle,
  'amount': instance.amount,
  'createdAt': instance.createdAt,
  'settledAt': instance.settledAt,
};
