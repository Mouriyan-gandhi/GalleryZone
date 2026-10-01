import '../../../core/api/json_utils.dart';
import '../../models/artist.dart';
import '../../models/artwork.dart';
import '../../models/marketplace.dart';
import '../../models/passport.dart';

/// Wire JSON -> models for the public catalogue: artworks, artists, the
/// marketplace page, the passport and ownership transfers.
///
/// The API speaks paise and nullable-by-default; the models hold rupees and
/// defaults. Conversion lives here, in one place, so nothing past a mapper
/// ever learns the wire shape — the same split the website keeps in
/// `lib/api-mappers.ts`.

String _s(Object? value, [String fallback = '']) => value is String ? value : fallback;
String? _sn(Object? value) => value is String && value.isNotEmpty ? value : null;

ArtworkStatus artworkStatusFromApi(Object? code) => switch (code) {
  'draft' => ArtworkStatus.draft,
  'pending_approval' => ArtworkStatus.pendingApproval,
  'marketplace' => ArtworkStatus.marketplace,
  'reserved' => ArtworkStatus.reserved,
  'preparing_dispatch' => ArtworkStatus.preparingDispatch,
  'in_transit' => ArtworkStatus.inTransit,
  'with_aggregator' => ArtworkStatus.withAggregator,
  'sold' => ArtworkStatus.sold,
  'settlement_complete' => ArtworkStatus.settlementComplete,
  'delivered' => ArtworkStatus.delivered,
  'completed' => ArtworkStatus.completed,
  'returned' => ArtworkStatus.returned,
  'sold_externally' => ArtworkStatus.soldExternally,
  // A status this build has never heard of is treated as "not for sale" —
  // the safe reading for a piece someone might otherwise try to buy.
  _ => ArtworkStatus.sold,
};

String artworkStatusToApi(ArtworkStatus status) => switch (status) {
  ArtworkStatus.draft => 'draft',
  ArtworkStatus.pendingApproval => 'pending_approval',
  ArtworkStatus.marketplace => 'marketplace',
  ArtworkStatus.reserved => 'reserved',
  ArtworkStatus.preparingDispatch => 'preparing_dispatch',
  ArtworkStatus.inTransit => 'in_transit',
  ArtworkStatus.withAggregator => 'with_aggregator',
  ArtworkStatus.sold => 'sold',
  ArtworkStatus.settlementComplete => 'settlement_complete',
  ArtworkStatus.delivered => 'delivered',
  ArtworkStatus.completed => 'completed',
  ArtworkStatus.returned => 'returned',
  ArtworkStatus.soldExternally => 'sold_externally',
};

ListingType listingTypeFromApi(Object? code) => switch (code) {
  'aggregator_only' => ListingType.aggregatorOnly,
  'marketplace_and_aggregator' => ListingType.marketplaceAndAggregator,
  _ => ListingType.marketplaceOnly,
};

String listingTypeToApi(ListingType type) => switch (type) {
  ListingType.marketplaceOnly => 'marketplace_only',
  ListingType.aggregatorOnly => 'aggregator_only',
  ListingType.marketplaceAndAggregator => 'marketplace_and_aggregator',
};

ArtworkSizeBand? sizeBandFromApi(Object? code) => switch (code) {
  'small' => ArtworkSizeBand.small,
  'medium' => ArtworkSizeBand.medium,
  'large' => ArtworkSizeBand.large,
  _ => null,
};

String sizeBandToApi(ArtworkSizeBand band) => band.name;

FramingState? framingFromApi(Object? code) => switch (code) {
  'framed' => FramingState.framed,
  'stretched_canvas' => FramingState.stretchedCanvas,
  'unframed_rolled' => FramingState.unframedRolled,
  'mounted_board' => FramingState.mountedBoard,
  'freestanding' => FramingState.freestanding,
  _ => null,
};

String framingToApi(FramingState framing) => switch (framing) {
  FramingState.framed => 'framed',
  FramingState.stretchedCanvas => 'stretched_canvas',
  FramingState.unframedRolled => 'unframed_rolled',
  FramingState.mountedBoard => 'mounted_board',
  FramingState.freestanding => 'freestanding',
};

ArtworkPhysical? physicalFromApi(Object? value) {
  if (value is! Map) return null;
  final json = asMap(value);
  final weight = json['weightKg'];
  return ArtworkPhysical(
    weightKg: weight is num ? weight.toDouble() : null,
    framing: framingFromApi(json['framing']),
    format: _sn(json['format']),
    hangingHardwareIncluded: json['hangingHardwareIncluded'] == true,
    packagingConfirmed: json['packagingConfirmed'] == true,
  );
}

Map<String, dynamic> physicalToApi(ArtworkPhysical physical) => {
  'weightKg': physical.weightKg,
  'framing': physical.framing == null ? null : framingToApi(physical.framing!),
  'format': physical.format,
  'hangingHardwareIncluded': physical.hangingHardwareIncluded,
  'packagingConfirmed': physical.packagingConfirmed,
};

ArtworkImage imageFromApi(Map<String, dynamic> json) {
  final url = _s(json['url']);
  return ArtworkImage(
    url: url,
    thumbnailUrl: _sn(json['thumbnailUrl']) ?? url,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    altText: _s(json['altText']),
    id: _sn(json['id']),
  );
}

List<ArtworkImage> _imagesOf(Object? value) =>
    asMapList(value).map(imageFromApi).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

/// A piece as the public sees it (`CustomerArtworkDto`). The same function
/// reads the owner's richer view, whose extra fields are all optional.
Artwork artworkFromApi(Map<String, dynamic> json) {
  final images = _imagesOf(json['images']);
  final status = artworkStatusFromApi(json['status']);
  final history = asMapList(json['statusHistory']);
  return Artwork(
    id: _s(json['id']),
    title: _s(json['title']),
    artistId: _s(json['artistId']),
    artistName: _s(json['artistName']),
    // Verification tiers aren't on the public DTO yet — the website defaults
    // them to false too, so no badge is drawn rather than a guessed one.
    verifiedArtist: false,
    category: _s(json['category']),
    medium: _s(json['medium']),
    customerPrice: rupeesAt(json, 'displayPricePaise'),
    // No photo yet reads as an empty url, which the image view draws as an
    // honest "Image coming soon" rather than a shared stock picture.
    thumbnailUrl: images.firstOrNull?.thumbnailUrl ?? '',
    insured: json['insured'] == true,
    status: status,
    listingType: listingTypeFromApi(json['listingType']),
    description: _s(json['description']),
    dimensions: _sn(json['dimensions']),
    yearCreated: (json['yearCreated'] as num?)?.toInt(),
    images: images,
    coaCertificateNumber: _s(json['coaCertificateNumber']),
    coaIssueDate: isoOf(json['coaIssuedAt']),
    socialProofLinks: const [],
    // The public view carries only the current status. The owner's view
    // carries the log; otherwise one synthetic entry keeps "newest" ordering
    // and the edit-window arithmetic working.
    statusHistory: history.isNotEmpty
        ? [
            for (final event in history)
              ArtworkStatusEvent(
                status: artworkStatusFromApi(event['status']),
                changedAt: isoOf(event['changedAt']),
              ),
          ]
        : [ArtworkStatusEvent(status: status, changedAt: isoOf(json['createdAt']))],
    nfcTagId: _sn(json['nfcTagId']),
    rarityType: artworkRarityFromCode(_sn(json['rarityType'])),
    physical: physicalFromApi(json['physical']),
    productCode: _sn(json['productCode']),
    artworkType: _sn(json['artworkType']),
    paintingStyle: _sn(json['paintingStyle']),
    insuranceNumber: _sn(json['insuranceNumber']),
    insuranceStatus: reviewStatusFromCode(_sn(json['insuranceStatus'])),
    artistLocation: _sn(json['artistLocation']),
    sizeBand: sizeBandFromApi(json['sizeBand']),
  );
}

/// The artist's own view of a piece (`OwnerArtworkDto`): the public piece plus
/// the private price and what the artist would take home.
ArtistArtwork ownerArtworkFromApi(Map<String, dynamic> json) {
  final net = asMap(json['artistNet']);
  final insuranceOpted = json['insuranceOpted'] == true;
  return ArtistArtwork(
    artwork: artworkFromApi(json).copyWith(insured: insuranceOpted || json['insured'] == true),
    artistPrice: rupeesAt(json, 'artistPricePaise'),
    artistNetMarketplace: rupeesAt(net, 'marketplace'),
    artistNetAggregator: rupeesAt(net, 'aggregatorEstimate'),
    editableUntil: _sn(json['editableUntil']),
    insuranceOpted: insuranceOpted,
  );
}

ArtistProfile artistProfileFromApi(Map<String, dynamic> json) => ArtistProfile(
  id: _s(json['id']),
  name: _s(json['name']),
  bio: _s(json['bio']),
  profileImageUrl: _s(json['profileImageUrl']),
  verification: const ArtistVerificationState(
    tier1SocialMedia: false,
    tier2ActivePlan: false,
    tier3FirstSale: false,
  ),
  socialLinks: const [],
  headline: _s(json['headline']),
  location: _s(json['location']),
);

ArtistCard artistCardFromApi(Map<String, dynamic> json) => ArtistCard(
  profile: artistProfileFromApi(json),
  artworkCount: (json['artworkCount'] as num?)?.toInt() ?? 0,
  coverImageUrl: _sn(json['coverImageUrl']),
);

MarketplacePage marketplacePageFromApi(Map<String, dynamic> json) {
  final facets = asMap(json['facets']);
  final counts = <ArtworkRarity, int>{};
  // "N" and "S" are the same rank; fold any old rows onto Standard.
  asMap(facets['rarityCounts']).forEach((code, count) {
    final rank = artworkRarityFromCode(code);
    if (rank != null && count is num) counts[rank] = (counts[rank] ?? 0) + count.toInt();
  });
  final range = asMap(facets['priceRangePaise']);
  List<String> strings(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is String) item,
  ];
  return MarketplacePage(
    artworks: asMapList(json['artworks']).map(artworkFromApi).toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['pageSize'] as num?)?.toInt() ?? marketplacePageSize,
    facets: MarketplaceFacets(
      categories: strings(facets['categories']),
      mediums: strings(facets['mediums']),
      locations: strings(facets['locations']),
      artists: [
        for (final artist in asMapList(facets['artists']))
          FacetArtist(id: _s(artist['id']), name: _s(artist['name'])),
      ],
      rarityCounts: counts,
      priceMin: range['min'] is num ? paiseToRupees(range['min'] as num) : null,
      priceMax: range['max'] is num ? paiseToRupees(range['max'] as num) : null,
    ),
  );
}

// --- Provenance --------------------------------------------------------------

TransferKind transferKindFromApi(Object? code) =>
    code == 'display' ? TransferKind.display : TransferKind.ownership;

TransferStatus transferStatusFromApi(Object? code) => switch (code) {
  'accepted' => TransferStatus.accepted,
  'cancelled' => TransferStatus.cancelled,
  _ => TransferStatus.pending,
};

/// A transfer as one of its two parties sees it (`GET /v1/transfers/:id`).
OwnershipTransfer transferFromApi(Map<String, dynamic> json) => OwnershipTransfer(
  id: _s(json['id']),
  artworkId: _s(json['artworkId']),
  artworkTitle: _s(json['artworkTitle'], 'Artwork'),
  fromName: _s(json['fromName']),
  toName: _s(json['toName']),
  toEmail: _s(json['toEmail']),
  initiatedAt: isoOf(json['initiatedAt']),
  acceptedAt: isoOrNull(json['acceptedAt']),
  cancelledAt: isoOrNull(json['cancelledAt']),
  status: transferStatusFromApi(json['status']),
  kind: transferKindFromApi(json['kind']),
  displayEndsAt: isoOrNull(json['displayEndsAt']),
  displayEndedAt: isoOrNull(json['displayEndedAt']),
);

PassportEvent passportEventFromApi(Map<String, dynamic> json) => PassportEvent(
  id: _s(json['id']),
  kind: transferKindFromApi(json['kind']),
  status: transferStatusFromApi(json['status']),
  fromName: _s(json['fromName']),
  toName: _s(json['toName']),
  viaSale: json['viaSale'] == true,
  initiatedAt: isoOf(json['initiatedAt']),
  acceptedAt: isoOrNull(json['acceptedAt']),
  cancelledAt: isoOrNull(json['cancelledAt']),
  displayEndsAt: isoOrNull(json['displayEndsAt']),
  displayEndedAt: isoOrNull(json['displayEndedAt']),
);

Passport passportFromApi(Map<String, dynamic> json) {
  final owner = asMap(json['owner']);
  return Passport(
    artworkId: _s(json['artworkId']),
    productCode: _s(json['productCode']),
    title: _s(json['title']),
    artistId: _s(json['artistId']),
    artistName: _s(json['artistName']),
    category: _s(json['category']),
    medium: _s(json['medium']),
    dimensions: _sn(json['dimensions']),
    yearCreated: (json['yearCreated'] as num?)?.toInt(),
    images: _imagesOf(json['images']),
    status: _s(json['status']),
    coaCertificateNumber: _sn(json['coaCertificateNumber']),
    coaIssuedAt: isoOrNull(json['coaIssuedAt']),
    listedAt: isoOf(json['listedAt']),
    ownerKind: owner['kind'] == 'collector' ? PassportOwnerKind.collector : PassportOwnerKind.artist,
    ownerName: _s(owner['displayName']),
    events: asMapList(json['events']).map(passportEventFromApi).toList(),
  );
}

MyPassports myPassportsFromApi(Map<String, dynamic> json) => MyPassports(
  total: (json['total'] as num?)?.toInt() ?? 0,
  items: [
    for (final item in asMapList(json['items']))
      MyPassport(
        relations: [
          for (final relation in (item['relations'] as List? ?? const []))
            switch (relation) {
              'artist' => PassportRelation.artist,
              'holder' => PassportRelation.holder,
              _ => PassportRelation.owner,
            },
        ],
        nfcLinked: item['nfcLinked'] is bool ? item['nfcLinked'] as bool : null,
        holdingId: _sn(item['holdingId']),
        passport: passportFromApi(asMap(item['passport'])),
      ),
  ],
);
