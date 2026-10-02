import '../../data/models/artist_portal.dart';
import '../../data/models/artwork.dart';

/// The three verification tiers, computed from the account's real state:
///
///  1. a public handle (Instagram or a website) on the profile;
///  2. the artist agreement (MOU) signed;
///  3. a first confirmed sale.
///
/// Nothing here is stored - it is a projection of the profile, the agreement
/// and the artworks, so a tier cannot be ahead of or behind what it describes.
/// Port of `useVerificationTiers`.
List<VerificationTier> verificationTiersFor({
  required ArtistProfileDetails? profile,
  required MouAcceptance? mou,
  required List<ArtistArtwork> artworks,
}) {
  const sold = {
    ArtworkStatus.sold,
    ArtworkStatus.settlementComplete,
    ArtworkStatus.delivered,
    ArtworkStatus.completed,
  };
  final handle = (profile?.instagram ?? '').trim().isNotEmpty || (profile?.website ?? '').trim().isNotEmpty;
  final saleDates = [
    for (final entry in artworks)
      for (final event in entry.artwork.statusHistory)
        if (sold.contains(event.status)) event.changedAt,
  ]..sort();
  final firstSale = saleDates.firstOrNull;

  final done = [handle, mou != null, firstSale != null];
  final firstOpen = done.indexOf(false);
  VerificationTierStatus statusOf(int i) => done[i]
      ? VerificationTierStatus.complete
      : i == firstOpen
          ? VerificationTierStatus.active
          : VerificationTierStatus.locked;
  String? day(String? iso) => iso == null || iso.length < 10 ? null : iso.substring(0, 10);

  return [
    VerificationTier(
      tier: 1,
      title: 'Social media',
      description: 'Link an official handle so collectors can verify you.',
      detail: 'Add at least one official handle (Instagram or a website) on your profile so collectors can verify '
          "you're a real, active artist.",
      status: statusOf(0),
    ),
    VerificationTier(
      tier: 2,
      title: 'Artist agreement',
      description: 'Sign the GalleryZone artist agreement.',
      detail: 'Read and sign the Memorandum of Understanding from your profile. It covers listing, sale, settlement '
          'and provenance.',
      status: statusOf(1),
      completedOn: day(mou?.acceptedAt),
    ),
    VerificationTier(
      tier: 3,
      title: 'First sale',
      description: 'Complete your first confirmed sale on GalleryZone.',
      detail: "Sell one artwork through the marketplace or a partner gallery. Once confirmed, you'll unlock the Gold "
          '✦ Verified badge on your public profile and listings.',
      status: statusOf(2),
      completedOn: day(firstSale),
    ),
  ];
}

/// One thing that needs the artist's attention, and where to deal with it.
class AttentionItem {
  const AttentionItem({required this.id, required this.message, required this.path});

  final String id;
  final String message;
  final String path;
}

/// The same real signals - drafts, work awaiting review, unpaid settlements,
/// the badge still to earn - feed both the single "next up" prompt and the full
/// "needs attention" list, worked out once here so the two cannot drift apart.
/// Port of `useArtistAttentionItems`.
List<AttentionItem> attentionItemsFor({
  required List<ArtistArtwork> artworks,
  required List<Settlement> settlements,
  required List<VerificationTier> tiers,
}) {
  final drafts = artworks.where((a) => a.artwork.status == ArtworkStatus.draft).length;
  final inReview = artworks.where((a) => a.artwork.status == ArtworkStatus.pendingApproval).length;
  final pending = settlements.where((s) => s.status == SettlementStatus.pending).length;
  final tier3 = tiers.where((t) => t.tier == 3).firstOrNull;
  String plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';

  return [
    if (drafts > 0)
      AttentionItem(id: 'drafts', message: '${plural(drafts, 'artwork')} still in draft', path: '/dashboard/artworks'),
    if (inReview > 0)
      AttentionItem(
        id: 'review',
        message: '${plural(inReview, 'artwork')} awaiting curator review',
        path: '/dashboard/artworks',
      ),
    if (pending > 0)
      AttentionItem(
        id: 'settlements',
        message: '${plural(pending, 'settlement')} pending payout',
        path: '/dashboard/settlements',
      ),
    if (tier3 != null && tier3.status != VerificationTierStatus.complete)
      const AttentionItem(
        id: 'verification',
        message: 'Complete your first sale to unlock the Gold ✦ Verified badge',
        path: '/dashboard/verification',
      ),
  ];
}
