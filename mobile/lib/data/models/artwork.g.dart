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
};

const _$ListingTypeEnumMap = {
  ListingType.marketplaceOnly: 'marketplace_only',
  ListingType.marketplaceAndAggregator: 'marketplace_and_aggregator',
};
