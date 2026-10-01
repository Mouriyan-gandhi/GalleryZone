import 'package:gallery_zone/data/models/artist.dart';
import 'package:gallery_zone/data/models/artwork.dart';
import 'package:gallery_zone/data/models/passport.dart';

/// A live marketplace piece. Every field a screen reads has a value; override
/// only what a test is about.
Artwork fixtureArtwork({
  String id = 'aw-1',
  String title = 'Monsoon, Madurai',
  String category = 'mixed-media',
  String medium = 'oil-on-canvas',
  double price = 48000,
  ArtworkStatus status = ArtworkStatus.marketplace,
  String thumbnail = '',
  String? nfcTagId,
  String coaNumber = 'GZ-COA-2026-0001',
  String coaIssued = '2026-03-04',
  ArtworkRarity? rank = ArtworkRarity.rare,
  List<ArtworkStatusEvent> history = const [],
  ArtworkCustody? custody,
}) {
  return Artwork(
    id: id,
    title: title,
    artistId: 'ar-1',
    artistName: 'Ananya Rao',
    verifiedArtist: true,
    category: category,
    medium: medium,
    customerPrice: price,
    thumbnailUrl: thumbnail,
    insured: true,
    status: status,
    listingType: ListingType.marketplaceOnly,
    description: 'A study in rain light.',
    dimensions: '24 x 36 in',
    yearCreated: 2021,
    images: const [],
    coaCertificateNumber: coaNumber,
    coaIssueDate: coaIssued,
    socialProofLinks: const [],
    statusHistory: history,
    nfcTagId: nfcTagId,
    rarityType: rank,
    custody: custody,
  );
}

ArtistProfile fixtureArtist({
  String id = 'ar-1',
  String name = 'Ananya Rao',
  String headline = 'Coastal light in oils',
  String location = 'Pune, Maharashtra',
  String bio = '<p>Ananya paints the coast.</p>',
}) {
  return ArtistProfile(
    id: id,
    name: name,
    bio: bio,
    profileImageUrl: '',
    verification: const ArtistVerificationState(
      tier1SocialMedia: true,
      tier2ActivePlan: false,
      tier3FirstSale: false,
    ),
    socialLinks: const [
      SocialProofLink(platform: SocialProofPlatform.instagram, url: 'https://instagram.com/ananya'),
      SocialProofLink(platform: SocialProofPlatform.youtube, url: 'https://youtube.com/@ananya'),
    ],
    headline: headline,
    location: location,
    joinedAt: '2026-03-04T09:00:00.000Z',
  );
}

PassportEvent fixtureEvent({
  String id = 'ev-1',
  TransferKind kind = TransferKind.ownership,
  TransferStatus status = TransferStatus.accepted,
  String from = 'Ananya Rao',
  String to = 'Dev Mehta',
  String initiatedAt = '2026-04-01T10:00:00.000Z',
  String? acceptedAt = '2026-04-02T10:00:00.000Z',
}) {
  return PassportEvent(
    id: id,
    kind: kind,
    status: status,
    fromName: from,
    toName: to,
    viaSale: false,
    initiatedAt: initiatedAt,
    acceptedAt: acceptedAt,
  );
}

Passport fixturePassport({
  String artworkId = 'aw-1',
  String owner = 'Dev Mehta',
  String? coaNumber = 'GZ-COA-2026-0001',
  String? coaIssuedAt = '2026-03-04',
  List<PassportEvent> events = const [],
}) {
  return Passport(
    artworkId: artworkId,
    productCode: 'GZ000004',
    title: 'Monsoon, Madurai',
    artistId: 'ar-1',
    artistName: 'Ananya Rao',
    category: 'mixed-media',
    medium: 'oil-on-canvas',
    images: const [],
    status: 'delivered',
    ownerKind: PassportOwnerKind.collector,
    ownerName: owner,
    events: events,
    listedAt: '2026-03-04T00:00:00.000Z',
    dimensions: '24 x 36 in',
    yearCreated: 2021,
    coaCertificateNumber: coaNumber,
    coaIssuedAt: coaIssuedAt,
  );
}
